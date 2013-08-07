% script to convert fluxall files to text, and save session transcript to a file

[ y, mon, d, h, m, s ] = datevec( now() );
fname = fullfile( getenv( 'HOME' ), ...
                  'Matlab_Transcripts', ...
                  sprintf( '%s_matlab_transcript.txt', ...
                           datestr( now(), 'yyyy-mm-dd-HHMMSS' ) ) );
diary( fname );

% %for this_site = UNM_sites( [ 1, 2, 3, 4, 5, 6, 7 ] )
% for this_site = UNM_sites( [ 10, 11 ] )
%     for this_year = 2007:2011
%         try 
%             UNM_RemoveBadData_pre2012( this_site, this_year, ...
%                                        'draw_fingerprints', false, ...
%                                        'draw_plots', false, ...
%                                        'write_QC', true, ...
%                                        'write_GF', true, ...
%                                        'load_binary', true );
%             close all
%         catch err
%             % if an error occurs, write the message and continue with next year
%             disp( getReport( err ) );
%         end
%     end
% end

%for this_site = UNM_sites( [ 1, 2, 3, 4, 5, 6, 7 ] )
for this_site = UNM_sites( [ 5,6 ] )
    for this_year = 2010:2011
        try 
            UNM_fill_met_gaps_from_nearby_site( this_site, ...
                                                this_year, ...
                                                'draw_plots', false );
        catch err
            % if an error occurs, write the message and continue with next year
            disp( getReport( err ) );
        end
        fprintf( '==================================================\n' );
    end
end

% for this_site = UNM_sites.TX
%     for this_year = 2007:2010
%         try 
%             UNM_RemoveBadData_pre2012( this_site, this_year, ...
%                                        'draw_fingerprints', false, ...
%                                        'draw_plots', false, ...
%                                        'write_QC', true, ...
%                                        'write_GF', true );
%             close all
%         catch err
%             % if an error occurs, write the message and continue with next year
%             disp( getReport( err ) );
%         end
%     end
% end

diary off