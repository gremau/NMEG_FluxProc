function vars = regexp_ds_vars(ds, re)
% REGEXP_DS_VARS - returns cell array of strings of variable names from dataset
%   ds that match regular expression re
%
% (c) Timothy W. Hilton, UNM, Jan 2012
    
    vars = regexp( ds.Properties.VarNames, re, 'match' );
    vars = vars( ~cellfun( 'isempty', vars ) );
    vars = cellfun( @cell2mat, vars, 'UniformOutput', false ); 
