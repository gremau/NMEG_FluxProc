function hh = hourly_pcp_2_half_hourly( pcp, timestamps )
% HOURLY_PCP_2_HALF_HOURLY - convert a time series of hourly precipitation
% observations to half hourly, with both half-hourly observations from a given
% hour half the full-hour observation
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
% (c) Timothy W. Hilton, UNM, July 2012

mins30 = 1/48;  % thirty minutes in units of days

% make sure we have row vectors of doubles
pcp = reshape( double( pcp ), 1, [] );
timestamps = reshape( double( timestamps ), 1, [] );

hh_pcp = (reshape( repmat( pcp, 2, 1 ), 1, [] ) )' / 2.0;
hh_timestamps = ( reshape( [ timestamps; timestamps + mins30 ], 1, [] ) )';
hh = dataset( { [ hh_pcp, hh_timestamps ], 'pcp' ,'timestamp' } );