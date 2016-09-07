function result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, ...
    varargin )
% UNM_FILL_MET_GAPS_FROM_NEARBY_SITE - fills gaps in site's meteorological data
%   from the closest nearby site
%
% USAGE
%     result = UNM_fill_met_gaps_from_nearby_site( sitecode, year )
%     result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, draw_plots )
%
% INPUTS
%     sitecode [ UNM_sites object ]: code of site to be filled
%     year [ integer ]: year to be filled
% PARAMETER-VALUE PAIRS
%     write_output: true | {false}; if true, write new for_gapfilling_filled
%                                 file
%     draw_plots: {true} | false; if true, plot observed and filled
%                          T, Rg, RH.
%
% OUTPUTS
%     result [ integer ]: 0 on success, -1 on failure
%
% SEE ALSO
%     UNM_sites
%
% author: Timothy W. Hilton, UNM, March 2012
% modified by: Gregory E. Maurer, UNM, February 2015

% -----
% define optional inputs, with defaults and typechecking
% -----
[ this_year, ~, ~ ] = datevec( now() );
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParameter( 'write_output', false, ...
    @(x) ( islogical( x ) & numel( x ) == 1 ) );
args.addParameter( 'draw_plots', true, ...
    @(x) ( islogical( x ) & numel( x ) == 1 ) );
args.parse( sitecode, year, varargin{ : } );
% -----

sitecode = args.Results.sitecode;
year = args.Results.year;
write_output = args.Results.write_output;
draw_plots = args.Results.draw_plots;

if isintval( sitecode )
    sitecode = UNM_sites( sitecode );
else
    error( 'sitecode must be an integer' );
end

% initialize
filled_file_false = false;

%--------------------------------------------------
% Parse unfilled data from requested site

fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
    get_site_name( sitecode ), year );
thisData = parse_forgapfilling_file( sitecode, year, ...
    'use_filled', filled_file_false );

% Fill in missing timestamps for this data
thisData = fillTstamps( thisData, thisData.timestamp, 1/48 );

%--------------------------------------------------
% Get Met gapfilling configuration
% We need to parse YAML config files for given year to do this
start_dt = datenum([ num2str( year ), '-01-01' ]);
end_dt = datenum([ num2str( year ), '-12-31' ]);

configFileName = 'MetFill';
thisConfig = parse_yaml_config( sitecode, configFileName, ...
    [ start_dt, end_dt ] );

%--------------------------------------------------
% VPD will need to be recalculated for the Tair and
% RH gaps that are filled - make an index

recalcVPD = [];

%--------------------------------------------------
% Now we are going to fill selected met variables in thisData

% List of variables in thisData to fill
fillVars = { 'Tair', 'rH', 'Rg', 'Precip' };
% Struct to hold data from filling sites
fillData = struct();

for i = 1:length( fillVars )
    % Get configurations for filling sites for this variable
    varConfig = thisConfig.( [ 'fill' fillVars{ i } ] );
    % If fillData doesn't already have the required data from each
    % filling site listed in varConfig, load it
    for j = 1:length( varConfig )
        % Create a field name to look for in fillData
        varConfig( j ).('fillDataField') = ...
            [ varConfig( j ).siteType '_' ...
            num2str( varConfig( j ).siteID ) ];
        % If that field is not present run getFillData
        if not( isfield( fillData, varConfig( j ).fillDataField ) )
            fillData = getFillData( fillData, ...
                varConfig( j ).siteType, varConfig( j ).siteID );
        end
    end
    
    try
        % Replace missing data in thisData with data from fillData
        % NOTE this also returns indices of what was filled
        [ thisData, varConfig ] = ...
            fill_variable( thisData, fillData, fillVars{ i }, varConfig );
    catch
        fprintf([ 'ABORTING UNM_fill_met_gaps_from_nearby_site \n' ...
            'There is not enough ancillary met data available \n' ...
            'Filled file not written. \n' ]);
        result = 1;
        error( 'Met gapfilling failed' );
    end
    
    % Combine the two filled indices into one ( used for recalcVPD )
    filledIdx = [];
    for count=1:length( varConfig )
        filledIdx = [ filledIdx; varConfig( count ).fillIdx ];
    end
        
    % Remove bad values from the now filled variables and recalc VPD
    if strcmp( fillVars{ i }, 'rH' )
        thisData.rH( thisData.rH > 100.0 ) = 100.0;
        thisData.rH( thisData.rH < 0.0 ) = 0.0;
        % Add filled indices to the vpd refill index
        recalcVPD = [ recalcVPD ; filledIdx ];
    elseif strcmp( fillVars{ i }, 'Tair' );
        % Add filled indices to the vpd refill index
        recalcVPD = [ recalcVPD ; filledIdx ];
    elseif strcmp( fillVars{ i }, 'Rg' )
        thisData.Rg( thisData.Rg < -50 ) = NaN;
    elseif strcmp( fillVars{ i }, 'Precip' )
        thisData.Precip( thisData.Precip < 0 ) = NaN;
    end
    
    % Draw a plot if requested
    if draw_plots
        h_fig = plot_filled_variable( thisData, fillVars{ i }, ...
            varConfig, sitecode, year );
    end
end

% Recalculate VPD
recalcVPD = unique( recalcVPD );
es = 6.1078 .* exp( (17.269 .* thisData.Tair )./(237.3 + thisData.Tair) );
vpd_temp = es - ( thisData.rH .* es ./ 100 );
thisData.VPD( recalcVPD ) = vpd_temp( recalcVPD );

% Replace NaNs with -9999
foo = table2array( thisData );
foo( isnan( foo ) ) = -9999;
thisData{:,:} = foo;

% Write filled data to file except for matlab datenum timestamp column
if write_output
    outfile = fullfile( get_site_directory( sitecode ), ...
        'processed_flux', ...
        sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
        get_site_name( sitecode ), year ) );
    fprintf( 'writing %s\n', outfile );
    thisData.timestamp = [];
    write_table_std( outfile, thisData, 'write_units', true );
end

result = 0;

%========================= SUBFUNCTIONS ==================================

% Function to get the filling site data
    function filledStruct = getFillData( dataStruct, siteType, siteID )
        % Copy data to new struct
        filledStruct = dataStruct;
        % Get the new field name for the data
        if ischar( siteID )
            newFieldName = [siteType '_' siteID];
        else
            newFieldName = [siteType '_' num2str( siteID )];
        end
        
        % Based on configuration, load filling site data, prepare the
        % data, and put into fillSiteData structure
        try
            switch lower( siteType )
                case 'nmeg'
                    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt \n', ...
                        get_site_name( siteID ), year );
                    addData = parse_forgapfilling_file( siteID, year, ...
                        'use_filled', filled_file_false );
                    nmegSiteQC = parse_fluxall_qc_file( siteID, year );
                    addData.Precip = nmegSiteQC.precip;
                    
                case 'sev' % Parse the nearest Sevilletta met site
                    addData = UNM_parse_sev_met_data( year, siteID );
                    addData = prepare_met_data( addData, year, 'Sev' );
                    
                case 'vcp' % Parse the nearest VC met site
                    addData = UNM_parse_valles_met_data( siteID, year );
                    addData = prepare_met_data( addData, year, 'VCP' );
                    
                case 'snotel' % Parse the nearest SNOTEL site
                    addData = UNM_parse_SNOTEL_data( siteID, year );
                    addData = prepare_daily_precip( addData, 'Precip');
                    
                case 'ghcnd' % Parse the nearest GHCND site
                    addData = UNM_parse_GHCN_met_data( siteID, year );
                    addData = prepare_daily_precip( addData, 'PRCP' );
                    % Convert from tenths to mm
                    % Used to be needed - no more
                    %addData.Precip = addData.Precip ./ 10;
                    
                case 'prism'
                    addData = UNM_parse_PRISM_met_data( siteID, year );
                    addData = prepare_daily_precip( addData, 'Precip');
                    
                case 'daymet'
                    addData = UNM_parse_DayMet_data( sitecode, year );
                    addData = prepare_daily_precip( addData, 'prcp_mm_day_' );
            end
            % Fill the timestamps in this dataset and put in fillSiteData
            filledStruct.( newFieldName ) = ...
                fillTstamps( addData, thisData.timestamp, 1/48 );
        catch
            % Let missing data slide with a warning only in current year
            % and fill with NaNs. This is an error in earlier years
            if year == this_year;
                warning( sprintf( 'The %s filling data failed to parse', ...
                    newFieldName ));
            else
                error( sprintf( 'The %s filling data failed to parse', ...
                    newFieldName ));
            end
        end
    end

%==========================================================================
% Function to fill in timestamps of a new dataset
    function filledTsData = fillTstamps( data, tStamps, delta )
        % Subset data
        data = data( ( data.timestamp >= min( tStamps ) & ...
            data.timestamp <= max( tStamps ) ), : );
        % Fill in timestamps
        filledTsData = table_fill_timestamps( data, 'timestamp', ...
            't_min', min( tStamps ), ...
            't_max', max( tStamps ), ...
            'delta_t', delta );
        filledTsData.timestamp = datenum( filledTsData.timestamp );
    end
    
%==========================================================================
    function [ fillDest, varConfRet ] = fill_variable( fillDest, ...
            fillSource, varName, varConf )
        % replace missing values in on variable of dataset fillDest with
        % corresponding values from dataset source1.  Where source1 also
        % has missing values, fall back to source2 if provided.
        
        % Initialize some flags/counters
        nodata = 0;
        n_filled = 0;
        n_missing = numel( find( isnan( fillDest.( varName ) ) ) );
        varConfRet = varConf; % Copy conf for adding indices
        [ varConfRet.fillIdx ] = deal( [] );
        
        for k = 1:length( varConf )
            % Get data source and set linfit and scaling options
            source = fillSource.( varConf(k).fillDataField );
            linfitSource = false;
            scaleSource = false;
            if isfield( varConf(k), 'linfit' ) && varConf(k).linfit
                linfitSource = true;
            end
            if isfield( varConf(k), 'scale' ) && varConf(k).scale
                scaleSource = true;
            end
            % Check that there is valid data in the filling data
            if sum( ~isnan( source.( varName ))) == 0
                nodata = nodata + 1;
                warning(sprintf('There is no valid data in %s source %d', ...
                    varName, k ));
            end
            % Get the index of data in fillDest to fill with
            % non-nan data from source
            fillIdx = find( isnan( fillDest.( varName )) & ...
                ~isnan( source.( varName ) ) );
            varConfRet( k ).fillIdx = fillIdx;
            % Do a linear fit if requested
            if linfitSource
                replacement = linfit_var( source.( varName ), ...
                    fillDest.( varName ), fillIdx );
            else
                replacement = source.( varName );
            end
            % Scale the data if requested
            if scaleSource
                replacement = replacement * ( 1 + varConf(k).scale/100 );
            end
            
            % Put the replacement data in the fill destination and count
            fillDest.( varName )( fillIdx ) = replacement( fillIdx );
            n_filled = n_filled + numel( fillIdx );
        end
        if nodata > 1
            error(sprintf('No data found in %s source 1 or %s source 2',...
                varName, varName ));
        end
        % Calculate and display number of filled data
        fprintf( '%s: replaced %d / %d missing observations\n', ...
            varName, n_filled, n_missing );
    end

%==========================================================================
    function h_fig = plot_filled_variable( filledData, varName, ...
            varConf, sitecode, year )
        
        seconds = repmat( 0.0, size( filledData, 1 ), 1 );
        ts = datenum( filledData.year, filledData.month, filledData.day, ...
            filledData.hour, filledData.minute, seconds );
        nobs = size( filledData, 1 );
        jan1 = datenum( filledData.year, repmat( 1, nobs, 1 ), repmat( 1, nobs, 1 ) );
        doy = ts - jan1 + 1;
        % Make figure and plot all data
        h_fig = figure();
        handles(1) = plot( doy, filledData.( varName ), '.k' );
        handleNames = {'observed'};
        hold on;
        % Then plot filled data from each source
        mcolors = summer( length( varConf ) );
        for l = 1:length( varConf )
            fillIdx = varConf( l ).fillIdx;
            if ~isempty( fillIdx )
                handles(l+1) = plot( doy( fillIdx ), ...
                    filledData.( varName )( fillIdx ), ...
                    '.', 'MarkerEdgeColor', mcolors( l, : ), 'MarkerSize', 10 );
                handleNames{ l + 1 } = [ 'filled ', num2str( l ) ];
            else % if empty still plot something and acknowledge as none
                handles(l+1) = plot( 1, nan, '.', 'MarkerEdgeColor', 'white' );
                handleNames{ l + 1 } = [ 'filled ', num2str( l ), ...
                    ' (none)' ];
            end
        end
        ylabel( varName );
        xlabel( 'day of year' );
        title( sprintf( '%s %d', get_site_name( sitecode ), year ) );
        legend( handles, handleNames );
    end

%===========================================================================

    function T = prepare_met_data( T_in, year, site )
        % Initialize some met variables and configuration for the data
        % If data are hourly, convert to 30min , if precip is in inches,
        % convert it to mm
        if strcmp(site, 'VCP')
            hr_2_30min = true; prec_conv = false; % Conversions
            varCell = { 'AvAirTemp', 'RelHumidty', 'SolarRad', 'Precip'};
            [ TairVar, rhVar, RgVar, PrecVar ] = deal(varCell{:});
        elseif strcmp(site, 'Sev')
            hr_2_30min = true; prec_conv = false;
            varCell = { 'Temp_C', 'Relative_Humidity', ...
                'Solar_Radiation', 'Precipitation' };
            [ TairVar, rhVar, RgVar, PrecVar ] = deal(varCell{:});
        end
        
        % Get subset of met variables and rename
        T = T_in( : , {'timestamp', TairVar, rhVar, RgVar, PrecVar } );
        T.Properties.VariableNames = { 'timestamp', 'Tair', 'rH', 'Rg', 'Precip' };
        
        % Fill in missing timestamps for this data
        %T = fillTstamps( T, T.timestamp, 1/24 );
        
        % Convert rH from [ 0, 1 ] to [ 0, 100 ]
        if nanmax( T.rH ) < 1.5
            T.rH = T.rH * 100.0;
        end
        % Convert precip to mm
        if prec_conv
            T.Precip = T.Precip .* 25.4;
        end
        
        % If readings are hourly -- interpolate to 30 mins
        if hr_2_30min
            ts = T.timestamp;
            thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
            ts_30 = ts + thirty_mins;
            Tair_interp = interp30min( T, ts, ts_30, 'Tair' );
            rH_interp = interp30min( T, ts, ts_30, 'rH' );
            Rg_interp = interp30min( T, ts, ts_30, 'Rg' );
            
            % Setting 30 min Precip to 0
            Prec_interp = zeros(length(ts_30), 1);
            
            T = vertcat( T, table( ts_30, rH_interp, Tair_interp, Rg_interp , ...
                Prec_interp, 'VariableNames', ...
                { 'timestamp', 'rH', 'Tair', 'Rg', 'Precip' } ) );
        end
        
        % Interp subfunction (may fail if there are duplicate timestamps)
        function varInterp = interp30min( dTable, tstamp, tstamp_30, varName )
            valid = find( ~isnan( dTable.( varName) ) );
            if length( valid ) < 2
                varInterp = zeros( length( tstamp_30 ), 1) * nan;
            else
                varInterp = interp1( tstamp( valid ), ...
                    dTable.( varName )( valid ), tstamp_30 );
            end
        end
        
        % filter out bogus values
        T.Tair( abs( T.Tair ) > 100 ) = NaN;
        T.rH( T.rH > 100.0 ) = NaN;
        T.rH( T.rH < 0.0 ) = NaN;
        T.Rg( T.Rg < -20.0 ) = NaN;
        
        % sort by timestamp
        [ ~, idx ] = sort( T.timestamp );
        T = T( idx, : );
    end

%==========================================================================
    function T_resamp = prepare_daily_precip( T, varname )
        %
        %
        T = T( : , { 'timestamp', varname } );
        T.Properties.VariableNames = { 'timestamp', 'Precip' };
        
        % remove duplicated timestamps
        dup_timestamps = find( abs( diff( T.timestamp ) ) < 1e-10 );
        T( dup_timestamps, : ) = [];
        
        % Resample the timeseries to 30mins
        nsamples = repmat(48, 1, length(T.timestamp) - 1);
        x = cumsum([1 nsamples]);
        ts_resamp = interp1(x, T.timestamp, x(1):x(end))';
        
        % Create a new 30 min table and move values over
        Precip = zeros(length(ts_resamp), 1);
        T_resamp = table(ts_resamp, Precip);
        match_rs = find(ismember(ts_resamp, T.timestamp)); %Match by timestamp
        T_resamp.Precip(match_rs) = T.Precip;
        
        % filter out nonsensical values
        T_resamp.Precip( T_resamp.Precip < 0 ) = NaN;
        T_resamp.Precip( T_resamp.Precip > 100 ) = NaN;
        
        % sort by timestamp
        [ discard, idx ] = sort( T_resamp.ts_resamp );
        T_resamp = T_resamp( idx, : );
        T_resamp.Properties.VariableNames{'ts_resamp'} = 'timestamp';
        
    end
%===========================================================================

    function result = linfit_var( x, y, idx )
        
        % find timestamps without NaN in either variable
        nan_idx = any( isnan( [ x, y ] ), 2 );
        
        x_valid = x( ~nan_idx );
        y_valid = y( ~nan_idx );
        
        % linear regression of var2 against var1
        slope = fminsearch( @(m) sse_linfit_slope_only( x_valid, y_valid, m ), ...
            1.10 );
        
        result = x;
        result( idx ) = x( idx ) * slope;
        
        function sse = sse_linfit_slope_only( x, y, m )
            sse = sum( ( y - ( m * x ) ) .^ 2 );
        end
    end

    function result = linfit_var2( x, y, idx )
        
        % find timestamps without NaN in either variable
        nan_idx = any( isnan( [ x, y ] ), 2 );
        
        % linear regression of var2 against var1
        linfit = polyfit( x( ~nan_idx ), y( ~nan_idx ), 1 );
        
        % return prediction of var2 at idx based on regression
        result = x;
        result( idx ) = ( x( idx ) * linfit( 1 ) ) + linfit( 2 );
    end

end

