function [ data, timestamp ]  = UNM_parse_fluxall_xls_file( sitecode, year )
% UNM_PARSE_FLUXALL_XLS_FILE - parse fluxall data and timestamps from excel
% file to matlab matrices
%   
    
    [ lastcolumn, filelength_n ] = get_FluxAll_File_Properties( sitecode, year );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up file name and file path
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fluxrc = UNM_flux_process_config();
    site = get_site_name( sitecode );
    
    row1=5;  %first row of data to process - rows 1 - 4 are header
    fname = sprintf( '%s_FLUX_all_%d.xls', site, year );
    filein = fullfile( get_site_directory( sitecode ), fname );
    
    range = sprintf( 'B%d:%s%d', row1 ,lastcolumn, filelength_n );
    headerrange = sprintf( 'B2:%s2',lastcolumn );
    time_stamp_range = sprintf( 'A5:A%d', filelength_n );

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Open file and parse out dates and times
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp( sprintf( 'reading %s...', fname ) );
    
    % read the headertext
    [ num, headertext ] = xlsread( filein, headerrange );
    % read the numeric data
    [ data, discard ] = xlsread( filein, range );  %does not read in first column
                                                   %because it's text!!!!!!!!
    %% replace -9999s with NaN using floating point test with tolerance of 0.0001.
    data = replace_badvals( data, [ -9999 ], 0.0001 );
    %% read the timestamps
    [ discard, timestamp ] = xlsread( filein, time_stamp_range );
    
    disp( 'file read' );

    


