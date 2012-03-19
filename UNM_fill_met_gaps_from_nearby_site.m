function result = UNM_fill_met_gaps_from_nearby_site( site_code, year )
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
    
% initialize
result = -1;
    
% assign each site a paired site to fill gaps from ( destination -- source )
nearby_site = [ 2, ...   % GLand -- SLand
                1, ...   % SLand -- GLand
                4, ...   % JSav -- GLand (use the met station, then PJ)
                9, ...   % PJ -- PJ girdle
                6, ...   % PPine -- MCon  (use met station)
                5, ...   % MCon -- PPine  (use met station)
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

% replace missing Tair with nearby site
Tair_idx = isnan( this_data.Tair );
n_valid_fillins = numel( find( ~isnan( nearby_data.Tair( Tair_idx ) ) ) );
this_data.Tair( Tair_idx ) = nearby_data.Tair( Tair_idx );
fprintf( 'Tair: replaced %d / %d missing observations\n', ...
         n_valid_fillins, ...
         numel( find( Tair_idx ) ) );
                
% replace missing RH with nearby site
rH_idx = isnan( this_data.rH );
n_valid_fillins = numel( find( ~isnan( nearby_data.rH( rH_idx ) ) ) );
this_data.rH( rH_idx ) = nearby_data.rH( rH_idx );
fprintf( 'rH: replaced %d / %d missing observations\n', ...
         n_valid_fillins, ...
         numel( find( rH_idx ) ) );
fprintf( '-----\n' );

export( this_data, 'file', 'test_export.txt' );

result = 0;