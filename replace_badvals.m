function arr = replace_badvals(arr, badvals, tol)
% REPLACE_BADVALS - where arr equal to any element of badval, replaces with NaN
% 
% USAGE
%     arr = replace_badvals( arr, badvals, tol )
%
% INPUTS
%     arr: array in which to replace bad values
%     badvals: array of values to be replace with NaN
%     tol: floating point tolerance for comparison
%
% OUTPUTS
%     arr: input array with specified bad values replaced with NaNs
%
% (c) Timothy W. Hilton, UNM
    
    badvals = reshape(badvals, 1, numel(badvals));
    badval_idx = zeros(size(arr));
    
    for i = 1:length(badvals)
        
        badval_idx = badval_idx | abs(arr - badvals(i)) < tol;
        arr(badval_idx) = NaN;
        
    end
