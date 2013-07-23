function ds_out = dataset_vertcat_fill_vars( varargin )
% DATASET_VERTCAT_FILL_VARS - create a new dataset by vertically concatenating
%   all input arguments.  ds_out has all variables present anywhere in input
%   datasets.  When an input dataset is missing an output variable, the
%   variable is added and to the dataset and populated with NaN.
%
% USAGE
%    ds_out = dataset_vertcat_fill_vars( ds1, ds2, ... );
%
% INPUTS
%    variable; two or more dataset arrays
%
% OUTPUTS
%    ds_out: dataset array; the concatenated input datasets with all
%        variables filled as described above.
%
% SEE ALSO
%    dataset
%
% (c) Timothy W. Hilton, UNM, Feb 2012
    
    all_vars = varargin{1}.Properties.VarNames;
    for i = 2:numel( varargin )
        all_vars = union( all_vars, varargin{i}.Properties.VarNames );
    end
    
    for i = 1:numel( varargin )
        new_vars = setdiff( all_vars, varargin{i}.Properties.VarNames );
        for j = 1:numel( new_vars )
            varargin{ i }.( new_vars{ j } ) = ...
                            repmat( NaN, ...
                                    size( varargin{ i }, 1 ), 1 );
        end
    end
    
    % now all datasets have the same variables
    ds_out = vertcat( varargin{ : } );
                                                    
