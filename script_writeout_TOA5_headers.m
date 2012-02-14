date_start = datenum( 2009, 1, 1 );
date_end = datenum( 2011, 12, 31 ); 

sites = [ 1, 2, 3, 4, 5, 6, 10, 11 ];

for s = 1 : numel( sites )
    disp( TOA5_column_headers_2_csv( sites( s ), date_start, date_end ) );
end