sites = [ 1, 2, 4, 6 ];

for i = 1:numel( sites )
    for y = [ 2007, 2008 ]
        UNM_RemoveBadData( sites( i ), y );
        close all
        %UNM_Ameriflux_file_maker_TWH( sites( i ), y );
    end
end

