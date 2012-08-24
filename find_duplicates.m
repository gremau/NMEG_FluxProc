function [ dupindx, dupvals ] = find_duplicates2( A )
% FIND_DUPLICATES - returns duplicated rows in A
%
% USAGE:
%     [ dupindx, dupvals ] = find_duplicates2( A )

[b, m, n]=unique(A) ;
dupindx=find(diff(sort(m))>1)+1 ;
dupvals=A(dupindx) ; 