function ds  = UNM_parse_fluxall_xls_file( sitecode, year )
% UNM_PARSE_FLUXALL_XLS_FILE - parse fluxall data and timestamps from excel
% file to matlab matrices
%   
% ds  = UNM_parse_fluxall_xls_file( sitecode, year )
%
% Timothy W. Hilton, UNM, January 2012
    
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
    
    %% read the headertext ( windows only )
    %% outside of windows, xlsread operates in 'basic' mode, and can only
    %% read the entire spreadsheet.  We already did this, so the next line is
    %% unnecessary.
    if ( strcmp( computer(), 'WIN' ) )
        [ num, headertext ] = xlsread( filein, headerrange );
    end
    
    % read the numeric data (all operating systems)
    [ data, discard ] = xlsread( filein, range );  

    %% replace -9999s with NaN using floating point test with tolerance of 0.0001.
    data = replace_badvals( data, [ -9999 ], 0.0001 );

    %% read the timestamps (windows only -- see comment above)
    if ( strcmp( computer(), 'WIN' ) )
        [ discard, timestamp ] = xlsread( filein, time_stamp_range );
    end
    
    disp( 'file read' );

    %% create cell array of variable names -- Col_001, Col_002, ... Col_N
    col_names = arrayfun( @(x) sprintf('Col_%03d', x), ...
                          1:size( data, 2 ), ...
                          'UniformOutput', false );
    ds = dataset( { data, col_names{:} } );

    %% convert excel serial dates to matlab datenums (as per
    %% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s)
    ds.timestamp = excel_date_2_matlab_datenum( data( :, 1 ) );
    %% reject data without a timestamp
    ds = ds( ~isnan( ds.timestamp ), : );
