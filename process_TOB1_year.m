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

    % process 30-minute averages
    whole_year{ m } = process_TOB1_chunk( sitecode, t_start, t_end, lag, ...
                                          rotation )
end

whole_year = vertcat( whole_year{ : } );

outfile = fullfile( get_out_directory( sitecode ), ...
                    'TOB1_data', ...
                    sprintf( '%s_TOB1_%d.mat', ...
                             get_site_name( sitecode ), year ) );

save( outfile, 'whole_year' );

fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );

result = 1;