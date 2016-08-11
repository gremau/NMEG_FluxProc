function T = table_append_common_vars( varargin )
% TABLE_APPEND_COMMON_VARS - vertically concatenates input table arrays,
%   ignoring variables that are not common to all inputs.
%
% USAGE
%    T = table_append_common_vars( T1, T2, T3, ... )
%
% INPUTS
%    T1, T2, ...: table arrays to be concatenated.  Any number of inputs
%        may be passed.  ALL inputs must be table arrays.
%
% OUTPUTS
%    T: table array; concatenated input tables with variables not common
%        to all inputs removed.
%
% SEE ALSO
%    table
%
% author: Gregory E. Maurer, UNM, Aug 2015
% based on dataset version by Timothy W. Hilton, UNM, Oct 2012

fill_vars = true;

if nargin == 0
    error( 'at least two input arguments are required' );
end

% make sure all inputs are table arrays
inputs_are_tables = cellfun( @( x ) isa( x, 'table' ), varargin );
if not( inputs_are_tables )
    error( 'all inputs must be table arrays' );
end

if fill_vars
    % keep all variables that exist in *any* input table; where a variable
    % does not exist, fill with NaN
    all_vars = cellfun( @(x) x.Properties.VariableNames, ...
        varargin, ...
        'UniformOutput', false );
    all_vars = unique( horzcat( all_vars{ : } ) );
    for i = 1:nargin
        this_missing_vars = setdiff( all_vars, ...
            varargin{ i }.Properties.VariableNames );
        nan_array = NaN( size( varargin{ i }, 1 ), 1 );
        for j = 1:numel( this_missing_vars );
            fprintf( 'filling %s\n', this_missing_vars{ j } );
            varargin{ i }.( this_missing_vars{ j } ) = nan_array;
        end
    end
% else
%     % identify and remove variables not common to all tables
%     
%     % identify variables common to all tables
%     common_vars = varargin{ 1 }.Properties.VariableNames;
%     for i = 2:nargin
%         [ ~, ia, ib ] = ...
%             intersect( common_vars, varargin{ i }.Properties.VariableNames );
%         % intersect sorts its output -- put the columns back in their original
%         % order
%         common_vars = common_vars( sort( ia ) );
%     end
%     
%     unique_vars = cell( 1, nargin );
%     for i = 1:nargin
%         unique_vars{ i } = setdiff( varargin{ i }.Properties.VariableNames,...
%             common_vars );
%         varargin{ i } = varargin{ i }( :, common_vars );
%     end
end

% concatenate  into single table array
T = vertcat( varargin{ : } );

% if not( fill_vars )
%     % write a message noting the variables that were ignored
%     for i = 1:nargin
%         these_vars = replace_hex_chars( unique_vars{ i } );
%         if not( isempty( these_vars ) )
%             fprintf( 'ignored from input %d: ', i );
%             for j = 1:numel( these_vars )
%                 fprintf( '%s ', these_vars{ j } );
%             end
%             fprintf( '\n' );
%         end
%     end
% end