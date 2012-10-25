<<<<<<< local
function hf = plot_CZO_Valles_figure( sitecode, years, ylims )
=======
function hf = plot_CZO_Valles_figure( sitecode, years, binary_data )
>>>>>>> other
% PLOT_CZO_VALLES_FIGURE - 
%
% USAGE
%    hf = plot_CZO_Valles_figure( sitecode, years, binary_data )
%
% (c) Timothy W. Hilton, UNM, July 2012

% load ameriflux data for requested years
aflx_data = assemble_multi_year_ameriflux( sitecode, years, ...
<<<<<<< local
                                           'binary_data', false);
=======
                                           'binary_data', binary_data );

if sitecode == UNM_sites.PPine
    idx = ( aflx_data.YEAR == 2009 ) & ...
          ( aflx_data.DTIME > 149 ) & ...
          ( aflx_data.DTIME < 195 );
    aflx_data.RE( idx ) = aflx_data.RE( idx ) * 0.5;
    aflx_data.FC( idx ) = aflx_data.RE( idx ) - aflx_data.GPP( idx );
end
>>>>>>> other

%convert C fluxes to gC / m2
aflx_data.FCgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.FC );
aflx_data.GPPgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.GPP ); 
aflx_data.REgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.RE );
% convert water flux (mg/m^2/s) to mm / 30 minutes
aflx_data.ETmm = aflx_data.FH2O * 30 * 60 * 1e-6;

% calculate matlab datenum timestamps
tstamp = datenum( aflx_data.YEAR, 1, 0 ) + aflx_data.DTIME;
[ ~, month, ~, ~, ~, ~ ] = datevec( tstamp );

% calculate monthly sums for pcp and carbon fluxes
[ year_mon, agg_sums, idx ] = consolidator( ...
    double( [ aflx_data.YEAR, month ] ), ...
    double( aflx_data( :, { 'PRECIP', 'FCgc', ...
                    'GPPgc', 'REgc', 'ETmm' } ) ), ...
    @nansum );

if sitecode == UNM_sites.MCon
    % sub in Redondo pcp for Mcon pcp as per conversation with Marcy 30 Jul 2012
    valles = UNM_parse_valles_met_data( 2011 );
    redondo = valles( valles.sta == 14, : );
    redondo.timestamp = datenum( redondo.year, 1, 0 ) +  redondo.day;
    [ ~, red_month, ~, ~, ~, ~ ] = datevec( redondo.timestamp );
    [ ~, monthly_pcp_11, ~ ] = consolidator( red_month, ...
                                             redondo.ppt, ...
                                             @nansum );
    agg_sums( end-11:end, 1 ) = monthly_pcp_11;
end
    

% calculate monthly means for air T
[ year_mon, T_mean, idx ] = consolidator( ...
    double( [ aflx_data.YEAR, month ] ), ...
    double( aflx_data.TA ), ...
    @nanmean );

[ year_mon, Rg_max, idx ] = consolidator( ...
    double( [ aflx_data.YEAR, month ] ), ...
    double( aflx_data.Rg ), ...
    @nanmean );

% combine aggregated data to dataset object
agg = dataset( { [ year_mon, agg_sums, T_mean, Rg_max ], ...
                 'year', 'month', 'PCP', 'NEE', 'GPP', ...
                 'RE', 'ET', 'TA', 'Rg' } );
agg.timestamp = datenum( agg.year, agg.month, 1 );

%================
% plot the figure
%================

hf = figure( 'Units', 'Inches' );
% set figure dimensions to US letter paper, landscape orientation
% pos = get( hf, 'Position' );
% pos( 3:4 ) = [ 11, 8.5 ];
set( hf, 'Position', [ 0, 0, 11, 8.5 ] );
ylim( ylims( 1, : ) );

% set horizontal axis limit to time frame requested +- 30 days
x_limits = [ datenum( agg.year( 1 ), agg.month( 1 ), 1 ) - 30, ...
             datenum( agg.year( end ), agg.month( end ), 1 ) + 30 ];

tick_years = reshape( repmat( unique( agg.year )', 4, 1 ), [], 1 );
tick_months = repmat( [ 1, 4, 7, 10 ]', numel( unique( years ) ), 1 );
x_ticks = datenum( tick_years, tick_months, 1 );
%x_limits = [ min( x_ticks ) - 30, max( x_ticks ) + 30 ];

med_blue = [ 0, 0, 205 ] / 255;

%--
% NEE 
ax1 = subplot( 4, 1, 1 );
h_NEE = bar( agg.timestamp, agg.NEE );
set( ax1, 'XLim', x_limits, ...
          'XTick', x_ticks, ...
          'XTickLabel', [], ...
          'YLim', ylims( 1, : ) );
ylabel( 'NEE [ gC m^{-2} ]' );
info = parse_UNM_site_table();
title( info.SITE_NAME( sitecode ) );
ylim( [ -150, 250 ] );

%--
% RE and GPP
ax2 = subplot( 4, 1, 2 );
h_GPP = bar( agg.timestamp, agg.GPP, 'FaceColor', med_blue );
hold( ax2, 'on' );
h_RE = bar( agg.timestamp, agg.RE * -1.0 );
ylim( [ -400, 250 ] );
set( ax2, 'XLim', x_limits, ...
          'XTick', x_ticks, ...
          'XTickLabel', [], ...
          'YLim', ylims( 2, : ) );
ylabel( 'GPP & RE [ gC m^{-2} ]' );
legend( [ h_GPP, h_RE ], 'GPP', 'RE', 'Location', 'best' );

pal = cbrewer( 'div', 'PRGn', 9 );
set( h_GPP, 'FaceColor', pal( end, : ) );  %plot GPP in green
set( h_RE, 'FaceColor', pal( 1, : ) );  %plot RE in purple

%--
% ET & Rg
% normalized axis position hardcoded in -- for some reason using subplot here
% seems to move the other axes around and mess up the two plots with two
% vertical axes
ax3L = axes( 'Units', 'Normalized', ...
             'Position', [0.1300 0.3291 0.7750 0.1577 ] );
h_ET = bar( double( agg.timestamp ), double( agg.ET ), ...
            'FaceColor', med_blue );
ylabel('ET [ mm ]')
set( ax3L, 'XLim', x_limits, ...
           'XTick', x_ticks, ...
           'XTickLabel', [], ...
<<<<<<< local
           'YLim', ylims( 3, : ), ...
=======
           'YLim', [ 0, 110 ], ...
>>>>>>> other
           'YColor', get( h_ET, 'FaceColor' ) );

ax3R = axes( 'Position', get( ax3L, 'Position' ) );
plot( double( agg.timestamp ), double( agg.Rg ), '-ok', ...
      'LineWidth', 3 );
set(ax3R, 'YAxisLocation', 'right', ...
          'Color', 'none', ...
          'XLim', get(ax3L, 'XLim'), ...
          'Layer', 'top', ...
          'XAxisLocation', 'top', ...
          'XTick', x_ticks, ...
          'XTickLabel', [], ...
          'YLim', ylims( 4, : ) );
ylabel( 'Rg [ W m^{-2} ]' );

set( ax3L, 'box', 'off' );
set( ax3R, 'box', 'off' );

%--
% PCP and Air T

ax4L = axes( 'Units', 'Normalized', ...
             'Position', [ 0.1300 0.1100 0.7750 0.1577 ] );
h_pcp = bar( agg.timestamp, agg.PCP, ...
        'FaceColor', med_blue );
ylabel('precipitation [ mm ]')
set( ax4L, 'XLim', x_limits, ...
           'XTick', x_ticks, ...
<<<<<<< local
           'YLim', ylims( 5, : ), ...
=======
           'YLim', [ 0, 110 ], ...
>>>>>>> other
           'YColor', get( h_ET, 'FaceColor' ), ...
           'XTickLabel', datestr( x_ticks, 'mmm yy' ) );

ax4R = axes('Position', get( ax4L, 'Position' ) );
plot( double( agg.timestamp ), double( agg.TA ), '-ok', ...
      'LineWidth', 3 );
set(ax4R, 'YAxisLocation', 'right', ...
          'Color', 'none', ...
          'XLim', get(ax4L, 'XLim'), ...
          'XTick', x_ticks, ...
          'Layer', 'top', ...
          'XAxisLocation', 'top', ...
          'XTickLabel', [], ...
          'YLim', ylims( 6, : ) );
ylabel( 'Air temp [ ^{\circ}C ]' );

set( ax4L, 'box', 'off' );
set( ax4R, 'box', 'off' );

linkaxes( [ ax1, ax2, ax3L, ax3R, ax4L, ax4R ], 'x' );