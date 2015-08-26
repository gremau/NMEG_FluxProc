function fluxall = fluxall_fill_timestamps( fluxall )
% FLUXALL_FILL_TIMESTAMPS - Make sure a UNM annual fluxall file timestamp
% record is complete and unambiguous.
%
% makes sure a FLUXALL dataset has a complete record
% of 30-minute timestamps using dataset_fill_timestamps and that all
% timestamp-related fields (jday, date) for added timestamps are non-nan.
% Begins each year's fluxall file at 00:30:00 on 1 Jan as per UNM convention.
%  
% INPUTS:
%    fluxall: table array; parsed fluxall data (arbitrary site and year)
%
% OUTPUTS:
%    fluxall: table array; fluxall data with complete record of 30-minute
%        timestamps 
%
% SEE ALSO:
%     table_fill_timestamps
%
% author: Timothy W. Hilton, UNM, Dec 2012
% Modified to use tables by Greg Maurer, 2015

year = mode( fluxall.year );

fluxall = table_fill_timestamps( fluxall, ...
                                 'timestamp', ...
                                 't_min', datenum( year, 1, 1, 0, 30, 0 ) );

t = fluxall.timestamp;
[ fluxall.year, fluxall.month, fluxall.day, ...
  fluxall.hour, fluxall.min, fluxall.second ] = datevec( t );
fluxall.jday = t - datenum( year, 1, 0 );
fluxall.date = ( fluxall.month * 1e4 + ...
                 fluxall.day * 1e2 + ...
                 mod( fluxall.year, 1000 ) );

