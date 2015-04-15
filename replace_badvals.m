function arr = replace_badvals(arr, badvals, tol)
% REPLACE_BADVALS - replace specifed values within an array with NaN, with
% floating point comparison 
% 
% (see, for example, http://support.microsoft.com/kb/69333,
% http://en.wikipedia.org/wiki/Floating_point).
%
% Elements of arr that are equal to any element of badvals are replaced with NaN.
% 
% USAGE
%     arr = replace_badvals( arr, badvals, tol )
%
% INPUTS
%     arr: array or dataset array in which to replace bad values
%     badvals: array of values to be replace with NaN
%     tol: tolerance for floating point comparison; floating point values
%         that differ by less than tol are considered equal.
%
% OUTPUTS
%     arr: input array with specified bad values replaced with NaNs
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM
    
arg_is_dataset = false;
if isa( arr, 'dataset' )
    arg_is_dataset = true;
    arr_arg = arr;
    arr = double( arr );
end

badvals = reshape( badvals, 1, [] );
badval_idx = zeros( size( arr ) );

for i = 1:length(badvals)
    
    badval_idx = badval_idx | abs(arr - badvals(i)) < tol;
    arr(badval_idx) = NaN;
    
end

% if argument was a dataset, convert it back
if ( arg_is_dataset )
    arr = replacedata( arr_arg, arr );
end
