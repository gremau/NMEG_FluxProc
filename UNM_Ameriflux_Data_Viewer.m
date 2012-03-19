function UNM_Ameriflux_Data_Viewer( sitecode, year )
% UNM_Ameriflux_Data_Viewer -- a graphical user interface to view and compare
% gapfilled and non-gapfilled Ameriflux data
%       
% USAGE
%    UNM_Ameriflux_Data_Viewer( sitecode, year )
%
% (c) Timothy W. Hilton, UNM, Feb 2012
    
%-------------------------
% Initialization tasks
%--------------------------

% determine screensize
    scrsz = get(0,'ScreenSize');
    
    % read site names
    sites_ds = parse_UNM_site_table();

    % parse the Ameriflux Files
    fname_gaps = fullfile( get_out_directory( sitecode ), ...
                           sprintf( '%s_%d_with_gaps.txt', ...
                                    sites_ds.Ameriflux{ sitecode }, year ) );
    fname_filled = fullfile( get_out_directory( sitecode ), ...
                           sprintf( '%s_%d_gapfilled.txt', ...
                                    sites_ds.Ameriflux{ sitecode }, year ) );
    data_gaps = parse_ameriflux_file( fname_gaps );
    data_filled = parse_ameriflux_file( fname_filled );
    
    nfields = max( size( data_gaps, 2 ), size( data_filled, 2 ) );

    % create a figure to contain the GUI, use entire screen
    fh = figure( 'Name', 'UNM Ameriflux Data Viewer', ...
                 'Position', scrsz, ...  
                 'NumberTitle', 'off', ...
                 'ToolBar', 'figure', ...
                 'MenuBar', 'none' );
    set( fh, 'UserData', struct( 'cur_col', 5 ) ); % start with column 5
                                                   % (UST); first four
                                                   % columns are just time
                                                   % fields
    
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
xlabel( axh_gap, 'day of year' );
title( axh_filled, [ data_filled.Properties.VarNames{ 5 }, ' (gapfilled)' ] );

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
    vars = get_var( ud.cur_col );
    if strcmp( vars.var_gaps, '' )
        cla( axh_gap )
    else 
        plot( axh_gap, data_gaps.DTIME, data_gaps.( vars.var_gaps ), '.k' );
    end
    plot( axh_filled, data_filled.DTIME, data_filled.( vars.var_filled ), '.k' );
    set( fh, 'UserData', ud );

    set( axh_gap, 'xlim', [ 0, 366 ] );
    set( axh_filled, 'xlim', [ 0, 366 ] );
    
    % label x axis on lower plot
    xlabel( axh_gap, 'day of year' );
    
    % title string
    t_str = strrep( vars.var_filled, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    title( axh_filled, [ t_str, ' (gapfilled)' ] );

    
    
%------------------------------------------------------------
function cur_col = next_but_cbk( source, eventdata, nfields, ...
                                 axh_gap, axh_filled, fh, ...
                                 data_gaps, data_filled )
    %% plot to the previous data field

    % increment cur_col
    ud = get( fh, 'UserData' );
    ud.cur_col = min( ud.cur_col + 1, nfields );
    % get the new variable names
    vars = get_var( ud.cur_col );
    if strcmp( vars.var_gaps, '' )
        cla( axh_gap )
    else 
        plot( axh_gap, data_gaps.DTIME, data_gaps.( vars.var_gaps ), '.k' );
    end
    plot( axh_filled, data_filled.DTIME, data_filled.( vars.var_filled), '.k' );
    set( fh, 'UserData', ud );
    
    %set axis x limits
    set( axh_gap, 'xlim', [ 0, 366 ] );
    set( axh_filled, 'xlim', [ 0, 366 ] );

    % label x axis on lower plot
    xlabel( axh_gap, 'day of year' );
    
    % title string
    t_str = strrep( vars.var_filled, '_', '\_');
    t_str = strrep( t_str, '0x2E', '.');
    title( axh_filled, [ t_str, ' (gapfilled)' ] );
    

%------------------------------------------------------------
function vars = get_var( gapfilled_col )
% helper function to match filled, unfilled Ameriflux data columns

    map = { 'YEAR', 'YEAR'; ...
            'DOY', 'DOY'; ...
            'HRMIN', 'HRMIN'; ...
            'DTIME', 'DTIME'; ...
            'UST', 'UST'; ...
            'TA', 'TA'; ...
            'TA_flag', ''; ...
            'WD', 'WD'; ...
            'WS', 'WS'; ...
            'NEE', 'NEE'; ...
            'FC', 'FC'; ...
            'FC_flag', ''; ...
            'SFC', 'SFC'; ...
            'H', 'H'; ...
            'H_flag', ''; ...
            'SSA', 'SSA'; ...
            'LE', 'LE'; ...
            'LE_flag', ''; ...
            'SLE', 'SLE'; ...
            'G1', 'G1'; ...
            'TS_20x2E5cm', ''; ...
            'PRECIP', 'PRECIP'; ...
            'RH', 'RH'; ...
            'PA', 'PA'; ...
            'CO2', 'CO2'; ...
            'VPD', 'VPD'; ...
            'VPD_flag', ''; ...
            'SWC_20x2E5cm', 'SWC_20x2E5cm'; ...
            'RNET', 'RNET'; ...
            'PAR', 'PAR'; ...
            'PAR_DIFF', 'PAR_DIFF'; ...
            'PAR_out', 'PAR_out'; ...
            'Rg', 'Rg'; ...
            'Rg_flag', ''; ...
            'Rg_DIFF', 'Rg_DIFF'; ...
            'Rg_out', 'Rg_out'; ...
            'Rlong_in', 'Rlong_in'; ...
            'Rlong_out', 'Rlong_out'; ...
            'FH2O', 'FH2O'; ...
            'H20', 'H20'; ...
            'RE', 'RE'; ...
            'RE_flag', ''; ...
            'GPP', 'GPP'; ...
            'GPP_flag', ''; ...
            'APAR', 'APAR'; ...
            'SWC_2', ''; ...
            'SWC_3', '' };
    
    vars = struct( 'var_filled', map{ gapfilled_col, 1 }, ...
                   'var_gaps', map{ gapfilled_col, 2 } );