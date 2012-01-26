function result = UNM_Ameriflux_plot_dataset_png( ds, fname, year )
% UNM_AMERIFLUX_PLOT_DATASET - 
%   
    
% create a temporary directory
    tmp_dir = tempname();
    mkdir( tmp_dir );

    for i = 5:length( ds.Properties.VarNames )
        this_png = fullfile( tmp_dir, sprintf( '%03d.png', i ) );
        h = UNM_Ameriflux_plot_field( ds, ds.Properties.VarNames{ i }, year );
        set( h, 'Units', 'inches' );
        set( h, 'Position', [ 0, 0, 6, 6 ] ); %6in by 6in figure
        export_fig( this_png, '-png', h );
        close( h );
        fprintf( 1, '.' );
    end
    fprintf( '\n' );

    % -----
    % combine the png files into a multi-page pdf using system call to
    % ImageMagick's convert tool.

    % if windows machine, convert DOS paths to unix paths
    if ( ispc() )
        [ result, img_cygpath ] = system( sprintf( 'cygpath %s', tmp_dir ) );
        [ result, out_cygpath ] = system( sprintf( 'cygpath %s', fname ) );
        % remove trailing carriage return
        img_cygpath = deblank( img_cygpath );
        out_cygpath = deblank( out_cygpath );
        % replace spaces in path with '\ '
        img_cygpath = regexprep( img_cygpath, '\n' , '\\ ' );
        out_cygpath = regexprep( out_cygpath, '\n', '\\ ' );
    end 
    keyboard()
    cmd = sprintf( 'convert %s/*.png %s', img_cygpath, out_cygpath );
    fprintf( '%s\n', cmd );
    [ result, cmd_output ] = system( cmd );

    
