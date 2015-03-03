function result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, varargin )
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
%     draw_plots: {true} | false; if true, plot observed and filled T, Rg, RH.
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
args.addParamValue( 'draw_plots', true, ...
    @(x) ( islogical( x ) & numel( x ) == 1 ) );
args.parse( sitecode, year, varargin{ : } );
% -----

sitecode = args.Results.sitecode;
year = args.Results.year;
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
thisData = dataset2table(thisData);

% Fill in missing timestamps for this data
thisData = fillTstamps( thisData, thisData.timestamp );

%--------------------------------------------------
% Get Met gapfilling configuration
% We need to parse YAML config files to do this

configFileName = 'MetFill.yaml';

thisConfig = parse_yaml_site_config( configFileName, sitecode, year );

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
        varConfig{j}.('fillDataField') = ...
            [ varConfig{ j }.siteType '_' ...
            num2str( varConfig{ j }.siteID ) ];
        % If that field is not present run getFillData
        if not( isfield( fillData, varConfig{ j }.fillDataField ) )
            fillData = getFillData( fillData, ...
                varConfig{ j }.siteType, varConfig{ j }.siteID );
        end
    end
    % If there is no secondary site for the variable, enter some dummy
    % values into config
    if length( varConfig ) < 2
        varConfig{ 2 } = struct( 'fillDataField', 'empty', 'linfit', 0);
        fillData.('empty') = [];
    end
    
    try
        % Replace missing data in thisData with data from fillData
        % NOTE this also returns indices of what was filled
        [ thisData, filledIdx1, filledIdx2 ] = ...
            fill_variable( thisData, ...
            fillData.( varConfig{ 1 }.fillDataField ), ...
            fillData.( varConfig{ 2 }.fillDataField ), ...
            fillVars{ i }, fillVars{ i }, fillVars{ i }, ...
            varConfig{ 1 }.linfit, ...
            varConfig{ 2 }.linfit );
    catch
        fprintf([ 'ABORTING UNM_fill_met_gaps_from_nearby_site \n' ...
            'There is not enough ancillary met data available \n' ...
            'Filled file not written. \n' ]);
        result = 1;
        return
    end
    % Remove bad values from the now filled variables
    if strcmp( fillVars{ i }, 'rH' )
        thisData.rH( thisData.rH > 1.0 ) = 1.0;
        thisData.rH( thisData.rH < 0.0 ) = 0.0;
    elseif strcmp( fillVars{ i }, 'Rg' )
        thisData.Rg( thisData.Rg < -50 ) = NaN;
    elseif strcmp( fillVars{ i }, 'Precip' )
        thisData.Precip( thisData.Precip < 0 ) = NaN;
    end
    
    % Draw a plot if requested
    if draw_plots
    h_fig = plot_filled_variable( thisData, ...
        fillVars{ i }, filledIdx1, filledIdx2, ...
        sitecode, year );
    end
end
    
% Replace NaNs with -9999
foo = table2array( thisData );
foo( isnan( foo ) ) = -9999;
thisData{:,:} = foo;

% Write filled data to file except for matlab datenum timestamp column
outfile = fullfile( get_site_directory( sitecode ), ...
    'processed_flux', ...
    sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
    get_site_name( sitecode ), year ) );
fprintf( 'writing %s\n', outfile );
thisData.timestamp = [];
thisData2 = table2dataset(thisData);
%export_dataset_tim( outfile, thisData2, 'write_units', true );
%export( thisData( :, 2:end ), 'file', outfile );

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
                nmegSiteQC = UNM_parse_QC_txt_file( siteID, year );
                addData.Precip = nmegSiteQC.precip;
                %FIXME - transition to table
                addData = dataset2table(addData);
                
            case 'sev' % Parse the nearest Sevilletta met site
                addData = UNM_parse_sev_met_data( year, siteID );
                addData = prepare_met_data( addData, year, 'Sev' );
                
            case 'vcp' % Parse the nearest VC met site
                addData = UNM_parse_valles_met_data( 'VCP', year, siteID );
                addData = prepare_met_data( addData, year, 'VCP' );
                
            case 'dri' % DRI files only contain 1 site
                addData = UNM_parse_valles_met_data( 'DRI', year, 'Jemez' );
                addData = prepare_met_data( addData, year, 'DRI' );
                
            case 'snotel' % Parse the nearest SNOTEL site
                addData = UNM_parse_SNOTEL_data( siteID, year );
                addData = prepare_daily_precip( addData, 'Precip');
                
            case 'ghcnd' % Parse the nearest GHCND site
                addData = UNM_parse_GHCND_met_data( siteID, year );
                addData = prepare_daily_precip( addData, 'PRCP' );
                % Convert from tenths to mm
                addData.Precip = addData.Precip ./ 10;
                
            case 'prism'
                addData = UNM_parse_PRISM_met_data( sitecode, year );
                addData = prepare_daily_precip( addData, 'Precip');
                
            case 'daymet'
                addData = UNM_parse_DayMet_data( sitecode, year );
                addData = prepare_daily_precip( addData, 'prcp_mm_day_' );
        end
        % Fill the timestamps in this dataset and put in fillSiteData
        filledStruct.( newFieldName ) = ...
            fillTstamps( addData, thisData.timestamp );
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
    function filledTsData = fillTstamps( data, tStamps )
        % Subset data
        data = data( ( data.timestamp >= min( tStamps ) & ...
            data.timestamp <= max( tStamps ) ), : );
        % Fill in timestamps
        filledTsData = table_fill_timestamps( data, 'timestamp', ...
            't_min', min( tStamps ), ...
            't_max', max( tStamps ) );
        filledTsData.timestamp = datenum( filledTsData.timestamp );
    end
%==========================================================================

    function [ fillDest, idx1, idx2 ] = fill_variable( fillDest, ...
            source1, source2, ...
            varNameDest, ...
            varNameSource1, ...
            varNameSource2, ...
            linfitSource1, ...
            linfitSource2)
        % replace missing values in on variable of dataset fillDest with
        % corresponding values from dataset source1.  Where source1 also
        % has missing values, fall back to source2 if provided.
     
        n_missing = numel( find( isnan( fillDest.( varNameDest ) ) ) );
        
        % Check that there is valid data in the filling data
        if sum( ~isnan( source1.( varNameSource1 ))) == 0
            error(sprintf('There is no valid data in %s source 1', ...
                varNameSource1));
        end
        % Otherwise, get the index of data in fillDest to fill with
        % non-nan data from source 1
        idx1 = find( isnan( fillDest.( varNameDest ) ) & ...
            ~isnan( source1.( varNameSource1 ) ) );
        % Do a linear fit if requested
        if linfitSource1
            replacement = linfit_var( source1.( varNameSource1 ), ...
                fillDest.( varNameDest ), ...
                idx1 );
        else
            replacement = source1.( varNameSource1 );
        end
        % Put the replacement data in the fill destination
        fillDest.( varNameDest )( idx1 ) = replacement( idx1 );
        
        % If there is a secondary site, fill remaining missing values
        idx2 = [];  %initialize to empty in case no second site provided
        if not( isempty( source2 ) )
            if sum( ~isnan( source2.( varNameSource2 ))) == 0
                error(sprintf('There is no valid data in %s source 2', ...
                    varNameSource2));
            end
            idx2 = find( isnan( fillDest.( varNameDest ) ) & ...
                isnan( source1.( varNameSource1 ) ) & ...
                ~isnan( source2.( varNameSource2 ) ) );
            fillDest.( varNameDest )( idx2 ) = ...
                source2.( varNameSource2 )( idx2 );
        end
        % Calculate and display number of filled data
        n_filled = numel( idx1 ) + numel( idx2 );
        fprintf( '%s: replaced %d / %d missing observations\n', ...
            varNameDest, n_filled, n_missing );
    end
%==========================================================================

    function h_fig = plot_filled_variable( filledData, varName, ...
            filledIdx1, filledIdx2, ...
            sitecode, year )
        
        seconds = repmat( 0.0, size( filledData, 1 ), 1 );
        ts = datenum( filledData.year, filledData.month, filledData.day, ...
            filledData.hour, filledData.minute, seconds );
        nobs = size( filledData, 1 );
        jan1 = datenum( filledData.year, repmat( 1, nobs, 1 ), repmat( 1, nobs, 1 ) );
        doy = ts - jan1 + 1;
        
        h_fig = figure();
        h_obs = plot( doy, filledData.( varName ), '.k' );
        hold on;
        h_filled_1 = plot( doy( filledIdx1 ), ...
            filledData.( varName )( filledIdx1 ), ...
            '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
        if not( isempty( filledIdx2 ) )
            h_filled_2 = plot( doy( filledIdx2 ), ...
                filledData.( varName )( filledIdx2 ), ...
                '.', 'MarkerEdgeColor', [ 217, 95, 2 ] / 255.0 );
        else
            h_filled_2 = 0;
        end
        ylabel( varName );
        xlabel( 'day of year' );
        title( sprintf( '%s %d', get_site_name( sitecode ), year ) );
        legend( [ h_obs, h_filled_1, h_filled_2 ], ...
            'observed', 'filled 1', 'filled 2' );
    end
%===========================================================================

    function T = prepare_met_data( T_in, year, site )
        % Initialize some met variables and configuration for the data
        % If data are hourly, convert to 30min , if precip is in inches,
        % convert it to mm
        if strcmp(site, 'VCP')
            hr_2_30min = true; prec_conv = false; % Conversions
            varCell = { 'airt', 'rh', 'sol', 'ppt'};
            [ TairVar, rhVar, RgVar, PrecVar ] = deal(varCell{:});
        elseif strcmp(site, 'DRI')
            hr_2_30min = true; prec_conv = false;
            varCell = { 'Tair_C', 'RH_pct', 'Rad_wm2', 'Precip_mm' };
            [TairVar, rhVar, RgVar, PrecVar ] = deal(varCell{:});
        elseif strcmp(site, 'Sev')
            hr_2_30min = true; prec_conv = false;
            varCell = { 'Temp_C', 'RH', 'Solar_Rad', 'Precip' };
            [ TairVar, rhVar, RgVar, PrecVar ] = deal(varCell{:});
        end
        
        % Get subset of met variables and rename
        T = T_in( : , {'timestamp', TairVar, rhVar, RgVar, PrecVar } );
        T.Properties.VariableNames = { 'timestamp', 'Tair', 'rH', 'Rg', 'Precip' };
        
        % Convert rH from [ 0, 100 ] to [ 0, 1 ]
        if nanmax(T.rH > 2)
            T.rH = T.rH ./ 100.0;
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
            if isempty( valid )
                varInterp = zeros( length( tstamp_30 ), 1) * nan;
            else
                varInterp = interp1( tstamp( valid ), ...
                    dTable.( varName )( valid ), tstamp_30 );
            end
        end
        
        % filter out bogus values
        T.Tair( abs( T.Tair ) > 100 ) = NaN;
        T.rH( T.rH > 1.0 ) = NaN;
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

