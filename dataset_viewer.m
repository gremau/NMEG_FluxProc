function fh =  dataset_viewer( ds, varargin )
% dataset_viewer -- a graphical user interface to view variables from a dataset
% array column by column.
%       
% USAGE
%    fh = datasetviewer( ds )
%    fh = datasetviewer( ds, 't_var', 'timestamp_variable' )
%
% INPUTS:
%    ds: variable of class dataset array
% KEYWORD ARGUMENTS
%    t_var: optional; if specified, each column is plotted against timestamps in
%         this column.  Values in specified column must be matlab serial
%         datenumbers.
%
% OUTPUTS:
%    fh: handle to the figure window created
%
% SEE ALSO
%    dataset, datenum
%
% author: Timothy W. Hilton, UNM, Mar 2012

%-------------------------
% parse optional arguments
%-------------------------

args = inputParser;
args.addRequired( 'ds', @(x) isa( x, 'dataset' ) );
args.addParamValue( 't_var', '', @ischar );

args.parse( ds, varargin{ : } );

ds = args.Results.ds;
t_var = args.Results.t_var;

%-------------------------
% Initialization tasks
%-------------------------

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
                    axh, fh, ds, t_var, pbh_prev } );

set( pbh_prev, 'CallBack', { @prev_but_cbk, nfields, axh, fh, ...
                    ds, t_var, pbh_next} );
set( pbh_next, 'CallBack', { @next_but_cbk, nfields, axh, fh, ...
                    ds, t_var, pbh_prev} );
%--------------------------
%  plot first field
%--------------------------

if not( isempty( t_var ) )
    x_vals = ds.( t_var );
else
    x_vals = 1:size( ds, 1 );
end

plot( axh, x_vals, ds( :, 1 ), '.k', 'MarkerSize', 12 );
xlabel( axh, 'index' );
t_str = ds.Properties.VarNames{ 1 };
t_str = replace_hex_chars( t_str );
t_str = regexprep( t_str, '_', '\\_' );
ylabel( axh, t_str );
if not( isempty( t_var ) )
    dynamicDateTicks();
end

%--------------------------
%  Callbacks for GUI
%--------------------------

function cur_col = prev_but_cbk( source, eventdata, ...
                                 nfields, axh, fh, ds, t_var, pbh_next )
%% change the plot to the previous data field

% decrement cur_col
ud = get( fh, 'UserData' );
ud.cur_col = max( ud.cur_col - 1, 1 );
% get the new variable names
this_var = ds.Properties.VarNames{ ud.cur_col };
if isnumeric( ds.( this_var ) )
    if not( isempty( t_var ) )
        x_vals = ds.( t_var );
    else
        x_vals = 1:size( ds, 1 );
    end
    plot( axh, x_vals, ds.( this_var ), '.k', 'MarkerSize', 12 );
    if not( isempty( t_var ) )
        dynamicDateTicks();
    end
else
    cla( axh );
end
set( fh, 'UserData', ud );

% label x axis on lower plot
xlabel( axh, 'index' );

% title string
t_str = replace_hex_chars( this_var );
t_str = regexprep( t_str, '_', '\\_' );
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
                                 nfields, axh, fh, ds, t_var, pbh_prev )
%% change the plot to the previous data field

% decrement cur_col
ud = get( fh, 'UserData' );
ud.cur_col = min( ud.cur_col + 1, nfields );
% get the new variable names
this_var = ds.Properties.VarNames{ ud.cur_col };
if isnumeric( ds.( this_var ) )
    if not( isempty( t_var ) )
        x_vals = ds.( t_var );
    else
        x_vals = 1:size( ds, 1 );
    end
    plot( axh, x_vals, ds.( this_var ), '.k', 'MarkerSize', 12 );
    if not( isempty( t_var ) )
        dynamicDateTicks();
    end
else
    cla( axh );
end

set( fh, 'UserData', ud );

% label x axis on lower plot
xlabel( axh, 'index' );

% title string
t_str = replace_hex_chars( this_var );
t_str = regexprep( t_str, '_', '\\_' );
ylabel( axh, t_str );

% just advanced, so can't be on first column
set( pbh_prev, 'enable', 'on' );

% disable "next" button if we're on the last column
if ud.cur_col == nfields
    set( source, 'enable', 'off' );
else
    set( source, 'enable', 'on' );
end