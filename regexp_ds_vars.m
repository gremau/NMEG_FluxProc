function [ vars, varargout ] = regexp_ds_vars( ds, re )
% REGEXP_DS_VARS - returns cell array of strings of variable names from dataset
%   ds that match regular expression re
%
% USAGE
%    vars = regexp_ds_vars( ds, re )
%    [ vars, idx ] = regexp_ds_vars( ds, re )
%
% INPUTS
%    ds: Matlab dataset
%    re: string; regular expression to match against dataset variable names
%
% OUTPUTS
%    vars: cell array of strings; variable names from ds that match re
%    idx: optional; vector of column indices of the matches
%
% (c) Timothy W. Hilton, UNM, Jan 2012
    
    vars = regexp( ds.Properties.VarNames, re, 'match' );
    idx = find( ~cellfun( 'isempty', vars ) );
    vars = ds.Properties.VarNames( idx );

    varargout = { idx };
