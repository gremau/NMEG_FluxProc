function result = UNM_Ameriflux_write_file( sitecode, ...
                                            year, ...
                                            af_tbl, ...
                                            fname_suffix, ...
                                            varargin )
% UNM_AMERIFLUX_WRITE_FILE - writes a table containing ameriflux data out to
%   an Ameriflux ASCII file with appropriate headers.  
%
% Primarily a helper function for UNM_Ameriflux_File_Maker.
%
% USAGE
%    UNM_Ameriflux_write_file( sitecode, year, af_tbl, fname_suffix )
%
% INPUTS
%     sitecode: UNM_sites object or integer; specifies site to process
%     year: integer; year to process
%     af_tbl: table array; the data to write.  Usually the output of
%         UNM_Ameriflux_prepare_output_data 
%     fname_suffix: char; 'gapfilled' or 'with_gaps'
% PARAMETER-VALUE PAIRS
%     email: contact email address to list in the Ameriflux file header.
%         Default is mlitvak@unm.edu
%     outdir: char; full path to directory to write ameriflux files to.
%         Defaults to get_out_directory( sitecode ).
%
% author: Timothy W. Hilton, UNM, 2012


[ this_year, ~, ~ ] = datevec( now );

% parse and validate arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'af_tbl', @(x) isa( x, 'table' ) );
args.addRequired( 'fname_suffix', @ischar );
args.addParameter( 'email', 'mlitvak@unm.edu', @ischar );
args.addParameter( 'outdir', '', @ischar );

args.parse( sitecode, year, af_tbl,  varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
af_tbl = args.Results.af_tbl;
fname_suffix = args.Results.fname_suffix;
email = args.Results.email;
outdir = args.Results.outdir;

% Now create and write the output file
result = 1;

% We can now remove 'timestamp'
if any( strcmp( 'timestamp', af_tbl.Properties.VariableNames ) )
    af_tbl.timestamp = [];
end

% Use a default if no output directory specified
if strcmp( outdir, '' )
    outdir = get_out_directory( sitecode );
end

delim = ',';
ncol = size( af_tbl, 2 );

sites_info = parse_UNM_site_table();
aflx_site_name = char( sites_info.Ameriflux( sitecode ) );
fname = fullfile( outdir, ...
                  sprintf( '%s_%d_%s_branch.txt', ...
                           aflx_site_name, ...
                           year, ...
                           fname_suffix ) );

fprintf( 1, 'writing %s...\n', fname );

fid = fopen( fname, 'w+' );

fprintf( fid, 'Site name: %s\n', aflx_site_name );
fprintf( fid, 'Email: %s\n', email );
fprintf( fid, 'Created: %s\n', datestr( now() ) );

% Write variables name and unit headers
tok_str = sprintf( '%s%%s', delim );
fmt = [ '%s', repmat( tok_str, 1, ncol-1 ), '\n' ];
var_names = af_tbl.Properties.VariableNames;
% '.' was replaced with 'p' to make legal Matlab variable names.  Change
% these 'p's back to '.'s -- identify by '.' between two digits
var_names = regexprep( var_names, '([0-9])p([0-9])', '$1\.$2');
fprintf( fid, fmt, var_names{:} );
units = af_tbl.Properties.VariableUnits;
fprintf( fid, fmt, units{:} );

% This could work, but fmt would have to be specified for each column
% Also, it is SLOWER than dlmwrite
% dat_str = sprintf( '%s%%f', delim );
% fmt = [ '%s', repmat( dat_str, 1, ncol-1 ), '\n' ];
% for i = 1:height( af_tbl );
%    y = table2cell( af_tbl( i, : ) );
%    fprintf( fid, fmt, y{:} );
% end

fclose( fid );


% Beware of ints when converting table to array!
% Use high precision so TIMESTAMP is represented correctly
data = table2array( af_tbl );
data( isnan( data ) ) = -9999;
dlmwrite( fname, data, '-append', ...
          'Delimiter', delim, ...
          'Precision', 14 );

