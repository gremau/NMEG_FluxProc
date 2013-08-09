function hf = plot_CZO_figure( sitecode, years, varargin )
% PLOT_CZO_FIGURE - produces a four-panel plot showing monthly integrated NEE
% bar plot (top panel), monthly integrated GPP and RE bar plots (second panel)
% panel), monthly evapotranspiration (ET) and incoming shortwave radiation (Rg)
% (third panel), and monthly total precipitation and mean air temperature
% (bottom panel).  The horizontal axes are linked to zoom simultaneously.
%
% NOTES
% For mixed conifer site, precip is replaced with the precip from the Redondo
% met station as per 30 July 2012 conversation with Marcy.
%
% USAGE
%    hf = plot_CZO_figure( sitecode, years );
%    hf = plot_CZO_figure( sitecode, years, ylims );
%    hf = plot_CZO_figure( sitecode, years, ..., binary_data );
%
% INPUTS
%    sitecode: integer or UNM_sites object; which site to plot
%    years: numeric vector; which years to plot
%
% PARAMETER-VALUE PAIRS
%    ylims: 2 by 6 numeric vector.  Contains vertical-axis limits for the NEE
%        plot (first row), GPP/RE plot (second row), ET plot( third row ), Rg
%        plot( fourth row), pcp plot (fifth row) and air T plot (sixth row).
%        First column contains lower axis limit, second column contains upper
%        axis limit.  If unspecified vertical axes are sized to the range of data
%        in the plot.
%    binary_data: if true, seeks to load ameriflux files from
%        $BINARYDATA/SITE_with_gaps.mat, where $BINARYDATA is an operating system
%        environment variable.  If false (the default) the annual with_gaps
%        Ameriflux files are parsed to obtain the data.
%
% OUTPUTS
%    hf: handle to the figure window containing the plot.
%
% author: Timothy W. Hilton, UNM, July 2012

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'years', ...
               @(x) ( all( x >= 2006 ) & ...
                      all( x <= this_year ) ) );
args.addParamValue( 'ylims', NaN, @isnumeric );                    
args.addParamValue( 'binary_data', false, @islogical );

% parse optional inputs
args.parse( sitecode, years, varargin{ : } );

% if ylims specified, issue error if it is not a 6 by 2 numeric array.
if not( all( isnan( args.Results.ylims ) ) )
    validateattributes( args.Results.ylims, {'numeric'}, {'size',[4,6,2]} );
end

% -----

% load ameriflux data for requested years
aflx_data = assemble_multi_year_ameriflux( args.Results.sitecode, ...
                                           args.Results.years, ...
                                           'binary_data', args.Results.binary_data );

if args.Results.sitecode == UNM_sites.PPine
    idx = ( aflx_data.YEAR == 2009 ) & ...
          ( aflx_data.DTIME > 149 ) & ...
          ( aflx_data.DTIME < 195 );
    aflx_data.RE( idx ) = aflx_data.RE( idx ) * 0.5;
    aflx_data.FC( idx ) = aflx_data.RE( idx ) - aflx_data.GPP( idx );
end

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

if args.Results.sitecode == UNM_sites.MCon
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

hf = figure( 'Visible', 'on' );

% set horizontal axis limit to time frame requested +- 30 days
x_limits = [ datenum( agg.year( 1 ), agg.month( 1 ), 1 ) - 30, ...
             datenum( agg.year( end ), agg.month( end ), 1 ) + 30 ];

tick_years = reshape( repmat( unique( agg.year )', 2, 1 ), [], 1 );
tick_months = repmat( [ 1, 7 ]', numel( unique( args.Results.years ) ), 1 );
x_ticks = datenum( tick_years, tick_months, 1 );
%x_limits = [ min( x_ticks ) - 30, max( x_ticks ) + 30 ];

med_blue = [ 0, 0, 205 ] / 255;

%--
% NEE 
ax1 = subplot( 4, 1, 1 );
h_NEE = bar( agg.timestamp, agg.NEE );
set( ax1, 'XLim', x_limits, ...
          'XTick', x_ticks, ...
          'XTickLabel', [] );
if not( isnan( args.Results.ylims ) )
    set( ax1, 'YLim', args.Results.ylims( 1, : ) );
end
ylabel( 'NEE [ gC m^{-2} ]' );
info = parse_UNM_site_table();
title( info.SITE_NAME( args.Results.sitecode ) );
%ylim( [ -150, 250 ] );

%--
% RE and GPP
ax2 = subplot( 4, 1, 2 );
h_GPP = bar( agg.timestamp, agg.GPP, 'FaceColor', med_blue );
hold( ax2, 'on' );
h_RE = bar( agg.timestamp, agg.RE * -1.0 );
%ylim( [ -400, 250 ] );
set( ax2, 'XLim', x_limits, ...
          'XTick', x_ticks, ...
          'XTickLabel', [] );
if not( isnan( args.Results.ylims ) )
    set( ax2, 'YLim', args.Results.ylims( 2, : ) );
end
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
           'YColor', get( h_ET, 'FaceColor' ) );

if not( isnan( args.Results.ylims ) )
    set( ax3L, 'YLim', args.Results.ylims( 3, : ) );
end

ax3R = axes( 'Position', get( ax3L, 'Position' ) );
plot( double( agg.timestamp ), double( agg.Rg ), '-ok', ...
      'LineWidth', 3 );
set(ax3R, 'YAxisLocation', 'right', ...
          'Color', 'none', ...
          'XLim', get(ax3L, 'XLim'), ...
          'Layer', 'top', ...
          'XAxisLocation', 'top', ...
          'XTick', x_ticks, ...
          'XTickLabel', [] );

if not( isnan( args.Results.ylims ) )
    set( ax3R, 'YLim', args.Results.ylims( 4, : ) );
end

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
           'YColor', get( h_ET, 'FaceColor' ), ...
           'XTickLabel', datestr( x_ticks, 'mmm yy' ) );
if not( isnan( args.Results.ylims ) )
    set( ax4L, 'YLim', args.Results.ylims( 5, : ) );
end

ax4R = axes('Position', get( ax4L, 'Position' ) );
plot( double( agg.timestamp ), double( agg.TA ), '-ok', ...
      'LineWidth', 3 );
set(ax4R, 'YAxisLocation', 'right', ...
          'Color', 'none', ...
          'XLim', get(ax4L, 'XLim'), ...
          'XTick', x_ticks, ...
          'Layer', 'top', ...
          'XAxisLocation', 'top', ...
          'XTickLabel', [] );
if not( isnan( args.Results.ylims ) )
    set( ax4R, 'YLim', args.Results.ylims( 6, : ) );
end

ylabel( 'Air temp [ ^{\circ}C ]' );

set( ax4L, 'box', 'off' );
set( ax4R, 'box', 'off' );

linkaxes( [ ax1, ax2, ax3L, ax3R, ax4L, ax4R ], 'x' );

% set figure dimensions to US letter paper, landscape orientation
set( hf, 'Units', 'Inches', ...
         'Position', [ 0, 0, 11, 8.5 ] );