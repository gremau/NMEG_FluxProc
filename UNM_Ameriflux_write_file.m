function result = UNM_Ameriflux_write_file( sitecode, year, ds_aflx, email, ...
                                            fname_suffix )
    % UNM_AMERIFLUX_WRITE_FILE - writes a dataset containing ameriflux data out to
    %   an Ameriflux ASCII file with appropriate headers
    
    result = 1;
    
    delim = '\t';
    ncol = size( ds_aflx, 2 );
    
    sites_info = parse_UNM_site_table();
    aflx_site_name = char( sites_info.Ameriflux( sitecode ) );
    fname = fullfile( get_out_directory( sitecode ), ...
                      sprintf( '%s_%d_%s.txt', ...
                               aflx_site_name, ...
                               year, ...
                               fname_suffix ) );

    fprintf( 1, 'writing %s...\n', fname );
    
    fid = fopen( fname, 'w+' );

    fprintf( fid, 'Site name: %s\n', aflx_site_name );
    fprintf( fid, 'Email: %s\n', email );
    fprintf( fid, 'Created: %s\n', datestr( now() ) );

    fmt = [ '%s', repmat( '\t%s', 1, ncol-1 ), '\n' ];
    var_names = ds_aflx.Properties.VarNames;
    fprintf( fid, fmt, var_names{:} );
    units = ds_aflx.Properties.Units;
    fprintf( fid, fmt, units{:} );
    
    fclose( fid );

    data = double( ds_aflx );
    data( isnan( data ) ) = -9999;
    dlmwrite( fname, data, '-append', 'delimiter', delim );

