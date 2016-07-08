function  tab  = ameriflux_table_get_timestamp( tab )
% AMERIFLUX_TABLE_GET_TIMESTAMP - add a timestamp field of Matlab serial
% datenumbers to a table containing parsed ameriflux data.
%
% Ameriflux files contain their timestamp information in these variables:
% YEAR: integer four-digit year
% DOY: integer day of year
% HRMIN: integer hour and minutes in the format 000, 030, 100, 130, 200, 230,
%     etc. (for the 30-minute timestamps between 00:00 and 02:20).
% DTIME: fractional day of year
%
% USAGE
%    tab  = ameriflux_table_get_timestamp( tab );
%
% INPUTS
%    tab: Matlab table array; parsed ameriflux data.  The output of
%        parse_ameriflux_file or UNM_parse_both_ameriflux_files may be passed
%        directly as tab.n
%
% OUTPUTS
%    tab: Matlab table array; input table with "timestamp" column added.
%
% SEE ALSO
%    table, datenum, parse_ameriflux_file, UNM_parse_both_ameriflux_files
%
% author: Timothy W. Hilton, UNM, 2012
% modified by Gregory E. Maurer, UNM, Feb 2016
    
if ismember('TIMESTAMP', tab.Properties.VariableNames)
    
    tab.timestamp = datenum( num2str( tab.TIMESTAMP ), 'YYYYmmDDHHMMSS' );
    
else % The old files have no timestamp
    previous_year_31Dec = datenum( tab.YEAR, 1, 0 );
    hours_per_day = 24;
    minutes_per_day = 24 * 60;
    
    tab.timestamp = previous_year_31Dec + ...
        tab.DOY + ...
        ( floor( tab.HRMIN / 100 ) / hours_per_day ) + ...
        ( mod( tab.HRMIN, 100 ) / minutes_per_day );
end
