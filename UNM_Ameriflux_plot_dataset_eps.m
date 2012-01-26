function result = UNM_Ameriflux_plot_dataset_eps(ds, fname, year)
% UNM_AMERIFLUX_PLOT_DATASET - 
%   
    
    if exist( fname ) == 2
        delete( fname );
    end
    
    for i = 5:length( ds.Properties.VarNames )
        h = UNM_Ameriflux_plot_field( ds, ds.Properties.VarNames{ i }, year );
        set( h, 'PaperUnits', 'inches' );
        set( h, 'PaperSize', [ 4.1, 5.8 ] ); % A6 paper size
        set( h, 'PaperPosition', [ 0, 0, 4.1, 5.8 ] );
        set( h, 'PaperOrientation', 'landscape' );
        print( fname,'-append','-dpsc' ); 
        close( h );
        fprintf( 1, '.' );
    end
    
    fprintf( '\n' );

    ps2pdf( 'psfile', fname, ...
            'pdffile', strrep( fname, '.ps', '.pdf' ), ... 
            'gspapersize', 'a6' );
    %            'deletepsfile', 1 );
    
