function uidx = find_unique( A )
% FIND_DUPLICATES - returns indices of first occurence of each unique element
% of A
%
% USAGE:
%     uidx = find_unique( A )

% find index to first occurence of each unique element of A
[ ~, uidx, ~ ] = unique( A, 'first' );


