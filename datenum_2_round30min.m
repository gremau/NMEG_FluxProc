function [ ts, t0 ] = datenum_2_round30min(ds_in, time_var, tol, t0)
% MERGE_DATASETS_BY_DATENUM - fills in two 30-minute timeseries datasets so
% that both have identical timestamps.  Where a timestamp is present in A but
% not B, adds the timestamp to B and fills data with NaNs.  Timestamps within
% tol minutes of a "round" half hour (e.g. 00 or 30 minutes past the hour)
% are rounded to the nearest half hour.  Rows with timestamps not within tol
% minutes of a "round" half hour are discarded.

%% pull out the timestamp column
ts = double( ds_in( :, time_var ) );

%% convert matlab datenums to seconds since 00:00 of the day of the first
%% timestamp in the series 
secs_per_day = 24 * 60 * 60;
ts = ( ts - t0 ) * secs_per_day;
ts = int32( ts );

%% express 30 minutes as seconds
secs_per_30min = int32( 30 * 60 );
%% convert tol to seconds
tol_secs = int32( tol * 60 );

%% figure out how far away is each timestamp from a "round" half hour
secs_from_prev_half_hour = mod( ts, secs_per_30min );

%% discard data more than tol minutes from a round half hour
keep_idx = ( secs_from_prev_half_hour <= tol_secs | ...
             secs_from_prev_half_hour >= ( secs_per_30min - tol_secs ) );
ts = ts( keep_idx );
ds_in = ds_in( keep_idx, : );

%% convert timestamps from seconds past t0 to thirty-minute intervals past
%% t0; seconds now expressed as fractions 
ts = double( ts ) / double( secs_per_30min );

%% round timestamps to nearest round half hour
ts = int32( round( ts ) );

%% convert back to minutes past t0
ts = ts * 30;

