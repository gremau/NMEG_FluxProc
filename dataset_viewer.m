function dataset_viewer( ds )
% dataset_viewer -- a graphical user interface to view matlab variables of
% class dataset column by column
%       
% USAGE
%    datasetviewer( ds )
%
% INPUTS:
%    ds: variable of class dataset
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
    fh = figure( 'Name', 'dataset viewer', ...
                 'Position', scrsz ./ [ 1, 2, 1, 2 ], ...  
                 'NumberTitle', 'off', ...
                 'ToolBar', 'figure', ...
                 'MenuBar', 'none' );
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
                          'String','previous', ...
                          'Position', [ 50 10 200 40] );
    set( pbh_prev, 'enable', 'off' );  % start at the first column
    
    %add a "next" button
    pbh_next = uicontrol( fh, ...
                          'Style', 'pushbutton', ...
                          'String','next', ...
                          'Position', [ 250 10 200 40], ...
                          'CallBack', { @next_but_cbk, nfields, ...
                        axh, fh, ds, pbh_prev } );

    set( pbh_prev, 'CallBack', { @prev_but_cbk, nfields, axh, fh, ds, pbh_next} );
    set( pbh_next, 'CallBack', { @next_but_cbk, nfields, axh, fh, ds, pbh_prev} );
%--------------------------
%  plot first field
%--------------------------

plot( axh, ds( :, 1 ), '.k' );
xlabel( axh, 'index' );
t_str = ds.Properties.VarNames{ 1 };
t_str = strrep( t_str, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
ylabel( axh, t_str );

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
    plot( axh, ds.( this_var ), '.k' );
    set( fh, 'UserData', ud );

    % label x axis on lower plot
    xlabel( axh, 'index' );
    
    % title string
    t_str = strrep( this_var, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    ylabel( axh, t_str );
    
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
    plot( axh, ds.( this_var ), '.k' );
    set( fh, 'UserData', ud );

    % label x axis on lower plot
    xlabel( axh, 'index' );
    
    % title string
    t_str = strrep( this_var, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    ylabel( axh, t_str );

    % just advanced, so can't be on first column
    set( pbh_prev, 'enable', 'on' );
    
    % disable "next" button if we're on the last column
    if ud.cur_col == nfields
        set( source, 'enable', 'off' );
    else
        set( source, 'enable', 'on' );
    end