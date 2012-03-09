sites = [ 2, 3, 4, 5, 6, 10, 11 ];
years = [ 2009 ];

%sites = [ 4 ];
%years = [ 2010 ];

for s = 1:numel( sites )
    for y = 1:numel( years )
        try
            result = process_TOB1_year( sites( s ), years( y ) );
        catch err
            disp( getReport( err ) );
        end
    end
end