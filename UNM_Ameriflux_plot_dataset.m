function result = UNM_Ameriflux_plot_dataset(ds, fname, year, pdf)
% UNM_AMERIFLUX_PLOT_DATASET - 
%   
    
    if exist( fname ) == 2
        delete( fname );
    end
    
    for i = 5:10 %length( ds.Properties.VarNames )
        h = UNM_Ameriflux_plot_field( ds, ds.Properties.VarNames{ i }, year );
        export_fig( fname, '-png', '-append', h );
        close( h );
        fprintf( 1, '.' );
    end
    
    fprintf( '\n' );
    
