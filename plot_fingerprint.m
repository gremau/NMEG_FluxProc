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
args.addParamValue( 'clim', [], @isnumeric );
args.addParamValue( 'h_fig', NaN, @isnumeric );
args.addParamValue( 'h_ax', NaN, @isnumeric );
args.addParamValue( 'center_caxis', false, @islogical );
args.addParamValue( 'fig_visible', true, @islogical );

% parse optional inputs
args.parse( dtime, data, t_str, varargin{ : } );

dtime = args.Results.dtime;
data = args.Results.data;
t_str = args.Results.t_str;
fp_cmap = args.Results.cmap;
fp_clim = args.Results.clim;
h_fig = args.Results.h_fig;
h_ax = args.Results.h_ax;
% -----
% define some defaults for cmap, h_fig, h_ax
% -----

% should figure be visible?
if args.Results.fig_visible
    fig_visible = 'on';
else
    fig_visible = 'off';
end

% if figure or axes were not specified as arguments, create them now
if isnan( h_fig )
    h_fig = figure( 'Visible', fig_visible );
    %figure( h_fig );
end
if isnan( h_ax )
    h_ax = axes();
end

% if colormap was not defined as an argument, define a default here
if isempty( fp_cmap )
    pal = colormap( cbrewer( 'seq', 'YlGnBu', 9 ) );
    fp_cmap = [ interp1( 1:9, pal, linspace( 1, 9, 100 ) ) ];
end

% -----
% create the fingerprint plot
% -----
tstamp = datenum( 2004, 1, 0 ) + dtime;
t_min = datenum( 2004, 1, 1 );
t_max = datenum( 2004, 12, 31, 23, 59, 59 );
tstamp = datenum_2_round30min( tstamp, 10, t_min );
temp_data = dataset( { [ tstamp, data ], 'timestamp', 'data' } );
temp_data = dataset_fill_timestamps( temp_data, 'timestamp', ...
                                     't_min', t_min, 't_max', t_max );

dtime = temp_data.timestamp - datenum( 2004, 1, 0 );
data = temp_data.data;

% pad data so number of rows is a multiple of 48 (that is, if there is an
% imcomplete day at the end, pad to a complete day.)
padded_nrow = ceil( size( data, 1 ) / 48.0 ) * 48.0;
data( end:padded_nrow, : ) = NaN;

data_rect = reshape( data, 48, [] )';

hours_of_day = (1:48) / 2;

image( hours_of_day, 1:366 , data_rect, ...
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

if not( isempty( fp_clim ) )
    set( h_ax, 'CLim', fp_clim );
end

% make sure the colormap and colorbars for this plot don't change if
% if a subsequent subplot changes the colormap
freezeColors_exists = not( isempty( which( 'freezeColors' ) ) );
if freezeColors_exists
    freezeColors;
    cbfreeze(colorbar);
end