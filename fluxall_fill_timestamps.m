function fluxall = fluxall_fill_timestamps( fluxall )
% FLUXALL_FILL_TIMESTAMPS - makes sure a FLUXALL dataset has a complete record of 30-minute timestamps
%   

year = mode( fluxall.year );

fluxall = dataset_fill_timestamps( fluxall, ...
                                   'timestamp', ...
                                   't_min', datenum( year, 1, 1, 0, 30, 0 ) );

t = fluxall.timestamp;
[ fluxall.year, fluxall.month, fluxall.day, ...
  fluxall.hour, fluxall.min, fluxall.second ] = datevec( t );
fluxall.jday = t - datenum( year, 1, 0 );
fluxall.date = ( fluxall.month * 1e4 + ...
                 fluxall.day * 1e2 + ...
                 mod( fluxall.year, 1000 ) );

