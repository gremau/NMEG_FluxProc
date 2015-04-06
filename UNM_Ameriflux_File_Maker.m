
function result = UNM_Ameriflux_File_Maker( sitecode, year, varargin )
% UNM_AMERIFLUX_FILE_MAKER - writes delimited ASCII files in the format for
% submission to Ameriflux.
%
% Reads in the QC file and the gap-filled and flux partitioned files and writes
% delimited ASCII files in the format for submission to Ameriflux.
%
% Based on code created by Krista Anderson Teixeira in July 2007 and modified by
% John DeLong 2008 through 2009.  Extensively modified by Timothy W. Hilton 2011
% to 2013.
%
% Ameriflux files are written to the output of get_out_directory( sitecode ).
%
% USAGE
%    result = UNM_Ameriflux_File_Maker( sitecode, year, ... )
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
% PARAMETER-VALUE PAIRS:
%    write_files: {true}|false; if false, do not write the Ameriflux files (useful
%        for debugging without writing over good ameriflux files)
%    write_daily_files: {true}|false; if true, write daily aggregated data for
%        selected variables to a separate file.  For a list of aggregated
%        variables, see help for UNM_Ameriflux_daily_aggregator.
%
% OUTPUTS
%    success: 0 on success; non-zero on failure.
%
% SEE ALSO
%    UNM_sites, get_out_directory
%
% author: Timothy W. Hilton, UNM, 2011 - 2013

load_t0 = now();

result = -1;  %initialize to error; replace upon successful completion

%-----
% parse arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'year', @isnumeric );
args.addParamValue( 'write_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParamValue( 'write_daily_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParamValue( 'draw_CZO_plot', true, ...
                    @(x) ( numel(x) == 1 ) & islogical(x) );
args.parse( sitecode, year, varargin{ : } );
sitecode = args.Results.sitecode;
year = args.Results.year;
%-----

site = char( sitecode );

if isa( sitecode, 'UNM_sites' )
    sitecode = int8( sitecode );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse Flux_All_qc, gapfilled fluxes, and partitioned fluxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse the QC file
ds_qc = UNM_parse_QC_txt_file( sitecode, year );

% parse gapfilled and partitioned fluxes (ds_gf_pt abbreviates
% dataset_gapfilled_partitioned)
ds_gf_pt = UNM_parse_gapfilled_partitioned_output( UNM_sites( sitecode ), ...
                                                  year );
fp_tol = 1e-6;  %floating point tolerance for badvalue replacement
ds_gf_pt = replace_badvals( ds_gf_pt, -9999, fp_tol );
% make sure that QC, FluxAll, and gapfilled/partitioned have identical, complete
% 30 minute timeseries
fprintf( 'synchronizing timestamps... ');
t0 = now(); % record running time

t_min = min( [ ds_qc.timestamp; ds_gf_pt.timestamp ] );
t_max = max( [ ds_qc.timestamp; ds_gf_pt.timestamp ] );

[ ds_gf_pt, ds_qc ] = ...
    merge_datasets_by_datenum( ds_gf_pt, ds_qc, ...
                               'timestamp', 'timestamp', ...
                               3, t_min, t_max );

Jan1 = datenum( year, 1, 1, 0, 0, 0 );
Dec31 = datenum( year, 12, 31, 23, 59, 59 );
ds_qc = dataset_fill_timestamps( ds_qc, 'timestamp', ...
                                 't_min', Jan1, 't_max', Dec31 );
ds_gf_pt = dataset_fill_timestamps( ds_gf_pt, 'timestamp', ...
                                    't_min', Jan1, 't_max', Dec31 );


seconds_per_day = 60 * 60 * 24;
t_run = ceil( ( now() - t0 ) * seconds_per_day );
fprintf( 'done (%d seconds)\n', t_run ); %done sychronizing timestamps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do some bookkeeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a column of -9999s to place in the dataset where a site does not
% record a particular variable
dummy = repmat( -9999, size( ds_qc, 1 ), 1 );

%% calculate fractional day of year (i.e. 3 Jan at 12:00 would be 3.5)
ds_qc.fjday = ( ds_qc.jday + ...
                ( ds_qc.hour / 24.0 ) + ...
                ( ds_qc.minute / ( 24.0 * 60.0) ) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data processing and fixing datalogger & instrument errors 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fix incorrect precipitation values
ds_qc.precip = fix_incorrect_precip_factors( sitecode, year, ...
                                             ds_qc.fjday, ds_qc.precip );

switch sitecode
  case int8( UNM_sites.JSav ) 
    if  year == 2007 
        % the gapfiller does some filling before the JSav tower was
        % operational (4 May 2007 15:30), but the filled data do not look
        % good (they are time-shifted).  Remove those data here.
        row_idx = 1:DOYidx( 145 );
        non_data_vars = { 'Day', 'Month', 'Year', 'Hour', ...
                          'Minute', 'julday', 'Hr', 'timestamp' };
        
        data_cols = find( not( ismember( ds_pt.Properties.VarNames, ...
                                         non_data_vars ) ) );
        temp_arr = double( ds_pt );
        temp_arr( row_idx, data_cols ) = NaN;
        ds_pt = replacedata( ds_pt, temp_arr );
    end
  case int8( UNM_sites.PPine ) 
    switch year
      case 2011
        
        % the gapfiller/partitioner diagnosed curiously low RE between days 27
        % and 48.  Raise  that spike to 6.  (as per conversation with Marcy
        % 16 Apr 2013).  The fix must be applied to NEE because GPP will be
        % recalculated as NEE - RE to ensure carbon balance.
        idx = ( ds_pt.NEE_HBLR > 0.0 ) & ...
              ( ds_pt.julday >= 27 ) & ...
              ( ds_pt.julday <= 48 );
        ds_pt.NEE_HBLR( idx ) = ds_pt.NEE_HBLR( idx ) * ...
            ( 8 / max( ds_pt.NEE_HBLR( idx ) ) );
        fprintf( 'Fixing PPine 2011 GPP\n' );
    end
        
  case int8( UNM_sites.MCon ) 
    switch year
      case 2009
        
        NEE_vars = cellfun( @(x) not(isempty(x)), ...
                            regexp( ds_gf_pt.Properties.VarNames, '.*NEE.*' ) );
        GPP_vars = cellfun( @(x) not(isempty(x)), ...
                            regexp( ds_gf_pt.Properties.VarNames, '.*GPP.*' ) );
        RE_vars = cellfun( @(x) not(isempty(x)), ...
                           regexp( ds_gf_pt.Properties.VarNames, '.*RE.*' ) );
        LE_vars = cellfun( @(x) not(isempty(x)), ...
                           regexp( ds_gf_pt.Properties.VarNames, '.*LE.*' ) );
        H_vars = cellfun( @(x) not(isempty(x)), ...
                          regexp( ds_gf_pt.Properties.VarNames, '.*H_.*' ) );
        shift_vars = find( NEE_vars | GPP_vars | RE_vars | H_vars );
        idx = 1:DOYidx( 20 );
        temp_arr = double( ds_pt );
        temp_arr( idx, : ) = shift_data( temp_arr( idx, : ), -1.0, ...
                                         'cols_to_shift', shift_vars );
        ds_pt = replacedata( ds_pt, temp_arr );
      case 2011
        % the gapfiller/partitioner put in a big RE spike between days 300
        % and 335.  Dampen that spike to 2 (as per conversation with Marcy 17
        % Apr 2013)
        idx = DOYidx( 300 ) : DOYidx( 335 );
        ds_pt.Reco_HBLR( idx ) = ds_pt.Reco_HBLR( idx ) * ...
            ( 2 / max( ds_pt.Reco_HBLR( idx ) ) );
      case 2012
        % the gapfiller/partitioner put in a big RE spike between days 120
        % and 133.  Dampen that spike to 6.
        idx = DOYidx( 120 ) : DOYidx( 133 );
        ds_pt.Reco_HBLR( idx ) = ds_pt.Reco_HBLR( idx ) * ...
            ( 6 / max( ds_pt.Reco_HBLR( idx ) ) );
    end

  case int8( UNM_sites.PJ_girdle )
    switch year
        case 2011
          % the gapfiller/partitioner put in large RE and GPP spike between
          % days 335 and 360 - replace the GPP with that from days 306.25 to
          % 316, recycled to the appropriate length.
          fill_idx = DOYidx( 306.25 ) : DOYidx( 316 );
          replace_idx = DOYidx( 335 ) : DOYidx( 360 );
          filler = ds_gf_pt.Reco_HBLR( fill_idx );
          filler = repmat( filler, 3, 1 );
          filler = filler( 1 : numel( replace_idx ) );
          ds_pt.Reco_HBLR( replace_idx ) = filler;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create Ameriflux output dataset and write to ASCII files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ds_soil = [];  % dummy for now  -- TWH 29 May 2013

% create the variables to be written to the output files
[ amflux_gaps, amflux_gf ] = ...
    UNM_Ameriflux_prepare_output_data( sitecode, year, ...
                                       ds_qc, ds_gf_pt, ds_soil );

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
% draw CZO (critical zone observatory) plot if requested
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.draw_CZO_plot
    [ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );
    plot_CZO_figure( sitecode, 2007:this_year );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write daily aggregated files if requested
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.write_daily_files
    agg = UNM_Ameriflux_daily_aggregator( sitecode );
    agg.write_daily_file()
end

result = 0;
