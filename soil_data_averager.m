function [ avg_soil_data, avg_by_cover, avg_by_depth ] = ...
    soil_data_averager( soil_data )
% SOIL_DATA_AVERAGER - calculates average soil data (moisture or temperature)
% within cover type, depth groups.  Also computes average by cover type.
%   
% USAGE:
%    [ avg_soil_data, avg_by_cover, avg_by_depth ] = ...
%         soil_data_averager( soil_data )
%
% INPUTS:
%    soil_data: dataset; one column per soil observation.  Variables must be
%        named with format obs_cover_idx_depth_*, where obs is the measurmement
%        (e.g. 'soilT', 'VWC', etc., cover is the cover type ('open', 'pinon',
%        etc.), depth is the depth (2p5, 12p5, etc.), and * is arbitrary text.
%
% OUTPUTS:
%    avg_soil_data: dataset containing average observations for each
%         cover/depth pair.
%    avg_by_cover: average across all depths by cover type
%    avg_by_depth: average across all covers by depth
%
% (c) Timothy W. Hilton, UNM, April 2012

% if there is only one column of data, there is no averaging to do
if ( size( soil_data, 2 ) == 1 )
    avg_soil_data = soil_data;
    avg_by_cover = soil_data;
    avg_by_depth = soil_data;
    return;
end

grp_vars = regexp( soil_data.Properties.VarNames, '_', 'split' );
grp_vars = vertcat( grp_vars{ : } ); 

var = unique( grp_vars( :, 1 ) );  %variable (Tsoil, cs616) is 1st
                                   %underscore-delimited field
covers = unique( grp_vars( :, 2 ) );  %cover is 2nd underscore-delimited field
depths = unique( grp_vars( :, 4 ) );  %depth is 4th underscore-delimited field
                
switch var{ 1 }
  case 'cs616SWC'
    prefix = 'VWC';
  case 'soilT'
    prefix = 'Tsoil';
  case 'SHF'
    prefix = 'SHF';
  otherwise
    error( sprintf( [ 'label prefix should be either' ...
                      '"cs616SWC", "soilT", or "SHF".  It is "%s".' ], ...
                    var{ 1 } ) );
end

% -----
% calculate average at each depth by cover type
% -----

avg_soil_data_vars = cell( 1, numel( covers) * numel( depths ) );
avg_soil_data = repmat( NaN, ...
                        size( soil_data, 1 ), ...
                        numel( avg_soil_data_vars ) );

soil_data = double( soil_data );
count = 1;
for this_cov = 1:numel( covers )
    for this_depth = 1:numel( depths )
        avg_soil_data_vars{ count } = sprintf( '%s_%s_%s', ...
                                               prefix, ...
                                               covers{ this_cov }, ...
                                               depths{ this_depth } );
        idx = strcmp( grp_vars( :, 4 ), depths( this_depth ) ) & ...
              strcmp( grp_vars( :, 2 ), covers( this_cov ) );
        
        avg_soil_data( :, count ) = nanmean( soil_data( :, idx ), 2 );
        count = count + 1;
    end
end

avg_soil_data = dataset( { avg_soil_data, avg_soil_data_vars{ : } } );

% -----
% calculate average across all depths by cover type
% -----

avg_by_cover_vars = cell( 1, numel( covers ) );
avg_by_cover = repmat( NaN, size( soil_data, 1 ), numel( covers ) );

for this_cov = 1:numel( covers )
    idx = strcmp( grp_vars( :, 2 ), covers( this_cov ) );

    avg_by_cover( :, this_cov ) = nanmean( soil_data( :, idx ), 2 );

    avg_by_cover_vars{ this_cov } = sprintf( '%s_%s_Avg', ...
                                             prefix, covers{ this_cov } );
end

avg_by_cover = dataset( { avg_by_cover, avg_by_cover_vars{ : } } );

for this_depth = 1:numel( depths )
    idx = strcmp( grp_vars( :, 4 ), depths( this_depth ) );

    % % display the groupings for debugging 
    % disp( grp_vars( find( idx ) , : ) );
    % disp( '----------' );
    
    avg_by_depth( :, this_depth ) = nanmean( soil_data( :, idx ), 2 );

    avg_by_depth_vars{ this_depth } = sprintf( '%s_%s_Avg', ...
                                             prefix, depths{ this_depth } );
end

avg_by_depth = dataset( { avg_by_depth, avg_by_depth_vars{ : } } );
