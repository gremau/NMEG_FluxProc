function diagFig1 = plot_qc_radiation(  sitecode, ...
    year, ...
    timestamp, ...
    sw_incoming, ...
    sw_outgoing, ...
    lw_incoming, ...
    lw_outgoing, ...
    Par_Avg, ...
    NR_tot )
% plot_qc_radiation - makes 2 diagnostic figures showing radiation
%
% Called from UNM_RBD.m
%
% FIXME - this needs to be finished....
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
% args = inputParser;
% args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
% args.addRequired( 'year', ...
%     @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ...
%     ) );
% args.addRequired( 'dataTable', @istable );
%args.addRequired( 'dataShifted',  @istable );

% parse optional inputs
% args.parse( sitecode, year, dataTable );
% 
% sitecode = args.Results.sitecode;
% year = args.Results.year;
% dataT = args.Results.dataTable;

allTimestamps = timestamp;

% Number of days to plot radiation for
radDays = 10; % July 10

% Day of month to center data around
dom = 15;

% Check that there aren't multiple years in the incoming data
% FIXME There are other checks on years - can probably remove this
% [ y, ~, ~, ~, ~, ~ ] = datevec( dataOrig.timestamp( 1:end-1 ));
% if length( unique( y )) > 1 || not( ismember( year, y ) )
%     error(' Error in years being compared ');
% end

% -----------------------------------------------------------------
% Identify and check for Rg and PAR columns in the original data table
% RgVar = 'Rad_short_Up_Avg';
% parVar = 'par_faceup_Avg';
% 
% RgCol = find( strcmp( RgVar, ...
%     dataOrig.Properties.VariableNames ), 1 );
% parCol = find( strcmp( parVar, ...
%     dataOrig.Properties.VariableNames), 1 );
% if isempty( parCol )
%     parVar = 'missing';
% end
% if isempty( RgCol )
%     error( 'could not find incoming shortwave column' );
% end

% -----------------------------------------------------------------
% Get the NOAA solar model results for all the timestamps in either
% table. These are theoretical values for sunrise, sunset and solar noon.
% They ignore topography and atmospheric condition effects.
% solDates = unique( round( timestamp )); % Dates in the plotting range
% solDates = solDates( ~isnan( solDates ));
% % [Solar noon, theoretical sunrise, theoretical sunset]
% solCalcs = noaa_solar_calcs( ...
%     UNM_sites_info( sitecode ).latitude, ...
%     UNM_sites_info( sitecode ).longitude, ...
%     solDates );
% % Convert from times from day fraction to hours
% solCalcs = solCalcs( :, 2:4 ) .* 24;
% solCalcs = [ solCalcs (solDates - datenum( year, 1, 0 )) ];

% ============================ FIGURE 1 =================================
% Plot two rows of diagnostic plots. Top row is original data, bottom row
% is shifted data. Solar events are plotted. If there are tilted radiation
% sensors it may be useful to compare PAR and Rg data. Full year 
% fingerprints help to quickly identify timing shifts in radiation of flux
% data and whether corrections are accurate relative to sunrise/sunset.

% Set up figure window
h_fig1 = figure( 'Name', ...
    sprintf('%s %d Radiation diagnostics 1/2', ...
    get_site_name( sitecode ), year ), ...
    'Position', [230 100 1250 950], 'Visible', 'on' )

% Arrays of data and labels
xLabelList = { 'January', 'February', 'March', 'April', 'May', 'June', ...
    'July', 'August', 'September', 'October', 'November', 'December' };

% Make sure we don't plot months without at least 7 days
[ ~, monthsPresent, daysPresent, ~, ~, ~ ] = datevec( allTimestamps );
fullMonthsPresent = monthsPresent( daysPresent >= dom + 5 ); 

for i = 1:max( fullMonthsPresent )
    % Get day numbers, mean data for 2 variables, and solar events for 
    % the first week of month (i)
    repday = datenum( year, i, dom );
    solCalcs = noaa_potential_rad( UNM_sites_info( sitecode ).latitude, ...
        UNM_sites_info( sitecode ).longitude, ...
        repday );
    
    startDay = repday - radDays/2;
    endDay = repday + radDays/2;
    radTest = allTimestamps >= startDay & allTimestamps <= endDay;
    
%     [ ~, firstWkOrig ] = get_data_subset( startWkDay, endWkDay, ...
%         year, dataOrig, RgVar, 'Fc_raw_massman_ourwpl' );
%     [ ~, firstWkShifted ] = get_data_subset( startWkDay, endWkDay, ...
%         year, dataShifted, RgVar, 'Fc_raw_massman_ourwpl' );
    % Create subplot and draw dual y axis with original (unshifted) data
    hAx = subplot( 3, 4, i );
    hLine1 = plot( solCalcs( :, 1 ), solCalcs( :, 2 ), ...
        '.-r' );
    xlabel( xLabelList{ i } );
    ylim([ 0 1400 ]);
    xlim([ 0 24 ]);
    hold on;
    times = allTimestamps( radTest ) - floor( allTimestamps( radTest ));
    times = times * 24;
    hLine2 = plot( times, Par_Avg( radTest ) * 0.48, '.', ...
        'Color', [0.3, 0.3, 0.3]);
    hLine3 = plot( times, sw_incoming( radTest ), '.', ...
        'Color', [0.7, 0.7, 0.7]);

    if i == 1
        lh = legend( [ hLine1, hLine2, hLine3 ], ...
            'Rg\_potential', 'scaled PPFD', 'Rg', ...
            'Location', 'NorthWest', 'Orientation', 'horizontal' );
        set( lh , 'Position', get( lh, 'Position') + [0 .04 0 0 ] );
    end
%     hLine4 = plot( hAx( 2 ), firstWkShifted.time, ...
%         firstWkShifted.Fc_raw_massman_ourwpl, 'ok', 'MarkerSize', 5 );
%     % Plot some dotted lines for every 2 hours for reference
%     gray = [ 0.4, 0.4, 0.4 ];
%     for k = 2:2:22
%         plot( hAx( 1 ), [ k, k ], leftLim, ':', 'Color', gray + .3 )
%     end
%     % Plot the solar events
%     plot( hAx( 1 ), [12, 12], leftLim , '-', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(1), solEventsWk(1)], leftLim, ...
%         '--', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(2), solEventsWk(2)], leftLim, ...
%         '--', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(3), solEventsWk(3)], leftLim, ...
%         '--', 'Color', gray );
    % Label axes
    if i == 1 || i == 5 || i == 9 ;
        ylabel( hAx( 1 ), 'Radiation ( W m^2 )');
    end
end

diagFig1 = h_fig1;

%=============================== FIGURE 2 =============================
% Diurnal curves of Rg and Fc for the first week of each month. Useful for
% assessing shifts between solar events and ecosystem fluxes, which may
% indicate that the 10hz and 30min data in a fluxall file are offset for
% some reason.

% Set up figure window
% h_fig2 = figure( 'Name', ...
%     sprintf('%s %d datalogger time-shift diagnostics 2/2', ...
%     get_site_name( sitecode ), year ), ...
%     'Position', [230 100 1250 950], 'Visible', 'on' );
% % Arrays of data and labels
% xLabelList = { 'January', 'February', 'March', 'April', 'May', 'June', ...
%     'July', 'August', 'September', 'October', 'November', 'December' };
% 
% % Make sure we don't plot months without at least 7 days
% [ ~, monthsPresent, daysPresent, ~, ~, ~ ] = datevec( allTimestamps );
% fullMonthsPresent = monthsPresent( daysPresent >= 7 ); 
% 
% for i = 1:max( fullMonthsPresent )
%     % Get day numbers, mean data for 2 variables, and solar events for 
%     % the first week of month (i)
%     startWkDay = datenum( year, i, 1) - datenum( year, 1, 0 );
%     endWkDay = datenum( year, i, 7) - datenum( year, 1, 0 );
%     solEventsWk = solCalcs( startWkDay + 3, : );
%     [ ~, firstWkOrig ] = get_data_subset( startWkDay, endWkDay, ...
%         year, dataOrig, RgVar, 'Fc_raw_massman_ourwpl' );
%     [ ~, firstWkShifted ] = get_data_subset( startWkDay, endWkDay, ...
%         year, dataShifted, RgVar, 'Fc_raw_massman_ourwpl' );
%     % Create subplot and draw dual y axis with original (unshifted) data
%     subplot( 3, 4, i );
%     [ hAx, hLine1, hLine2] = plotyy( ...
%         firstWkOrig.time, firstWkOrig.( RgVar ), ...
%         firstWkOrig.time, firstWkOrig.Fc_raw_massman_ourwpl );
%     xlabel( xLabelList{ i } );
%     leftLim = [ -1100 1100 ];
%     set( hAx( 1 ), 'YLim',leftLim , 'XLim', [ 0 24 ], ...
%         'YColor', 'r' );
%     set( hAx( 2 ), 'YLim', [ -8 12 ], 'XLim', [ 0 24 ], 'YColor', 'b' );
%     set( hLine1, 'Color', 'r', 'LineStyle', 'none', 'Marker', '.' );
%     set( hLine2, 'Color', 'b', 'LineStyle', 'none', 'Marker', '.'  );
%     % Plot the shifted data
%     hold(hAx( 1 ),'on');
%     hold(hAx( 2 ),'on');
%     hLine3 = plot( hAx( 1 ), firstWkShifted.time, ...
%         firstWkShifted.( RgVar ), 'ok', 'MarkerSize', 5 );
%     if i == 1
%         lh = legend( [ hLine1, hLine2, hLine3 ], ...
%             'Rg (raw)', 'Fc (raw)', 'Shifted values', ...
%             'Location', 'NorthWest', 'Orientation', 'horizontal' );
%         set( lh , 'Position', get( lh, 'Position') + [0 .04 0 0 ] );
%     end
%     hLine4 = plot( hAx( 2 ), firstWkShifted.time, ...
%         firstWkShifted.Fc_raw_massman_ourwpl, 'ok', 'MarkerSize', 5 );
%     % Plot some dotted lines for every 2 hours for reference
%     gray = [ 0.4, 0.4, 0.4 ];
%     for k = 2:2:22
%         plot( hAx( 1 ), [ k, k ], leftLim, ':', 'Color', gray + .3 )
%     end
%     % Plot the solar events
%     plot( hAx( 1 ), [12, 12], leftLim , '-', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(1), solEventsWk(1)], leftLim, ...
%         '--', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(2), solEventsWk(2)], leftLim, ...
%         '--', 'Color', gray );
%     plot( hAx( 1 ), [solEventsWk(3), solEventsWk(3)], leftLim, ...
%         '--', 'Color', gray );
%     % Label axes
%     if i == 1 || i == 5 || i == 9 ;
%         ylabel( hAx( 1 ), 'Rg');
%     elseif i == 4 || i == 8 || i == 12 ;
%         ylabel( hAx( 2 ), 'Fc\_raw\_massman\_ourwpl' );
%     end
% end

%diagFig2 = h_fig2;

end