function optimal_offset = ...
    match_solarangle_radiation( rad, sol, t, this_doy, year, debug )
% MATCH_SOLARANGLE_RADIATION - find the time offset that results in the best
% match of sunrise in observed radiation to calculated sunrise.
%
% This is a quite low-level function.  Plots of THEORETICAL sunrise vs
% OBSERVED radiation by site-year as available from UNM_site_plot_doy_time_offsets
% and UNM_site_plot_fullyear_time_offsets.
%
% USAGE
%   optimal_offset = ...
%        match_solarangle_radiation( rad, sol, t, this_doy, year, debug );
%
% INPUTS
%   rad: 1xN numeric; OBSERVED solar radiation
%   sol: 1xN numeric: THEORETICAL solar angle (as from SolarAzEl)
%   t: 1xN matlab serial datenumbers: timestamps for rad and sol
%   this_doy: 0 < this_doy <= 366; the day of year to calculate offset
%   year: four digit year
%   debug: true|false; if true, draws diagnostic plots
%
% OUTPUTS
%   optimal_offset: the offset, in hours, to ADD to t to make the daily cycle
%       in rad for this_doy most closely match the daily cycle in sol for
%       this_doy
%
% SEE ALSO
%   SolarAzEl, UNM_site_plot_doy_time_offsets,
%   UNM_site_plot_fullyear_time_offsets 
%
% Author: Timothy W. Hilton, UNM, Jan 2012
% RJL modified sunrise angle from 0 to -0.8333 to account for refraction
% and the size of solar disk.

doy = t - datenum( year, 1, 0 );
idx_doy_start = min( find( floor( doy ) == this_doy ) );
hours_12 = 24;  % observation interval is 30 mins; therefore 24 obs = 12 hours

% If there aren't any data for this day, return NaN.
if ( ( this_doy < floor( min( doy ) ) ) || ...
     ( this_doy > floor( max( doy ) ) ) )
    optimal_offset = NaN;
    return
end

% Search a +/- five hour range of potential time offsets.
n_obs = 10; % observation interval is 30 mins; therefore 10 obs = 5 hours

this_rad = rad( idx_doy_start : ...
                min( idx_doy_start + hours_12, numel( rad ) ) );  
this_sol = sol( idx_doy_start : ...
                min( idx_doy_start + hours_12, numel( sol ) ) );

% if any( diff( this_sol ) < 0 )
%     warning( sprintf( 'solar angle is not monotonically increasing: doy %d', ...
%                       this_doy ) );
% end

% Sunrise according to THEORETICAL solar angle.
idx_sol_sunrise = min( find( this_sol > -0.8333 ) );
% Sunrise according to OBSERVED radiation.
rad_diff = [ NaN; reshape( diff( this_rad ), [], 1 ) ];
idx_rad_sunrise = min( find( rad_diff > 5.0 ) );

% Optimal time offset matches THEORETICAL solar angle sunrise to OBSERVED
% radiation sunrise.
hours_per_observation = 0.5; % observation interval is 30 minutes
optimal_offset = ( idx_rad_sunrise - idx_sol_sunrise ) * hours_per_observation;

if ( isempty( optimal_offset ) )
    optimal_offset = NaN;
end

if numel( find( ~isnan( this_rad ) ) ) < 5
    optimal_offset = NaN;
end

if debug %Plot
    figure()
    plot_idx = idx_doy_start : idx_doy_start + hours_12;

    plot_rad = @( x, y ) plot( x, y, '.k' );
    plot_sol = @( x, y ) plot( x, y, 'ob' );

    [ ax, h_sol, h_rad ] = plotyy( t( plot_idx ), this_sol, ...
                                   t( plot_idx ), rad_diff, ...
                                   plot_sol, plot_rad );    
    hold( ax( 1 ), 'on' );
    h_x = plot( ax( 1 ), ...
                t( idx_doy_start -1 + idx_sol_sunrise ), ...
                this_sol( idx_sol_sunrise ), ...
                'xb' );    
    set( h_x, 'MarkerSize', 12 );
    hold( ax( 1 ), 'off' );
    hold( ax( 2 ), 'on' );
    h_x = plot( ax( 2 ), ...
                t( idx_doy_start - 1 + idx_rad_sunrise ), ...
                rad_diff( idx_rad_sunrise ), ...
                'xk' );
    set( h_x, 'MarkerSize', 12 );
    
    % Draw reference line at solar angle = 0.
    % axes( ax ( 1 ) );
    h_ref = refline( 0, 0 );
    set( h_ref, 'LineStyle', ':' );
    % Label stuff.
    datetick( ax( 1 ), 'x', 'HH:MM' );
    datetick( ax( 2 ), 'x', 'HH:MM' );
    set( ax( 2 ), 'XTick', [ ] );
    legend( [ h_sol, h_rad, h_x ], ...
            'Solar angle', 'radiation difference', 'sunrise', ...
            'Location', 'best' );
    title( sprintf( 'DOY: %d, offset: %0.2f hours', ...
                    this_doy, ...
                    optimal_offset ) );
end

