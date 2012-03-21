SWC_cols = regexp( result.Properties.VarNames, ...
                   '^(open[12]|grass[12])_[0-9]' );
SWC_cols = find( ~cellfun( 'isempty', SWC_cols ) );

dn = datenum( result.TIMESTAMP, 'mm/dd/yyyy HH:MM:SS' );

for i = 1 : length( SWC_cols )
    this_fig = figure();
    this_var = result.Properties.VarNames{ SWC_cols( i ) };
    plot( dn, result.( this_var ), 'ok' );
    datetick( 'x' );
    ylabel( 'volumetric SWC' );
    ylim( [ 0, 0.3 ] );
    title( strrep( this_var, '_', '\_' ) );
    hold on;
    
    echo_var = [ 'echo_', this_var, '_Avg' ];
    if any( strcmp( result.Properties.VarNames, echo_var ) )
        plot( dn, result.( echo_var ), '.b' );
        legend( 'echo / CS616', 'echo / echo' );
    else
        legend( 'echo / CS616' );
    end    

    %don't advance until user clicks
    % waitforbuttonpress();
    hold off;
    
    psname = 'C:\cygwin\home\Tim\GLand_SWC.ps';
    print('-dpsc2', psname, '-append', '-loose', sprintf('-f%d', this_fig));
    close( this_fig );
end
ps2pdf( 'psfile', psname, ...
        'pdffile', strrep( psname, 'ps', 'pdf' ), ...
        'deletepsfile', 1 ); 
    
    