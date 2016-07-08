function gf_data_outfile = UNM_run_gapfiller( sitecode, year, varargin ) 
% UNM_RUN_GAPFILLER - run the MPI gapfiller/partitioner for the specified site year.
%   
% This is the main wrapper function to use the Max Planck Institute's (MPI) eddy
% covariance flux gapfiller/partitioner to gapfill and partition a specified UNM
% dataset.  UNM_write_for_gapfiller_file generates a delimited ASCII file in
% a format that may be fed directly to UNM_run_gapfiller.  A "blocking" file
% is created using create_blocking_file to prevent Matlab from continuing
% until the gapfiller completes.
% The following tasks are performed:
%   (1) an R script is automatically generated to perform the
%       gapfilling/partitioning
%   (2) a system call is made to R to run the script
%   (3) the location of the R script, the gapfiller input file, the gapfiller
%       output file, and the gapfiller log file are written to stdout.
% 
% USAGE
%   gf_data_outfile = UNM_run_gapfiller( sitecode, year, ...
%                                        gf_data_dir, gf_data_infile );
%
% INPUTS
%    sitecode: UNM_sites object; the site whose data are to be processed
%    year: the year of the data to be processed.
%
% PARAMETER-VALUE PAIRS
%    gf_data_dir: character string; the directory containing the data to be
%        gapfilled and partitioned
%    gf_data_infile: character string; the file (within gf_data_dir) containing
%        the data to be gapfilled and partitioned
%
% OUTPUTS
%    gf_data_outfile: character string; the full path to the output generated
%        by REddyProc.
%
% SEE ALSO
%    UNM_write_for_gapfiller_file, create_blocking_file
%
% NOTE: As of July 2013, gapfilling and partitioning is performed locally using
% MPI's R package REddyProc.  This is a change from the past, when we used the
% online version of the tool.  As of 31 July 2013, further information about
% REddyProc is available at
% http://www.bgc-jena.mpg.de/bgi/index.php/Services/REddyProcWebRPackage.  Also
% as of 31 July 2013, the online version is available at
% http://www.bgc-jena.mpg.de/REddyProc/brew/REddyProc.rhtml.
%
% UNM_run_gapfiller generates an R script that uses REddyProc to gapfill and
% partition a dataset.  R and REddyProc (both free and open source) must be
% installed on the system; see http://www.r-project.org/ and
% http://cran.r-project.org/doc/manuals/r-release/R-admin.html#Installing-packages.
%
% author: Timothy W. Hilton and Litvak Lab, UNM, July 2013


%--------------------------------------------------
% parse inputs

args = inputParser();

args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'year', @isnumeric );
args.addParamValue( 'write_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParamValue( 'gf_data_dir', '', @ischar )
args.addParamValue( 'gf_data_infile', '', @ischar );

args.parse( sitecode, year, varargin{ : } );

if isempty( args.Results.gf_data_dir )
    gf_data_dir = fullfile( get_site_directory( args.Results.sitecode ), ...
                            'processed_flux' );
else
    gf_data_dir = args.Results.gf_data_dir; 
end

if isempty( args.Results.gf_data_infile )
    gf_data_infile = sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
                              char( args.Results.sitecode ), ...
                              args.Results.year );
else
    gf_data_infile = args.Results.gf_data_infile;
end

%--------------------------------------------------

% create blocking file
msg = sprintf( 'generated for gapfilling of %s-%d', ...
               char( args.Results.sitecode ), ...
               args.Results.year );
block_fname = create_blocking_file( msg );

% generate R script
[ gf_data_outfile, gf_R_infile ] = ...
    generate_gapfill_R_code( args.Results.sitecode, ...
                             args.Results.year, ...
                             gf_data_dir, ...
                             gf_data_infile, ...
                             block_fname );

% generate logfile name
gf_R_outfile = fullfile( getenv( 'FLUXROOT' ), 'Logs',...
                         'Gapfiller_Logs', ...
                         sprintf( '%s_%s_%d_gapfill.log', ...
                                  datestr( now, 'yyyy-mm-dd_HHMMSS' ), ...
                                  char( args.Results.sitecode ), ...
                                  args.Results.year ) );

% make system call to R to run the gapfiller
% Runs ok for linux
%cmd = sprintf( 'R CMD BATCH --no-restore --no-save %s %s', ...
%               gf_R_infile, ...
%               gf_R_outfile );
% but for windows specify the path
cmd = ['"C:\Program Files\R\R-3.3.0\bin\R.exe" ', ... 
        sprintf( 'CMD BATCH --no-restore --no-save %s %s', ...
                gf_R_infile, ...
                gf_R_outfile )] ;

fprintf( '\n-------------------------\nGAPFILLING/PARTITIONING\n' );
fprintf( 'R script: %s\n', gf_R_infile );
fprintf( 'gapfiller log file: %s\n', gf_R_outfile );
fprintf( 'gapfiller input data file: %s\n', fullfile( gf_data_dir, gf_data_infile ) );
fprintf( 'gapfiller output data file: %s\n', gf_data_outfile );
fprintf( 'system call: %s\n', cmd );
fprintf( 'gapfiller running\n ', cmd );

% calling R from within Matlab requires some environment variable
% manipulation.  See call_R (below) for details.
success = call_R( cmd );
% wait for the gapfiller, checking every 5 seconds whether it has completed
pause on;
while( exist( block_fname ) == 2 )
    fprintf( '.' );
    % flush non-graphics queues
    drawnow( 'update' );
    pause( 5 );
end
fprintf( '  done\n' );
pause off

fprintf( '-------------------------\n' );

% ============================================================

function [ gf_data_outfile, R_code_file ] = ...
    generate_gapfill_R_code( sitecode, ...
                             year, ...
                             gf_data_dir, ...
                             gf_data_infile, ...
                             blk_file )
% GENERATE_GAPFILL_R_CODE - generate an R script to run the gapfiller for a
%   given site, year, and for_gapfill data file.  This is a helper function
%   for UNM_run_gapfiller.  The R script generated is based on the example
%   provided with REddyProc.
%
% USAGE
% [ gf_data_outfile, gf_R_infile ] = ...
%     generate_gapfill_R_code( sitecode, ...
%                              year, ...
%                              gf_data_dir, ...
%                              gf_data_infile, ...
%                              block_file );
%
% INPUTS
%    sitecode: UNM_sites object; the site whose data are to be processed
%    year: the year of the data to be processed.
%    gf_data_dir: character string; the directory containing the data to be
%        gapfilled and partitioned
%    gf_data_infile: character string; the file (within gf_data_dir) containing
%        the data to be gapfilled and partitioned
%    block_file: a "blocking" file to prevent Matlab from moving forward
%        until the R script completes. 
%
% OUTPUTS
%    gf_data_outfile: character string; the full path to the output generated
%        by REddyProc.
%    R_code_file: character string; the full path to the R script file
%        generated. 
%
% SEE ALSO
%    create_blocking_file
%
% author: Timothy W. Hilton and Litvak Lab, UNM, July 2013

% Get site configuration
SiteConf = parse_yaml_config( sitecode, 'SiteVars' );

gf_data_outfile = '';

plot_outpath = fullfile( getenv( 'FLUXROOT' ), 'Plots', 'Reddyproc_out' );

R_code_file = sprintf( '%s_%s_%d_REddyProc.R', ...
                    tempname(), ...
                    char( sitecode ), ...
                    year );
fid = fopen( R_code_file, 'w' );



% ------------------------------------------------------------

%escape windows path backslashes for R
gf_data_dir = preformat_win_path( gf_data_dir );
gf_data_infile = preformat_win_path( gf_data_infile );
plot_outpath = preformat_win_path( plot_outpath );
% ------------------------------------------------------------
% write R code to run the gapfiller to R_code_file

fprintf( fid, '##generated automatically %s\n\n', datestr( now() ) );

fprintf( fid, 'library( "REddyProc" )\n\n' );

fprintf( fid, '##+++ write warning messages as they occur\n' );
fprintf( fid, 'options( warn=1 )\n\n' );

fprintf( fid, '##+++ Load data with one header and one unit row from (tab-delimited) text file\n' );
fprintf( fid, 'dir <- "%s"\n', gf_data_dir );
fprintf( fid, ['EddyData.F <- ' ...
               'fLoadTXTIntoDataframe("%s", Dir.s=dir)\n'], gf_data_infile );
fprintf( fid, '##+++ If not provided, calculate VPD from Tair and rH\n' );
fprintf( fid, 'EddyData.F <- cbind(EddyData.F,VPD=fCalcVPDfromRHandTair(EddyData.F$rH, EddyData.F$Tair))\n' );

fprintf( fid, '##+++ Add time stamp in POSIX time format\n' );
fprintf( fid, [ 'EddyDataWithPosix.F <- fConvertTimeToPosix(EddyData.F,', ...
                '"YMDHM", Year.s="year", Month.s="month", Day.s="day", Hour.s="hour", Min.s="minute")\n'] );
%'"YDH", Year.s="Year", Day.s="DoY", Hour.s="Hour")\n' ] );

fprintf( fid, '##+++ Initalize R5 reference class sEddyProc for processing of eddy data\n' );
fprintf( fid, '##+++ with all variables needed for processing later\n' );
fprintf( fid, ['EddyProc.C <- sEddyProc$new("%s", EddyDataWithPosix.F, ' ...
               'c("NEE","Rg", "Tair", "VPD", "LE", "H" ))\n\n'], ...
         UNM_sites_info( sitecode ).ameriflux );

fprintf( fid, '##+++ Generate plots of all data in directory plots (of current R working dir)\n' );
fprintf( fid, 'EddyProc.C$sPlotHHFluxes("NEE", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotFingerprint("Rg", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotDiurnalCycle("Tair", Dir.s="%s")\n', plot_outpath);
fprintf( fid, '##+++ Plot individual years to screen (of current R graphics device)\n' );
fprintf( fid, 'EddyProc.C$sPlotHHFluxesY("NEE", Year.i=%d)\n', year );
fprintf( fid, 'EddyProc.C$sPlotFingerprintY("NEE", Year.i=%d)\n\n', year );

% Note that there is no ustar filtering occurring here
fprintf( fid, '##+++ Fill gaps in variables with MDS gap filling algorithm\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("Tair", FillAll.b=FALSE)\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("VPD", FillAll.b=FALSE)\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("Rg", FillAll.b=FALSE)\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("NEE", FillAll.b=TRUE)\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("LE", FillAll.b=TRUE)\n' );
fprintf( fid, 'EddyProc.C$sMDSGapFill("H", FillAll.b=TRUE)\n\n' );

fprintf( fid, '##+++ Generate plots of filled data in directory /plots (of current R working dir)\n' );
fprintf( fid, 'EddyProc.C$sPlotHHFluxes("NEE_f", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotFingerprint("NEE_f", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotDailySums("NEE_f","NEE_fsd", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotDiurnalCycle("NEE_f", Dir.s="%s")\n\n', plot_outpath);

fprintf( fid, '#+++ Partition NEE into GPP and respiration (Reichstein 2005)\n');
fprintf( fid, ['EddyProc.C$sMRFluxPartition(', ...
    sprintf('Lat_deg.n=%2.2f, Long_deg.n=%3.2f, TimeZone_h.n=-7)', ...
           SiteConf.latitude, SiteConf.longitude), '\n']);  %Add location of site

fprintf( fid, '#+++ Example plots of calculated GPP and respiration\n' ); 
fprintf( fid, 'EddyProc.C$sPlotFingerprintY("GPP_f", Year.i=%d)\n', year );
fprintf( fid, 'EddyProc.C$sPlotFingerprint("GPP_f", Dir.s="%s")\n', plot_outpath);
fprintf( fid, 'EddyProc.C$sPlotHHFluxesY("Reco", Year.i=%d)\n', year );
fprintf( fid, 'EddyProc.C$sPlotHHFluxes("Reco", Dir.s="%s")\n\n', plot_outpath);

fprintf( fid, '##+++ Plot individual years/months to screen (of current R graphics device)\n' );
fprintf( fid, 'EddyProc.C$sPlotHHFluxesY("NEE_f", Year.i=%d)\n', year );
fprintf( fid, 'EddyProc.C$sPlotFingerprintY("NEE_f", Year.i=%d)\n', year );
fprintf( fid, 'EddyProc.C$sPlotDailySumsY("NEE_f","NEE_fsd", Year.i=%d)\n\n', year );
% I think this was causing an error
%fprintf( fid, 'EddyProc.C$sPlotDiurnalCycle("NEE_f", Month.i=5)\n' );

fprintf( fid, '##+++ Export gap filled data to standard data frame\n' );
fprintf( fid, 'FilledEddyData.F <- EddyProc.C$sExportResults()\n\n' );

fprintf( fid, '##+++ Save results into (tab-delimited) text file in directory /out\n' );
fprintf( fid, 'CombinedData.F <- cbind(EddyData.F, FilledEddyData.F)\n' );
fprintf( fid, '#+++ Lasslop partitioning of NEE not implemented in Reddyproc\n');
fprintf( fid, 'CombinedData.F[[ "Reco_HBLR" ]] <- NA\n' );
fprintf( fid, 'CombinedData.F[[ "GPP_HBLR" ]] <- NA\n' );

fprintf( fid, ['##+++ Replace "." with "_" in variable names for Matlab ' ...
               'compatibility\n'] ); 
% to replace a literal '.' in R, need to escape it twice -- once for Matlab,
% once for R.  Therefore need four backslashes.
fprintf( fid, ['names( CombinedData.F ) ', ...
               '<- gsub( "\\\\.", "_", names( CombinedData.F ) ) \n' ] );

out_dir = fullfile( getenv( 'FLUXROOT' ), ...
                    'SiteData', ...
                    char( sitecode ), ...
                    'processed_flux' );
out_dir = preformat_win_path( out_dir );

gf_out_fname = sprintf( 'data_gapfilled_partitioned_%s_%d.txt', ...
                        char( sitecode ), ...
                        year );
fprintf( fid, 'fWriteDataframeToFile(CombinedData.F, FileName.s="%s", Dir.s="%s")\n\n',...
         gf_out_fname, out_dir );
fprintf( fid, 'file.remove( "%s" )', preformat_win_path( blk_file ) );

fclose( fid );
fprintf( 'wrote %s\n', R_code_file );
gf_data_outfile = fullfile( out_dir, gf_out_fname );

% ============================================================

function success = call_R( cmd )
% MAKE_R_SYSTEM_CALL - call R from within Matlab with some required environment
% variable manipulation.
%
% Details: Matlab (on linux, at least) includes a pre-packaged gfortran system
% library.  Matlab's version is, at least on some systems, not the most recent
% version.  R uses the system gfortran library; thus if the system gfortran
% library is newer than the Matlab gfortran library R will complain and refuse
% to run.  call_R queries the system OS.  If it is (li/u)nux, it sets the
% LD_LIBRARY_PATH environment variable so that the system gfortran library is
% used rather than Matlab's packaged library.  It seems possible this could trip
% up Matlab later on, so the original value of LD_LIBRARY_PATH is restored
% before exiting.
%
% My thread on StackOverflow details how I tracked this glitch down (and
% might be useful for troubleshooting this issue on other systems?):
%    http://stackoverflow.com/questions/17982116/calling-r-from-within-matlab/
%
% A similar manipulation may be necessary on Windows systems.  I will update
% this function as soon as I have access to a Windows machine to test
% this. --TWH
%
% USAGE
%    success = call_R( cmd );
%
% INPUTS
%    cmd: character string; the command to call via system.
%
% OUTPUTS
%    sucess: 0 on success, 1 on failure
%
% SEE ALSO:
%     system
%
% author: Timothy W. Hilton & Litvak Lab, UNM, July 2013

success = 0;

if isunix()
    LD_LIBRARY_PATH_orig = getenv( 'LD_LIBRARY_PATH' );

    % prepend the system library directory to LD_LIBRARY_PATH environment
    % variable
    setenv( 'LD_LIBRARY_PATH', ...
            strcat( '/usr/lib/x86_64-linux-gnu:', ...
                    getenv( 'LD_LIBRARY_PATH' ) ) )
    success = system( cmd );
    
    % restore LD_LIBRARY_PATH to its original value
    setenv( 'LD_LIBRARY_PATH', LD_LIBRARY_PATH_orig );
elseif ispc()
    % seems to work OK on Windows without LD_LIBRARY_PATH issue
    success = system( cmd );
else
    warning( 'ispc and isunix both return false' );
    success = false;
end

% ============================================================

function path_out = preformat_win_path( path_in )
% PREFORMAT_WIN_PATHS - replace single backslashes with double backslashes in paths
%
% I'm not sure this is really the "right" way to do this...  Windows accepts
% '/' as the path separator, and that seems to be the more recommended way to
% write paths to work on both Windows and *nix on stackoverflow threads I've read.
%
% However, Matlab's fullfile inserts '\' for the path separator on Windows
% machines, and windows environment variables (e.g. FLUXROOT) also commonly
% contain '\' path separators.  And R interprets '\' as an escape character
% , so using a single '\' as the separator in R code won't work.  Because of
% all this, to replace '\' with '/' as the path separator I would need to
% separate '\' characters that are path separators from '\' characters that
% are legitimate escape characters (e.g. for spaces in file names).  The
% double backslash path separator will still work, I think, because R accepts
% \\ as a windows path separator...  
%
% Anyway, this seems kludgy, but seems to work.
%
% author: Timothy W. Hilton, Aug 2013

if ispc()
    path_out = strrep( path_in, '\', '\\' );
else
    path_out = path_in;
end
