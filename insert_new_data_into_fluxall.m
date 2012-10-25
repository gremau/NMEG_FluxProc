function fluxall = insert_new_data_into_fluxall( new_data, ...
                                                 fluxall, ...
                                                 varargin )
% INSERT_NEW_DATA_INTO_FLUXALL - inserts new data into fluxall.  Default is to
%   take care not to overwrite data from the fluxall with NaNs from new
%   data, but this can be turned off.  new_data and fluxall must have
%   complete timestamp records (no missing 30-minute timestamps).

p = inputParser;
p.addRequired( 'new_data', @( x ) isa( x, 'dataset' ) );
p.addRequired( 'fluxall', @( x ) isa( x, 'dataset' ) );
p.addOptional( 'allow_NaNs', false, @islogical );
p.parse( new_data, fluxall, varargin{ : } );

new_data = p.Results.new_data;
fluxall = p.Results.fluxall;
allow_NaNs = p.Results.allow_NaNs;

t_new_min = min( new_data.timestamp );
t_new_max = max( new_data.timestamp );

% make sure fluxall is sorted by increasing timestamp (it should be
% already, but the insertion will get messed up if it isn't for some
% reason). 
[ ~, idx_sort ] = sort( fluxall.timestamp );
fluxall = fluxall( idx_sort, : );

idx_replace = find( ( fluxall.timestamp >= t_new_min ) & ...
                    ( fluxall.timestamp <= t_new_max ) );

% % the code below doesn't deal with new_data having more or fewer columns than
% % fluxall.  For now just ignore the NaN issue

% data_to_replace = double( fluxall( idx_replace, : ) );
% new_data = double( new_data );
% if not( allow_NaNs ) 
%     if size( data_to_replace ) ~= size( new_data )
%         warning( ['new_data is not the same size as the fluxall section ' ...
%                   'to replace'] );
%     else
%         new_data( isnan( new_data ) ) = ...
%             data_to_replace( isnan( new_data ) );
%     end
% end

fluxall( idx_replace, : ) = [];
fluxall = dataset_append_common_vars( fluxall, new_data );

% resort fluxall timestamps
[ ~, idx_sort ] = sort( fluxall.timestamp );
fluxall = fluxall( idx_sort, : );    

