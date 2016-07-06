function filled_series = median_fill_series(series, window)
% Fill gaps in a timeseries with the running median. It should fill 
% all NaN's with a median value. This can be usefull for running mean and
% variance calculations.
%
% Interpolates over NaNs (data gaps) in the input time series (may be
% complex) using interp1 function. If there are leading or trailing NaN's
% in the series, they are set to the mean of the entire dataset.
%
% WARNING: If series contains only NaN's, interp1 throws an error, so this
% function simply returns the original series of NaN's if this is the case.
%
% author: Gregory E. Maurer, University of Utah

if sum(isnan(series))==length(series)
    filled_series = series;
else
    filled_series = series;
    bad = isnan(series);
    good = find(~bad);
    
    % Old option to skip interpolation of NaNs at either end of the series.
    % bad([1:(min(good)-1) (max(good)+1):end]) = 0;
    
    % Fill in all Nans using the running median
    runningM = slidefun(@nanmedian, window, filled_series);

    % Resulting stat is shifted forward in phase by window/2, shift it back
    runningM = circshift(runningM, -floor(window/2));
    filled_series(bad)=runningM(bad);
    
    % If there were NaNs at either end of the series, fill them with the
    % mean of the good data
    filled_series([1:(min(good)-1) (max(good)+1):end]) = nanmean(series);
end
