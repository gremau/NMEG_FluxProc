sites = [ 1, 2, 3, 4, 5, 6, 10 ];

for i = 1:numel( sites )
    for y = 2009:2010
        UNM_RemoveBadData( sites( i ), y );
    end
end

UNM_RemoveBadData( 11, 2010 );