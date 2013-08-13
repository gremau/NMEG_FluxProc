function par_norm = normalize_PAR( sitecode, par, doy, draw_plots, par_max )
% NORMALIZE_PAR - normalizes the 98.8th percentile of observed PAR to a
% specified maximum.  
%
% 98.8th percetile was chosen visually; this value seems to work well for
% producing a smooth annual cycle of PAR.
%
% USAGE:
%     par_norm = normalize_PAR( sitecode, par, doy, draw_plots, par_max );
%
% INPUTS:
%     sitecode: UNM_sites object; the site to normalize
%     par: unnormalized PAR
%     doy: day of year (used for plotting)
%     draw_plots: true|false; if true, draw a "before/after" plot
%     par_max: value to normalize 98.8 percentile of PAR to
%   
% OUTPUTS
%     par_norm: normalized PAR
%
% SEE ALSO
%     UNM_sites
% 
% author: Timothy W. Hilton, UNM, 2013

doy = floor( doy );
norm_factor = par_max / prctile( par, 99.8 );
par_norm = par * norm_factor;

if draw_plots
    figure( 'NumberTitle', 'off', ...
            'Name', 'PAR normalization' );

    max_par = nanmax( [ par, par_norm ] );

    pal = cbrewer( 'qual', 'Dark2', 8 );
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
