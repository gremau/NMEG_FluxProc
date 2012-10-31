function ds = dataset_append_common_vars( varargin )
% DATASET_APPEND_COMMON_VARS - vertically concatenates input dataset arrays,
%   ignoring variables that are not common to all inputs.
%
% USAGE
%    ds = dataset_append_common_vars( ds1, ds2, ds3, ... )
%
% INPUTS
%    ds1, ds2, ...: dataset arrays to be concatenated.  Any number of inputs
%        may be passed.  ALL inputs must be dataset arrays.
%
% OUTPUTS
%    ds: dataset array; concatenated input datasets with variables not common
%        to all inputs removed.
%
% (c) Timothy W. Hilton, UNM, Oct 2012

if nargin == 0
    error( 'at least two input arguments are required' );
end

% make sure all inputs are dataset arrays
inputs_are_datasets = cellfun( @( x ) isa( x, 'dataset' ), varargin );
if not( inputs_are_datasets )
    error( 'all inputs must be dataset arrays' );
end

% identify variables common to all datasets
common_vars = varargin{ 1 }.Properties.VarNames;
for i = 2:nargin
    [ ~, ia, ib ] = ...
        intersect( common_vars, varargin{ i }.Properties.VarNames );
    % intersect sorts its output -- put the columns back in their original
    % order
    common_vars = common_vars( sort( ia ) );
end

% identify variables not common to all datasets
unique_vars = cell( 1, nargin );
for i = 1:nargin
    unique_vars{ i } = setdiff( varargin{ i }.Properties.VarNames, common_vars );
    varargin{ i } = varargin{ i }( :, common_vars );
end

% concatenate common variables into single dataset array
save( 'data.mat' );
ds = vertcat( varargin{ : } );

% write a message noting the variables that were ignored
for i = 1:nargin
    these_vars = replace_hex_chars( unique_vars{ i } );
    if not( isempty( these_vars ) )
        fprintf( 'ignored from input %d: ', i );
        for j = 1:numel( these_vars )
            fprintf( '%s ', these_vars{ j } );
        end
        fprintf( '\n' );
    end
end
    