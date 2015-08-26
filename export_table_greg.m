function success = export_table_greg( fname, T, varargin )
% EXPORT_DATASET_TIM - write a table array to a delimited ASCII text file.
%
% The builtin table export method is really slow; this is pretty quick.  An
% existing file named fname will be overwritten.
% 
% USAGE
%     success = export_table_tim( fname, T )
%     success = export_table_tim( fname, T, 'delimiter', dlm )
%     success = export_table_tim( fname, T, ..., 'replace_NaNs', rplc )
%     success = export_table_tim( fname, T, ..., 'write_units', write_units )
%
% INPUTS
%     fname: char; full path of file to write.
%     T: table array
%
% PARAMETER-VALUE PAIRS
%     dlm: character; the delimiter to use.  Optional, defaults to tab.
%     replace_nans: numeric; value with which to replace NaNs.  Defaults to
%         NaN (i.e. no replacement of NaNs).
%     write_units: true|{false}; if true, the write a line of units
%         beneath the variable names (on line 2).  If T.Properties.VariableUnits is
%         empty, writes '--' for each units.  
%
% OUTPUTS
%     success: 0 if file written successfully; non-zero otherwise
% 
% SEE ALSO
%    table
%
% author: Timothy W. Hilton, UNM, Oct 2012

args = inputParser;
args.addRequired( 'fname', @ischar );
args.addRequired( 'T', @( x ) isa( x, 'table' ) );
args.addParameter( 'delimiter', '\t', @ischar );
args.addParameter( 'replace_nans', NaN, @isnumeric ); %
args.addParameter( 'write_units', false, @islogical ); %

% parse optional inputs
args.parse( fname, T, varargin{ : } );

if args.Results.write_units
    if isempty( T.Properties.VariableUnits )
        T.Properties.VariableUnits = regexprep( ...
            T.Properties.VariableNames, '.*', '--' );
    end
end

% write the headers 
t0 = now();
fid = fopen( args.Results.fname, 'w' );
headers = replace_hex_chars( args.Results.T.Properties.VariableNames );
fprintf( fid, '%s\t', headers{ 1:end - 1 } );
fprintf( fid, '%s\n', headers{ end } );
if args.Results.write_units
    var_units = T.Properties.VariableUnits;
    fprintf( fid, '%s\t', var_units{ 1:end-1 } );
    fprintf( fid, '%s\n', var_units{ end } );
end
fclose( fid );

T_dbl = table2array( args.Results.T );
if ~isnan( args.Results.replace_nans );
% replace NaNs with user-specified value
    T_dbl( isnan( T_dbl ) ) = args.Results.replace_nans;
end

% Append the data to the file.
dlmwrite( args.Results.fname, ...
          T_dbl, ...
          '-append', ...
          'Delimiter', args.Results.delimiter, 'Precision', 8 );

t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );

success = 0;
