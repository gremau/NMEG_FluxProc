function plot_qc_meteorology(  sitecode, ...
    year, ...
    timestamp, ...
    Tair_hmp, ...
    RH_hmp, ...
    VPD, ...
    Tair_sonic, ...
    H2O_irga, ...
    precip,...
    NR_tot )
% plot_qc_radiation - makes diagnostic figures showing met variables
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

%warning( 'Met diagnostic not done yet!' );

%return

allTimestamps = timestamp;

% Number of days to plot radiation for
metDays = 10; % July 10

% Day of month to center data around
dom = 15;

% Colors
rhhmp1_c = [ 0 168/255 119/255 ];
rhhmp2_c = [ 0 106/255 78/255 ];
tahmp1_c = [ 255/255 140/255 0 ];
tahmp2_c = [ 255/255 88/255 0 ];
irgah2o_c = [ 0 147/255 175/255 ];
precip_c = [ 0 24/255 168/255 ];
tason_c = [237/255 28/255 36/255 ];
%rnet_c = [ 0 0 0 ]

hmp2 = false;
precip2 = false;

% ============================ FIGURE 1 =================================

% Quick figure to check whether PPFD and SWin are scaled well.
% PPFD (PAR) converts to SWin using a .48 scaling factor, and it should
% normally be slightly larger than our sw_incoming measurement, but below
% the top of the atmosphere max SWin ( around 1300 W/m2 ).

h_fig1 = figure( 'Name', 'Met: 1 year T and RH', ...
    'Position', [ 100 100 800 750 ] );
h_ax( 1 ) = subplot( 6, 1, 1:2);
plot(timestamp, Tair_hmp, '-', 'Color', tahmp1_c );
hold on;
plot( timestamp, Tair_sonic - 273.15, '-', 'Color', tason_c );
if hmp2
    plot( timestamp, Tair_hmp2, ':', 'Color', tahmp2_c );
    legend( 'Tair (hmp 1)', 'Tair (sonic anem.)', ...
        'Tair (hmp 2)', 'Location', 'SouthWest' );
else
    legend( 'Tair (hmp 1)', 'Tair (sonic anem.)', ...
        'Location', 'NorthWest' );
end
datetick('x','mmm dd', 'keepticks');
ylabel( 'Tair ( degrees C )' );
ylim( [-30, 40] );
xlim([ min( timestamp ) max( timestamp ) ]);

h_ax( 2 ) = subplot( 6, 1, 3:4 );
[yy_ax, h_line1, h_line2 ] = plotyy( timestamp, RH_hmp, timestamp, VPD );
set( h_line1, 'Color', rhhmp1_c );
set( h_line2, 'Color', 'Black', 'LineStyle', ':');
if hmp2
    plot( yy_ax( 1 ), timestamp, RH_hmp2, ':', 'Color', rhhmp2_c );
    legend( 'RH (hmp 1)', 'VPD', 'RH (hmp 2)', 'Location', 'NorthWest' );
else
    legend( 'RH', 'VPD', 'Location', 'NorthWest' );
end
%ylabel( 'RH ( % )' );
ylim( yy_ax( 1 ), [-2, 102] );
ylim( yy_ax( 2 ), [0, 100] );
xlim( yy_ax( 1 ), [ min( timestamp ) max( timestamp ) ]);
xlim( yy_ax( 2 ), [ min( timestamp ) max( timestamp ) ]);
datetick('x','mmm dd', 'keepticks');

h_ax( 3 ) = subplot( 6, 1, 5 );
plot( timestamp, precip, '-', 'Color', [ 0.2 0.2 0.2 ] );
if precip2
    plot( timestamp, precip2, '-', 'Color', [ 0.5 0.5 0.5 ] );
    legend( 'RH (hmp 1)', 'RH (hmp 2)', 'Location', 'SouthWest' );
end
ylabel( {'Precip', '( mm )'} );
%ylim( [-2, 102] );
xlim([ min( timestamp ) max( timestamp ) ]);
datetick('x','mmm dd', 'keepticks');

PRISM_precip = UNM_parse_PRISM_met_data( sitecode, year );

h_ax( 4 ) = subplot( 6, 1, 6 );
plot( PRISM_precip.timestamp, PRISM_precip.Precip, '-', 'Color', precip_c );
xlabel( 'Timestamp');
ylabel( {'PRISM', '( mm )'} );
%ylim( [-5, 102] );
xlim([ min( timestamp ) max( timestamp ) ]);
datetick('x','mmm dd', 'keepticks', 'keeplimits' );

linkaxes( h_ax, 'x' );

% ============================ FIGURE 2 =================================
% Tair in each month of year

% Set up figure window
h_fig2 = figure( 'Name', ...
    sprintf('%s %d Met diagnostics 2/2', ...
    get_site_name( sitecode ), year ), ...
    'Position', [100 100 1250 950], 'Visible', 'on' );

% Arrays of data and labels
xLabelList = { 'January', 'February', 'March', 'April', 'May', 'June', ...
    'July', 'August', 'September', 'October', 'November', 'December' };

% Dont plot months without the days we need
[ ~, monthsPresent, daysPresent, ~, ~, ~ ] = datevec( allTimestamps );
fullMonthsPresent = monthsPresent( daysPresent >= dom + 5 ); 

for i = 1:max( fullMonthsPresent )
    % Get day numbers, mean data for 2 variables, and solar events for 
    % the first week of month (i)
    repday = datenum( year, i, dom );
    
    startDay = repday - metDays/2;
    endDay = repday + metDays/2;
    metTest = allTimestamps >= startDay & allTimestamps <= endDay;
    
    times = allTimestamps( metTest ) - floor( allTimestamps( metTest ));
    times = times * 24;
    % Create subplot and draw dual y axis with original (unshifted) data
    hAx = subplot( 3, 4, i );
    hLine1 = plot( times, Tair_hmp( metTest ), '.', ...
        'Color', tahmp1_c);
    hold on;
    hLine2 = plot( times, Tair_sonic( metTest ) - 273.15, '.', ...
        'Color', tason_c );
    xlabel( xLabelList{ i } );
    ylim([ -30 40 ]);
    xlim([ 0 24 ]);
    hold on;

    if i == 1
        lh = legend( [ hLine1, hLine2 ], ...
            'Tair (hmp1)', 'Tair (sonic)', ...
            'Location', 'NorthWest', 'Orientation', 'horizontal' );
        set( lh , 'Position', get( lh, 'Position') + [0 .05 0 0 ] );
    end

    % Label axes
    if i == 1 || i == 5 || i == 9 ;
        ylabel( hAx( 1 ), 'Tair ( degrees )');
    end
end