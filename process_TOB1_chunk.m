function ds_avg_30min = process_TOB1_chunk(sitecode, t_start, t_end, lag, rotation)
% PROCESS_TOB1_CHUNK - process 10 hz data within a specified time window to
% 30-minute averages.  Returns a matlab dataset, each row of which contains
% the processed and averaged 10-hz data for a 30 minute window. 
%   
% USAGE
%    ds_avg_30min = process_TOB1_chunk( sitecode, t_start, t_end, lag, rotation )
%
% (c) Timothy W. Hilton, UNM, Feb 2012

    t0 = now(); % monitor running time

    file_list = get_ts_file_names( get_site_name( sitecode ), t_start, t_end );

    data = cellfun( @read_TOB1_file, file_list, 'UniformOutput', false );
    all_data = vertcat( data{ : } );

    % define some constants
    secs_per_day = 24 * 60 * 60;
    secs_per_30mins = 60 * 30;

    % convert datalogger timestamp (seconds since 1990) to matlab datenum 
    dn =  datenum( 1990, 1, 1) + ( all_data.SECONDS / secs_per_day );

    % index each timestamp to a 30 minute time period beginning with t_start
    edges = t_start:(1/48):t_end;
    [ count, idx30min ] = histc( dn, edges );

    % remove data from outside [ t_start, t_end ]
    outside = find( idx30min == 0 );
    all_data( outside, : ) = [];
    idx30min( outside ) = [];

    fprintf( 1, 'done (%d seconds)\nmaking 30-min chunks... ', ...
             int32( ( now() - t0 ) * 86400 ) );

    % split all_data into a cell array, each cell containing data from a
    % 30-minute window
    row_idx = 1:size( all_data, 1 );
    n_chunks = numel( edges );
    chunks_30_min = accumarray( idx30min, ...
                                row_idx, ...
                                [ n_chunks, 1 ], ...
                                @( i ) { all_data( i, : ) } );

    fprintf( 1, 'done (%d seconds)\ncalculating 30-min avgs... ', ...
             int32( ( now() - t0 ) * 86400 ) );

    %process each 30-minute chunk into averages
    avg_30min_cell = cell( size( chunks_30_min ) );
    for i = 1:numel( edges )
        if not( isempty( chunks_30_min{ i } ) )
            avg_30min_cell{ i } = UNM_30min_TS_averager( sitecode, edges( i ), ...
                                                         lag, rotation, ...
                                                         chunks_30_min{ i } ...
                                                         );
        end
        if ( mod( i, 100 ) == 0 )
            fprintf( 'iteration %d\n', i );
        end
    end

    ds_avg_30min = vertcat( avg_30min_cell{ : } );