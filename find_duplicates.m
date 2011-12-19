function dupvals = find_duplicates(A)
% FIND_DUPLICATES - returns duplicated rows in A

[b, m, n]=unique(A) ;
dupindx=find(diff(sort(m))>1)+1 ;
dupvals=A(dupindx) ; 