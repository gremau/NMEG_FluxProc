% file_list = get_ts_file_names( 'GLand', datenum( 2009, 1, 1 ), ...
%                                         datenum( 2009, 1, 15 ) );

% data = cellfun( @read_TOB1_file, file_list, 'UniformOutput', false );

% all_data = vertcat( data{ : } );

% define some constants
secs_per_day = 24 * 60 * 60;
secs_per_30mins = 60 * 30;

% convert datalogger timestamp (seconds since 1990) to matlab datenum 
dn =  datenum( 1990, 1, 1) + ( all_data.SECONDS / secs_per_day );
t_start = floor( min( dn ) );
edges = t_start:(1/48):( t_start + 1.0 );

[ count, idx ] = histc( dn, edges );

% remove data from the next day (49th half hour )
all_data = all_data( idx < 49, : );

