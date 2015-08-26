function T_out = table_vertcat_fill_vars( varargin )
% TABLE_VERTCAT_FILL_VARS - create a new table by vertically concatenating
% all input arguments, preserving all variables present in any input.
%
% T_out has all variables present anywhere in input tables.  When an input
% table is missing an output variable, the variable is added and to the
% table and populated with NaN.
%
% USAGE
%    T_out = table_vertcat_fill_vars( ds1, ds2, ... );
%
% INPUTS
%    variable; two or more table arrays
%
% OUTPUTS
%    T_out: table array; the concatenated input tables with all
%        variables filled as described above.
%
% SEE ALSO
%    table
%
% author: Gregory E. Maurer, UNM, Feb 2015. 
% Modified from dataset version by Timothy Hilton.

all_vars = varargin{1}.Properties.VariableNames;
for i = 2:numel( varargin )
    all_vars = union( all_vars, varargin{i}.Properties.VariableNames );
end

for i = 1:numel( varargin )
    new_vars = setdiff( all_vars, varargin{i}.Properties.VariableNames );
    for j = 1:numel( new_vars )
        varargin{ i }.( new_vars{ j } ) = ...
            NaN( size( varargin{ i }, 1 ), 1 );
    end
end

% now all tables have the same variables
T_out = vertcat( varargin{ : } );
                                                    
