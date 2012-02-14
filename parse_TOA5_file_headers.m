function [ var_names, var_units, file_lines, first_data_line, delim ] = ...
        parse_TOA5_file_headers( fname )
% PARSE_TOA5_FILE_HEADERS - parse variable names and units for a specified TOA5
%   file.  Returns cell array of variable names, cell array of variable
%   units, cell array of full text of file, one line per cell, the first line
%   number that contains data, and the delimiter used in the file. 
%
% USAGE
%    [ var_names, var_units, file_lines ] = parse_TOA5_file_headers( infile )
%
% (c) Timothy W. Hilton, UNM, Feb 2012

    n_header_lines = 4;
    first_data_line = n_header_lines + 1;
    delim = detect_delimiter( fname );
    
    % read file one line at a time into a cell array of strings
    fid = fopen(fname, 'rt');
    file_lines = textscan(fid, '%s', 'delimiter', '\n', 'BufSize', 1e6);
    fclose(fid);
    file_lines = file_lines{1,1};
    
    % if quotes are present in the header line, use them to separate variable names
    % and units.  Some TOA5 files contain both quoted variable names that
    % contain the delimiter (!) (e.g. "soil_water_T(8,1)" in a comma-delimited
    % file) as well as unquoted variable names.  so, need a regular expression
    % that ferrets out tokens by "stuff between quotes" or "stuff between commas
    % but not quotes"
    
    re = sprintf( '(?:^|%s)(\"(?:[^\"]+|\"\")*\"|[^%s]*)', delim, delim );
    var_names = regexp( file_lines{ 2 }, re, 'tokens' );
    var_names = [ var_names{ : } ];  % 'unnest' the cell array
    var_units = regexp( file_lines{ 3 }, re, 'tokens' );
    var_units = [ var_units{ : } ];  % 'unnest' the cell array
    not_empty = not( cellfun( @isempty, var_names ) );
    var_names = var_names( not_empty );
    var_units = var_names( not_empty );

    % remove remaining quotation marks
    var_names = strrep( var_names, '"', '' );
    var_units = strrep( var_units, '"', '' );



