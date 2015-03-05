function ds = dataset_append_common_vars( varargin )
% DATASET_APPEND_COMMON_VARS - vertically concatenates input dataset arrays,
%   ignoring variables that are not common to all inputs.
%
% FIXME - Deprecated. This function is being superseded by 
% 'table_append_common_vars.m'
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
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, Oct 2012

warning( 'This function ( dataset_append_common_vars.m ) is deprecated' );

fill_vars = true;

if nargin == 0
    error( 'at least two input arguments are required' );
end

% make sure all inputs are dataset arrays
inputs_are_datasets = cellfun( @( x ) isa( x, 'dataset' ), varargin );
if not( inputs_are_datasets )
    error( 'all inputs must be dataset arrays' );
end

if fill_vars
    % keep all variables that exist in *any* input dataset; where a variable
    % does not exist, fill with NaN
    all_vars = cellfun( @(x) x.Properties.VarNames, ...
                        varargin, ...
                        'UniformOutput', false );
    all_vars = unique( horzcat( all_vars{ : } ) );
    for i = 1:nargin
        this_missing_vars = setdiff( all_vars, varargin{ i }.Properties.VarNames );
        nan_array = repmat( NaN, size( varargin{ i }, 1 ), 1 );
        for j = 1:numel( this_missing_vars );
            fprintf( 'filling %s\n', this_missing_vars{ i } );
            varargin{ i }.( this_missing_vars{ j } ) = nan_array;
        end
    end
else
    % identify and remove variables not common to all datasets

    % identify variables common to all datasets
    common_vars = varargin{ 1 }.Properties.VarNames;
    for i = 2:nargin
        [ ~, ia, ib ] = ...
            intersect( common_vars, varargin{ i }.Properties.VarNames );
        % intersect sorts its output -- put the columns back in their original
        % order
        common_vars = common_vars( sort( ia ) );
    end
    
    unique_vars = cell( 1, nargin );
    for i = 1:nargin
        unique_vars{ i } = setdiff( varargin{ i }.Properties.VarNames, common_vars );
        varargin{ i } = varargin{ i }( :, common_vars );
    end
end

% concatenate  into single dataset array
save( 'data.mat' );
ds = vertcat( varargin{ : } );

if not( fill_vars )
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
end