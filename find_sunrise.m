function [ sunrise_obs, sunrise_calc ] = find_sunrise( ds, sitecode, year )
% FIND_RUNRISE - Finds sunrise for each day in the dataset ds.  ds must
%   contain data from only one calendar year.

sd = parse_UNM_site_table();
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
