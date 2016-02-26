function  ds  = ameriflux_dataset_get_timestamp( ds )
% AMERIFLUX_DATASET_GET_TIMESTAMP - add a timestamp field of Matlab serial
% datenumbers to a dataset containing parsed ameriflux data.
%
% Ameriflux files contain their timestamp information in these variables:
% YEAR: integer four-digit year
% DOY: integer day of year
% HRMIN: integer hour and minutes in the format 000, 030, 100, 130, 200, 230,
%     etc. (for the 30-minute timestamps between 00:00 and 02:20).
% DTIME: fractional day of year
%
% ameriflux_dataset_get_timestamp adds a "timestamp" column containing matlab
% serial datenumbers for the timestamps present in ds.YEAR, ds.DOY, and
% ds.HRMIN.  ds must contain the timestamp variables YEAR, DOY, HRMIN.
%
% USAGE
%    ds  = ameriflux_dataset_get_timestamp( ds );
%
% INPUTS
%    ds: Matlab dataset array; parsed ameriflux data.  The output of
%        parse_ameriflux_file or UNM_parse_both_ameriflux_files may be passed
%        directly as ds.n
%
% OUTPUTS
%    ds: Matlab dataset array; input dataset with "timestamp" column added.
%
% SEE ALSO
%    dataset, datenum, parse_ameriflux_file, UNM_parse_both_ameriflux_files
%
% author: Timothy W. Hilton, UNM, 2012

warning( 'This function ( ameriflux_dataset_get_tstamp.m ) is deprecated' );
    
if ismember('TIMESTAMP', ds.Properties.VarNames)
    
    ds.timestamp = datenum( num2str( ds.TIMESTAMP ), 'YYYYmmDDHHMMSS' );
    
else % The old files have no timestamp
    previous_year_31Dec = datenum( ds.YEAR, 1, 0 );
    hours_per_day = 24;
    minutes_per_day = 24 * 60;
    
    ds.timestamp = previous_year_31Dec + ...
        ds.DOY + ...
        ( floor( ds.HRMIN / 100 ) / hours_per_day ) + ...
        ( mod( ds.HRMIN, 100 ) / minutes_per_day );
end
