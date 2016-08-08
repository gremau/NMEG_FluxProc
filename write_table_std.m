function success = write_table_std( fname, tab_in, varargin )
% WRITE_TABLE_STD.M - write a table array to a delimited ASCII text file.
%
% The builtin table export method is really slow; this is pretty quick.  An
% existing file named fname will be overwritten.
% 
% USAGE
%     success = write_table_std( fname, tab_in )
%     success = write_table_std( fname, tab_in, 'delimiter', dlm )
%     success = write_table_std( fname, tab_in, ..., 'replace_NaNs', rplc )
%     success = write_table_std( fname, tab_in, ..., 'write_units', write_units )
%
% INPUTS
%     fname: char; full path of file to write.
%     tab_in: table array
%
% PARAMETER-VALUE PAIRS
%     dlm: character; the delimiter to use.  Optional, defaults to tab.
%     replace_nans: numeric; value with which to replace NaNs.  Defaults to
%         NaN (i.e. no replacement of NaNs).
%     write_units: true|{false}; if true, the write a line of units
%         beneath the variable names (on line 2).  If 
%         tab_in.Properties.VariableUnits is empty, writes '--' for each 
%         units.  
%     precision: floating point precision, default is 8
%
% OUTPUTS
%     success: 0 if file written successfully; non-zero otherwise
% 
% SEE ALSO
%    table
%
% author: Timothy W. Hilton, UNM, Oct 2012
% rewritten by Gregory E. Maurer, UNM, Feb 2016

args = inputParser;
args.addRequired( 'fname', @ischar );
args.addRequired( 'tab_in', @( x ) isa( x, 'table' ) );
args.addParameter( 'delimiter', '\t', @ischar );
args.addParameter( 'replace_nans', NaN, @isnumeric ); %
args.addParameter( 'write_units', false, @islogical ); %
args.addParameter( 'precision', 8, @(x) isa( x, 'numeric' )); %

% parse optional inputs
args.parse( fname, tab_in, varargin{ : } );

if args.Results.write_units
    if isempty( tab_in.Properties.VariableUnits )
        tab_in.Properties.VariableUnits = regexprep( ...
            tab_in.Properties.VariableNames, '.*', '--' );
    end
end

% write the headers 
t0 = now();
fid = fopen( args.Results.fname, 'w' );
headers = replace_hex_chars( args.Results.tab_in.Properties.VariableNames );
fprintf( fid, '%s\t', headers{ 1:end - 1 } );
fprintf( fid, '%s\n', headers{ end } );
if args.Results.write_units
    var_units = tab_in.Properties.VariableUnits;
    fprintf( fid, '%s\t', var_units{ 1:end-1 } );
    fprintf( fid, '%s\n', var_units{ end } );
end
fclose( fid );

tab_dbl = table2array( args.Results.tab_in );
if ~isnan( args.Results.replace_nans );
% replace NaNs with user-specified value
    tab_dbl( isnan( tab_dbl ) ) = args.Results.replace_nans;
end

% Append the data to the file.
dlmwrite( args.Results.fname, ...
          tab_dbl, ...
          '-append', ...
          'Delimiter', args.Results.delimiter, ...
          'Precision', args.Results.precision );

t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );

success = 0;
