function UNM_site_plot_doy_time_offsets( sitecode, year, doy )
% UNM_SITE_PLOT_DOY_TIME_OFFSETS - 
%
% USAGE
%   UNM_site_plot_doy_time_offsets( sitecode, year, doy )
% 
% INPUTS
%   sitecode: integer or UNM_sites object
%   year: integer: the year requested
%   doy: integer: the day of year to plot
%
% OUTPUTS
%   no outputs
%
% (c) Timothy W. Hilton, UNM, June 2012

data = parse_forgapfilling_file( sitecode, year, '' );
sol_ang = UNM_get_solar_angle( sitecode, data.timestamp );
opt_off = match_solarangle_radiation( data.Rg, ...
                                      sol_ang, ...
                                      data.timestamp, ...
                                      doy, year, true );

