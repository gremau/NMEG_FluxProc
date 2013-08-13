function hh = hourly_pcp_2_half_hourly( pcp, timestamps )
% HOURLY_PCP_2_HALF_HOURLY - convert a time series of hourly precipitation
% observations to half hourly.
%
% Both half-hourly observations from a given hour are set to half the full-hour
% observation
% 
% USAGE:
%     hh = hourly_pcp_2_half_hourly( pcp, timestamps )
%
% INPUTS:
%     pcp: double array of hourly pcp observations
%     timestamps: datenum array of hourly timetamps
%
% OUTPUTS:
%     hh: matlab dataset object containing half-hourly pcp and timestamps
%
% SEE ALSO
%     datenum
%
% author: Timothy W. Hilton, UNM, July 2012

thirty_min = 1/48;  % thirty minutes in units of days

% make sure we have row vectors of doubles
pcp = reshape( double( pcp ), 1, [] );
timestamps = reshape( double( timestamps ), 1, [] );

hh_pcp = (reshape( repmat( pcp, 2, 1 ), 1, [] ) )' / 2.0;
hh_timestamps = ( reshape( [ timestamps; timestamps + thirty_min ], 1, [] ) )';
hh = dataset( { [ hh_pcp, hh_timestamps ], 'pcp' ,'timestamp' } );