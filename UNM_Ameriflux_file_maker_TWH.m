function result = UNM_Ameriflux_file_maker_TWH( sitecode, year, varargin )
% UNM_AMERIFLUX_FILE_MAKER_TWH
%
% UNM_Ameriflux_file_maker_TWH( sitecode, year )
% This code reads in the QC file, the original annual flux all file for
% soil data and the gap filled and flux partitioned files and generates
% output in a format for submission to Ameriflux
%
% based on code created by Krista Anderson Teixeira in July 2007 and modified by
% John DeLong 2008 through 2009.  Extensively modified by Timothy W. Hilton 2011
% to 2012.
%
% Timothy W. Hilton, UNM, Dec 2011 - Jan 2012

load_t0 = now();

result = -1;  %initialize to error; replace upon successful completion

%-----
% parse arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'year', @isnumeric );
args.addParamValue( 'write_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
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

% %% parse the annual Flux_All file
% data = UNM_parse_fluxall_xls_file( sitecode, year );


% % seems to be parsing header of NewGland_2011 to bogus dates -- temporary
% % fix until I get the front end of processing away from excel files
% data( data.timestamp < datenum( 2000, 1, 1 ), : ) = [];

% %% parse the QC file
% ds_qc = UNM_parse_QC_txt_file( sitecode, year );

% %% parse gapfilled and partitioned fluxes
% [ ds_pt_GL, ds_pt_MR ] = ...
%     UNM_parse_gapfilled_partitioned_output( sitecode, year );

% % make sure that QC, FluxAll, gapfilled, and partitioned have identical,
% % complete 30 minute timeseries
% fprintf( 'synchronizing timestamps... ');
% t0 = now(); % record running time

% t_min = min( [ ds_qc.timestamp; data.timestamp; ...
%                ds_pt_GL.timestamp; ds_pt_MR.timestamp ] );
% t_max = max( [ ds_qc.timestamp; data.timestamp; ...
%                ds_pt_GL.timestamp; ds_pt_MR.timestamp ] );

% [ ds_qc, data ] = merge_datasets_by_datenum( ds_qc, data, ...
%                                              'timestamp', 'timestamp', ...
%                                              3, t_min, t_max );
% [ ds_pt_GL, data ] = ...
%     merge_datasets_by_datenum( ds_pt_GL, data, ...
%                                'timestamp', 'timestamp', ...
%                                3, t_min, t_max );
% [ ds_pt_MR, data ] = ... 
%     merge_datasets_by_datenum( ds_pt_MR, data, ...
%                                'timestamp', 'timestamp', ...
%                                3, t_min, t_max );

% Jan1 = datenum( year, 1, 1, 0, 0, 0 );
% Dec31 = datenum( year, 12, 31, 23, 59, 59 );
% data = dataset_fill_timestamps( data, 'timestamp', ...
%                                 't_min', Jan1, 't_max', Dec31 );
% ds_qc = dataset_fill_timestamps( ds_qc, 'timestamp', ...
%                                  't_min', Jan1, 't_max', Dec31 );
% ds_pt_GL = dataset_fill_timestamps( ds_pt_GL, 'timestamp', ...
%                                     't_min', Jan1, 't_max', Dec31 );
% ds_pt_MR = dataset_fill_timestamps( ds_pt_MR, 'timestamp', ...
%                                     't_min', Jan1, 't_max', Dec31 );
% % merge gapfilling/partitioning output into one dataset so we don't have
% % to worry about which variables are in which dataset
% cols = setdiff( ds_pt_MR.Properties.VarNames, ...
%                 ds_pt_GL.Properties.VarNames );
% ds_pt = [ ds_pt_GL, ds_pt_MR( :, cols ) ];

% seconds_per_day = 60 * 60 * 24;
% t_run = ceil( ( now() - t0 ) * seconds_per_day );
% fprintf( 'done (%d seconds)\n', t_run ); %done sychronizing timestamps

% %% parsing the excel files is slow -- this loads parsed data for testing
% %%load( '/media/OS/Users/Tim/DataSandbox/GLand_2010_fluxall.mat' );

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % do some bookkeeping
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % create a column of -9999s to place in the dataset where a site does not
% % record a particular variable
% dummy = repmat( -9999, size( data, 1 ), 1 );

% %% calculate fractional day of year (i.e. 3 Jan at 12:00 would be 3.5)
% ds_qc.fjday = ( ds_qc.jday + ...
%                 ( ds_qc.hour / 24.0 ) + ...
%                 ( ds_qc.minute / ( 24.0 * 60.0) ) );

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % data processing and fixing datalogger & instrument errors 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %% fix incorrect precipitation values
% ds_qc.precip = fix_incorrect_precip_factors( sitecode, year, ...
%                                              ds_qc.fjday, ds_qc.precip );

% if sitecode == int8( UNM_sites.JSav ) & ( year == 2007 )
%     % the gapfiller does some filling before the JSav tower was
%     % operational (4 May 2007 15:30), but the filled data do not look
%     % good (they are time-shifted).  Remove those data here.
%     row_idx = 1:DOYidx( 145 );
%     non_data_vars = { 'Day', 'Month', 'Year', 'Hour', ...
%                       'Minute', 'julday', 'Hr', 'timestamp' };

%     data_cols = find( not( ismember( ds_pt.Properties.VarNames, ...
%                                      non_data_vars ) ) );
%     temp_arr = double( ds_pt );
%     temp_arr( row_idx, data_cols ) = NaN;
%     ds_pt = replacedata( ds_pt, temp_arr );
% elseif sitecode == int8( UNM_sites.MCon ) & ( year == 2009 )

%     NEE_vars = cellfun( @(x) not(isempty(x)), ...
%                         regexp( ds_pt_GL.Properties.VarNames, '.*NEE.*' ) );
%     GPP_vars = cellfun( @(x) not(isempty(x)), ...
%                         regexp( ds_pt_GL.Properties.VarNames, '.*GPP.*' ) );
%     RE_vars = cellfun( @(x) not(isempty(x)), ...
%                        regexp( ds_pt_GL.Properties.VarNames, '.*RE.*' ) );
%     LE_vars = cellfun( @(x) not(isempty(x)), ...
%                        regexp( ds_pt_GL.Properties.VarNames, '.*LE.*' ) );
%     H_vars = cellfun( @(x) not(isempty(x)), ...
%                       regexp( ds_pt_GL.Properties.VarNames, '.*H_.*' ) );
%     shift_vars = find( NEE_vars | GPP_vars | RE_vars | H_vars );
%     idx = 1:DOYidx( 20 );
%     temp_arr = double( ds_pt );
%     temp_arr( idx, : ) = shift_data( temp_arr( idx, : ), -1.0, ...
%                                      'cols_to_shift', shift_vars );
%     ds_pt = replacedata( ds_pt, temp_arr );
% end

% % save a file to restart just before soil calculations
soil_restart_fname = sprintf( 'soil_restart_%s_%d.mat', ...
                              char( UNM_sites( sitecode ) ), year );
% save( fullfile( getenv( 'FLUXROOT' ), ...
%                 'FluxOut', ...
%                 'SoilRestartFiles', ...
%                 soil_restart_fname ) );
load( fullfile( getenv( 'FLUXROOT' ), ...
                'FluxOut', ...
                'SoilRestartFiles', ...
                soil_restart_fname ) );
fprintf( 'time to load: %0.1f\n', ( now() - load_t0 ) * 86400 );

% create dataset of soil properties.
ds_soil = UNM_Ameriflux_prepare_soil_met( sitecode, year, data, ds_qc );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create Ameriflux output dataset and write to ASCII files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the variables to be written to the output files
[ amflux_gaps, amflux_gf ] = ...
    UNM_Ameriflux_prepare_output_data( sitecode, year, ...
                                       data, ds_qc, ...
                                       ds_pt, ds_soil );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the data before writing out to files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0
    start_col = 5; %skip plotting for first 4 columns (time variables)
    t0 = now();
    fname = fullfile( get_out_directory( sitecode ), ...
                      sprintf( '%s_%d_gapfilled.ps', ...
                               get_site_name(sitecode), year ) );
    UNM_Ameriflux_plot_dataset_eps( amflux_gf, fname, year, start_col );
    fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );
    
    t0 = now();
    fname = fullfile( get_out_directory( sitecode ), ...
                      sprintf( '%s_%d_with_gaps.ps', ...
                               get_site_name(sitecode), year ) );
    UNM_Ameriflux_plot_dataset_eps( amflux_gaps, fname, year, start_col );
    fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write gapfilled and with_gaps Ameriflux files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.write_files 
UNM_Ameriflux_write_file( sitecode, year, amflux_gf, ...
                          'mlitvak@unm.edu', 'gapfilled' );

UNM_Ameriflux_write_file( sitecode, year, amflux_gaps, ...
                          'mlitvak@unm.edu', 'with_gaps' );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write another Ameriflux files with soil heat flux for internal use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shf_vars = regexp_ds_vars( ds_qc, 'soil_heat_flux.*' );
% shf_idx = find( ismember( ds_qc.Properties.VarNames, shf_vars ) );
% ds_shf = ds_qc( :, shf_idx );
% units = cell( 1, numel( shf_idx ) );
% for i = 1:numel( shf_idx )
%     units{i} = 'W / m2';
% end
% ds_shf.Properties.Units = units;

% amflux_shf = [ amflux_gaps, ds_shf ];
UNM_Ameriflux_write_file( sitecode, year, ds_soil, ...
                          'mlitvak@unm.edu', 'soil' );

% % plot the soil heat flux variables
% ds_shf = [ amflux_shf( :, 'DTIME' ), ds_shf ];
% t0 = now();
% fname = fullfile( get_out_directory( sitecode ), ...
%                   sprintf( '%s_%d_SHF.ps', ...
%                            get_site_name(sitecode), year ) );
% UNM_Ameriflux_plot_dataset_eps( ds_shf, fname, year, 2 );
% fprintf( 'plot time: %.0f secs\n', ( now() - t0 ) * 86400 );

result = 0;
