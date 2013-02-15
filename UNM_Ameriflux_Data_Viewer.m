function UNM_Ameriflux_Data_Viewer( sitecode, year, varargin )
% UNM_Ameriflux_Data_Viewer -- a graphical user interface to view and compare
% gapfilled and non-gapfilled Ameriflux data
%       
% USAGE
%    UNM_Ameriflux_Data_Viewer( sitecode, year )
%    UNM_Ameriflux_Data_Viewer( sitecode, year, prompt_for_files )
%    UNM_Ameriflux_Data_Viewer( sitecode, year, 'AFlux_dir', 'some/path'  )
%
% (c) Timothy W. Hilton, UNM, Feb 2012

%-------------------------
% Initialization tasks
%--------------------------

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

args = inputParser;
args.addRequired( 'sitecode', ...
                    @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'prompt_for_files', false, @islogical );
args.addParamValue( 'AFlux_dir', '', @ischar );

% parse optional inputs
args.parse( sitecode, year,  varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;

% determine screensize
scrsz = get(0,'ScreenSize');

% read site names
sites_ds = parse_UNM_site_table();

if args.Results.prompt_for_files
    start_dir = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_Files', '*.txt' );
    h = msgbox( 'Select the with-gaps Ameriflux file', '' );
    waitfor( h );
    [ fname_gaps, path_gaps ] ...
        = uigetfile( start_dir, 'Select the with-gaps Ameriflux file' );
    fname_gaps = fullfile( path_gaps, fname_gaps );
    
    h = msgbox( 'Select the gapfilled Ameriflux file', '' );
    waitfor( h );
    [ fname_filled, path_filled ] = ...
        uigetfile( start_dir, 'Select the gapfilled Ameriflux file' );
    fname_filled = fullfile( path_filled, fname_filled );
    
else
    if isempty( args.Results.AFlux_dir )
        AFlux_dir = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_Files' );
    else
        AFlux_dir = args.Results.AFlux_dir;
    end
    
    % parse the Ameriflux Files
    fname_gaps = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_Files', ...
                           sprintf( '%s_%d_with_gaps.txt', ...
                                    sites_ds.Ameriflux{ sitecode }, year ) );
    fname_filled = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_Files', ...
                             sprintf( '%s_%d_gapfilled.txt', ...
                                      sites_ds.Ameriflux{ sitecode }, year ) );
end
fprintf( 'Ameriflux_Data_Viewer: parsing %s and %s\n', ...
         fname_gaps, fname_filled );
data_gaps = parse_ameriflux_file( fname_gaps );
data_filled = parse_ameriflux_file( fname_filled );

nfields = max( size( data_gaps, 2 ), size( data_filled, 2 ) );

if not( isnan( sitecode ) )
    fig_name = sprintf( 'UNM Ameriflux Data Viewer - %s %d', ...
                        get_site_name( sitecode ), year );
else
    fig_name = 'Ameriflux Data Viewer';
end

% create a figure to contain the GUI, use entire screen
fh = figure( 'Name', fig_name, ...
             'Position', scrsz .* [ 1, 1, 0.8, 0.8 ], ...  
             'NumberTitle', 'off', ...
             'ToolBar', 'figure', ...
             'MenuBar', 'none' );

% start with column 5 (UST); first four columns are just time fields
set( fh, 'UserData', struct( 'cur_col', 5, ...
                             'FontSize', 20 ) ); 

%--------------------------
% Construct GUI components
%--------------------------

%add axes for plots
axh_gap = axes( 'Parent', fh, ...
                'Units', 'normalized', ...
                'HandleVisibility','callback', ...
                'Position',[ 0.1, 0.1, 0.8, 0.4 ] );
% gap_label = uicontrol( fh, ...
%                        'Style', 'text', ...
%                        'Units', 'normalized', ...
%                        'Position', [ 0.02, 0.3, 0.1, 0.1 ], ...
%                        'String', 'with gaps' );


axh_filled = axes( 'Parent', fh, ...
                   'Units', 'normalized', ...
                   'HandleVisibility','callback', ...
                   'Position',[ 0.1, 0.55, 0.8, 0.4 ] );

% "link"  axes so they zoom together
linkaxes( [ axh_gap, axh_filled ], 'xy' );

%add a "previous" button
pbh_prev = uicontrol( fh, ...
                      'Style', 'pushbutton', ...
                      'String','previous', ...
                      'Position', [ 50 10 200 40], ...
                      'CallBack', { @prev_but_cbk, ...
                    axh_gap, axh_filled, fh, ...
                    data_gaps, data_filled } );
%add a "next" button
pbh_next = uicontrol( fh, ...
                      'Style', 'pushbutton', ...
                      'String','next', ...
                      'Position', [ 250 10 200 40], ...
                      'CallBack', { @next_but_cbk, nfields, ...
                    axh_gap, axh_filled, fh, ...
                    data_gaps, data_filled } );


%--------------------------
%  plot first field
%--------------------------

plot( axh_gap, data_gaps.DTIME, data_gaps( :, 5 ), '.k' );
plot( axh_filled, data_filled.DTIME, data_filled( :, 5 ), '.k' );
set( axh_gap, 'xlim', [ 0, 366 ] );
set( axh_filled, 'xlim', [ 0, 366 ] );
xlabel( axh_gap, 'day of year', ...
        'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ) );
title( axh_filled, ...
       [ data_filled.Properties.VarNames{ 5 }, ' (gapfilled)' ], ...
       'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ) );

%--------------------------
%  Callbacks for GUI
%--------------------------

function cur_col = prev_but_cbk( source, eventdata, ...
                                 axh_gap, axh_filled, fh, ...
                                 data_gaps, data_filled )
%% advance the plots to the next data field

% decrement cur_col
ud = get( fh, 'UserData' );
ud.cur_col = max( ud.cur_col - 1, 5 );
% get the new variable names
vars = get_var( ud.cur_col, data_gaps, data_filled );
if strcmp( vars.var_gaps, '' )
    cla( axh_gap )
else 
    plot( axh_gap, data_gaps.DTIME, data_gaps.( vars.var_gaps ), '.k' );
end

update_filled_plot( axh_gap, axh_filled, ...
                    data_gaps, data_filled, ...
                    vars );

set( fh, 'UserData', ud );

% set x limits and y limits
set( axh_gap, 'xlim', [ 0, 366 ] );
set( axh_filled, 'xlim', [ 0, 366 ] );

% yrange = [ get( axh_filled, 'YLim' ), get( axh_gap, 'YLim' ) ];
% set( axh_filled, 'YLim', [ min( yrange ), max( yrange ) ] );
% set( axh_gap, 'YLim', [ min( yrange ), max( yrange ) ] );

% label x axis on lower plot
xlabel( axh_gap, 'day of year', ...
        'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ) );

% title string
t_str = strrep( vars.var_filled, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
title( axh_filled, [ t_str, ' (gapfilled)' ], ...
       'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ) );



%------------------------------------------------------------
function cur_col = next_but_cbk( source, eventdata, nfields, ...
                                 axh_gap, axh_filled, fh, ...
                                 data_gaps, data_filled )
%% plot to the previous data field

% increment cur_col
ud = get( fh, 'UserData' );
ud.cur_col = min( ud.cur_col + 1, nfields );
% get the new variable names
vars = get_var( ud.cur_col, data_gaps, data_filled );

if strcmp( vars.var_gaps, '' )
    cla( axh_gap )
else 
    plot( axh_gap, data_gaps.DTIME, data_gaps.( vars.var_gaps ), '.k' );
end
update_filled_plot( axh_gap, axh_filled, ...
                    data_gaps, data_filled, ...
                    vars );

set( fh, 'UserData', ud );

%set axis x and y limits
set( axh_gap, 'xlim', [ 0, 366 ] );
set( axh_filled, 'xlim', [ 0, 366 ] );

% yrange = [ get( axh_filled, 'YLim' ), get( axh_gap, 'YLim' ) ];
% set( axh_filled, 'YLim', [ min( yrange ), max( yrange ) ] );
% set( axh_gap, 'YLim', [ min( yrange ), max( yrange ) ] );

% label x axis on lower plot
xlabel( axh_gap, 'day of year', ...
        'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ));

% title string
t_str = strrep( vars.var_filled, '_', '\_');
t_str = strrep( t_str, '0x2E', '.');
title( axh_filled, [ t_str, ' (gapfilled)' ], ...
       'FontSize', getfield( get( fh, 'UserData' ), 'FontSize' ) );


%------------------------------------------------------------
function vars = get_var( gapfilled_col, data_gaps, data_filled )
% helper function to match filled, unfilled Ameriflux data columns

var_filled = data_filled.Properties.VarNames{ gapfilled_col }; 

if strfind( var_filled , 'flag' )
    var_gaps = '';
elseif not( ismember( var_filled, data_gaps.Properties.VarNames ) )
    var_gaps = '';
else
    var_gaps = var_filled;
end

vars = struct( 'var_filled', var_filled, ...
               'var_gaps', var_gaps );


%--------------------------------------------------

function update_filled_plot( axh_gap, axh_filled, ...
                             data_gaps, data_filled, vars )
% UPDATE_FILLED_PLOT - update the "filled data" plot this is a helper function
% for UNM_Ameriflux_Data_Viewer

cla( axh_filled );

pal = brewer_palettes( 'Dark2' );
flag_val = zeros( size( data_filled.DTIME ) );
flag_col = find( strcmp( data_filled.Properties.VarNames, ...
                         sprintf( '%s_flag', vars.var_filled ) ) );
if ~isempty( flag_col )
    flag_val = double( data_filled( :, flag_col ) );
end
this_data = data_filled.( vars.var_filled );
idx_filled = flag_val > 0;
h_obs_points = plot( axh_filled, ...
                     data_filled.DTIME( ~idx_filled ), ...
                     this_data( ~idx_filled ), ...
                     '.k' );
hold( axh_filled, 'on' );
h_filled_points = plot( axh_filled, ...
                        data_filled.DTIME( idx_filled ), ...
                        this_data( idx_filled ), ...
                        'LineStyle', 'none', ...
                        'Marker', '.', ...
                        'MarkerFaceColor', pal( 1, : ), ...
                        'MarkerEdgeColor', pal( 1, : ) );
hold( axh_filled, 'off' );

% create a legend
if ~isempty( h_filled_points )
    legend( [ h_obs_points, h_filled_points ], 'observed', 'filled' );
else
    legend( [ h_obs_points ], 'observed' );
end

