function fh =  fluxraw_table_viewer( tbl, this_site, mod_date )
%FLUXRAW_TABLE_VIEWER --  graphical user interface to view TOA5 files
%containing 30-minute datalogger data.  
%
% This is intended for use during card conversion for a quick visual
%inspection to identify problems with instruments or the datalogger.
%Provides a plot of each variable in the TOA5 file, one at a time, and
%"previous" and "next" buttons to move among variables.  Support Matlab's
%zooming and scrolling capabilities.
%       
% USAGE fh = fluxraw_table_viewer( tbl, this_site, mod_date )
%
% INPUTS:
%    tbl: table array; the data to be plotted.
%    this_site: UNM_sites object; which UNM site?
%    mod_date: the modification time of the 30-minute datalogger file (used
%        to identify the TOA5 file)
%
% OUTPUTS:
%    fh: handle to the figure window created
%
% (c) Timothy W. Hilton, UNM, Mar 2012
%  Rewritten by Gregory Maurer, UNM, Mar, 2015
    
%-------------------------
% Initialization tasks
%--------------------------



% determine screensize
    scrsz = get(0,'ScreenSize');
    
    nfields = size( tbl, 2 );

    % create a figure to contain the GUI, use entire screen horizontally,
    % upper half of the screen vertically
    fh = figure( 'Name', sprintf( '%s datalogger record -- %s', ...
                                  char( this_site ), ...
                                  datestr( mod_date, 'dd mmm yyyy HH:MM' ) ), ...
                 'Units', 'normalized', ...
                 'Position', [ 0.1, 0.1, 0.7, 0.5 ], ...  
                 'NumberTitle', 'off', ...
                 'ToolBar', 'figure', ...
                 'MenuBar', 'none', ...
                 'WindowKeyPressFcn', @key_press_cbk );
    set( fh, 'UserData', struct( 'cur_col', 1 ) ); % start with column 1
    
    %--------------------------
    % Construct GUI components
    %--------------------------
    
    %add axes for plots
    axh = axes( 'Parent', fh, ...
                'Units', 'normalized', ...
                'HandleVisibility','callback', ...
                'Position',[ 0.1, 0.15, 0.8, 0.7 ] );
    
    %add a "previous" button
    pbh_prev = uicontrol( fh, ...
                          'Style', 'pushbutton', ...
                          'String','<===', ...
                          'Position', [ 50 10 200 40] );
    set( pbh_prev, 'enable', 'off' );  % start at the first column
    
    %add a "next" button
    pbh_next = uicontrol( fh, ...
                          'Style', 'pushbutton', ...
                          'String','===>', ...
                          'Position', [ 250 10 200 40], ...
                          'CallBack', { @next_but_cbk, nfields, ...
                        axh, fh, tbl, pbh_prev } );

    set( pbh_prev, 'CallBack', { @prev_but_cbk, nfields, axh, fh, tbl, pbh_next} );
    set( pbh_next, 'CallBack', { @next_but_cbk, nfields, axh, fh, tbl, pbh_prev} );
    set( fh, 'WindowKeyPressFcn', { @key_press_cbk, fh, nfields, axh, tbl, ...
                        pbh_prev, pbh_next } );

%--------------------------
%  plot first field
%--------------------------

plot_fluxraw_field( axh, tbl, 1 );
xlabel( axh, 'date' );
datetick( 'x', 'ddmmmyy' );
t_str = tbl.Properties.VariableNames{ 1 };
t_str = strrep( t_str, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
ylabel( axh, sprintf( '%s [%s]', t_str, tbl.Properties.VariableUnits{ 1 } ) );

%--------------------------
%  Callbacks for GUI
%--------------------------

function cur_col = prev_but_cbk( source, eventdata, ...
                                 nfields, axh, fh, tbl, pbh_next )
    %% change the plot to the previous data field
    
    % decrement cur_col
    ud = get( fh, 'UserData' );
    ud.cur_col = max( ud.cur_col - 1, 1 );
    set( fh, 'UserData', ud );
    
    plot_fluxraw_field( axh, tbl, ud.cur_col );
    
    % just backed up, so can't be on last column
    set( pbh_next, 'enable', 'on' );
    
    % disable "prev" button if we're on the first column
    if ud.cur_col == 1
        set( source, 'enable', 'off' );
    else
        set( source, 'enable', 'on' );
    end    
    
function cur_col = next_but_cbk( source, eventdata, ...
                                 nfields, axh, fh, tbl, pbh_prev )
    %% change the plot to the previous data field
    
    % decrement cur_col
    ud = get( fh, 'UserData' );
    ud.cur_col = min( ud.cur_col + 1, nfields );
    set( fh, 'UserData', ud );
    
    % get the new variable names
    this_var = tbl.Properties.VariableNames{ ud.cur_col };
    plot_fluxraw_field( axh, tbl, ud.cur_col );

    % just advanced, so can't be on first column
    set( pbh_prev, 'enable', 'on' );
    
    % disable "next" button if we're on the last column
    if ud.cur_col == nfields
        set( source, 'enable', 'off' );
    else
        set( source, 'enable', 'on' );
    end
    
function zoom_but_cbk( source, eventdata, ...
                       nfields, axh, fh, tbl )
%% change the plot to the previous data field

ud = get( fh, 'UserData' );
cur_ylim = get( axh, 'YLim' );

new_ylim = prctile( double( tbl( :, ud.cur_col ) ), ...
                    [ 0.1, 99.9 ] );
set( axh, 'YLim', new_ylim );

%==================================================

function key_press_cbk( source, eventdata, fh, nfields, axh, tbl, ...
                        pbh_prev, pbh_next  )

switch eventdata.Key
    
  case 'q'
    close( fh );

  case 'leftarrow'
    prev_but_cbk( pbh_prev, eventdata, nfields, axh, fh, tbl, pbh_next );
    
  case 'rightarrow'
    next_but_cbk( pbh_next, eventdata, nfields, axh, fh, tbl, pbh_prev );
    
  case 'z'
    zoom_but_cbk( source, eventdata, nfields, axh, fh, tbl );
    
end

%==================================================

function plot_fluxraw_field( axh, tbl, cur_col)
% PLOT_FLUXRAW_FIELD - plots single field of fluxraw table to specified axes
%   

% get the new variable names
this_var = tbl.Properties.VariableNames{ cur_col };
this_data = tbl.( this_var );
idx_huge = find( abs( this_data ) > 1e12 );
n_huge = numel( idx_huge );
if ( n_huge <= 5 )
    this_data( idx_huge ) = NaN;
end
if isnumeric( tbl.( this_var ) )
    plot( axh, tbl.timestamp, this_data, '.k' );
    this_units = tbl.Properties.VariableUnits{ cur_col };
else
    cla( axh );
end

if ( n_huge <= 5 ) & ( n_huge > 0 )
    t_str = sprintf( '%d extreme points (< or > 10^{12}) not shown', ...
                     numel( idx_huge ) );
    title( axh, t_str );
end

% label x axis on lower plot
xlabel( axh, 'date' );
dynamicDateTicks();  % dateticks that play nice with zooming & panning
%datetick( axh, 'x', 'dd-mmm-yy' );

% title string
t_str = strrep( this_var, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
ylabel( axh, sprintf( '%s [%s]', t_str, this_units ) );
