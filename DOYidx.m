function idx = DOYidx( DOY )
% DOYIDX - calculates the array index for a specified day of year (DOY) assuming
% 30-minute observation interval (48 observations per day).  DOY may be
% fractional or integral.
%
% USAGE
%    idx = DOYidx( DOY )
%
% (c) Timothy W. Hilton, UNM, June 2012

obs_per_day = 48;
idx = int32( ( obs_per_day * DOY ) - obs_per_day + 1 );