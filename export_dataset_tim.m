function success = export_dataset_tim( fname, ds, varargin )
% EXPORT_DATASET_TIM - write a dataset array to a delimited ASCII text file.
%
% The builtin dataset export method is really slow; this is pretty quick.  An
% existing file named fname will be overwritten.
% 
% USAGE
%     success = export_dataset_tim( fname, ds )
%     success = export_dataset_tim( fname, ds, 'delimiter', dlm )
%     success = export_dataset_tim( fname, ds, ..., 'replace_NaNs', rplc )
%     success = export_dataset_tim( fname, ds, ..., 'write_units', write_units )
%
% INPUTS
%     fname: char; full path of file to write.
%     ds: dataset array
%
% PARAMETER-VALUE PAIRS
%     dlm: character; the delimiter to use.  Optional, defaults to tab.
%     replace_nans: numeric; value with which to replace NaNs.  Defaults to
%         NaN (i.e. no replacement of NaNs).
%     write_units: true|{false}; if true, the write a line of units
%         beneath the variable names (on line 2).  If ds.Properties.Units is
%         empty, writes '--' for each units.  
%
% OUTPUTS
%     success: 0 if file written successfully; non-zero otherwise
% 
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, Oct 2012

args = inputParser;
args.addRequired( 'fname', @ischar );
args.addRequired( 'ds', @( x ) isa( x, 'dataset' ) );
args.addParamValue( 'delimiter', '\t', @ischar );
args.addParamValue( 'replace_nans', NaN, @isnumeric ); %
args.addParamValue( 'write_units', false, @islogical ); %

% parse optional inputs
args.parse( fname, ds, varargin{ : } );

if args.Results.write_units
    if isempty( ds.Properties.Units )
        ds.Properties.Units = regexprep( ds.Properties.VarNames, '.*', '--' );
    end
end

% write the headers 
t0 = now();
fid = fopen( args.Results.fname, 'w' );
headers = replace_hex_chars( args.Results.ds.Properties.VarNames );
fprintf( fid, '%s\t', headers{ 1:end - 1 } );
fprintf( fid, '%s\n', headers{ end } );
if args.Results.write_units
    var_units = ds.Properties.Units;
    fprintf( fid, '%s\t', var_units{ 1:end-1 } );
    fprintf( fid, '%s\n', var_units{ end } );
end
fclose( fid );

ds_dbl = double( args.Results.ds );
if ~isnan( args.Results.replace_nans );
% replace NaNs with user-specified value
    ds_dbl( isnan( ds_dbl ) ) = args.Results.replace_nans;
end

% Append the data to the file.
dlmwrite( args.Results.fname, ...
          ds_dbl, ...
          '-append', ...
          'Delimiter', args.Results.delimiter, 'Precision', 8 );

t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );

success = 0;
