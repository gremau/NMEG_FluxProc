function ds_filled = dataset_fill_timestamps(ds, t_var, delta_t)
% DATASET_FILL_TIMESTAMPS - fill in missing timestamps in a dataset containing a
% regularly-spaced time series
% INPUTS:
%   ds: dataset to be filled
%   t_var: string containing the name of the time variable (e.g. 'TIMESTAMP')
%   delta_t: interval of the time series, in days.  e.g., 30 mins should have
%            delta_t value of 1/48.
%
% Timothy W. Hilton, UNM, Dec. 2011

    t_min = min( ds.( t_var ) );
    t_max = max( ds.( t_var ) );

    full_ts = ( t_min : delta_t : t_max )';
    full_ts = cellstr( datestr( full_ts, 'mm/dd/yyyy HH:MM:SS' ) );
    
    ds.( t_var ) = cellstr( datestr( ds.( t_var ), ...
                                     'mm/dd/yyyy HH:MM:SS' ) );

    %% create a dataset containing the filled timestamps
    ds_filled = dataset( { full_ts,  t_var } );
    
    %% fill in the timestamps in ds, adding NaNs in all variables where
    %% missing timestamps were added
    [ ds_filled, Aidx, Bidx ] = join( ds_filled, ...
                                      ds, ...
                                      'Keys', t_var, ...
                                      'Type', 'LeftOuter', ...
                                      'MergeKeys', true );

    
    

    

