function [ h_fig, h_ax ] = plot_fingerprint( dtime, data, t_str )
% PLOT_FINGERPRINT - plot Jena-style fingerprint plot of data
%   

doy = sort( unique( floor( dtime ) ) );
data_rect = reshape( data, 48, [] )';

h_fig = figure();
h_ax = axes();

hours_of_day = (1:48) / 2;

image( hours_of_day, 1:max( doy ), data_rect, ...
       'CDataMapping', 'scaled');
set( h_ax, 'YDir', 'normal' );
pal = colormap( cbrewer( 'seq', 'YlOrRd', 9 ) );
new_pal = [ pal( 1:6, : ); interp1( 0:3, pal( 6:9, : ), 0:1/10:3 ) ];
%new_pal = [ pal( 1:8, : ); interp1( 0:1, pal( 8:9, : ), 0:1/100:1 ) ];

colormap( new_pal );
%set( h_ax, 'CLim', [ 0, 200 ] );
colorbar();
xlabel( 'hour of day' );
ylabel( 'day of year' );
title( t_str );