function UNM_retrieve_card_data_GUI(varargin)
% UNM_retrieve_card_data -- Top-level function for processing datalogger cards
% from New Mexico Elevation Gradient sites.
%
% Creates a graphical user interface to select a UNM site and retrieve flux data
% from a compact flash card.
%
% This is the top-level function for processing datalogger cards from New Mexico
% Elevation Gradient sites.  This function simply prompts the user to select a
% site and then calls process_card_main to do the heavy lifting.  For a detailed
% description of what processing operations are performed see documentation for
% process_card_main.
%       
% USAGE
%    UNM_retrieve_card_data_GUI()
%
% INPUTS
%    no inputs
%
% OUTPUTS
%    no outputs
%
% (c) Timothy W. Hilton, UNM, 2011-2013

%-------------------------
% Initialization tasks
%--------------------------

% determine screensize
scrsz = get(0,'ScreenSize');

% read site names
sites_ds = parse_UNM_site_table();

% variable to contain selected site
selected_site = 1;

% create a figure to contain the GUI
fig_hgt = size( sites_ds, 1 ) * 30 + 100;   % figure height
fh = figure( 'Name', 'Flux Card Data Retrieval', ...
             'Position', [ scrsz(3) * 0.1, ...
                    ( scrsz( 4 ) * 0.9 ) - fig_hgt, ...
                    300, ...
                    fig_hgt ], ...
             'NumberTitle', 'off', ...
             'ToolBar', 'none', ...
             'MenuBar', 'none' );

% array for radio button handles
rbh = repmat( NaN, size( sites_ds, 1 ), 1 );

%--------------------------
% Construct the components
%--------------------------
% add button group for UNM field sites
site_bgh = uibuttongroup( 'Parent', fh,...
                          'Position', [ 0.1, 0.2, 0.8, 0.79 ] );
% populate the button group with radio buttons, one per site
rb_y = wrev( 0.00:( 0.9/length( rbh ) ):0.95 );  %vertical positions for buttons
for i = 1:size( sites_ds, 1 )
    rbh( i ) = uicontrol( site_bgh, ...
                          'Style','radiobutton', ...
                          'String', sites_ds.SITE_NAME( i ), ...
                          'Units', 'normalized', ...
                          'Position', ...
                          [ 0.05, rb_y( i ), 0.9, 0.9 / length( rbh ) ] );
end

%add a "retrieve data" button
pbh = uicontrol( fh, ...
                 'Style', 'pushbutton', ...
                 'String','Retrieve Data', ...
                 'Position', [ 50 20 200 40], ...
                 'CallBack', @but_cbk );

%--------------------------
%  Callbacks for GUI
%--------------------------

    function but_cbk( source, eventdata )
    %% starts the data retrieval main function for the selected site
    selected_button = get( site_bgh, 'SelectedObject' );
    % floating point comparison to identify selected radio handle
    selected_site_num = find( abs( rbh - selected_button ) < 0.0001 );
    this_site = sites_ds.FILE_NAME{ selected_site_num };
    
    % close the GUI figure when button is pressed
    close( fh );
    % pause for one second -- without this, the GUI doesn't actually
    % disappear until after card processing completes
    initial_pause_status = pause( 'on' );
    pause( 1 );
    pause( initial_pause_status ); %reset pause state to where it was
    
    fprintf( 1, '\nProcessing card for %s\n', this_site );
    process_card_main( selected_site_num );
    
    
    end

end