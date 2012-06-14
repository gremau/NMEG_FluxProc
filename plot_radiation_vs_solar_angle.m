function this_fig = plot_radiation_vs_solar_angle( sitecode, year )
    
sd = parse_UNM_site_table();

fname = get_ameriflux_filename( sitecode, ...
                                year, ...
                                'gapfilled' )
this_data = parse_ameriflux_file( fname );
this_data.timestamp = datenum( year, 1, 0 ) + this_data.DTIME;
this_data.SolEl = get_solar_elevation( sitecode, this_data.timestamp );

pal = brewer_palettes( 'Dark2' );
t_str = sprintf( '%s %d', ...
                 sd.SITE_NAME{ sitecode }, ...
                 year )
this_fig = figure( 'NumberTitle', 'off', ...
                   'Name', t_str );
h_all = plot( this_data.Rg, '.k' );
ylabel( 'Rg' );
xlabel( 'index' );
title( t_str );
hold on
idx = find( this_data.SolEl < 0 );
h_sundown = plot( idx, this_data.Rg( idx ), '.', 'Color', pal( 1, : ) );
idx = find( this_data.Rg_flag );
h_filled = plot( idx, this_data.Rg( idx ), 'o', 'Color', pal( 2, : ) );
h_50 = refline( 0, 50 );
set( h_50, 'LineWidth', 2 );

legend( [ h_all, h_sundown, h_filled, h_50 ], ...
        '', 'solar angle < 0', 'filled', 'Rg = 50', ...
        'Location', 'best' );
    

