function sol_el = get_solar_elevation( sitecode, t_mst )
% GET_SOLAR_ELEVATION - calculate solar elevation angle given UNM sitecode and
%   timestamps
%
% USAGE
%   el = get_solar_elevation( sitecode, t )
%
% INPUTS
%   sitecode: UNM site, UNM_sites object or integer
%   t_mst: matlab datenums, mountain standard time (MST)
%
% OUTPUTS
%   sol_el: solar elevation angle, degrees
%
% (c) Timothy W. Hilton, UNM, June 2012

% convert UTC <-> MST
seven_hours = 7 / 24;  % seven hours in units of days
utc2mst = @( t ) t - seven_hours;
mst2utc = @( t ) t + seven_hours;

sd = parse_UNM_site_table();

lat = repmat( sd.Latitude( sitecode ), numel( t_mst ), 1 );
lon = repmat( sd.Longitude( sitecode ), numel( t_mst ), 1 );
site_el = repmat( sd.Elevation( sitecode ), numel( t_mst ), 1 );

t_utc = mst2utc( t_mst );
[ ~, sol_el ] = arrayfun( @( t, lat, lon, alt ) ...
                       SolarAzEl( t, lat, lon, alt / 1000 ) , ...
                       t_utc, lat, lon, site_el );
