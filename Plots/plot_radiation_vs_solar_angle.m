function this_fig = plot_radiation_vs_solar_angle( sitecode, year )
% PLOT_RADIATION_VS_SOLAR_ANGLE - plot site-year time series of incoming
% shortwave, hilighting gap-filled and nighttime data points.
%
% Incoming shortwave time series is read from the gapfilled Ameriflux file
% (which must be readable by parse_ameriflux_file( get_ameriflux_filename(
% sitecode, year, 'gapfilled' ) ).  Nighttime is defined as solar angle < 0,
% where solar angle is determined by SolarAzEl.
%
% This plot is useful for scanning Ameriflux data for implausible nighttime
% radiation values.
%
% SEE ALSO
%    SolarAzEl, parse_ameriflux_file, get_ameriflux_filename
%
% author: Timothy W. Hilton, UNM, June 2012

fname = get_ameriflux_filename( sitecode, ...
                                year, ...
                                'gapfilled' );
this_data = parse_ameriflux_file( fname );
this_data.timestamp = datenum( year, 1, 0 ) + this_data.DTIME;
%this_data.SolEl = get_solar_elevation( sitecode, this_data.timestamp );

conf = parse_yaml_config(UNM_sites(sitecode), 'SiteVars');
solCalcs = noaa_solar_calcs(conf.latitude, conf.longitude, ...
    this_data.timestamp);
this_data.SolEl = 90 - solCalcs.solarZenithAngleDeg;

pal = cbrewer( 'qual', 'Dark2', 8 );
t_str = sprintf( '%s %d', ...
                 UNM_sites_info( sitecode ).long_name, ...
                 year );
this_fig = figure( 'NumberTitle', 'off', ...
                   'Name', t_str );
h_all = plot( this_data.DTIME, this_data.Rg, '.k' );
ylabel( 'Rg' );
xlabel( 'index' );
title( t_str );
hold on;
idx = find( this_data.SolEl < 0 );
h_sundown = plot( this_data.DTIME( idx ), ...
                  this_data.Rg( idx ), ...
                  '.', 'Color', pal( 1, : ) );
idx = find( this_data.Rg_flag );
h_filled = plot( this_data.DTIME( idx ), ...
                 this_data.Rg( idx ), ...
                 'o', 'Color', pal( 2, : ) );
h_50 = refline( 0, 50 );
set( h_50, 'LineWidth', 2 );

legend( [ h_all, h_sundown, h_filled, h_50 ], ...
        '', 'solar angle < 0', 'filled', 'Rg = 50', ...
        'Location', 'best' );
    

