function [ filled_idx, ds_for_gapfill ] = ...
        UNM_gapfill_from_local_data( sitecode, year, ds_for_gapfill )
% UNM_GAPFILL_FROM_LOCAL_DATA - 
%   

obs_per_day = 48;

if ( sitecode == 3 ) & ( year == 2009 )
    % JSav has no flux data for roughly 1 Dec 2008 to 1 Mar 2009.  The
    % gapfiller has trouble with this large gap at the beginning of 2009, so
    % here we fill the first 21 days with JSav 2008 data.  Hopefully the
    % gapfiller can "calibrate" from these data and produce a better fit for
    % the remaining gap.
    
    jsav08 = parse_forgapfilling_file( 3, 2008, '' );
    filled_idx = 1 : ( obs_per_day * 21 ); %first 21 days of the year
    
    % fill NEE, LE, and H for 1 to 21 Jan 2009 from 1 to 21 Jan 2008
    ds_for_gapfill.NEE( filled_idx ) = jsav08.NEE( filled_idx );
    ds_for_gapfill.qcNEE( filled_idx ) = ...
        isnan( jsav08.NEE( filled_idx ) ) + 1; % 2 for bad data, 1 for good
    ds_for_gapfill.LE( filled_idx ) = jsav08.LE( filled_idx );
    ds_for_gapfill.H( filled_idx ) = jsav08.H( filled_idx );
end