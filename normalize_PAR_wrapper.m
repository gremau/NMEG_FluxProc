function [ Par_Avg ] = normalize_PAR_wrapper( sitecode, year_arg, ...
                                              decimal_day, Par_Avg, ...
                                              draw_plots )
% NORMALIZE_PAR_WRAPPER - normalize PAR to account for calibration problems at
% some sites.This is a helper function for UNM_RemoveBadData.  It is not
% intended to be called on its own.  Input and output arguments are defined in
% UNM_RemoveBadData.
%
% USAGE:
%       [ Par_Avg ] = normalize_PAR_wrapper( sitecode, year_arg, ...
%                                            decimal_day, Par_Avg, ...
%                                            draw_plots );
%
% (c) Timothy W. Hilton, UNM, 2013

if ismember( sitecode, [ 1, 2, 3, 4, 10, 11 ] );
    if ( sitecode == 3 ) & ( year_arg == 2008 )
        % there is a small but suspicious-looking step change at DOY164 -
        % normalize the first half of the year separately from the second
        doy164 = DOYidx( 164 );
        Par_Avg1 = normalize_PAR( sitecode, ...
                                  Par_Avg( 1:doy164 ), ...
                                  decimal_day( 1:doy164 ), ...
                                  draw_plots );
        Par_Avg2 = normalize_PAR( sitecode, ...
                                  Par_Avg( (doy164 + 1):end ), ...
                                  decimal_day( (doy164 + 1):end ), ...
                                  draw_plots );
        Par_Avg = [ Par_Avg1; Par_Avg2 ];

    elseif ( sitecode == 10 ) & ( year_arg == 2010 )
        % two step changes in this one
        doy138 = DOYidx( 138 );
        doy341 = DOYidx( 341 );
        Par_Avg1 = normalize_PAR( sitecode, ...
                                  Par_Avg( 1:doy138 ), ...
                                  decimal_day( 1:doy138 ), ...
                                  draw_plots );
        Par_Avg2 = normalize_PAR( sitecode, ...
                                  Par_Avg( doy138+1:doy341 ), ...
                                  decimal_day( doy138+1:doy341 ), ...
                                  draw_plots );
        Par_Avg = [ Par_Avg1; Par_Avg2; Par_Avg( doy341+1:end ) ];
    else
        Par_Avg = normalize_PAR( sitecode, ...
                                 Par_Avg, ...
                                 decimal_day, ...
                                 draw_plots );
    end
end

% fix calibration problem at JSav 2009
if ( sitecode == 3 ) & ( year_arg == 2009 )
    Par_Avg( 1:1554 ) = Par_Avg( 1:1554 ) + 133;
end
Par_Avg( Par_Avg < -50 ) = NaN;

% ------------------------------------------------------------

function par_norm = normalize_PAR( sitecode, par, doy, draw_plots )
% NORMALIZE_PAR - normalizes PAR to a site-specific maximum.
%   

if ismember( sitecode, 5:9 )
    fprintf( 'PAR normalization not yet implemented for %s\n', ...
             char( UNM_sites( sitecode ) ) );
end

par_max = 2500;
doy = floor( doy );
norm_factor = par_max / prctile( par, 99.8 );
par_norm = par * norm_factor;

if draw_plots
    figure( 'NumberTitle', 'off', ...
            'Name', 'PAR normalization' );

    max_par = nanmax( [ par, par_norm ] );

    pal = brewer_palettes( 'Dark2' );
    h_par = plot( doy, par, 'ok' );
    hold on;
    h_par_norm = plot( doy, par_norm, 'x', 'Color', pal( 1, : ) );
    hold off;
    ylabel( 'PAR [W/m^2]' );
    xlabel( 'DOY' );
    legend( [ h_par, h_par_norm ], 'PAR (obs)', 'PAR (normalized)', ...
            'Location', 'best' );
end

%------------------------------------------------------------
