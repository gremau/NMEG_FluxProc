function arr = replace_badvals(arr, badvals, tol)
% REPLACE_BADVALS - where arr equal to any element of badval, replaces with
% NaN

    badvals = reshape(badvals, 1, numel(badvals));
    badval_idx = zeros(size(arr));
    
    for i = 1:length(badvals)
        
        badval_idx = badval_idx | abs(arr - badvals(i)) < tol;
        arr(badval_idx) = NaN;
        
    end
