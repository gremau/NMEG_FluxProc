function sol_ang = UNM_get_solar_angle( sitecode, t )
% UNM_GET_SOLAR_ANGLE - calculate solar angle for given times, site
%   

mst2utc = @( t ) t + ( 7 / 24 );

if ~isa( sitecode, 'UNM_sites' )
    sitecode = UNM_sites( sitecode );
end

sd = parse_UNM_site_table();

lat = repmat( sd.Latitude( sitecode ), numel( t ), 1 );
lon = repmat( sd.Longitude( sitecode ), numel( t ), 1 );
alt = repmat( sd.Elevation( sitecode ), numel( t ), 1 );

[ ~, sol_ang ] = arrayfun( @( t, lat, lon, alt ) ...
                           SolarAzEl( mst2utc( t ), lat, lon, alt / 1000 ) , ...
                           t, lat, lon, alt );


