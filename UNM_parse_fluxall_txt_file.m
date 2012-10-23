function ds  = UNM_parse_fluxall_txt_file( sitecode, year )
% UNM_PARSE_FLUXALL_TXT_FILE - parse fluxall data and timestamps from
% tab-delimited text file to matlab dataset
%   
% ds  = UNM_parse_fluxall_xls_file( sitecode, year )
%
% Timothy W. Hilton, UNM, January 2012
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up file name and file path
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fluxrc = UNM_flux_process_config();
    site = get_site_name( sitecode );
    
    fname = sprintf( '%s_FLUX_all_%d.txt', site, year );
    full_fname = fullfile( get_site_directory( sitecode ), fname );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Open file and parse out dates and times
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf( 'reading %s...', fname );
    
    fid = fopen( full_fname, 'r' );
    headers = fgetl( fid );
    
    % split the headers on tab characters
    headers = regexp( headers, '\t', 'split' );
    % remove or replace characters that are illegal in matlab variable names
    headers_orig = headers;
    headers = regexprep( headers, '[\(\),/;]', '_' );
    headers = regexprep( headers, '[\^" -]', '' );
    headers = regexprep( headers, '_+$', '' ); % remove trailing _
    headers = regexprep( headers, '^_+', '' ); % remove leading _
    % replace decimals in headers with 'p'
    headers = regexprep( headers, '([0-9])\.([0-9])', '$1p$2' );

    % read the numeric data
    fmt = repmat( '%f', 1, numel( headers ) );
    data = textscan( fid, ...
                     fmt, ...
                     'Delimiter', '\t' );
    data = cell2mat( data );

    %% replace -9999s with NaN using floating point test with tolerance of 0.0001
    data = replace_badvals( data, [ -9999 ], 0.0001 );

    % create matlab dataset from data
    empty_columns = find( cellfun( @length, headers ) == 0 );
    headers( empty_columns ) = [];
    data( :, empty_columns ) = [];
    ds = dataset( { data, headers{ : } } );

    ds.timestamp = datenum( ds.year, ds.month, ds.day, ...
                            ds.hour, ds.min, ds.second );

    fprintf( ' file read\n' );

    