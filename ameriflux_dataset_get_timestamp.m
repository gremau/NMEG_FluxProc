function  ds  = ameriflux_dataset_get_timestamp( ds )
% AMERIFLUX_DATASET_GET_TIMESTAMP - add a matlab datenum timestamp field to a
%   dataset containing parsed ameriflux data.
    
    previous_year_31Dec = datenum( ds.YEAR, 1, 0 );
    hours_per_day = 24;
    minutes_per_day = 24 * 60;
    
    ds.timestamp = previous_year_31Dec + ...
        ds.DOY + ...
        ( floor( ds.HRMIN / 100 ) / hours_per_day ) + ...
        ( mod( ds.HRMIN, 100 ) / minutes_per_day );
