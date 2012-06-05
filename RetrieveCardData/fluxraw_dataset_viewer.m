function fh =  fluxraw_dataset_viewer( ds, this_site, mod_date )
% dataset_viewer -- a graphical user interface to view matlab variables of
% class dataset column by column
%       
% USAGE
%    fh = datasetviewer( ds )
%
% INPUTS:
%    ds: variable of class dataset
%
% OUTPUTS:
%
%    fh: handle to the figure window created
%
% (c) Timothy W. Hilton, UNM, Mar 2012
    
%-------------------------
% Initialization tasks
%--------------------------

% determine screensize
    scrsz = get(0,'ScreenSize');
    
    nfields = size( ds, 2 );

    % create a figure to contain the GUI, use entire screen horizontally,
    % upper half of the screen vertically
    fh = figure( 'Name', sprintf( '%s datalogger record -- %s', ...
                                  this_site, ...
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
                        axh, fh, ds, pbh_prev } );

    pbh_zoom = uicontrol( fh, ...
                          'Style', 'pushbutton', ...
                          'String','Zoom', ...
                          'Position', [ 650 10 200 40], ...
                          'CallBack', { @zoom_but_cbk, nfields, ...
                        axh, fh, ds } );

    set( pbh_zoom, 'CallBack', { @zoom_but_cbk, nfields, axh, fh, ds } );
    set( pbh_prev, 'CallBack', { @prev_but_cbk, nfields, axh, fh, ds, pbh_next} );
    set( pbh_next, 'CallBack', { @next_but_cbk, nfields, axh, fh, ds, pbh_prev} );
    set( fh, 'WindowKeyPressFcn', { @key_press_cbk, fh, nfields, axh, ds, ...
                        pbh_prev, pbh_next } );

%--------------------------
%  plot first field
%--------------------------

plot( axh, ds.timestamp, ds( :, 1 ), '.k' );
xlabel( axh, 'date' );
datetick( 'x', 'ddmmmyy' );
t_str = ds.Properties.VarNames{ 1 };
t_str = strrep( t_str, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
ylabel( axh, sprintf( '%s [%s]', t_str, ds.Properties.Units{ 1 } ) );

%--------------------------
%  Callbacks for GUI
%--------------------------

function cur_col = prev_but_cbk( source, eventdata, ...
                                 nfields, axh, fh, ds, pbh_next )
    %% change the plot to the previous data field
    
    % decrement cur_col
    ud = get( fh, 'UserData' );
    ud.cur_col = max( ud.cur_col - 1, 1 );
    % get the new variable names
    this_var = ds.Properties.VarNames{ ud.cur_col };
    if isnumeric( ds.( this_var ) )
        plot( axh, ds.( this_var ), '.k' );
        this_units = ds.Properties.Units{ ud.cur_col };
    else
        cla( axh );
    end
    set( fh, 'UserData', ud );

    % label x axis on lower plot
    xlabel( axh, 'index' );
    
    % title string
    t_str = strrep( this_var, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    ylabel( axh, sprintf( '%s [%s]', t_str, this_units ) );
    
    % just backed up, so can't be on last column
    set( pbh_next, 'enable', 'on' );
    
    % disable "prev" button if we're on the first column
    if ud.cur_col == 1
        set( source, 'enable', 'off' );
    else
        set( source, 'enable', 'on' );
    end    
    
function cur_col = next_but_cbk( source, eventdata, ...
                                 nfields, axh, fh, ds, pbh_prev )
    %% change the plot to the previous data field
    
    % decrement cur_col
    ud = get( fh, 'UserData' );
    ud.cur_col = min( ud.cur_col + 1, nfields );
    % get the new variable names
    this_var = ds.Properties.VarNames{ ud.cur_col };
    if isnumeric( ds.( this_var ) )
        plot( axh, ds.timestamp, ds.( this_var ), '.k' );
        this_units = ds.Properties.Units{ ud.cur_col };
    else
        cla( axh );
    end

    set( fh, 'UserData', ud );

    % label x axis on lower plot
    xlabel( axh, 'date' );
    datetick( 'x', 'dd-mmm-yy' );
    
    % title string
    t_str = strrep( this_var, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    ylabel( axh, sprintf( '%s [%s]', t_str, this_units ) );

    % just advanced, so can't be on first column
    set( pbh_prev, 'enable', 'on' );
    
    % disable "next" button if we're on the last column
    if ud.cur_col == nfields
        set( source, 'enable', 'off' );
    else
        set( source, 'enable', 'on' );
    end
    
function zoom_but_cbk( source, eventdata, ...
                       nfields, axh, fh, ds )
%% change the plot to the previous data field

ud = get( fh, 'UserData' );
cur_ylim = get( axh, 'YLim' );

new_ylim = prctile( double( ds( :, ud.cur_col ) ), ...
                    [ 0.1, 99.9 ] );
set( axh, 'YLim', new_ylim );

%==================================================

function key_press_cbk( source, eventdata, fh, nfields, axh, ds, ...
                        pbh_prev, pbh_next  )

switch eventdata.Key
    
  case 'q'
    close( fh );

  case 'leftarrow'
    prev_but_cbk( pbh_prev, eventdata, nfields, axh, fh, ds, pbh_next );
    
  case 'rightarrow'
    next_but_cbk( pbh_next, eventdata, nfields, axh, fh, ds, pbh_prev );
    
  case 'z'
    zoom_but_cbk( source, eventdata, nfields, axh, fh, ds );
    
end