function optimal_offset = match_solarangle_radiation( rad, sol, t, this_doy, ...
                                                  year, debug )

doy = t - datenum( year, 1, 0 );
idx_doy_start = min( find( floor( doy ) == this_doy ) );
hours_12 = 24;  % observation interval is 30 mins; therefore 24 obs = 12 hours

% if there aren't any data for this day, return NaN
if ( ( this_doy < floor( min( doy ) ) ) | ...
     ( this_doy > floor( max( doy ) ) ) )
    optimal_offset = NaN;
    return
end

% ----
% search a +/- five hour range of potential time offsets
n_obs = 10; % observation interval is 30 mins; therefore 10 obs = 5 hours

this_rad = rad( idx_doy_start : idx_doy_start + hours_12 );
this_sol = sol( idx_doy_start : idx_doy_start + hours_12 );

% if any( diff( this_sol ) < 0 )
%     warning( sprintf( 'solar angle is not monotonically increasing: doy %d', ...
%                       this_doy ) );
% end

% sunrise according to calculated solar angle
idx_sol_sunrise = min( find( this_sol > 0 ) );
% sunrise according to observed radiation
rad_diff = [ NaN; diff( this_rad ) ];
idx_rad_sunrise = min( find( rad_diff > 5.0 ) );

% the optimal time offset matches solar angle sunrise to observed radiation
% sunrise
hours_per_observation = 0.5; % observation interval is 30 minutes
optimal_offset = ( idx_rad_sunrise - idx_sol_sunrise ) * hours_per_observation;

if ( isempty( optimal_offset ) )
    optimal_offset = NaN;
end

if numel( find( ~isnan( this_rad ) ) ) < 5
    optimal_offset = NaN;
end

if debug
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
    
    % draw reference line at solar angle = 0
    % axes( ax ( 1 ) );
    h_ref = refline( 0, 0 );
    set( h_ref, 'LineStyle', ':' );
    % label stuff
    datetick( ax( 1 ), 'x', 'HH:MM' );
    set( ax( 2 ), 'XTick', [ ] );
    legend( [ h_sol, h_rad ], 'Solar angle', 'radiation difference', ...
            'Location', 'best' );
    title( sprintf( 'DOY: %d, offset: %0.2f hours', ...
                    this_doy, ...
                    optimal_offset / 2 ) );
end

