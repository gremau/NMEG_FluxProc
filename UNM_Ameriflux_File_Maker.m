function result = UNM_Ameriflux_File_Maker( sitecode, year, varargin )
% UNM_AMERIFLUX_FILE_MAKER
%
% UNM_Ameriflux_file_maker( sitecode, year )
% This code reads in the QC file, the original annual flux all file for
% soil data and the gap filled and flux partitioned files and generates
% output in a format for submission to Ameriflux
%
% based on code created by Krista Anderson Teixeira in July 2007 and 
% modified by John DeLong 2008 through 2009. Extensively modified by
% Timothy W. Hilton 2011 to 2013.
%
% USAGE
%    result = UNM_Ameriflux_file_maker( sitecode, year, ... )
%
% KEYWORD ARGUMENTS:
%    write_files: logical; if false, do not write the Ameriflux files (useful
%        for debugging without writing over good ameriflux files)
%    write_daily_files: logical; if true, write daily aggregated data for
%        selected variables to a separate file.  For a list of aggregated
%        variables, see help for UNM_ameriflux_daily_aggregator.
%    process_soil_data: logical; if false, do not produce soil file
%    gf_part_source: string {eddyproc|Reddyproc} which
%        gapfiller/partitioner file to use
%
% Timothy W. Hilton, UNM, Dec 2011 - Jan 2012

load_t0 = now();

result = -1;  %initialize to error; replace upon successful completion

%-----
% parse arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'year', @isnumeric );
args.addParameter( 'write_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParameter( 'write_daily_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParameter( 'process_soil_data', false, @(x) ( islogical(x) & ...
                                                  numel( x ) ==  1 ) );
args.addParameter( 'gf_part_source', 'eddyproc', @(x) ( isstr(x) ) );
args.parse( sitecode, year, varargin{ : } );
sitecode = args.Results.sitecode;
year = args.Results.year;
%-----

site = char( sitecode );

if isa( sitecode, 'UNM_sites' )
    sitecode = int8( sitecode );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse Flux_All, Flux_All_qc, gapfilled fluxes, and partitioned fluxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse the annual Flux_All file FIXME: Why are we using this data?
if year < 2007
    % before 2009, fluxall data are in excel files
    data = UNM_parse_fluxall_xls_file( sitecode, year );
    warning( 'converting dataset to table' );
    dataset2table( data );
else
    % after 2012, fluxall data are kept in delimited ASCII files
    data = parse_fluxall_txt_file( sitecode, year );
end

% Parse the QC file
qc_tbl = parse_fluxall_qc_file( sitecode, year );

% Parse gapfilled and partitioned fluxes from online MPI eddyproc tool
[ pt_MR_tbl, pt_GL_tbl ] = ...
    UNM_parse_mpi_eddyproc_output( sitecode, year );

% Parse gapfilled fluxes from Reddyproc tool
try
    pt_MR_tbl_R = UNM_parse_reddyproc_output( sitecode, year );
catch
    pt_MR_tbl_R = table([]);
    warning('Reddyproc file did not parse.');
end
% Parse gapfilled and partitioned fluxes from Trevor Keenan's files
pt_TK_tbl = parse_TK201X_output( sitecode, year );

% Parse soil files.
if args.Results.process_soil_data
    % FIXME: This needs to be transitioned to tables
    warning( 'Converting between tables and datasets' );
    soil_tbl = UNM_Ameriflux_prepare_soil_met( sitecode, year, ...
        table2dataset( data ), table2dataset( qc_tbl ) );
    soil_tbl = dataset2table( soil_tbl );
else
    soil_tbl = table( [] );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ensure QC, FluxAll, gapfilled, and partitioned data have identical,
% complete 30 minute timeseries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf( 'synchronizing timestamps... ');
t0 = now(); % record running time

% Max/min times in all tables' timestamps
t_min = min( [ qc_tbl.timestamp; data.timestamp; ...
               pt_GL_tbl.timestamp; pt_MR_tbl.timestamp ] );
t_max = max( [ qc_tbl.timestamp; data.timestamp; ...
               pt_GL_tbl.timestamp; pt_MR_tbl.timestamp ] );

[ qc_tbl, data ] = merge_tables_by_datenum( qc_tbl, data, ...
    'timestamp', 'timestamp', 3, t_min, t_max );

[ pt_GL_tbl, data ] = merge_tables_by_datenum( pt_GL_tbl, data, ...
    'timestamp', 'timestamp', 3, t_min, t_max );

[ pt_MR_tbl, data ] = merge_tables_by_datenum( pt_MR_tbl, data, ...
    'timestamp', 'timestamp', 3, t_min, t_max );

if strcmpi(args.Results.gf_part_source, 'Reddyproc')
    [ pt_MR_tbl_R, data ] = merge_tables_by_datenum( pt_MR_tbl_R, data, ...
        'timestamp', 'timestamp', 3, t_min, t_max );
end
% Start/end time for the files being created
Jan1 = datenum( year, 1, 1, 0, 0, 0 );
%Dec31 = datenum( year, 12, 31, 23, 59, 59 );
% Preserves the last 30min period of year
Dec31 = datenum( year, 12, 31, 24, 0, 0 );

data = table_fill_timestamps( data, 'timestamp', ...
    't_min', Jan1, 't_max', Dec31 );
qc_tbl = table_fill_timestamps( qc_tbl, 'timestamp', ...
    't_min', Jan1, 't_max', Dec31 );
pt_GL_tbl = table_fill_timestamps( pt_GL_tbl, 'timestamp', ...
    't_min', Jan1, 't_max', Dec31 );
pt_MR_tbl = table_fill_timestamps( pt_MR_tbl, 'timestamp', ...
    't_min', Jan1, 't_max', Dec31 );

if strcmpi(args.Results.gf_part_source, 'Reddyproc')
    pt_MR_tbl_R = table_fill_timestamps( pt_MR_tbl_R, 'timestamp', ...
        't_min', Jan1, 't_max', Dec31 );
end

% Merge gapfilling/partitioning output into one table so we don't have
% to worry about which variables are in which table
if strcmp( args.Results.gf_part_source, 'eddyproc' )
    cols = setdiff( pt_MR_tbl.Properties.VariableNames, ...
        pt_GL_tbl.Properties.VariableNames );
    pt_tbl = [ pt_GL_tbl, pt_MR_tbl( :, cols ) ];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Amend periods where gapfilling fails or is ridiculous
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pt_tbl = amend_gapfilling_and_partitioning( sitecode, year, pt_tbl );
elseif strcmp( args.Results.gf_part_source, 'Reddyproc' )
    pt_tbl = pt_MR_tbl_R;
    cols = setdiff( pt_MR_tbl.Properties.VariableNames, ...
        pt_GL_tbl.Properties.VariableNames );
    pt_tbl_GL = [ pt_GL_tbl, pt_MR_tbl( :, cols ) ];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Amend periods where gapfilling fails or is ridiculous
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pt_tbl_GL = amend_gapfilling_and_partitioning( sitecode, year, pt_tbl_GL );
    pt_tbl.GPP_HBLR = pt_tbl_GL.GPP_HBLR;
    pt_tbl.Reco_HBLR = pt_tbl_GL.Reco_HBLR;
    pt_tbl = [pt_tbl,  pt_tbl_GL( :, {'Reco_HBLR_amended', 'amended_flag' })];
else
    error('Wrong gapfiller partitioning type!')
end

seconds_per_day = 60 * 60 * 24;
t_run = ceil( ( now() - t0 ) * seconds_per_day );
fprintf( 'done (%d seconds)\n', t_run ); %done sychronizing timestamps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If we have data from the keenan synthesis put it in pt_tbl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

keenan = false;

% if ~isempty( pt_TK_tbl )
%     [ pt_TK_tbl, data ] = merge_tables_by_datenum( pt_TK_tbl, data, ...
%         'timestamp', 'timestamp', 3, t_min, t_max );
%     pt_TK_tbl = table_fill_timestamps( pt_TK_tbl, 'timestamp', ...
%         't_min', Jan1, 't_max', Dec31 );
%     pt_tbl.GPP_f_TK201X = pt_TK_tbl.GPP_f;
%     pt_tbl.RE_f_TK201X = pt_TK_tbl.RE_f;
%     keenan = true;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Amend periods where gapfilling fails or is ridiculous
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%pt_tbl = amend_gapfilling_and_partitioning( sitecode, year, pt_tbl );

% This adds an Reco_HBLR_amended column

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create Ameriflux output table and write to ASCII files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the variables to be written to the output files
[ amflux_gaps, amflux_gf ] = ...
    prepare_AF_output_data( sitecode, qc_tbl, pt_tbl, soil_tbl, keenan );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make a diagnostic plot of partitioning outputs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

part_dfig = plot_compare_fc_partitioning( sitecode, year, amflux_gf, ...
    'keenan', keenan );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the data before writing out to files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0 % turned on for now
    start_col = 5; %skip plotting for first 4 columns (time variables)
    t0 = now();
    fname = fullfile( get_out_directory( sitecode ), 'figures',...
        sprintf( '%s_%d_gapfilled.ps', ...
        get_site_name(sitecode), year ) );
    UNM_Ameriflux_plot_dataset_eps( amflux_gf, fname, year, start_col );
    fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );
    
    t0 = now();
    fname = fullfile( get_out_directory( sitecode ), 'figures',...
        sprintf( '%s_%d_with_gaps.ps', ...
        get_site_name(sitecode), year ) );
    UNM_Ameriflux_plot_dataset_eps( amflux_gaps, fname, year, start_col );
    fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write gapfilled and with_gaps Ameriflux files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note that sometimes we don't want to export all the GPP/RECO columns
% Select what we want and remove the ones we don't want...
if sitecode==UNM_sites.MCon || sitecode==UNM_sites.PPine
    amflux_gf.GPP = amflux_gf.GPP_MR2005_ecb;
    amflux_gf.RECO = amflux_gf.RECO_MR2005_ecb;
    amflux_gaps.GPP = amflux_gaps.GPP_MR2005_ecb;
    amflux_gaps.RECO = amflux_gaps.RECO_MR2005_ecb;
    
else
    amflux_gf.GPP = amflux_gf.GPP_GL2010_amended_ecb;
    amflux_gf.RECO = amflux_gf.RECO_GL2010_amended_ecb;
    amflux_gaps.GPP = amflux_gaps.GPP_GL2010_amended_ecb;
    amflux_gaps.RECO = amflux_gaps.RECO_GL2010_amended_ecb;
    
end

amflux_gf.Properties.VariableUnits{end} = 'mumol/m2/s';
amflux_gf.Properties.VariableUnits{end-1} = 'mumol/m2/s';
amflux_gaps.Properties.VariableUnits{end} = 'mumol/m2/s';
amflux_gaps.Properties.VariableUnits{end-1} = 'mumol/m2/s';

% REMOVE UNWANTED COLUMNS
amflux_gf( :, {'GPP_F_MR2005','RECO_MR2005','GPP_GL2010','RECO_GL2010', ...
    'RECO_GL2010_amended', 'amended_FLAG', 'GPP_F_MR2005_FLAG', ...
    'GPP_MR2005_ecb', 'RECO_MR2005_ecb','NEE_MR2005_ecb', ...
    'GPP_GL2010_amended_ecb','RECO_GL2010_amended_ecb', ...
    'NEE_GL2010_amended_ecb'}) = [];
amflux_gaps( :, {'GPP_F_MR2005','RECO_MR2005','GPP_GL2010','RECO_GL2010', ...
    'RECO_GL2010_amended', 'amended_FLAG', 'GPP_MR2005_ecb', ...
    'RECO_MR2005_ecb','NEE_MR2005_ecb', ...
    'GPP_GL2010_amended_ecb','RECO_GL2010_amended_ecb','NEE_GL2010_amended_ecb'}) = [];

if args.Results.write_files
    UNM_Ameriflux_write_file( sitecode, year, amflux_gf, ...
        'mlitvak@unm.edu', 'gapfilled' );
    
    UNM_Ameriflux_write_file( sitecode, year, amflux_gaps, ...
        'mlitvak@unm.edu', 'with_gaps' );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write daily aggregated files if requested
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.write_daily_files
    agg = UNM_Ameriflux_daily_aggregator( sitecode );
    agg.write_daily_file()
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write another Ameriflux files with soil heat flux for internal use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shf_vars = regexp_header_vars( qc_tbl, 'soil_heat_flux.*' );
% shf_idx = find( ismember( qc_tbl.Properties.VariableNames, shf_vars ) );
% shf_tbl = qc_tbl( :, shf_idx );
% units = cell( 1, numel( shf_idx ) );
% for i = 1:numel( shf_idx )
%     units{i} = 'W / m2';
% end
% shf_tbl.Properties.VariableUnits = units;

% amflux_shf = [ amflux_gaps, shf_tbl ];
if args.Results.process_soil_data
    UNM_Ameriflux_write_file( sitecode, year, soil_tbl, ...
                              'mlitvak@unm.edu', 'soil' );
end

% % plot the soil heat flux variables
% shf_tbl = [ amflux_shf( :, 'DTIME' ), shf_tbl ];
% t0 = now();
% fname = fullfile( get_out_directory( sitecode ), ...
%                   sprintf( '%s_%d_SHF.ps', ...
%                            get_site_name(sitecode), year ) );
% UNM_Ameriflux_plot_dataset_eps( shf_tbl, fname, year, 2 );
% fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );

result = 0;
end

