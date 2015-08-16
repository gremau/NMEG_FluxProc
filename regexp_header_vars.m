function [ vars, varargout ] = regexp_header_vars( arr, re )
% REGEXP_HEADER_VARS - returns cell array of strings of variable names
% from table or dataset arr that match regular expression re
%
% USAGE
%    vars = regexp_header_vars( arr, re )
%    [ vars, idx ] = regexp_header_vars( arr, re )
%
% INPUTS
%    arr: Matlab table or dataset array
%    re: string; regular expression to match against dataset variable names
%
% OUTPUTS
%    vars: cell array of strings; variable names from arr that match re
%    idx: optional; vector of column indices of the matches
%
% SEE ALSO
%    dataset, table,  regexp
%
% author: Timothy W. Hilton, UNM, Jan 2012
% Modified by Gregory E. Maurer, UNM, April 2015

if isa( arr, 'dataset' )
    vars = regexp( arr.Properties.VarNames, re, 'match' );
    idx = find( ~cellfun( 'isempty', vars ) );
    vars = arr.Properties.VarNames( idx );
elseif isa( arr, 'table' );
    vars = regexp( arr.Properties.VariableNames, re, 'match' );
    idx = find( ~cellfun( 'isempty', vars ) );
    vars = arr.Properties.VariableNames( idx );
end

varargout = { idx };
