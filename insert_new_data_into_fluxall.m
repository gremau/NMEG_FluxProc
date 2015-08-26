function fluxall = insert_new_data_into_fluxall( new_data, ...
                                                 fluxall, ...
                                                 varargin )
% INSERT_NEW_DATA_INTO_FLUXALL - inserts new data into existing fluxall data.  
%
%   new_data and fluxall must have complete timestamp records (no missing
%   30-minute timestamps).  Variables that do not occur in both new_data and
%   fluxall will be discarded in the output.  Output is sorted
%   chronologically by timestamps.
%
% USAGE: 
%    fluxall = insert_new_data_into_fluxall( new_data, fluxall );
%
% INPUTS
%    new_data: table array: the data to be inserted to fluxall table
%    fluxall: table array; existing fluxall data (may be output of
%        UNM_parse_fluxall_txt_file) 
%
% OUTPUTS
%    fluxall: fluxall input with new_data inserted.
%
% SEE ALSO
%    table, UNM_parse_fluxall_txt_file
%
% author: Timothy W. Hilton, UNM, Oct 2012
% Modified to use tables by Greg Maurer, 2015

p = inputParser;
p.addRequired( 'new_data', @( x ) isa( x, 'table' ) );
p.addRequired( 'fluxall', @( x ) isa( x, 'table' ) );
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
dup_tol = 0.00000001;  %floating point tolerance
dup_idx = find( diff( fluxall.timestamp ) < dup_tol ) + 1;
fluxall( dup_idx, : ) = [];

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
fluxall = table_append_common_vars( fluxall, new_data );

% resort fluxall timestamps
[ ~, idx_sort ] = sort( fluxall.timestamp );
fluxall = fluxall( idx_sort, : );    

fluxall = fluxall_fill_timestamps( fluxall );

