function success = export_dataset_tim( fname, ds, varargin )
% EXPORT_DATASET_TIM - write a dataset array to a delimited text file.  The
%   builtin dataset export method is really slow; this is pretty quick.  An
%   existing file named fname will be overwritten.  NaNs in data are replaced
%   with -9999.
% 
% USAGE
%     success = export_dataset_tim( fname, ds )
%     success = export_dataset_tim( fname, ds, 'delimiter', dlm )
%     success = export_dataset_tim( fname, ds, ..., 'replace_NaNs', rplc )
%
% INPUTS
%     fname: char; full path of file to write.
%     ds: dataset array
%     dlm: character; the delimiter to use.  Optional, defaults to tab.
%     rplc: logical; if true, NaNs are replaced with -9999.  Defaults to false.
%
% OUTPUTS
%     success: 0 if file written successfully; non-zero otherwise
% 
% (c) Timothy W. Hilton, UNM, Oct 2012

args = inputParser;
args.addRequired( 'fname', @ischar );
args.addRequired( 'ds', @( x ) isa( x, 'dataset' ) );
args.addParamValue( 'delimiter', '\t', @ischar );
args.addParamValue( 'replace_nans', false, @islogical ); %

% parse optional inputs
args.parse( fname, ds, varargin{ : } );

% write the headers 
t0 = now();
fid = fopen( args.Results.fname, 'w' );
headers = replace_hex_chars( args.Results.ds.Properties.VarNames );
fprintf( fid, '%s\t', headers{ : } );
fprintf( fid, '\n' );
fclose( fid );

ds_dbl = double( args.Results.ds );
if args.Results.replace_nans
% replace NaNs with -9999
    ds_dbl( isnan( ds_dbl ) ) = -9999;
end

% write the data
dlmwrite( args.Results.fname, ...
          ds_dbl, ...
          '-append', ...
          'Delimiter', args.Results.delimiter );

t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );

success = 0;
