function [ chunks_30_min ] = UNM_data_processor( sitecode, filename, file_date, ...
                                                 rotation, lag, writefluxall )
    % UNM_data_processor( sitecode, filename, file_date, ...
    %                     rotation, lag, writefluxall )
    % reads in raw ts data from TOB1 file, separates into half-hour periods, and
    %sends to other programs for processing/ averaging into half-hour values.
    %outputs half-hour values with timestamps corresponding to the end of the
    %half-hour period
    %
    % modified by Krista Anderson-Teixeira 1/08
    % substantially rewritten by Timothy W. Hilton, Jan 2012
    %
    % author: Timothy W. Hilton, UNM, Jan 2012
% Pretty sure this is deprecated (Not called by other functions
% See process_TOB1_chunk.m
error('This function is deprecated!')


    ds = read_TOB1_file( filename );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % divide data into 30-minute chunks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % define some constants
    secs_per_day = 24 * 60 * 60;
    secs_per_30mins = 60 * 30;
    days_per_30mins = 1 / 48;

    % convert datalogger timestamp (seconds since 1990) to matlab datenum 
    dn =  datenum( 1990, 1, 1) + ( ds.SECONDS / secs_per_day );
    
    % index each timestamp to a 30 minute time period beginning with t_start
    edges = file_date : days_per_30mins : ( file_date + 1.0 );
    [ count, idx30min ] = histc( dn, edges );

    % remove data from outside file_date
    outside = find( idx30min == 0 );
    ds( outside, : ) = [];
    idx30min( outside ) = [];

    % split data into a cell array, each cell containing data from a
    % 30-minute window
    row_idx = 1:size( ds, 1 );
    n_chunks = max( idx30min );
    chunks_30_min = accumarray( idx30min, ...
                                row_idx, ...
                                [ n_chunks, 1 ], ...
                                @( i ) { ds( i, : ) } );
