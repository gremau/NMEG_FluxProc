function T = cr23x_2_table( fname )
% TOA5_2_DATASET - parse a Campbell Scientific TOA5 file to a matlab dataset
% array.
%
% Uses parse_TOA5_file_headers to determine variable names, variable units,
% file size, and delimiter.  Adds a 'timestamp' variable of the file's
% timetamps converted to Matlab serial datenumbers.  Uses clean_up_varnames
% to convert variable names to legal Matlab variables.
%
% INPUTS:
%    fname: string; full path of file to be parsed
%
% OUTPUTS:
%    ds: matlab dataset array; the data from the TOA5 file
%
% SEE ALSO
%    dataset, datenum, parse_TOA5_file_headers, clean_up_varnames
%
% author: Timothy W. Hilton, UNM, Oct 2011

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

T =  newT;

% Add a timestamp
hourminute_prepend = num2str( T.Hour_Minute_RTM, '%04i' );
[ ~, ~, ~, hour, min ] = datevec( hourminute_prepend( :, : ), 'HHMM' );
proto_dn = datenum( T.Year_RTM, 1, 1, hour, min, 0 );
dn = proto_dn + T.Day_RTM - 1;

T.timestamp = dn;


