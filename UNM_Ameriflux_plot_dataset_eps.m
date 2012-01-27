function result = UNM_Ameriflux_plot_dataset_eps(ds, fname, year, start_col)
% UNM_AMERIFLUX_PLOT_DATASET - 
%   
    
    if exist( fname ) == 2
        delete( fname );
    end
    
    for i = start_col:length( ds.Properties.VarNames )
        h = UNM_Ameriflux_plot_field( ds, ds.Properties.VarNames{ i }, year );
        %set( h, 'PaperSize', [ 4.1, 5.8 ] ); % A6 paper size
        set( h, 'PaperType', 'A5' );
        orient( h, 'landscape' );
        %set( h, 'PaperPosition', [ 3, 2, 5.8, 4.1 ] );
        print( fname,'-append','-dpsc' ); 
        close( h );
        fprintf( 1, '.' );
    end
    
    fprintf( '\n' );

    ps2pdf( 'psfile', fname, ...
            'pdffile', strrep( fname, '.ps', '.pdf' ), ... 
            'gspapersize', 'a5', ...
            'deletepsfile', 1 );
    
