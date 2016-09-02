function plot_fixed_datalogger_timestamps( sitecode, year, ...
                                           dataOrig, dataShifted )
% plot_fixed_datalogger_timestamps - makes 2 diagnostic figures showing the
% data shifts between original and shifted datalogger tables.
%
% Called from UNM_fix_datalogger_timestamps.m
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%    dataOrig: NxM numeric: the original, unshifted fluxall data
%    dataShifted: NxM numeric: the shifted fluxall data.
%
% OUTPUTS
%    2 figure handles
%
% SEE ALSO
%    UNM_sites, dataset, UNM_fix_datalogger_timestamps, shift_data
%
% author: Gregory E. Maurer, UNM, February 2015
% adapted from code by Tim Hilton (in UNM_fix_datalogger_timestamps.m)

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ...
    ) );
args.addRequired( 'dataOrig', @istable );
args.addRequired( 'dataShifted',  @istable );

% parse optional inputs
args.parse( sitecode, year, dataOrig, dataShifted );

sitecode = args.Results.sitecode;
year = args.Results.year;
dataOrig = args.Results.dataOrig;
dataShifted = args.Results.dataShifted;

% Days to plot radiation averages for
radStartDay = 171; % June 20
radEndDay = 191; % July 10

% Check that there aren't multiple years in the incoming data
% FIXME There are other checks on years - can probably remove this
% [ y, ~, ~, ~, ~, ~ ] = datevec( dataOrig.timestamp( 1:end-1 ));
% if length( unique( y )) > 1 || not( ismember( year, y ) )
%     error(' Error in years being compared ');
% end

% -----------------------------------------------------------------
% Identify and check for Rg and PAR columns in the original data table
RgVar = 'Rad_short_Up_Avg';
parVar = 'par_faceup_Avg';

RgCol = find( strcmp( RgVar, ...
    dataOrig.Properties.VariableNames ), 1 );
parCol = find( strcmp( parVar, ...
    dataOrig.Properties.VariableNames), 1 );
if isempty( parCol )
    parVar = 'missing';
end
if isempty( RgCol )
    error( 'could not find incoming shortwave column' );
end

% -----------------------------------------------------------------
% Get the NOAA solar model results for all the timestamps in either
% table. These are theoretical values for sunrise, sunset and solar noon.
% They ignore topography and atmospheric condition effects.
allTimestamps = [ dataOrig.timestamp, dataShifted.timestamp ];
solDates = unique( round( allTimestamps )); % Dates in the plotting range
solDates = solDates( ~isnan( solDates ));
% [Solar noon, theoretical sunrise, theoretical sunset]
solCalcs = noaa_solar_calcs( ...
    UNM_sites_info( sitecode ).latitude, ...
    UNM_sites_info( sitecode ).longitude, ...
    solDates );
% Convert from times from day fraction to hours
solCalcs = solCalcs( :, {'solarNoonLST', 'sunriseTimeLST', 'sunsetTimeLST'} );
solCalcs{:,:} = solCalcs{:,:} * 24;
solCalcs.julday = solDates - datenum( year, 1, 0 );

% ============================ FIGURE 1 =================================
% Plot two rows of diagnostic plots. Top row is original data, bottom row
% is shifted data. Solar events are plotted. If there are tilted radiation
% sensors it may be useful to compare PAR and Rg data. Full year 
% fingerprints help to quickly identify timing shifts in radiation of flux
% data and whether corrections are accurate relative to sunrise/sunset.

% Set up figure window
h_fig1 = figure( 'Name', ...
    sprintf('%s %d datalogger time-shift diagnostics 1/2', ...
    get_site_name( sitecode ), year ), ...
    'Position', [50 50 1370 700], 'Visible', 'on' );
% Arrays of data and labels
tableList = { dataOrig, dataShifted };
titleStrings = { 'before', 'after' };
subplotIterator = [ 0, 4 ];

for i = 1:2
    % Get variables needed for this row of data
    [ radSubset, radMean ] = get_data_subset( ...
        radStartDay, radEndDay, year, tableList{ i }, ...
        parVar, RgVar );
    
    % Plot PAR during test time period
    ax = subplot( 2, 4, 1 + subplotIterator( i ));
    xAxLim = [0 24];
    yAxLim = [-5 3000];
    ax = radiation_subplot( ax, radStartDay, radEndDay, radSubset, ...
        radMean, solCalcs, parVar, titleStrings{ i }, ...
        yAxLim );
    xlim( xAxLim ); ylim( yAxLim );
    
    % Plot Rg during test period
    ax = subplot( 2, 4, 2 + subplotIterator( i ));
    yAxLim = [-5 1500];
    ax = radiation_subplot( ax, radStartDay, radEndDay, radSubset, ...
        radMean, solCalcs, RgVar, titleStrings{ i }, ...
        yAxLim );
    xlim( xAxLim ); ylim( yAxLim );
    
    % Plot an Rg fingerprint for entire year
    ax = subplot( 2, 4, 3 + subplotIterator( i ));
    [ ~, ax ] = fingerprint_subplot( h_fig1, ax, tableList{ i }, RgVar, ...
        solCalcs, [0, 900], titleStrings{ i }, year );
    hold( ax, 'on' );
    % Plot markers at start/end times for Rg radiation means (prior plot).
    plot( ax, [ 1 4 ] , [ radStartDay radStartDay ], ...
        [ 20 24 ] , [ radStartDay radStartDay ], 'LineStyle', ...
        ':', 'color', 'g' );
    plot( ax, [ 1 4 ] , [ radEndDay radEndDay ], ...
        [ 20 24 ] , [ radEndDay radEndDay ], 'LineStyle', ...
        ':', 'color', 'g' );
    
    % Plot an NEE fingerprint for entire year
    ax = subplot( 2, 4, 4 + subplotIterator( i ));
    [ ~, ax ] = fingerprint_subplot( h_fig1, ax, tableList {i }, ...
        'Fc_raw_massman_ourwpl', solCalcs, [-10, 0], ...
        titleStrings{ i }, year );
end % End fig 1

%=============================== FIGURE 2 =============================
% Diurnal curves of Rg and Fc for the first week of each month. Useful for
% assessing shifts between solar events and ecosystem fluxes, which may
% indicate that the 10hz and 30min data in a fluxall file are offset for
% some reason.

% Set up figure window
h_fig2 = figure( 'Name', ...
    sprintf('%s %d datalogger time-shift diagnostics 2/2', ...
    get_site_name( sitecode ), year ), ...
    'Position', [50 50 1050 750], 'Visible', 'on' );
% Arrays of data and labels
xLabelList = { 'January', 'February', 'March', 'April', 'May', 'June', ...
    'July', 'August', 'September', 'October', 'November', 'December' };

% Make sure we don't plot months without at least 7 days
[ ~, monthsPresent, daysPresent, ~, ~, ~ ] = datevec( allTimestamps );
fullMonthsPresent = monthsPresent( daysPresent >= 7 ); 

for i = 1:max( fullMonthsPresent )
    % Get day numbers, mean data for 2 variables, and solar events for 
    % the first week of month (i)
    startWkDay = datenum( year, i, 1) - datenum( year, 1, 0 );
    endWkDay = datenum( year, i, 7) - datenum( year, 1, 0 );
    solEventsWk = solCalcs( startWkDay + 3, : );
    [ ~, firstWkOrig ] = get_data_subset( startWkDay, endWkDay, ...
        year, dataOrig, RgVar, 'Fc_raw_massman_ourwpl' );
    [ ~, firstWkShifted ] = get_data_subset( startWkDay, endWkDay, ...
        year, dataShifted, RgVar, 'Fc_raw_massman_ourwpl' );
    % Create subplot and draw dual y axis with original (unshifted) data
    subplot( 3, 4, i );
    [ hAx, hLine1, hLine2] = plotyy( ...
        firstWkOrig.time, firstWkOrig.( RgVar ), ...
        firstWkOrig.time, firstWkOrig.Fc_raw_massman_ourwpl );
    xlabel( xLabelList{ i } );
    leftLim = [ -1100 1100 ];
    set( hAx( 1 ), 'YLim',leftLim , 'XLim', [ 0 24 ], ...
        'YColor', 'r' );
    set( hAx( 2 ), 'YLim', [ -8 12 ], 'XLim', [ 0 24 ], 'YColor', 'b' );
    set( hLine1, 'Color', 'r', 'LineStyle', 'none', 'Marker', '.' );
    set( hLine2, 'Color', 'b', 'LineStyle', 'none', 'Marker', '.'  );
    % Plot the shifted data
    hold(hAx( 1 ),'on');
    hold(hAx( 2 ),'on');
    hLine3 = plot( hAx( 1 ), firstWkShifted.time, ...
        firstWkShifted.( RgVar ), 'ok', 'MarkerSize', 5 );
    if i == 1
        lh = legend( [ hLine1, hLine2, hLine3 ], ...
            'Rg (raw)', 'Fc (raw)', 'Shifted values', ...
            'Location', 'NorthWest', 'Orientation', 'horizontal' );
        set( lh , 'Position', get( lh, 'Position') + [0 .04 0 0 ] );
    end
    hLine4 = plot( hAx( 2 ), firstWkShifted.time, ...
        firstWkShifted.Fc_raw_massman_ourwpl, 'ok', 'MarkerSize', 5 );
    % Plot some dotted lines for every 2 hours for reference
    gray = [ 0.4, 0.4, 0.4 ];
    for k = 2:2:22
        plot( hAx( 1 ), [ k, k ], leftLim, ':', 'Color', gray + .3 )
    end
    % Plot the solar events
    plot( hAx( 1 ), [12, 12], leftLim , '-', 'Color', gray );
    plot( hAx( 1 ), [solEventsWk.solarNoonLST, ...
        solEventsWk.solarNoonLST], leftLim, '--', 'Color', gray );
    plot( hAx( 1 ), [solEventsWk.sunriseTimeLST, ...
        solEventsWk.sunriseTimeLST], leftLim, '--', 'Color', gray );
    plot( hAx( 1 ), [solEventsWk.sunsetTimeLST, ...
        solEventsWk.sunsetTimeLST], leftLim, '--', 'Color', gray );
    % Label axes
    if i == 1 || i == 5 || i == 9 ;
        ylabel( hAx( 1 ), 'Rg');
    elseif i == 4 || i == 8 || i == 12 ;
        ylabel( hAx( 2 ), 'Fc\_raw\_massman\_ourwpl' );
    end
end

%=====================================================================
% Data functions

% Subset the radiation data from the specified table for the given date
% range and calculate a mean
    function [ subsetT, meanT ] = get_data_subset( ...
            startDay, endDay, yr, dataT, varName1, varName2 )
        % Something is wrong with jday in some fluxall files ( FIXME ) so
        % calculate a day of year
        doy = dataT.timestamp - datenum( yr, 1, 0 );
        subsetT = dataT( doy >= startDay & doy <= endDay + 1, : );
        subsetT.doy = subsetT.timestamp - datenum( yr, 1, 0 );
        % Calculate decimal hours of day
        subsetT.decimalHrs = 24 * ( subsetT.timestamp - ...
            floor( subsetT.timestamp ));
        % Change 0 to 24
        subsetT.decimalHrs( subsetT.decimalHrs == 0 ) = 24.0;
        if strcmp('missing', varName1 )
            subsetT.( varName1 ) = (1:size( subsetT, 1 ))';
        end
        if strcmp('missing', varName2 )
            subsetT.( varName2 ) = (1:size( subsetT, 1 ))';
        end
        % Get the set of 48 decimal hours in a day (30 min data)
        timesIn1Day = unique( subsetT.decimalHrs );
        % Group by decimalHrs and then aggregate variable as a mean
        [ ~, groups ] = ismember( subsetT.decimalHrs , timesIn1Day );
        indices = [ groups ones( size( groups ))];
        meanVar1 = accumarray( indices, subsetT.( varName1 ), ...
            [ numel( unique( groups )) 1 ], @mean );
        meanVar2 = accumarray( indices, subsetT.( varName2 ), ...
            [ numel( unique( groups )) 1 ], @mean );
        % Put in a table
        meanT = table( timesIn1Day, meanVar1, meanVar2, ...
            'VariableNames', { 'time', varName1, varName2 } );
    end

% ========================== PLOT DEFINITIONS =============================

% Plot radiation for specified period and its average
    function axh = radiation_subplot( axh, startDay, endDay, radSubset, ...
            meanRad, solarEvents, radVarName, shiftStr, ...
            yLimit )
        hold on;
        for j = startDay:endDay
            test = floor( radSubset.doy ) == j ;
            plot( radSubset.decimalHrs( test ), ...
                radSubset{ test, radVarName }, '.k');
        end
        plot([12, 12], yLimit, '-k');
        % Making these plots before startDay doesn't make sense
        if max(solarEvents.julday) >= endDay
            solarEvents = solarEvents( solarEvents.julday == ...
                floor( mean( [startDay, endDay] )), : );
            plot([solarEvents.solarNoonLST, solarEvents.solarNoonLST],...
                yLimit, '--r');
            plot([solarEvents.sunriseTimeLST, solarEvents.sunriseTimeLST],...
                yLimit, ':r');
            plot([solarEvents.sunsetTimeLST, solarEvents.sunsetTimeLST],...
                yLimit, ':r');
            plot( meanRad.time, meanRad.( radVarName ), '-og' );
        end
        titleStr = sprintf( '%s %s timing fixed', radVarName, shiftStr );
        titleStr = strrep( titleStr, '_', '\_' );
        title( titleStr );
    end

% Plot a full year fingerprint for a variable
    function [ figHandle, axisHandle ] = fingerprint_subplot( ...
            figHandle, axisHandle, dataT, varName, ...
            solarEvents, clim, shiftStr, yr )
        % Make a fractional day column
        dtime = dataT.timestamp - datenum( yr, 1, 0 );
        % Subplot title
        titleStr = sprintf( '%s %s timing fixed', varName, shiftStr );
        titleStr = strrep( titleStr, '_', '\_' );
        % Call to plot_fingerprint.m
        [ figHandle, axisHandle ] = plot_fingerprint( dtime, ...
            dataT.( varName ), ...
            titleStr, ...
            'clim', clim, ...
            'fig_visible', true, ...
            'h_fig', figHandle, ...
            'h_ax', axisHandle, ...
            'cmap', colormap('jet'));
        hold on;
        % Plot noon and the NOAA solar model
        plot([ 12, 12 ], [ 0, 365 ], '-k');
        plot( solarEvents.solarNoonLST , solarEvents.julday, ...
            ':', 'color', [ 0.8 0.8 0.8 ]);
        plot( solarEvents.sunriseTimeLST , solarEvents.julday, ...
            ':', 'color', [ 0.8 0.8 0.8 ]);
        plot( solarEvents.sunsetTimeLST , solarEvents.julday, ...
            ':', 'color', [ 0.8 0.8 0.8 ]);
    end

end