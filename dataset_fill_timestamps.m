function ds_filled = dataset_fill_timestamps(ds, t_var, delta_t)
% DATASET_FILL_TIMESTAMPS - fill in missing timestamps in a dataset containing a
% regularly-spaced time series
%   

    t_min = min( ds.( t_var ) );
    t_max = max( ds.( t_var ) );

    full_ts = ( t_min : delta_t : t_max )';
    
    %% create a dataset containing the filled timestamps
    ds_filled = dataset( { full_ts,  t_var } );
    
    %% fill in the timestamps in ds, adding NaNs in all variables where
    %% missing timestamps were added
    [ ds_filled, Aidx, Bidx ] = join( ds_filled, ...
                                      ds, ...
                                      'Keys', t_var, ...
                                      'Type', 'LeftOuter', ...
                                      'MergeKeys', true );

    
    

    

