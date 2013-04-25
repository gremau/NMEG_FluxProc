function result = UNM_Ameriflux_write_file( sitecode, ...
                                            year, ...
                                            ds_aflx, ...
                                            fname_suffix, ...
                                            varargin )
% UNM_AMERIFLUX_WRITE_FILE - writes a dataset containing ameriflux data out to
%   an Ameriflux ASCII file with appropriate headers
    
[ this_year, ~, ~ ] = datevec( now );

% parse and validate arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'ds_aflx', @(x) isa( x, 'dataset' ) );
args.addRequired( 'fname_suffix', @ischar );
args.addParamValue( 'email', 'mlitvak@unm.edu', @ischar );
args.addParamValue( 'outdir', '', @ischar );

args.parse( sitecode, year, ds_aflx,  varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
ds_aflx = args.Results.ds_aflx;
fname_suffix = args.Results.fname_suffix;
email = args.Results.email;
outdir = args.Results.outdir;

% now create and write the output file
result = 1;

%use a default if no output directory specified
if strcmp( outdir, '' )
    outdir = get_out_directory( sitecode );
end

delim = ',';
ncol = size( ds_aflx, 2 );

sites_info = parse_UNM_site_table();
aflx_site_name = char( sites_info.Ameriflux( sitecode ) );
fname = fullfile( outdir, ...
                  sprintf( '%s_%d_%s.txt', ...
                           aflx_site_name, ...
                           year, ...
                           fname_suffix ) );

fprintf( 1, 'writing %s...\n', fname );

fid = fopen( fname, 'w+' );

fprintf( fid, 'Site name: %s\n', aflx_site_name );
fprintf( fid, 'Email: %s\n', email );
fprintf( fid, 'Created: %s\n', datestr( now() ) );

%% write variables name and unit headers
tok_str = sprintf( '%s%%s', delim );
fmt = [ '%s', repmat( tok_str, 1, ncol-1 ), '\n' ];
var_names = ds_aflx.Properties.VarNames;
% '.' was replaced with 'p' to make legal Matlab variable names.  Change
% these 'p's back to '.'s -- identify by '.' between two digits
var_names = regexprep( var_names, '([0-9])p([0-9])', '$1\.$2');
fprintf( fid, fmt, var_names{:} );
units = ds_aflx.Properties.Units;
fprintf( fid, fmt, units{:} );

fclose( fid );

data = double( ds_aflx );
data( isnan( data ) ) = -9999;
dlmwrite( fname, data, '-append', ...
          'delimiter', delim, ...
          'precision', 7 );
%'precision', '%.7f' );  %use 15 signigicant figures

