function diagFig1 = plot_qc_meteorology(  sitecode, ...
    year, ...
    timestamp, ...
    Tair_hmp, ...
    RH_hmp, ...
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

warning( 'Met diagnostic not done yet!' );

return

allTimestamps = timestamp;

% Number of days to plot radiation for
radDays = 10; % July 10

% Day of month to center data around
dom = 15;

% Colors
parin_c = [ 0 168/255 119/255 ];
parout_c = [ 0 106/255 78/255 ]
swin_c = [ 255/255 140/255 0 ];
swout_c = [ 255/255 88/255 0 ];
lwin_c = [ 0 147/255 175/255 ];
lwout_c = [ 0 24/255 168/255 ];
swinpot_c = [237/255 28/255 36/255 ];
rnet_c = [ 0 0 0 ]

% Get an array of potential SW_in on noon of each day of the year.
% This is a pretty rough estimation I think (solar noon is estimated)
% but its helpful for setting an upper bound on the annual radiation.
noon_dnums = ( 0.5 : 10 : 364.5 ) + datenum( year, 1, 1, 0, 30, 0 );
yr_solCalcs = arrayfun( @(x) max( noaa_potential_rad( ...
    UNM_sites_info( sitecode ).latitude, ...
    UNM_sites_info( sitecode ).longitude, ...
    floor( x ) )), noon_dnums, 'UniformOutput', false );
yr_swinpot = arrayfun( @(x) max( x{:} ), yr_solCalcs);

% ============================ FIGURE 1 =================================

% Quick figure to check whether PPFD and SWin are scaled well.
% PPFD (PAR) converts to SWin using a .48 scaling factor, and it should
% normally be slightly larger than our sw_incoming measurement, but below
% the top of the atmosphere max SWin ( around 1300 W/m2 ).

h_fig1 = figure( 'Name', 'Radiation: 1 year PAR vs SWin scaling', ...
    'Position', [ 230 230 700 550 ] );
plot(timestamp, Par_Avg, '.', 'Color', [ 0.6 0.6 0.6 ] );
hold on;
plot( timestamp, Par_Avg * .48, 'o', 'Color', parin_c );
plot( timestamp, sw_incoming, '.', 'Color', swin_c );
plot( noon_dnums, yr_swinpot, '.-', 'Color', swinpot_c );
legend( 'raw PPFD (umol m^{-2} s^{-2})', 'scaled PPFD (W/m2)', ...
    'SWin (W/m2)', 'SWin\_{pot} (Max @ top of atmos.)', 'Location',...
    'SouthWest' );
xlabel( 'Timestamp');
ylabel( 'Radiation' );
ylim( [-10, 1500] );
xlim([ min( timestamp ) max( timestamp ) ]);
datetick('x','mmm dd', 'keepticks');


% ============================ FIGURE 2 =================================
% SWin vs PAR in each month of year

% Set up figure window
h_fig2 = figure( 'Name', ...
    sprintf('%s %d Radiation diagnostics 1/2', ...
    get_site_name( sitecode ), year ), ...
    'Position', [100 100 1250 950], 'Visible', 'on' )

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
    solCalcs = noaa_potential_rad( UNM_sites_info( sitecode ).latitude, ...
        UNM_sites_info( sitecode ).longitude, ...
        repday );
    
    startDay = repday - radDays/2;
    endDay = repday + radDays/2;
    radTest = allTimestamps >= startDay & allTimestamps <= endDay;
    

    % Create subplot and draw dual y axis with original (unshifted) data
    hAx = subplot( 3, 4, i );
    hLine1 = plot( solCalcs( :, 1 ), solCalcs( :, 2 ), ...
        '.-', 'Color', swinpot_c );
    xlabel( xLabelList{ i } );
    ylim([ 0 1400 ]);
    xlim([ 0 24 ]);
    hold on;
    times = allTimestamps( radTest ) - floor( allTimestamps( radTest ));
    times = times * 24;
    hLine2 = plot( times, Par_Avg( radTest ) * 0.48, '.', ...
        'Color', parin_c);
    hLine3 = plot( times, sw_incoming( radTest ), '.', ...
        'Color', swin_c);

    if i == 1
        lh = legend( [ hLine1, hLine2, hLine3 ], ...
            'SWin_{pot}', 'scaled PPFD', 'SWin', ...
            'Location', 'NorthWest', 'Orientation', 'horizontal' );
        set( lh , 'Position', get( lh, 'Position') + [0 .05 0 0 ] );
    end

    % Label axes
    if i == 1 || i == 5 || i == 9 ;
        ylabel( hAx( 1 ), 'Radiation ( W m^2 )');
    end
end

diagFig1 = h_fig2;

%=============================== FIGURE 3 =============================
% Annual pattern in Net Radiation

% Quick figure to asses the yearly pattern in NR and check whether
% NR_tot is the sum of the 4 components.

NR_calc = ( sw_incoming - sw_outgoing )+ ( lw_incoming - lw_outgoing );

h_fig3 = figure( 'Name', 'Radiation: Net radiation check', ...
    'Position', [ 230 230 700 550 ] );
plot(timestamp, NR_tot, 'Color', rnet_c );
hold on;
plot( timestamp, NR_calc, ':', 'Color', [ .6 .6 .6 ] );
plot( noon_dnums, yr_swinpot, '.-', 'Color', swinpot_c );
legend( 'Net Radiation ( W/m2 )', 'NR from 4 components', 'SWin_{pot}' );
xlabel( 'Timestamp');
ylabel( 'Radiation' );
ylim( [-250, 1500] );
xlim([ min( timestamp ) max( timestamp ) ]);
datetick('x','mmm dd', 'keepticks');

%=============================== FIGURE 4 =============================
% Net radiation and 4 components in each month of the year

% Set up figure window
h_fig4 = figure( 'Name', ...
    sprintf('%s %d Radiation diagnostics 3/3', ...
    get_site_name( sitecode ), year ), ...
    'Position', [100 100 1250 950], 'Visible', 'on' )

% % Arrays of data and labels
xLabelList = { 'January', 'February', 'March', 'April', 'May', 'June', ...
    'July', 'August', 'September', 'October', 'November', 'December' };

% Dont plot months without the days we need
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
    
    % Create subplot and draw dual y axis with original (unshifted) data
    hAx = subplot( 3, 4, i );
    hLine1 = plot( solCalcs( :, 1 ), solCalcs( :, 2 ), ...
        '--', 'Color', swinpot_c );
    xlabel( xLabelList{ i } );
    ylim([ -700 1500 ]);
    xlim([ 0 24 ]);
    hold on;
    times = allTimestamps( radTest ) - floor( allTimestamps( radTest ));
    times = times * 24;
    hLine2 = plot( times, sw_incoming( radTest ), '.', ...
        'Color', swin_c, 'MarkerSize', 4.8 );
    hLine3 = plot( times, -sw_outgoing( radTest ), '.', ...
        'Color', swout_c, 'MarkerSize', 4.8 );
    hLine4 = plot( times, lw_incoming( radTest ), '.', ...
        'Color', lwin_c, 'MarkerSize', 4.8 );
    hLine5 = plot( times, -lw_outgoing( radTest ), '.', ...
        'Color', lwout_c, 'MarkerSize', 4.8 );
    hLine6 = plot( times, NR_tot( radTest ), 'o', ...
        'Color', rnet_c, 'MarkerSize', 5 );

    if i == 1
        lh = legend( [ hLine1, hLine2, hLine3, hLine4, hLine5, hLine6 ], ...
            'SWin_{pot}', 'SW\_in', 'SW\_out', 'LW\_in', 'LW\_out', ...
            'Net Radiation', ...
            'Location', 'NorthWest', 'Orientation', 'horizontal' );
        set( lh , 'Position', get( lh, 'Position') + [0 .05 0 0 ] );
    end

    % Label axes
    if i == 1 || i == 5 || i == 9 ;
        ylabel( hAx( 1 ), 'Radiation ( W m^2 )');
    end

end