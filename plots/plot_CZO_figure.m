function hf = plot_CZO_figure( sitecode, years, varargin )
% PLOT_CZO_FIGURE - produces a four-panel summary plot of monthly data for a
% specifed site.
%
% Produces a four-panel plot showing monthly integrated NEE
% bar plot (top panel), monthly integrated GPP and RE bar plots (second panel)
% panel), monthly evapotranspiration (ET) and incoming shortwave radiation (Rg)
% (third panel), and monthly total precipitation and mean air temperature
% (bottom panel).  The horizontal axes are linked to zoom simultaneously.
%
% For mixed conifer site, precipitation for 2011 to present is replaced with the
% Redondo met station precip record, as per 30 Jul 2012 consersation with Marcy.
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
%    xlims: 2-element vector of serial date numbers; horizontal axis limits
%    binary_data: if true, seeks to load ameriflux files from
%        $BINARYDATA/SITE_gapfilled.mat, where $BINARYDATA is an operating system
%        environment variable.  If false (the default) the annual gapfilled
%        Ameriflux files are parsed to obtain the data.
%
% OUTPUTS
%    hf: handle to the figure window containing the plot.
%
% SEE ALSO
%    datenum
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
args.addParamValue( 'xlims', NaN, @isnumeric );
args.addParamValue( 'binary_data', false, @islogical );

% parse optional inputs
args.parse( sitecode, years, varargin{ : } );

% if ylims specified, issue error if it is not a 6 by 2 numeric array.
if not( all( isnan( args.Results.ylims ) ) )
%RJL    validateattributes( args.Results.ylims, {'numeric'}, {'size',[4,6,2]} );
    validateattributes( args.Results.ylims, {'numeric'}, {'size',[6,2]} );
end

% -----

% load ameriflux data for requested years
aflx_data = assemble_multiyear_ameriflux( args.Results.sitecode, ...
                                           args.Results.years, ...
                                           'suffix', 'gapfilled');%, ...
                                           %'binary_data', args.Results.binary_data );

if args.Results.sitecode == UNM_sites.PPine
    idx = ( aflx_data.YEAR == 2009 ) & ...
          ( aflx_data.DTIME > 149 ) & ...
          ( aflx_data.DTIME < 195 );
    aflx_data.RECO( idx ) = aflx_data.RECO( idx ) * 0.5;
    aflx_data.FC_F( idx ) = aflx_data.RECO( idx ) - aflx_data.GPP( idx );
end

%convert C fluxes to gC / m2
aflx_data.FCgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.FC_F );
aflx_data.GPPgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.GPP ); 
aflx_data.REgc = umolPerSecPerM2_2_gcPerMSq( aflx_data.RECO );
% convert latent heat flux to mm / 30 minutes
lmbda = ( 2.501 - 0.00236 .* aflx_data.TA_F ) .* 1000;
et_mms = ( 1 ./ ( lmbda .* 1000 )) .* aflx_data.LE_F;
aflx_data.ETmm = et_mms * 1800;
% convert water flux (mg/m^2/s) to mm / 30 minutes
%aflx_data.ETmm = aflx_data.FH2O * 30 * 60 * 1e-6;

% calculate matlab datenum timestamps
tstamp = datenum( aflx_data.YEAR, 1, 0 ) + aflx_data.DTIME;
[ ~, month, ~, ~, ~, ~ ] = datevec( tstamp );

% calculate monthly sums for pcp and carbon fluxes
[ year_mon, agg_sums, idx ] = consolidator( ...
    [ aflx_data.YEAR, month ], ...
    table2array(aflx_data( :, { 'P_F', 'FCgc', ...
                    'GPPgc', 'REgc', 'ETmm' } ) ), ...
    @nansum );

% FIXME - should be able to get rid of this after precip gapfilling is
% complete - make sure there are not gaps in precip in 2013-2014
% if args.Results.sitecode == UNM_sites.MCon
%     % sub in Redondo pcp for Mcon pcp as per conversation with Marcy 30 Jul 2012
%     redondo_pcp = get_redondo_monthly_pcp_2011_to_present();
%     redondo_pcp = redondo_pcp( 1:end-1, : ); % Includes Jan 2015 - remove
%     replaceIdx = year_mon( :, 1 ) > 2010;
%     if sum( replaceIdx ) == length( redondo_pcp )
%         agg_sums( replaceIdx, 1 ) = redondo_pcp( 1:end, 3 );
%     else
%         error('redondo and MCon precip do not match in time');
%     end
% %     for i = 1:size( redondo_pcp, 1 )
% %         idx = year_mon( :, 1) == redondo_pcp( i, 1 ) &&  
% %         %agg_sums( idx, 1 ) = redondo_pcp.pcp( i, 3);
% %     end
% end

% calculate monthly means for air T
[ year_mon, T_mean, idx ] = consolidator( ...
    double( [ aflx_data.YEAR, month ] ), ...
    double( aflx_data.TA_F ), ...
    @nanmean );

[ year_mon, Rg_max, idx ] = consolidator( ...
    double( [ aflx_data.YEAR, month ] ), ...
    double( aflx_data.SW_IN_F ), ...
    @nanmean );

% combine aggregated data to dataset object
agg = array2table( [ year_mon, agg_sums, T_mean, Rg_max ], 'VariableNames',...
                 {'year', 'month', 'PCP', 'NEE', 'GPP', ...
                 'RE', 'ET', 'TA', 'Rg' } );
            
agg.timestamp = datenum( agg.year, agg.month, 1 );

% Remove some time periods because they are gapfilled/not needed (for latest
% figure sent to Jon Chorover)
test = agg.timestamp < datenum( 2009, 10, 1 );
agg( test, : ) = [];
% Remove fire
test = agg.timestamp > datenum( 2013, 4, 1 ) & agg.timestamp < datenum( 2013, 12, 1 );
agg{ test, 3:end } = NaN;
% Remove end of 2015
test = agg.timestamp > datenum( 2015, 9, 1 );
agg{ test, 3:end } = NaN;

%================
% plot the figure
%================

hf = figure( 'Visible', 'on', 'PaperPositionMode', 'auto', ...
             'Name', sprintf( '%s CZO plot', char( args.Results.sitecode ) ) );
if  all( isnan( args.Results.xlims ) )
    % set horizontal axis limit to time frame requested +- 30 days
    x_limits = [ datenum( agg.year( 1 ), agg.month( 1 ), 1 ) - 30, ...
                 datenum( agg.year( end ), agg.month( end ), 1 ) + 30 ];
else
    x_limits = args.Results.xlims;
end

tick_years = reshape( repmat( unique( agg.year )', 2, 1 ), [], 1 );
tick_months = repmat( [ 1, 7 ]', numel( unique( agg.year ) ), 1 );
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
           'FontSize', 13 );
if not( all( isnan( args.Results.ylims ) ) )
    set( ax1, 'YLim', args.Results.ylims( 1, : ) );
end
ylabel( {'NEE','[ gC m^{-2} ]'},  'FontSize', 18  );
info = parse_UNM_site_table();
title( info.SITE_NAME( args.Results.sitecode ), 'FontSize', 18 );
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
          'XTickLabel', [], ...
           'FontSize', 13 );
if not( isnan( args.Results.ylims ) )
    set( ax2, 'YLim', args.Results.ylims( 2, : ) );
end
ylabel( {'GPP & RE','[ gC m^{-2} ]'}, 'FontSize', 18 );
legend( [ h_GPP, h_RE ], 'GPP', 'RE', 'Location', 'NorthEast' );

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
ylabel({'ET','[ mm ]'},  'FontSize', 18 )
set( ax3L, 'XLim', x_limits, ...
           'XTick', x_ticks, ...
           'XTickLabel', [], ...           
           'YColor', get( h_ET, 'FaceColor' ), ...
           'FontSize', 13 );

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
          'XTickLabel', [], ...
           'FontSize', 13 );

if not( isnan( args.Results.ylims ) )
    set( ax3R, 'YLim', args.Results.ylims( 4, : ) );
end

ylabel( {'Rg','[ W m^{-2} ]'},  'FontSize', 18  );

set( ax3L, 'box', 'off' );
set( ax3R, 'box', 'off' );

%--
% PCP and Air T

ax4L = axes( 'Units', 'Normalized', ...
             'Position', [ 0.1300 0.1100 0.7750 0.1577 ] );
h_pcp = bar( agg.timestamp, agg.PCP, ...
        'FaceColor', med_blue );
ylabel({'Precip','[ mm ]'},  'FontSize', 18 )
set( ax4L, 'XLim', x_limits, ...
           'XTick', x_ticks, ...           
           'YColor', get( h_ET, 'FaceColor' ), ...
           'XTickLabel', datestr( x_ticks, 'mmm yy' ), ...
           'FontSize', 16 );
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
          'XTickLabel', [], ...
          'FontSize', 13 );
if not( isnan( args.Results.ylims ) )
    set( ax4R, 'YLim', args.Results.ylims( 6, : ) );
end

ylabel( {'Air temp','[ ^{\circ}C ]'}, 'FontSize', 18  );

set( ax4L, 'box', 'off' );
set( ax4R, 'box', 'off' );

linkaxes( [ ax1, ax2, ax3L, ax3R, ax4L, ax4R ], 'x' );

% set figure dimensions to US letter paper, landscape orientation
set( hf, 'Units', 'Inches', ...
         'Position', [ 0, 0, 11, 8.5 ] );

%============================================================
function [ redondo_monthly_pcp ] = get_redondo_monthly_pcp_2011_to_present()
% GET_REDONDO_MONTHLY_PCP_2011_TO_PRESENT - aggregates precipitation for Redondo
%   met station to monthly totals for 2011 to present
%
% USAGE
%     redondo_monthly_pcp = get_redondo_monthly_pcp_2011_to_present();
%
% INPUTS:
%     no inputs
%
% OUTPUTS:
%     redondo_monthly_pcp: Mx3 dataset array; contains variables year, month,
%         and monthly total precipitation (mm)
%
% SEE ALSO
%     dataset

HOURS_PER_DAY = 24.0;
[ present_year, ~, ~, ~, ~, ~ ] = datevec( now() );
fun = @(yr) { UNM_parse_valles_met_data( 'vcp', yr ) };
valles = arrayfun( fun, 2011:present_year - 1 );
valles = vertcat( valles{ : } );
valles.timestamp = datenum( valles.year, 1, 0 ) +  ...
    valles.day + valles.time / HOURS_PER_DAY;
% Redondo is station 14
redondo = valles( valles.sta == 14, : );
redondo = table2dataset(redondo); % FIXME - rely on tables
redondo = dataset_fill_timestamps( redondo, 'timestamp' );

[ red_year, red_month, ~, ~, ~, ~ ] = datevec( redondo.timestamp );
[ year_month, monthly_pcp, ~ ] = consolidator( [ red_year, red_month ], ...
                                               redondo.ppt, ...
                                               @nansum );
var_names = { 'year', 'month', 'pcp' };
redondo_monthly_pcp = dataset( { [ year_month, monthly_pcp ], ...
                    var_names{ : } } );