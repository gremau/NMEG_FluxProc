function T = cr23x_2_table( fname )
% CR23X_2_Table - parse a Campbell Scientific CR23X file to a matlab table
% array.
%
% Determines variable names, file size, and delimiter and loads file.  
% Adds a 'timestamp' variable of the file's timestamps converted to
% Matlab serial datenumbers. Removes datalogger "bad data" codes (usually
% -9999 or similar) and replaces with NaN values.
%
% INPUTS:
%    fname: string; full path of file to be parsed
%
% OUTPUTS:
%    T: matlab table array; the data from the TOA5 file
%
% SEE ALSO
%    table, datenum
%
% author: Gregory E Maurer, UNM,  2015

% Read the lines of the data file into a cell array
[ numlines, file_lines ] = parse_file_lines( fname );
% Separate the file lines from the header
% header = file_lines(1);
file_lines = file_lines( 2:end );

% Get the delimiter
delim = detect_delimiter( fname );

% Read the data file into a table.
newT = readtable( fname , 'Delimiter', delim );

% Count the number of columns in the file
n_numeric_vars = length( newT.Properties.VariableNames );

% Find invalid timestamps (NaN in any time column)
invalid_tstamps = ( isnan( newT.Year_RTM ) |...
    isnan( newT.Day_RTM ) |...
    isnan( newT.Hour_Minute_RTM ) );

% Remove invalid timestamps from table and raw file lines
newT = newT( not( invalid_tstamps ), : );
file_lines = file_lines( not( invalid_tstamps ));

% Count the number of numerics in each line of the raw data file
fmt = repmat( sprintf( '%%f%s', delim ), 1, n_numeric_vars );
[ ~ , count ] = cellfun( @(x) sscanf( x( 1:end ), fmt ), ...
    file_lines, ...
    'UniformOutput', false );

% Transpose count cell into an array
count = cell2mat(count)';

% Reject lines with fewer than n_numeric_vars readable numbers
short_lines = count < n_numeric_vars;
newT = newT( not( short_lines ), : );

% replace -9999 and -99999 with NaN
badValues = [ -9999, 9999, -99999, 99999 ];
newT = replace_badvals( newT, badValues, 1e-6 );

T =  newT;

% Beware that there is a problem with how cr23x dataloggers create date
% strings. Midnight is (always?) logged as 24:00 of the preceding day.
% MATLAB parses this as 00:00 of that day, meaning that midnight is moved
% 24 hours back in time. Fix this by changing all 24:00 time periods to
% 00:00 and incrementing the day.
fix_cr23x_tstamp = T.Hour_Minute_RTM==2400;
T.Hour_Minute_RTM( fix_cr23x_tstamp ) = 0;
T.Day_RTM( fix_cr23x_tstamp ) = T.Day_RTM( fix_cr23x_tstamp ) + 1;
% Add a timestamp
hourminute_prepend = num2str( T.Hour_Minute_RTM, '%04i' );
[ ~, ~, ~, hour, min ] = datevec( hourminute_prepend( :, : ), 'HHMM' );
proto_dn = datenum( T.Year_RTM, 1, 1, hour, min, 0 );
dn = proto_dn + T.Day_RTM - 1;

T.timestamp = dn;


