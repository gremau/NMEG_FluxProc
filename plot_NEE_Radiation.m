function fh = plot_NEE_Radiation( ds, sitecode, year )
% PLOT_NEE_RADIATION - 
%   

if ~isa( sitecode, 'UNM_sites' )
    sitecode = UNM_sites( sitecode );
end

sd = parse_UNM_site_table();

pal = cbrewer( 'qual', 'Dark2', 5 );

fh = figure( 'Name', 'Rg, PAR, Solar Angle, NEE' );
% axL1 = axes();
% axR1 = axes( 'Position', get(axL1,'Position'),...
%              'XAxisLocation', 'bottom', ...
%              'YAxisLocation', 'right', ...
%              'Color', 'none', ...
%              'XColor', 'k', ...
%              'YColor', 'k');

plotL = @( x, y ) plot( x, y, '-', 'Color', 'black', 'LineWidth', 2 );
plotR = @( x, y ) plot( x, y, '-', 'Color', pal( 1, : ), 'LineWidth', 2 );

[ ax, h_FC, h_PAR ] = plotyy( ds.DTIME, ds.FC * -1.0, ...
                             ds.DTIME, ds.PAR, ...
                             plotL, plotR );
ax_FC = ax( 1 );
ax_rad = ax( 2 );

% label axes
ylabel( ax( 1 ), 'NEE \times -1 [\mu mol m^{-2} s^{-1}]' );
ylabel( ax( 2 ), 'Radiation [ \mu mol m^{-2} s^{-1} ]' );
xlabel( 'day of year' );
title( sprintf( '%s %d', char( sitecode ), year ) );
set( ax, 'ColorOrder', pal );

% make zero on both vertical axes is vertically aligned
set( ax_rad, 'Ylim', max( get( ax_rad, 'Ylim' ) ) * [ -1, 1 ] );
set( ax_FC, 'Ylim', max( get( ax_FC, 'Ylim' ) ) * [ -1, 1 ] );

% add Rge to the plot
hold( ax_rad, 'on' );
hold( ax_FC, 'on' );
h_Rg = plot( ax_rad, ...
             ds.DTIME, ds.Rg, '-', ...
             'Color', pal( 2, : ), ...
             'LineWidth', 2 );

%reference line at 0
h_ref = refline( 0, 0 );
set( h_ref, 'Color', 'black', 'LineStyle', ':' );

legend( [ h_FC, h_PAR, h_Rg, h_ref ], '-NEE', 'PAR', 'Rg', '0', ...
        'Location', 'best' );


