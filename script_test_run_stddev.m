% demonstrates that running_stddev and running_mean are working

data = [ randn( 1, 1000 ), ( 2 * randn( 1, 1000 ) ), ( 3 * randn( 1, 1000 ) ) ];
figure();
plot( data, '.k' );
hold all;
h_sd = plot( running_stddev( data, 101 ) );
set( h_sd, 'LineWidth', 2 );

data = [ randn( 1, 1000 ), ( 1 + randn( 1, 1000 ) ), ( 2 + randn( 1, 1000 ) ) ];
figure();
plot( data, '.k' );
hold all;
h_avg = plot( running_mean( data, 101 ) );
set( h_avg, 'LineWidth', 2 );