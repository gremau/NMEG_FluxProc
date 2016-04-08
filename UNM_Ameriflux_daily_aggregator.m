classdef UNM_Ameriflux_daily_aggregator
% class that aggregates UNM gap-filled Ameriflux data to daily values.
%
% Applies mean, sum, and integrated sum where appropriate.
%
% variables aggregated by mean: USTAR, WS, PA, CO2, VPD_F, H2O, 'TA_F',
%                               RH_F
% variables aggregated by min: TA_F, VPD_F
% variables aggregated by max: TA_F, VPD_F
% variables aggregated by sum: P_F
% variables aggregated by integrated sum (radiation): RNET, PAR, SW_IN_F,
%                              SW_OUT, LW_IN, LW_OUT, LE_F, H_F 
% variables aggregated by integrated sum (C fluxes): FC_F, GPP, RECO
%
% USAGE:
%     agg = UNM_Ameriflux_daily_aggregator( sitecode )
%     agg = UNM_Ameriflux_daily_aggregator( sitecode, years )
%     agg = UNM_Ameriflux_daily_aggregator( sitecode, ..., 'binary_data' )
%
% INPUTS:
%     sitecode: UNM_sites object
%     years: optional; years to include.  Defaults to 2007-present
%     binary_data: optional, logical: if true, use binary data instead of
%          parsing ameriflux files
%
% OUTPUTS:
%     agg: UNM_Ameriflux_daily_aggregator object
%
% FIELDS:
%     sitecode
%     years
%     aflx_data: dataset array containing the aggregated data
%
% METHODS:
%    write_daily_file: write daily file to file.
%       USAGE
%          write_daily_file( 'use_Ameriflux_code', val )
%          write_daily_file( ..., 'outdir', dir )
%       INPUTS
%          use_Ameriflux_code: optional, logical; if true, uses the Ameriflux
%              site code in the file name (e.g. US-abc).  If false, uses the
%              internal UNM site abbreviation (e.g. GLand, SLand, etc.).
%              Default is true.
%          outdir: optional, char; path to directory in which to write output
%              files.  Default is $FLUXROOT/Ameriflux_files.
%
% author: Timothy W. Hilton, UNM, December 2012
    
    properties
        
        sitecode;
        years;
        aflx_data;
        daily_data;
        
    end
    
    methods
        
        % --------------------------------------------------
        
        function obj = UNM_Ameriflux_daily_aggregator( sitecode, varargin );
            
            % -----
            % parse user arguments & typecheck
            args = inputParser;
            args.addRequired( 'sitecode', ...
                @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) );
            args.addOptional( 'years', NaN, @isnumeric );
            args.parse( sitecode, varargin{ : } );
            % make sure sitecode is a UNM_sites object
            obj.sitecode = UNM_sites( args.Results.sitecode );
            obj.years = args.Results.years;
            
            % if years not specified, collect all site-years
            if all( isnan( obj.years ) )
                [ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );
                obj.years = 2007:this_year;
            end
            
            obj.aflx_data = ...
                assemble_multiyear_ameriflux( args.Results.sitecode, ...
                obj.years, ...
                'suffix', 'gapfilled' );
            
            % no data from the future :)
            future_idx = obj.aflx_data.timestamp > now();
            
            obj.aflx_data( future_idx, : ) = [];
            
            obj = aggregate_daily( obj );
            
        end
        
        % --------------------------------------------------
        
        function obj = aggregate_daily( obj )
            % AGGREGATE_DAILY 
            
            % carbon fluxes: integrate umol m-2 s-1 to gC m-2
            vars_Cfluxes = { 'FC_F', 'GPP', 'RECO' };
            units_Cfluxes = repmat( { 'gC m-2 d' }, 1, numel( vars_Cfluxes ) );
            % variables to be aggregated by daily mean
            vars_mean = { 'USTAR', 'WS', 'PA', 'CO2', 'VPD_F', 'H2O',...
                'TA_F', 'RH_F' };
            units_mean = { 'm s-1', 'm s-1', 'Pa', 'ppm', 'kPa',...
                'mmol mol-1', 'deg C', '%' };
            % variables to be aggregated by daily min / max
            vars_min = { 'TA_F', 'VPD_F' };
            vars_max = { 'TA_F', 'VPD_F' };
            % Have to make new varnames for these
            varnames_min = { 'TA_F_min', 'VPD_F_min' };
            varnames_max = { 'TA_F_max', 'VPD_F_max' };
            units_minmax = { 'deg C', 'kPa' };
            % variables to be aggregated by daily sum
            vars_sum = { 'P_F' };
            units_sum = { 'mm' };
            % radiation variables: aggregate by W m-2 to J m-2
            % FIXME - missing PAR_out (need to add to qc files)

            vars_rad = { 'RNET_F', 'PAR', 'SW_IN_F', 'SW_OUT', ...
                'LW_IN_F', 'LW_OUT', 'LE_F', 'H_F' };
            units_rad = repmat( { 'J m-2' }, 1, numel( vars_rad ) );
            
            t_30min = double( [ obj.aflx_data.YEAR, obj.aflx_data.DOY ] );
            units_time = { '-', '-' };
            
            % Aggregate the data using the "consolidator" function from the
            % MATLAB file exchange (John D'Errico)
            [ t, data_mean ]  = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_mean }, ...
                @nanmean );
            
            [ t, data_sum ] = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_sum }, ...
                @nansum );
            
            [ t, data_min ] = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_min }, ...
                @nanmin );
            
            [ t, data_max ] = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_max }, ...
                @nanmax );
            
            
            integrate_Cfluxes = @( x ) sum( umolPerSecPerM2_2_gcPerMSq( x ) );
            [ t, data_fluxes ] = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_Cfluxes }, ...
                integrate_Cfluxes );
            
            secs_per_30mins = 60 * 30;
            integrate_radiation = @( x ) sum( secs_per_30mins .* x );
            [ t, data_rad ] = ...
                consolidator( t_30min, obj.aflx_data{ :, vars_rad }, ...
                integrate_radiation );
            
            % build a dataset from the aggregated data
            vars = horzcat( { 'year', 'doy' }, ...
                vars_sum, vars_mean, varnames_min, varnames_max, ...
                vars_Cfluxes, vars_rad );
            obj.daily_data = ...
                array2table( [t, data_sum, data_mean, data_min, data_max, ...
                data_fluxes, data_rad], 'VariableNames', vars );
            obj.daily_data.Properties.VariableUnits = horzcat( ...
                units_time, units_sum, ...
                units_mean, units_minmax, units_minmax, ...
                units_Cfluxes, units_rad );
            
        end
        
        % --------------------------------------------------
        
        function write_daily_file( obj, varargin )
            % WRITE_DAILY_FILE -
            
            % -----
            args = inputParser;
            args.addRequired( 'obj', ...
                @(x) isa( x, 'UNM_Ameriflux_daily_aggregator' ) );
            args.addParameter( 'outdir', '', @ischar );
            args.addParameter( 'use_Ameriflux_code', true, @islogical );
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
            
            if args.Results.use_Ameriflux_code
                site_table = parse_UNM_site_table();
                site_abbrev = char( site_table.Ameriflux( obj.sitecode ) );
            else
                site_abbrev = char( obj.sitecode );
            end
            
            fname = fullfile( outdir, ...
                sprintf( '%s_%d_%d_daily.txt', ...
                site_abbrev, ...
                obj.years( 1 ), ...
                obj.years( end ) ) );
            
            fprintf( 'writing %s\n', fname );
            write_table_std( fname,  obj.daily_data, ...
                'replace_NaNs', -9999, ...
                'write_units', true );
        end
        
        % --------------------------------------------------
        
    end %methods
end %classdef
