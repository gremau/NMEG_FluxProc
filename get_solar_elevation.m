function sol_el = get_solar_elevation( sitecode, t_mst )
% GET_SOLAR_ELEVATION - calculate solar elevation angle given UNM sitecode and
% timestamps.
%
% sunrise is calculated by SolarAzEl
% (http://www.mathworks.com/matlabcentral/fileexchange/file_infos/23051-vectorized-solar-azimuth-and-elevation-estimation)
% based on the latitude, longitude, and elevation specified by sitecode (as
% determined by parse_UNM_site_table).
%
% USAGE
%   sol_el = get_solar_elevation( sitecode, t_mst )
%
% INPUTS
%   sitecode: UNM site, UNM_sites object or integer
%   t_mst: N-element vector of matlab serial datenumbers, mountain standard time (MST)
%
% OUTPUTS
%   sol_el: solar elevation angle, degrees
%
% SEE ALSO
%   SolarAzEl, datenum, parse_UNM_site_table
%
% author: Timothy W. Hilton, UNM, June 2012

% convert UTC <-> MST
seven_hours = 7 / 24;  % seven hours in units of days
utc2mst = @( t ) t - seven_hours;
mst2utc = @( t ) t + seven_hours;

sd = parse_UNM_site_table();

lat = repmat( sd.Latitude( sitecode ), size( t_mst ) );
lon = repmat( sd.Longitude( sitecode ), size( t_mst ) );
site_el = repmat( sd.Elevation( sitecode ), size( t_mst ) );

t_utc = mst2utc( t_mst );
[ ~, sol_el ] = arrayfun( @( t, lat, lon, alt ) ...
                       SolarAzEl( t, lat, lon, alt / 1000 ) , ...
                       t_utc, lat, lon, site_el );
