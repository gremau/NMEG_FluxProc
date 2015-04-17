function [ vars, varargout ] = regexp_ds_vars( ds, re )
% REGEXP_DS_VARS - returns cell array of strings of variable names from dataset
% array ds that match regular expression re
%
% FIXME - this function is deprecated. It is being superseded by 
%           regexp_header_vars.m
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
% SEE ALSO
%    dataset, regexp
%
% author: Timothy W. Hilton, UNM, Jan 2012

warning( 'This function ( regexp_ds_vars ) is deprecated!' );
    
    vars = regexp( ds.Properties.VarNames, re, 'match' );
    idx = find( ~cellfun( 'isempty', vars ) );
    vars = ds.Properties.VarNames( idx );

    varargout = { idx };
