function result = process_TOB1_year(sitecode, year)
% PROCESS_TOB1_YEAR - 
%   


t0 = now();

lag = 0;
rotation = 1;

whole_year = cell( 12, 1 );

% process a month at a time -- a whole year bogged down for lack of memory
for m = 1:12

    t_start = datenum( year, m, 1 );
    t_end = datenum( year, m, eomday( year, m ) );
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

    % write the 30-min averages to a file
    whole_year{ m } = vertcat( avg_30min_cell{ : } );

    % free up some memory
    clear( 'avg_30min_cell', 'chunks_30_min' );

end

whole_year = vertcat( whole_year{ : } );

outfile = fullfile( get_out_directory( sitecode ), ...
                    get_site_name( sitecode ), ...
                    sprintf( '%s_TOB1_%d.mat', ...
                             get_site_name( sitecode ), year ) );
save( outfile, 'whole_year' );

fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );

result = 1;