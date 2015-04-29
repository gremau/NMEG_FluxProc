function result = UNM_Ameriflux_plot_dataset_eps( tbl_in, fname, year, ...
                                                  start_col)
% UNM_AMERIFLUX_PLOT_DATASET - create a multipage pdf file containing
% plots of each field of an ameriflux dataset.
%   
% INPUTS:
%    tbl_in: table array: Ameriflux data to be plotted
%    fname: character string; path to a pdf file in which to save plots
%    year: four-digit year; the year of the data (for plot labels)
%    start_col: integer: tbl_in( :, start_col:end ) is plotted.  The 
%       first few columns of Ameriflux files contain year, month, day,
%       etc., and this allows the plotting to skip those.
%
% OUTPUTS
%    no output
%
% author: Timothy W. Hilton, UNM, January 2012

    if exist( fname ) == 2
        delete( fname );
    end
    
    for i = start_col:length( tbl_in.Properties.VariableNames )
        h = UNM_Ameriflux_plot_field( tbl_in, ...
            tbl_in.Properties.VariableNames{ i }, year );
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
    
