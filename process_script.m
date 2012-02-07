t0 = now();

sitecode = 1;
lag = 0;
rotation = 1;

t_start = datenum( 2009, 1, 1 );
t_end = datenum( 2009, 12, 31 );
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

fprintf( 1, 'done (%d seconds)\nmaking 30-min chunks... ', int32( ( now() - t0 ) * 86400 ) );

% split all_data into a cell array, each cell containing data from a
% 30-minute window
row_idx = 1:size( all_data, 1 );
n_chunks = numel( unique( idx30min ) );
chunks_30_min = accumarray( idx30min, ...
                            row_idx, ...
                            [ n_chunks, 1 ], ...
                            @( i ) { all_data( i, : ) } );

fprintf( 1, 'done (%d seconds)\ncalculating 30-min avgs... ', int32( ( now() - t0 ) * 86400 ) );

%process each 30-minute chunk into averages
avg_30min_cell = cell( size( chunks_30_min ) );
for i = 1:numel( edges )
    avg_30min_cell{ i } = UNM_30min_TS_averager( sitecode, edges( i ), ...
                                                 lag, rotation, ...
                                                 chunks_30_min{ i } );
    if ( mod( i, 100 ) == 0 )
        fprintf( 'iteration %d\n', i );
    end
end

avg_30min = vertcat( avg_30min_cell{ : } );
save( 'foo.mat', 'avg_30min' );


fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );
