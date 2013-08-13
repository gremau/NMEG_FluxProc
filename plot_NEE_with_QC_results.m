function [ h_fig_flux, ax_NEE, ax_flags ] = plot_NEE_with_QC_results( ...
    sitecode, year, decimal_day, fc_raw_massman_wpl, idx_NEE_good,ustarflag, ...
    precipflag, nightnegflag, windflag, maxminflag, lowco2flag,highco2flag, ...
    nanflag, stdflag, n_bins, endbin, startbin, bin_ceil, bin_floor, mean_flux )
% PLOT_NEE_WITH_QC_RESULTS - plot CO2 NEE with QC flags and standard deviation
% windows.
%
% This is a helper function for UNM_RemoveBadData -- it is not intended to be
% called as a stand-alone function.
%
% INPUTS
%     Inputs are defined as variables within UNM_Remove_Bad_Data.M
%
% OUTPUTS
%     h_fig_flux: handle to the figure created
%     ax_NEE: handle to the upper axis (that contains the NEE time series)
%     ax_flags: handle to the upper axis (that contains the various NEE QC
%         flags)
%
% author: Timothy W. Hilton, UNM, May 2012


pal = cbrewer( 'qual', 'Dark2', 5 );

fig_name = sprintf( 'NEE & filters, %s %d', ...
                    get_site_name( sitecode ), year( 1 ) );
h_fig_flux = figure( 'Units', 'Normalized', ...
                     'Position', [ 0.1, 0.2, 0.85, 0.70 ], ...
                     'Name', fig_name, ...
                     'NumberTitle', 'off' );
ax_flags = subplot( 'Position', [ 0.1, 0.05, 0.89, 0.2 ] );
ax_NEE = subplot( 'Position', [ 0.1, 0.30, 0.89, 0.64 ] );
hold on; 
box on;
% --------
% plot NEE in the top panel
% plot all observations as black circles
axes( ax_NEE );
h_all = plot( decimal_day, fc_raw_massman_wpl, 'ok' );
gray90 = [ 232, 232, 232 ] / 255;  %RGB specs for unix color "gray90"
set( h_all, 'MarkerEdgeColor', gray90  );
xlim( [ 0, 366 ] );

% plot the "good" observations (that weren't filtered out) as red dots
% find [CO2] observations that are (1) good or (2) excepted
h_good = plot( decimal_day( idx_NEE_good  ), ...
               fc_raw_massman_wpl( idx_NEE_good ), ...
               'LineStyle', 'none', ...
               'Marker', '.', ...
               'Color', pal( 1, : ) );

% mark points that were filtered for Std deviation and no other reason
idx_std = repmat( false, size( decimal_day ) );
idx_std( stdflag ) = true;
idx_std( unique( [ ustarflag ; precipflag ; nightnegflag ; ...
                   windflag ; maxminflag ; lowco2flag ; ...
                   highco2flag ; nanflag ] ) ) = false;
h_SD_only = plot( decimal_day( idx_std  ), ...
                  fc_raw_massman_wpl( idx_std ), ...
                  'LineStyle', 'none', ...
                  'Marker', 'o', ...
                  'MarkerEdgeColor', 'k', ...
                  'MarkerFaceColor', pal( 3, : ) );

idx_wd = repmat( false, size( decimal_day ) );
idx_wd( windflag ) = true;
idx_wd( unique( [ ustarflag ; precipflag ; nightnegflag ; ...
                  find( stdflag ) ; maxminflag ; lowco2flag ; ...
                  highco2flag ; nanflag ] ) ) = false;
h_WD_only = plot( decimal_day( idx_wd  ), ...
                  fc_raw_massman_wpl( idx_wd ), ...
                  'LineStyle', 'none', ...
                  'Marker', 'o', ...
                  'MarkerEdgeColor', 'k', ...
                  'MarkerFaceColor', pal( 4, : ) );
set( h_WD_only, 'Visible', 'off' );
set( h_all, 'Visible', 'on' );

%plot std dev windows
endbin( end ) = numel( decimal_day );
for i = 1:n_bins
    bin_x = [ decimal_day( startbin( i ) ), decimal_day( endbin( i ) ) ];
    bin_y = repmat( bin_ceil( i ), 1, 2 );
    h_SD = plot( bin_x, bin_y, ...
                 'Color', pal( 2, : ), 'LineStyle', '-', 'LineWidth', 2 );
    bin_y = repmat( bin_floor( i ), 1, 2 );
    h_SD = plot( bin_x, bin_y, ...
                 'Color', pal( 2, : ), 'LineStyle', '-', 'LineWidth', 2 );
    bin_y = [ mean_flux( i ), mean_flux( i ) ];
    h_mean = plot( bin_x, bin_y, ...
                   'Color', pal( 2, : ), 'LineStyle', '--', 'LineWidth', 2 );
           
end

legend( [ h_all, h_good, h_SD, h_SD_only, h_WD_only ], ...
        'all obs', '"good" obs', 'Std. Dev. window', 'SD only', 'WD only' );
xlabel('decimal day'); 
ylabel('CO_2 flux, [ \mu mol m^{-2} s^{-1} ]');
t_str = strrep( sprintf( '%s %d', get_site_name( sitecode ), year( 2 ) ), ...
                '_', '\_' );
title( t_str );
ylim( [ -25, 25 ] );
hold off; 

% -------
% plot reasons NEE was screened in the bottom panel
axes( ax_flags );
hold on
h_ustar = plot( decimal_day( ustarflag ), ...
                repmat( 1, numel( ustarflag), 1 ), '.k' );
h_pcp = plot( decimal_day( precipflag ), ...
                repmat( 2, numel( precipflag), 1 ), '.k' );
h_nightneg = plot( decimal_day( nightnegflag ), ...
                repmat( 3, numel( nightnegflag), 1 ), '.k' );
h_wind = plot( decimal_day( windflag ), ...
                repmat( 4, numel( windflag), 1 ), '.k' );
h_maxs_mins = plot( decimal_day( maxminflag ), ...
                repmat( 5, numel( maxminflag), 1 ), '.k' );
h_lowco2 = plot( decimal_day( lowco2flag ), ...
                repmat( 6, numel( lowco2flag), 1 ), '.k' );
h_highco2 = plot( decimal_day( highco2flag ), ...
                repmat( 7, numel( highco2flag), 1 ), '.k' );
h_nan = plot( decimal_day( nanflag ), ...
                repmat( 8, numel( nanflag), 1 ), '.k' );
h_std = plot( decimal_day( stdflag ), ...
              repmat( 9, numel( find( stdflag ) ), 1 ), '.k' );
set( ax_flags, 'YLim', [0, 10 ], ...
          'YTick', 1:9, ...
          'YTickLabel', ...
          { 'ustar', 'precip', 'night neg', 'wind', ...
            'max min', 'low co2', 'high co2', 'NaN', 'std dev' } );
ylabel( 'reason screened' );
xlabel( 'decimal day' );

linkaxes( [ ax_NEE, ax_flags ], 'x' );  %make axes zoom together horizontally

