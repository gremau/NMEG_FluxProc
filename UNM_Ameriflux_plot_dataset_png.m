function result = UNM_Ameriflux_plot_dataset_png( ds, fname, year )
% UNM_AMERIFLUX_PLOT_DATASET - 
%   
    
% create a temporary directory
    tmp_dir = tempname();
    mkdir( tmp_dir );

    for i = 5:length( ds.Properties.VarNames )
        this_png = fullfile( tmp_dir, sprintf( '%03d.png', i ) );
        h = UNM_Ameriflux_plot_field( ds, ds.Properties.VarNames{ i }, year );
        export_fig( this_png, '-png', h );
        close( h );
        fprintf( 1, '.' );
    end
    fprintf( '\n' );

    % combine the png files into a multi-page pdf
    [ result, cygpath ] = system( sprintf( 'cygpath %s', tmp_dir ) );
    cygpath = deblank( cygpath );
    cmd = sprintf( 'convert %s/*.png %s', cygpath, fname );
    fprintf( '%s\n', cmd );
    [ result, cmd_output ] = system( cmd );
    
