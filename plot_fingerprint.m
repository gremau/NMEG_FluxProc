function [ h_fig, h_ax ] = plot_fingerprint( dtime, data, t_str, varargin )
% PLOT_FINGERPRINT - plot Jena-style "fingerprint" plot of data.  
%
% A "fingerprint" plot is a color map with day of year (DOY) on the
% vertical axis, hour of day on the horizontal axis, and a color map of some
% observed quanitity.  These are useful for summarizing annual and daily
% cycles concisely and for quickly spotting datalogger timestamp glitches.
%   
% USAGE
%    [ h_fig, h_ax ] = plot_fingerprint( dtime, data, t_str )
%
% INPUTS
%    dtime: 1xN numeric; fractional day of year (1.0 is 00:00 on 1 Jan; 3.5
%        is 12:00 on 3 Jan, etc.)
%    data: 1xN numeric: the data to be plotted
%    t_str: character string; title for the plot
%    
% PARAMETER-VALUE PAIRS
%    cmap: numeric colormap.  See doc colormap for details of how to specify
%        a colormap.  If unspecified, the default is a 100-color sequence ranging
%        from yellow to blue created by interpolating the colors provided by
%        cbrewer( 'seq', 'YlGnBu', 9 ).
%    clim: 2-element numeric vector: data values outside of [ min(clim),
%        max(clim) ] will be displayed at the the extremes of the colormap.
%        Defaults to the range of values in data.  If provided, center_caxis
%        is ignored.
%    h_fig: figure handle; if provided, the plot is drawn in the specified
%        figure.  If unspecified a new figure is created.
%    h_ax: axis handle; if provided, the plot is drawn in the specified
%        axes.  If unspecified a new axes object is created in h_fig.
%    center_caxis: true|{false}; if true, the color map is forced to span +/-
%       +/- max( abs( data ) ) (with zero, by definition, in the center of
%       the colormap).  If unspecified the colormap spans the range of values
%       in data.  Ignored if clim is specified.
%    fig_visible: {true}|false; if true, the figure is drawn on screen.  If
%       false, the figure is created but kept invisible (useful for batch
%       processing).
%
% OUTPUTS:
%    h_fig: handle to the figure window used for the plot
%    h_ax:  handle to the axes used for the plot
%
% author: Timothy W. Hilton, UNM, June 2012


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'dtime', @(x) ( isnumeric( x ) & ...
                                  all( x >= 1 ) & ...
                                  all( x <=  367 ) ) );
args.addRequired( 'data', @isnumeric );
args.addRequired( 't_str', @ischar );
args.addParameter( 'cmap', [], @isnumeric );
args.addParameter( 'clim', [], @isnumeric );
args.addParameter( 'h_fig', [], @isobject );
args.addParameter( 'h_ax', [], @isobject );
args.addParameter( 'center_caxis', false, @islogical );
args.addParameter( 'fig_visible', true, @islogical );

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
if isempty( h_fig )
    h_fig = figure( 'Visible', fig_visible );
    %figure( h_fig );
end
if isempty( h_ax )
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
% Data will be plotted for an entire year
% Note that data timestamps denote end of 30min averaging period,
% so first meas of year is at 30min, last is at midnight
t_min = datenum( 2004, 1, 1, 0, 30, 0 );
t_max = datenum( 2005, 1, 1 );

tstamp = datenum_2_round30min( tstamp, 10, t_min );
temp_data = array2table( [ tstamp, data ], ...
    'VariableNames', {'timestamp', 'data'});
% temp_data now contains original data. Data missing from temp data
% (between t_min and t_max) will be filled with NaN
temp_data = table_fill_timestamps( temp_data, 'timestamp', ...
                                     't_min', t_min, 't_max', t_max );
                                 
% Make the filled timestamp back into fractional day of year
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
% if freezeColors_exists
%     freezeColors;
%     cbfreeze(colorbar);
% end