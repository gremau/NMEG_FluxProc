function outfname = TOA5_column_headers_2_csv( sitecode, date_start, date_end )
% TOA5_COLUMN_HEADERS_2_CSV - create a csv file in the user's temp directory
%   with column headers of TOA5 30-minute data from a specified range of dates.

% Useful for determining whether datalogger variable recording has changed.
% get_data_file_names is used to locate TOA5 files for the specified site and
% time range.
%
% The output is written to $TEMP/SITE_headers.txt.  If environment variable
% $TEMP does not exist, output is written to SITE_headers.txt in current
% working directory.
%
% USAGE:
%     outfname = TOA5_column_headers_2_csv( sitecode, date_start, date_end );
%
% INPUTS:
%     sitecode: UNM_sites object; specifies the site
%     date_start: Matlab serial datenumber; beginning of time period to
%          compile TOA5 file headers
%     date_end: Matlab serial datenumber; end of time period to
%          compile TOA5 file headers
%   
% OUTPUTS
%     outfname: character string; full path to the file created.
%
% SEE ALSO
%     datenum, get_data_file_names
%
% author: Timothy W. Hilton, Feb 2012

file_list = get_data_file_names( sitecode, date_start, date_end, 'TOA5' );

headers = cell( size( file_list ) );
dates = cell( size( file_list ) );

% open a file to write the headers to
outfname = fullfile( getenv( 'TEMP' ), ...
                     sprintf( '%s_headers.txt', get_site_name( sitecode ) ) );
try
    [ outfile, msg ] = fopen( outfname, 'wt' );
    if outfile < 0
        file_err = MException( 'TOA5_column_headers_2_csv:cannot_open_outfile', ...
                              'Error opening output file' );
        throw(file_err)
    end
catch err
    fprintf( 1, 'Error opening output file\n' );
    disp( msg );
    outfname = -1;
    return
end

fprintf( outfile, 'TOA5 file date\n' );

for i = 1:numel( file_list )
    
    [ infile_path, infile_name, infile_ext ] = fileparts( file_list{ i } );
    
    fprintf( 1, 'parsing %s\n', [ infile_name, infile_ext ] );

    % get date for this file
    file_date = get_TOA5_TOB1_file_date( [ infile_name, infile_ext ] );

    % parse this file
    [ var_names, var_units, file_lines, first_data_line, delim ] = ...
        parse_TOA5_file_headers( file_list{ i } );
    clear( 'file_lines', 'first_data_line', 'delim' ); % don't need these

    
    % write filename, date and variable names to output csv file
    fprintf( outfile, '%s\t', [ infile_name, infile_ext ] );
    fprintf( outfile, '%s\t', datestr( file_date, 'dd mmm YYYY' ) );
    fmt = [ repmat( '%s\t', 1, numel( var_names ) - 1 ), '%s\n' ];
    fprintf( outfile, fmt, var_names{ : } );
end

fclose( outfile );

