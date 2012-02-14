function [ ds_out1, ds_out2 ] = merge_datasets_by_datenum( ds_in1, ds_in2, ...
                                                      tvar1, tvar2, ...
                                                      tol, ...
                                                      t_start, t_end )
% MERGE_DATASETS_BY_DATENUM - fills in two 30-minute timeseries datasets so
% that both have identical timestamps.  Where a timestamp is present in A but
% not B, adds the timestamp to B and fills data with NaNs.  Timestamps within
% tol minutes of a "round" half hour (e.g. 00 or 30 minutes past the hour)
% are rounded to the nearest half hour.  Rows with timestamps not within tol
% minutes of a "round" half hour are discarded.
    
    mins_per_day = 24 * 60;
    days_per_30mins = 1 / 48;  %% 30 mins expressed in days
    
    %remove duplicate timestamps
    dup_tol = 0.00000001;  %floating point tolerance
    dup_idx = find( diff( ds_in1.( tvar1 ) ) < dup_tol ) + 1;
    ds_in1( dup_idx, : ) = [];
    dup_idx = find( diff( ds_in2.( tvar2 ) ) < dup_tol ) + 1;
    ds_in2( dup_idx, : ) = [];

    % use 00:00 on the first date in either timeseries as the reference date
    t0 = floor( min( [ double( ds_in1( :, tvar1 ) ); ...
                       double( ds_in2( :, tvar2 ) ); ...
                       t_start; ...
                       t_end ] ) );
    
    [ ts1, keep_idx1 ] = datenum_2_round30min( ds_in1.( tvar1 ), tol, t0 );
    [ ts2, keep_idx2 ] = datenum_2_round30min( ds_in2.( tvar2 ), tol, t0 );

    % round t_end to nearest 30 min value
    [ t_end_round, keep_idx_end ] = ...
        datenum_2_round30min( t_end, tol, t0 );

    % replace both datasets' timestamps with the "round" values
    ds_in1 = ds_in1( keep_idx1, : );
    ds_in1.( tvar1 ) = ts1;
    ds_in2 = ds_in2( keep_idx2, : );
    ds_in2.( tvar2 ) = ts2;

    %% combine timestamps & remove duplicates 
    ts_all = union( ts1, ts2 );

    %% fill both datasets so that they contain complete 30-minute timeseries
    %% for the entire range of ts_all
    ds_out1 = dataset_fill_timestamps( ds_in1, tvar1, days_per_30mins, ...
                                       min( ts_all ), max( ts_all ) );
    
    ds_out2 = dataset_fill_timestamps( ds_in2, tvar2, days_per_30mins, ...
                                       min( ts_all ), max( ts_all ) );
    
    % convert timestamps from strings back to matlab datenums
    ds_out1.( tvar1 ) = datenum( ds_out1.( tvar1 ) );
    ds_out2.( tvar2 ) = datenum( ds_out2.( tvar2 ) );
    

