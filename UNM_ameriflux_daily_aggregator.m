classdef UNM_ameriflux_daily_aggregator
% aggregates UNM gap-filled Ameriflux data to daily values.  Applies mean,
% sum, and integrated sum where appropriate (details below). 


properties
    
    sitecode;
    years;
    aflx_data;
    daily_data;
    
end

methods

% --------------------------------------------------

    function obj = UNM_ameriflux_daily_aggregator( sitecode, varargin );

    % -----
    % parse user arguments & typecheck
    args = inputParser;
    args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
    args.addOptional( 'years', NaN, @isnumeric );

    args.addParamValue( 'binary_data', false, @(x) ( islogical(x) & ...
                                                     numel( x ) ==  1 ) );
    args.parse( sitecode, varargin{ : } );
    % -----

    obj.sitecode = args.Results.sitecode;
    obj.years = args.Results.years;

    % if years not specified, collect all site-years
    if all( isnan( obj.years ) )
        [ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );
        obj.years = 2007:this_year;
    end

    obj.aflx_data = ...
        assemble_multi_year_ameriflux( args.Results.sitecode, ...
                                       obj.years, ...
                                       'suffix', 'gapfilled', ...
                                       'binary_data', args.Results.binary_data );

    obj = aggregate_daily( obj );

    end

% --------------------------------------------------

    function obj = aggregate_daily( obj )
    % AGGREGATE_DAILY - 
    %   

    % carbon fluxes: integrate umol m-2 s-1 to gC m-2
    vars_Cfluxes = { 'FC', 'GPP', 'RE' };
    units_Cfluxes = repmat( { 'gC m-2 d' }, 1, numel( vars_Cfluxes ) );
    % variables to be aggregated by daily mean
    vars_mean = { 'UST', 'WS', 'PA', 'CO2', 'VPD', 'H20', 'TA' };
    units_mean = { 'm s-1', 'm s-1', 'Pa', 'ppm', '-', 'mmol mol-1', 'deg C' };
    % variables to be aggregated by daily min / max
    vars_min = { 'TA' };
    vars_max = { 'TA' };
    units_minmax = { 'deg C' };
    % variables to be aggregated by daily sum
    vars_sum = { 'PRECIP' };
    units_sum = { 'mm' };
    % radiation variables: aggregate by W m-2 to J m-2
    vars_rad = { 'RNET', 'PAR', 'PAR_out', 'Rg', 'Rg_out', 'Rlong_in', ...
                 'Rlong_out' };
    units_rad = repmat( { 'J m-2' }, 1, numel( vars_rad ) );
    
    t_30min = double( [ obj.aflx_data.YEAR, obj.aflx_data.DOY ] );
    units_time = { '-', '-' }; 
    
    % aggregate the data
    [ t, data_mean ]  = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, vars_mean ) ), ...
                      @nanmean );

    [ t, data_sum ] = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, vars_sum ) ), ...
                      @nansum );
    
    [ t, TA_min ] = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, 'TA' ) ), ...
                      @nanmin );

    [ t, TA_max ] = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, 'TA' ) ), ...
                      @nanmax );

    
    integrate_Cfluxes = @( x ) sum( umolPerSecPerM2_2_gcPerMSq( x ) );
    [ t, data_fluxes ] = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, vars_Cfluxes ) ), ...
                      integrate_Cfluxes );
    
    secs_per_30mins = 60 * 30;
    integrate_radiation = @( x ) sum( secs_per_30mins .* x );
    [ t, data_rad ] = ...
        consolidator( t_30min, ...
                      double( obj.aflx_data( :, vars_rad ) ), ...
                      integrate_radiation );
    
    % build a dataset from the aggregated data
    vars = horzcat( { 'year', 'doy' }, ...
                    vars_sum, vars_mean, { 'TA_min', 'TA_max' }, ...
                    vars_Cfluxes, vars_rad );
    obj.daily_data = ...
        dataset( { [ t, data_sum, data_mean, TA_min, TA_max, ...
                     data_fluxes, data_rad ], ...
                   vars{ : } } );
    obj.daily_data.Properties.Units = horzcat( units_time, units_sum, ...
                                               units_mean, { 'deg C', 'deg C' }, ...
                                               units_Cfluxes, units_rad );
    
    end

% --------------------------------------------------

function write_daily_file( obj, varargin )
% WRITE_DAILY_FILE - 

% -----
args = inputParser;
args.addRequired( 'obj', @(x) isa( x, 'UNM_ameriflux_daily_aggregator' ) );
args.addParamValue( 'outdir', '', @ischar );
args.parse( obj, varargin{ : } );
obj = args.Results.obj;
% -----

% determine where to put the output file
if isempty( args.Results.outdir )
    outdir = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_files' );
elseif strcmp( args.Results.outdir, 'prompt' )
    outdir = uigetdir( getenv( 'HOME' ), ...
                       'Choose directory for aggregated daily data' );
else
    outdir = args.Results.outdir;
end
if exist( outdir ) ~= 7
    error( sprintf( 'directory %s does not exist; cannot write output', ...
                    outdir ) );
end

fname = fullfile( outdir, ...
                  sprintf( '%s_%d_%d_daily.txt', ...
                           char( obj.sitecode ), ...
                           obj.years( 1 ), ...
                           obj.years( end ) ) );

fprintf( 'writing %s\n', fname );
export_dataset_tim( fname, ...
                    obj.daily_data, ...
                    'replace_NaNs', -9999, ...
                    'write_units', true );
end

% --------------------------------------------------

end %methods
end %classdef



