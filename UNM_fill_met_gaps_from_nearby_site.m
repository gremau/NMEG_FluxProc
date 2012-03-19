function result = UNM_fill_met_gaps_from_nearby_site( site_code, year, draw_plots )
% UNM_FILL_MET_GAPS_FROM_NEARBY_SITE - fills gaps in site's meteorological data
%   from the closest nearby site
%
% USAGE
%     result = UNM_fill_met_gaps_from_nearby_site(site_code, year)
%
% INPUTS
%     site_code [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%
% OUTPUTS
%     result [ integer ]: 0 on success, -1 on failure
%
% (c) Timothy W. Hilton, UNM, March 2012
    
    
% assign each site a paired site to fill gaps from
nearby_site = [ 2, ...   % GLand -- SLand
                1, ...   % SLand -- GLand
                1, ...   % JSav -- GLand (check this one!)
                9, ...   % PJ -- PJ girdle
                6, ...   % PPine -- MCon
                5, ...   % MCon -- PPine
                NaN, ... % TX -- ?
                NaN, ... % TX -- ?
                NaN, ... % TX -- ?
                4, ...   % PJ_girdle -- PJ
                2 ];     % New_GLand -- GLand
                
fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
         get_site_name( nearby_site( site_code ) ), year );
nearby_data = parse_forgapfilling_file( nearby_site( site_code ), year );

fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
         get_site_name( site_code ), year );
this_data = parse_forgapfilling_file( site_code, year );

%--------------------------------------------------
% fill T, plot if requested

% replace missing Tair with nearby site
Tair_idx = isnan( this_data.Tair );
n_valid_fillins = numel( find( ~isnan( nearby_data.Tair( Tair_idx ) ) ) );
this_data.Tair( Tair_idx ) = nearby_data.Tair( Tair_idx );
fprintf( 'Tair: replaced %d / %d missing observations\n', ...
         n_valid_fillins, ...
         numel( find( Tair_idx ) ) );

if draw_plots
    % calculate day of year for 30-minute data
    h_T_fig = figure();
    doy = ( 1:size( this_data, 1 ) ) / 48.0;
    h_obs = plot( doy, this_data.Tair, '.k' );
    hold on;
    h_filled = plot( doy( find( Tair_idx ) ), nearby_data.Tair( find( Tair_idx ) ), ...
                     '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    ylabel( 'Tair (C)' );
    xlabel( 'day of year' );
    legend( [ h_obs, h_filled ], 'observed', 'filled' );
end

%--------------------------------------------------
% fill RH, plot if requested

% replace missing RH with nearby site
rH_idx = isnan( this_data.rH );
n_valid_fillins = numel( find( ~isnan( nearby_data.rH( rH_idx ) ) ) );
this_data.rH( rH_idx ) = nearby_data.rH( rH_idx );
fprintf( 'rH: replaced %d / %d missing observations\n', ...
         n_valid_fillins, ...
         numel( find( rH_idx ) ) );
fprintf( '-----\n' );

if draw_plots
    % calculate day of year for 30-minute data
    h_RH_fig = figure();
    doy = ( 1:size( this_data, 1 ) ) / 48.0;
    h_obs = plot( doy, this_data.rH, '.k' );
    hold on;
    h_filled = plot( doy( find( rH_idx ) ), nearby_data.rH( find( rH_idx ) ), ...
                     '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    ylabel( 'RH (%)' );
    xlabel( 'day of year' );
    legend( [ h_obs, h_filled ], 'observed', 'filled' );
end

result = this_data;