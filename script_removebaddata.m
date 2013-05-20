% script to convert fluxall files to text, and save session transcript to a file

[ y, mon, d, h, m, s ] = datevec( now() );
fname = sprintf( 'C:\\Users\\Tim\\Matlab_Transcripts\\%d-%02d-%02d_%02d%02d_matlab_transcript.txt', ...
                 y, mon, d, h, m );
diary( fname );

for this_site = UNM_sites( [ 1, 2, 3, 4, 6, 5, 10, 11 ] )
    for this_year = 2007:2011
        try 
            UNM_RemoveBadData_pre2012( this_site, this_year, ...
                                       'draw_fingerprints', false, ...
                                       'draw_plots', false, ...
                                       'write_QC', false, ...
                                       'write_GF', false );
            close all
        catch err
            % if an error occurs, write the message and continue with next year
            disp( getReport( err ) );
        end
    end
end

diary off