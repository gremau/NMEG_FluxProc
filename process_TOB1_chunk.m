function ds_avg_30min = process_TOB1_chunk(sitecode, t_start, t_end, lag, ...
                                           rotation, ts_data_dir )
% PROCESS_TOB1_CHUNK - process 10 hz data within a specified time window to
% 30-minute averages.  Returns a matlab dataset, each row of which contains
% the processed and averaged 10-hz data for a 30 minute window.  If no data
% are found within the requested time period, returns an empty dataset.
%   
% USAGE
%    ds_avg_30min = process_TOB1_chunk( sitecode, t_start, t_end, lag, rotation )
%
% (c) Timothy W. Hilton, UNM, Feb 2012

    t0 = now(); % monitor running time

    fmt = 'dd mmm yyyy HH:MM';
    fprintf( 1, 'reading TOB1 files (%s - %s):\n\t', ...
             datestr( t_start, fmt ), datestr( t_end, fmt ) );
    
    file_list = get_ts_file_names( get_site_name( sitecode ), t_start, t_end, ...
                                                ts_data_dir );

    if isempty( file_list )
        ds_avg_30min = dataset( [] );
        fprintf( 'No files found\n');
        return
    end
   
    data = cellfun( @read_TOB1_file, file_list, 'UniformOutput', false );
    all_data = vertcat( data{ : } );

    % define some constants
    secs_per_day = 24 * 60 * 60;
    secs_per_30mins = 60 * 30;

    % convert datalogger timestamp (seconds since 1990) to matlab datenum 
    dn =  datenum( 1990, 1, 1) + ( all_data.SECONDS / secs_per_day );

    % index each timestamp to a 30 minute time period beginning with the next even
    % half-hour after t_start 
    t_start = datenum_2_round30min( t_start, 14.99, floor( t_start ) );
    edges = t_start:(1/48):t_end;
    [ count, idx30min ] = histc( dn, edges );

    % remove data from outside [ t_start, t_end ]
    
    % two notes about the counting details: 

    % NOTE 1: matlab's histc function is defined to return in the last bin *only*
    % elements that are *exactly* equal to edges( end ) -- in this case, an
    % instant in time.  That is, now bins 1:end-1 each contain a 30-minute chunk
    % of data, but bin(end) contains only a single data point.  We aren't
    % interested in the instant, so remove it here.

    % NOTE 2: histc results will place in bin(k) every element x such that edges( k
    % ) <= x < edges( k + 1).  That is, each bin index will line up with the
    % timestamp (in edges) for the beginning of the 30-minute period.  The UNM
    % convention is to label each 30-minute average data point with the
    % timestamp of the *end* of the 30-minute period.  Therefore we need to
    % offset each 10-hz point's index (in idx30min) by one relative to its
    % timestamp (in edges) to get the timestamp label right.

    outside = find( idx30min == 0 | ...
                    idx30min == numel( edges ) );  % see note 1, above
    all_data( outside, : ) = [];
    idx30min( outside ) = [];

    edges = edges( 2:end );  %see note 2, above

    fprintf( 1, ' done (%d seconds)\nmaking 30-min chunks... ', ...
             int32( ( now() - t0 ) * 86400 ) );
    t0 = now();

    % split all_data into a cell array, each cell containing data from a
    % 30-minute window
    row_idx = 1:size( all_data, 1 );
    n_chunks = numel( edges );
    chunks_30_min = accumarray( idx30min, ...
                                row_idx, ...
                                [ n_chunks, 1 ], ...
                                @( i ) { all_data( i, : ) } );

    fprintf( 1, 'done (%d seconds)\ncalculating 30-min avgs: ', ...
             int32( ( now() - t0 ) * 86400 ) );
    t0 = now();

    %process each 30-minute chunk into averages
    avg_30min_cell = cell( size( chunks_30_min ) );
    for i = 1:numel( edges ) - 1
        if not( isempty( chunks_30_min{ i } ) )
            avg_30min_cell{ i } = UNM_30min_TS_averager( sitecode, ...
                                                         edges( i ), ...
                                                         lag, rotation, ...
                                                         chunks_30_min{ i } );
        end
        if ( mod( i, 100 ) == 0 )
            fprintf( '.' );
            %fprintf( 'iteration %d\n', i );
        end
    end
    fprintf( 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );
    ds_avg_30min = vertcat( avg_30min_cell{ : } );