function [ h_fig, h_ax ] = plot_fingerprint( dtime, data, t_str, varargin )
% PLOT_FINGERPRINT - plot Jena-style fingerprint plot of data
%   
% USAGE
%    [ h_fig, h_ax ] = plot_fingerprint( dtime, data, t_str )
%
% (c) Timothy W. Hilton, UNM, June 2012


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'dtime', @(x) ( isnumeric( x ) & ...
                                  all( x >= 1 ) & ...
                                  all( x <  367 ) ) );
args.addRequired( 'data', @isnumeric );
args.addRequired( 't_str', @ischar );
args.addParamValue( 'cmap', [], @isnumeric );
args.addParamValue( 'h_fig', NaN, @isnumeric );
args.addParamValue( 'h_ax', NaN, @isnumeric );
args.addParamValue( 'center_caxis', false, @logical );

% parse optional inputs
args.parse( dtime, data, t_str, varargin{ : } );

dtime = args.Results.dtime;
data = args.Results.data;
t_str = args.Results.t_str;
fp_cmap = args.Results.cmap;
h_fig = args.Results.h_fig;
h_ax = args.Results.h_ax;

% -----
% define some defaults for cmap, h_fig, h_ax
% -----

% if colormap was not defined as an argument, define a default here
if isempty( fp_cmap )
    pal = colormap( cbrewer( 'seq', 'YlGnBu', 9 ) );
    fp_cmap = [ interp1( 1:9, pal, linspace( 1, 9, 100 ) ) ];
end

% if figure or axes were not specified as arguments, create them now
if isnan( h_fig )
    h_fig = figure();
end
if isnan( h_ax )
    h_ax = axes();
end

% -----
% create the fingerprint plot
% -----
data = padarray( data, [ 48 - mod( size( data, 1 ), 48 ), 0 ], NaN, 'post' );

doy = sort( unique( floor( dtime ) ) );
data_rect = reshape( data, 48, [] )';

hours_of_day = (1:48) / 2;

image( hours_of_day, 1:max( doy ), data_rect, ...
       'CDataMapping', 'scaled');
set( h_ax, 'YDir', 'normal', 'XMinorTick', 'On' );
colormap( fp_cmap );
if args.Results.center_caxis
    maxval = nanmax( abs( reshape( data, [], 1 ) ) );
    set( h_ax, 'CLim', [ -1 * maxval, maxval ] );
end
colorbar();
xlabel( 'hour of day' );
ylabel( 'day of year' );
title( t_str );

% make sure the colormap and colorbars for this plot don't change if
% if a subsequent subplot changes the colormap
freezeColors
cbfreeze(colorbar)