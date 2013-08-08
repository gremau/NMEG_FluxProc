function [ dupindx, dupvals ] = find_duplicates( A )
% FIND_DUPLICATES - returns the indices of duplicated rows in A and the
% values in those rows
%
% USAGE:
%     [ dupindx, dupvals ] = find_duplicates( A )
%
% INPUTS
%     A: numeric array; the array to search for duplicated rows
%
% OUTPUTS
%     dupindx: the indices of duplicated rows
%     dupvals: the values in the duplicated rows; that is A( dupidx ).
%
% author: Timothy W. Hilton, UNM, Dec 2011
[b, m, n]=unique(A) ;
dupindx=find(diff(sort(m))>1)+1 ;
dupvals=A(dupindx) ; 