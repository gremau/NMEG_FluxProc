t0 = now();

t_start = datenum( 2009, 1, 1 );
t_end = datenum( 2009, 1, 15 );
file_list = get_ts_file_names( 'GLand', t_start, t_end );


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

% split all_data into a cell array, each cell containing data from a
% 30-minute window
row_idx = 1:size( all_data, 1 );
n_chunks = numel( unique( idx30min ) );
chunks_30_min = accumarray( idx30min, ...
                            row_idx, ...
                            [ n_chunks, 1 ], ...
                            @( i ) { all_data( i, : ) } );

%process each 30-minute chunk into averages

fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );