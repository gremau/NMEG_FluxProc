close all;
clear all;

t0 = now();

result = UNM_Ameriflux_file_maker_TWH( 1, 2010 ); 

fprintf( 1, 'Done -- %.0f secs\n', ( now() - t0 ) * 60 * 60 * 24 );