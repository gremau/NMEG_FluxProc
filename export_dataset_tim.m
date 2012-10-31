function success = export_dataset_tim( fname, ds, delimiter )
% EXPORT_DATASET_TIM - write a dataset array to a delimited text file.  The
%   builtin dataset export method is really slow; this is pretty quick.  An
%   existing file named fname will be overwritten.
% 
% USAGE
%     success = export_dataset_tim( fname, ds )
%
% INPUTS
%     fname: char; full path of file to write.
%     ds: dataset array
%     delimiter: character; the delimiter to use
%
% OUTPUTS
%     success: 0 if file written successfully; non-zero otherwise
% 
% (c) Timothy W. Hilton, UNM, Oct 2012

% write the headers 
t0 = now();
fid = fopen( fname, 'w' );
headers = replace_hex_chars( ds.Properties.VarNames );
fprintf( fid, '%s\t', headers{ : } );
fprintf( fid, '\n' );
fclose( fid );

% replace NaNs with -9999
ds_dbl = double( ds );
ds_dbl( isnan( ds_dbl ) ) = -9999;

% write the data
dlmwrite( fname, ...
          ds_dbl, ...
          '-append', ...
          'Delimiter', delimiter );

t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );

success = 0;
