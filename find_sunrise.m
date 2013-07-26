function [ sunrise_obs, sunrise_calc ] = find_sunrise( ds, sitecode, year )
% FIND_RUNRISE - Finds the observed and theoretical sunrise for each day in the
% dataset ds.  ds must contain data from only one calendar year.  The
% theoretical sunrise is calculated by SolarAzEl
% (http://www.mathworks.com/matlabcentral/fileexchange/file_infos/23051-vectorized-solar-azimuth-and-elevation-estimation)
% based on the latitude, longitude, and elevation specified by sitecode (as
% determined by parse_UNM_site_table). Observed sunrise is defined as the first
% timestamp of the day at which incoming shortwave radiation (Rg) exceeds 5 w
% m-2.
% 
% INPUTS
%    ds: dataset array; data from which to extract the dates and observed
%        sunrise times.  ds must contain fields Rg, from which observed sunrise
%        is calculated, and DTIME, from which the observed time of sunrise is
%        calculated.  ds.Rg should be in units of w m-2.  ds.DTIME must contain
%        the fractional day of year.
%    sitecode: UNM_sites object; which UNM site the data in ds represent
%    year: integer; which year the data represent
%
% OUTPUTS
%    sunrise_obs: 366 element numerical vector; the observed sunrise times
%        from ds in hours past 00:00 for each day of year.  sunrise_obs( 366 )
%        equals NaN for non-leap years.
%    sunrise_calc: 366 element numerical vector; the calculated sunrise times
%        from SolarAzEl in hours past 00:00 for each day of year. sunrise_obs( 366 )
%        equals NaN for non-leap years.
%
% SEE ALSO
%    dataset, SolarAzEl, UNM_sites, parse_UNM_site_table,
%    get_solar_elevation, parse_UNM_site_table
%
% (c) Timothy W. Hilton, UNM, June 2012

sd = parse_UNM_site_table();

% convert Mountain standard time to and from UTC
utc2mst = @( t ) t - ( 7 / 24 );
mst2utc = @( t ) t + ( 7 / 24 );

doy = floor( ds.DTIME );
sunrise_obs = repmat( NaN, 366, 1 );
sunrise_calc = repmat( NaN, 366, 1 );

for d = 1:366
    this_data = ds( doy == d, : );
    idx = find( this_data.Rg > 5 );
    t = this_data.HRMIN( min( idx ) );
    if not( isempty( t ) )
        sunrise_obs( d ) = floor( t / 100 ) + ( mod( t, 100 ) / 60 );
    end
    
    times = mst2utc( ( datenum( year, 1, 0 ) + d ) : ...
                     ( 1/48 ) : ...
                     ( datenum( year, 1, 0 ) + d + 1 ) )';
    lat = repmat( sd.Latitude( UNM_sites.MCon ), numel( times ), 1 );
    lon = repmat( sd.Longitude( UNM_sites.MCon ), numel( times ), 1 );
    alt = repmat( sd.Elevation( UNM_sites.MCon ), numel( times ), 1 );
    [ az, el ] = arrayfun( @( t, lat, lon, alt ) ...
                           SolarAzEl( t, lat, lon, alt / 1000 ) , ...
                           times, lat, lon, alt );
    times = utc2mst( times );
    sr_calc = times( min( find( el > 0 ) ) );
    [ ~, ~, ~, HH, MM, ~ ] = datevec (sr_calc );
    sunrise_calc( d ) = HH + ( MM / 60 );

    % if ismember( d, [ 100, 165, 270 ] )
    %     figure();
    %     h_Rg = plot( this_data.DTIME, this_data.Rg, '.k' );
    %     hold on
    %     h_par = plot( this_data.DTIME, this_data.PAR, 'xr' );
    %     xlabel( 'DOY' );
    %     ylabel( 'Rg' );
    %     ylim( [ -100, nanmax( [ nanmax( this_data.PAR ), ...
    %                         nanmax( this_data.Rg ) ] ) ] );
    %     title( sprintf( 'DOY %d', d ) );
    %     legend( [ h_Rg, h_par ], 'Rg', 'PAR' );
    %     % hold on
    %     % plot( this_data.DTIME( idx ), this_data.Rg( idx ), '.r' );
    %     hold off
        
    %     figure();
    %     plot( times, el, '.k' );
    %     set( gca, 'XGrid', 'on' );
    %     ylabel( 'solar angle' );
    %     datetick( 'x', 'HH:MM' );
    %     hl = refline( 0, 0 );
    %     set( hl, 'Color', 'black' );
    % end;

    
end
