function plots_for_PJgirdle_report_2009_2013()
% PLOTS_FOR_PJGIRDLE_REPORT_15OCT2012 - create a series of plots for Marcy's
% PJ/PJ girdle report of 31 Dec 2013.
%   
% Creates one plot each for cumulative NEE, GPP, and RE.  Each plot shows the
% fluxes from PJ, PJ_girdle, and JSav alongside one another.  The fluxes are
% plotted from March 2009 (establishment of the EC tower at PJ_girdled)
% through the present, with a vertical line drawn on 1 Sep 2009 (approximate
% date of girdling).
%
% USAGE:
%    plots_for_PJgirdle_report_15Oct2012();
%
% author: Timothy W. Hilton, UNM, Oct 2012



load( fullfile( getenv( 'FLUXROOT' ), ...
                'FluxOut', 'BinaryData', 'PJ_all_gapfilled.mat' ) );
pj = this_data;

load( fullfile( getenv( 'FLUXROOT' ), ...
                'FluxOut', 'BinaryData', 'PJ_girdle_all_gapfilled.mat' ) );
pjg = this_data;

load( fullfile( getenv( 'FLUXROOT' ), ...
                'FluxOut', 'BinaryData', 'JSav_all_gapfilled.mat' ) );
jsav = this_data;

pj( pj.timestamp < datenum( 2009, 1, 1 ), : ) = [];
pjg( pjg.timestamp < datenum( 2009, 1, 1 ), : ) = [];
jsav( jsav.timestamp < datenum( 2009, 1, 1 ), : ) = [];

pj.NEEg = umolPerSecPerM2_2_gcPerMSq( pj.FC );
pjg.NEEg = umolPerSecPerM2_2_gcPerMSq( pjg.FC );
jsav.NEEg = umolPerSecPerM2_2_gcPerMSq( jsav.FC );

pj_d = get_daily( pj, 'NEEg' );
pjg_d = get_daily( pjg, 'NEEg' );
jsav_d = get_daily( jsav, 'NEEg' );

% -----
% draw the plots

% h_fluxes = plot_PJ_PJg_C_fluxes( pj, pjg );
% figure_2_eps( h_fluxes, fullfile( getenv( 'PLOTS' ), 'PJ_PJg_fluxes.eps' ) );

% h_cumu = plot_cumulative( pj_d, pjg_d, jsav_d );
% figure_2_eps( h_cumu, fullfile( getenv( 'PLOTS' ), 'PJ_PJg_JSav_Cumu_NEE.eps' ) );

h_Re_GPP_ratio = plot_Re_GPP_ratio( pj, pjg  );
figure_2_eps( h_Re_GPP_ratio, ...
              fullfile( getenv( 'PLOTS' ), 'PJ_PJg_RE_GPP_ratio.eps' ) );

% --------------------------------------------------
function h_fig = plot_PJ_PJg_C_fluxes( pj, pjg )
% PLOT_PJ_PJG_C_FLUXES - 
%   


h_fig = figure();

% -----
% NEE plot

pj.NEEg = umolPerSecPerM2_2_gcPerMSq( pj.FC );
pjg.NEEg = umolPerSecPerM2_2_gcPerMSq( pjg.FC );

pj_d = get_daily( pj, 'NEEg' );
pjg_d = get_daily( pjg, 'NEEg' );

ax_NEE = subplot( 3, 1, 1 );
plot_site_fluxes( pj_d, pjg_d, ax_NEE );
ylabel( 'NEE (gC / m^{-2} / d^{-1} )' );
ylim( [ -3, 3 ] );
legend( 'off' );

% -----
% GPP plot
pj.GPPg = umolPerSecPerM2_2_gcPerMSq( pj.GPP );
pjg.GPPg = umolPerSecPerM2_2_gcPerMSq( pjg.GPP );

pj_d = get_daily( pj, 'GPPg' );
pjg_d = get_daily( pjg, 'GPPg' );

ax_GPP = subplot( 3, 1, 2 );
plot_site_fluxes( pj_d, pjg_d, ax_GPP );
ylabel( 'GPP (gC / m^{-2} / d^{-1} )' );
ylim( [ 0, 7 ] );

% -----
% RE plot
pj.REg = umolPerSecPerM2_2_gcPerMSq( pj.RE );
pjg.REg = umolPerSecPerM2_2_gcPerMSq( pjg.RE );

pj_d = get_daily( pj, 'REg' );
pjg_d = get_daily( pjg, 'REg' );

ax_RE = subplot( 3, 1, 3 );
plot_site_fluxes( pj_d, pjg_d, ax_RE );
ylabel( 'RE (gC / m^{-2} / d^{-1} )' );
ylim( [ 0, 7 ] );
xlabel( 'year' );


% --------------------------------------------------
function daily = get_daily( data, fld )
% GET_DAILY - 
%   
[ flux_d, yr ] = daily_flux( data.timestamp, data.( fld ) );

yr = repmat( reshape( yr, 1, [] ), size( flux_d, 1 ), 1 );
doy = repmat( reshape( 1:366, [], 1 ), 1, size( yr, 2 ) );

yr = reshape( yr, [], 1 );
doy = reshape( doy, [], 1 );

tstamp = datenum( yr, 1, 0 ) + doy;
flux_d = reshape( flux_d, [], 1 );

tstamp( ( doy == 366 ) & not( isleapyear( yr ) ) ) = [];
flux_d( ( doy == 366 ) & not( isleapyear( yr ) ) ) = [];

daily = dataset( { [ reshape( tstamp, [], 1 ), ...
                    reshape( flux_d, [], 1 ) ], ...
                   'date', 'flux' } );

% --------------------------------------------------
function plot_site_fluxes( pj, pjg, ax, col )
%   
% PLOT_SITE_FLUXES -s 

grey = [ 190, 190, 190 ] / 255;
dark_grey = [ 100, 100, 100 ] / 255;

hold( ax, 'on' );

h_pj = plot( ax, pj.date, pj.flux, '.' );
set( h_pj, 'MarkerSize', 8, 'MarkerEdgeColor', grey );

h_line = plot( ax, pj.date, running_mean( pj.flux, 7 ), '-' );
set( h_line, 'Color', grey );

h_pjg = plot( ax, pjg.date, pjg.flux, '.' );
set( h_pjg, 'MarkerSize', 8, 'MarkerEdgeColor', 'black' );

h_line = plot( ax, pjg.date, running_mean( pjg.flux, 7 ), '-' );
set( h_line, 'Color', 'black' );

datetick( ax, 'x' );
xlim( ax, [ datenum( 2009, 1, 1 ), datenum( 2012, 6, 11 ) ] );
legend( [ h_pj, h_pjg ], { 'Control', 'Manipulation' }, ...
        'Location', 'NorthWest' );
legend( 'boxoff' );

% vertical lines on 1 Jan each year, and on 1 Sep 2009 to mark the girdling
ref_lines = [ datenum( 2010, 1, 1), datenum( 2011, 1, 1), ...
              datenum( 2012, 1, 1), datenum( 2009, 9, 1 ) ];
for i = 1:numel( ref_lines )
    y_lim = get( ax, 'YLim' );
    h_line = line( repmat( ref_lines( i ), 1, 2 ), y_lim );
    set( h_line, 'LineStyle', '-', 'Color', dark_grey );
end
% put the reference lines underneath the data
chil = get( ax, 'children' );
chil = [ chil( 5:end ); chil( 1:4 ) ];
set( ax, 'Children', chil );

% somehow the box got turned off ?!?
set( ax, 'box', 'on' );


% --------------------------------------------------
function h_fig = plot_cumulative( pj_d, pjg_d, jsav_d )
% PLOT_CUMULATIVE - 
%   

grey = [ 190, 190, 190 ] / 255;

h_fig = figure();

% adjust the aspect ratio so the figure is shorter
set( h_fig, 'Units', 'inches' );
pos = get( h_fig, 'Position' );
pos( 4 ) = pos( 4 ) / 2;
set( h_fig, 'Position', pos );

t_min = datenum( 2009, 3, 15 );
t_girdle = datenum( 2009, 9, 1 );
% -----
% PJ

% adjust PJ to the pre-girdling girdled site
idx0 = min( find( pj_d.date >= t_min ) );
idxg = min( find( pj_d.date >= t_girdle ) );

pj_d.flux = ( pj_d.flux * 1.33735165150817 ) - 0.0706699297513139; 

h_pj = plot( pj_d.date( idx0:end ), ...
             cumsum( pj_d.flux( idx0:end ) ) );
set( h_pj, 'LineStyle', '--', 'Color', 'black', 'LineWidth', 2 );
hold on;

% -----
% PJ girdle
idx0 = min( find( pjg_d.date >= t_min ) );
h_pjg = plot( pj_d.date( idx0 : end ), ...
              cumsum( pjg_d.flux( idx0 : end ) ) );
set( h_pjg, 'LineStyle', '-', 'Color', grey , 'LineWidth', 2 );

% -----
% JSav
idx_pjg = min( find( jsav_d.date >= datenum( 2009, 9, 1 ) ) );
pjg_adjustment = nansum( pjg_d.flux( idx0:idx_pjg ) );

idx0 = min( find( jsav_d.date >= datenum( 2009, 9, 1 ) ) );
h_jsav = plot( jsav_d.date( idx0 : end ), ...
               cumsum( jsav_d.flux( idx0 : end ) ) + pjg_adjustment );
set( h_jsav, 'LineStyle', '-', 'Color', 'black' , 'LineWidth', 2 );

% -----
% setup labels, legend, other appearance things
legend( [ h_pj, h_pjg, h_jsav ], ...
        { '  control', '  manipulation', '  juniper savanna' }, ...
        'Location', 'Best' );

datetick( gca, 'x' );
xlim( [ datenum( 2009, 3, 15 ), datenum( 2013, 12, 31 ) ] );

% reference line at 1 Sep 2009 (girdling)
y_lim = get( gca, 'YLim' );
h_line = line( repmat( datenum( 2009, 9, 1 ), 1, 2 ), y_lim );
set( h_line, 'LineStyle', ':', ...
             'Color', 'black', ...
             'LineWidth', 2.0 );

ylabel( 'cumulative NEE (gC / m^{-2})' );
xlabel( 'date' );

% --------------------------------------------------

function h_fig = plot_Re_GPP_ratio( pj, pjg  )
% PLOT_RE_GPP_RATIO - 
%   

% -----
% prepare the data

pj.REg = umolPerSecPerM2_2_gcPerMSq( pj.RE );
pj.GPPg = umolPerSecPerM2_2_gcPerMSq( pj.GPP );

pjg.REg = umolPerSecPerM2_2_gcPerMSq( pjg.RE );
pjg.GPPg = umolPerSecPerM2_2_gcPerMSq( pjg.GPP );

pj_REd = get_daily( pj, 'REg' );
pj_GPPd = get_daily( pj, 'GPPg' );

pjg_REd = get_daily( pjg, 'REg' );
pjg_GPPd = get_daily( pjg, 'GPPg' );

% -----
% plot the data

pal = cbrewer( 'qual', 'Dark2', 3 );

h_fig = figure( 'Units', 'Normalized' );
pos = get( h_fig, 'Position' );
pos( 4 ) = pos( 4 ) / 2;
set( h_fig, 'Position', pos );

% ax2 = subplot( 'Position', [ 0.65, 0.1, 0.2, 0.8 ] );
% ax1 = subplot( 'Position', [ 0.1, 0.1, 0.6, 0.8 ] );
ax1 = axes();

grey = [ 120, 120, 120 ] / 255;

ratio = pj_REd.flux ./ pj_GPPd.flux;
ratio( ratio > 10 ) = NaN;

h_pj = plot( pj_REd.date, ratio, ...
             'Marker', '.', ...
             'LineStyle', 'None', ...
             'MarkerEdgeColor', 'blue', ...
             'MarkerSize', 10 );
hold( ax1, 'on' );

h_line = plot( ax1, pj_REd.date, running_mean( ratio, 7 ), '-' );
set( h_line, 'Color', 'blue' );

ratio = pjg_REd.flux ./ pjg_GPPd.flux;
ratio( ratio > 10 ) = NaN;
h_pjg = plot( pjg_REd.date, ratio, '.', ...
              'MarkerEdgeColor', 'red', 'MarkerSize', 10 );

h_line = plot( ax1, pjg_REd.date, running_mean( ratio, 7 ), '-' );
set( h_line, 'Color', 'red' );

datetick( ax1, 'x', 'mmm yyyy' );
ylim( ax1, [ 0, 4.5 ] );
xlim( [ datenum( 2009, 3, 15 ), datenum( 2013, 12, 31 ) ] );

xlabel( 'date' );
ylabel( 'RE / GPP' );

legend( [ h_pj, h_pjg ], ...
        { 'control', 'manipulation' }, ...
        'Location', 'best');

h_line = refline( 0, 1 );

