% run UNM_Ameriflux_file_maker for multiple sites.  Continues processing with
% next site if an error is encountered.

close all
clear all

sitecodes = [ 1, 2, 3, 4, 5, 6, 10, 11 ];
sitecodes = [ 10, 11 ];

for i = 1:numel(sitecodes)
    for y = 2009:2011
        try
            fprintf( '-------------\nrunning %s -- %d\n', ...
                     get_site_name( sitecodes( i ) ), y );
            result = UNM_Ameriflux_file_maker( sitecodes( i ), y );
        catch err
            % if an error occurs, display and message and keep going
            keyboard()
            disp( getReport( err ) );
        end
    end
end
