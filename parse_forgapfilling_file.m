function ds = parse_forgapfilling_file( sitecode, year, varargin )
% PARSE_FORGAPFILLING_FILE - parse an ASCII for_gapfilling file to a matlab dataset
%   
% USAGE
%    ds = parse_forgapfilling_file( sitecode, year, filled )
%
% INPUTS
%     sitecode [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%     filled [logical]: use T, RH, Rg filled forgapfilling file
%
% OUTPUTS
%     ds [ matlab dataset ]: the data contained in the file
%
% (c) Timothy W. Hilton, UNM, March 2012

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'use_filled', true, @islogical );
args.addParamValue( 'fname', '', @ischar );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
filled = args.Results.use_filled;
fname= args.Results.fname;

if filled
    fmt = '%s_flux_all_%d_for_gap_filling_filled.txt';
else
    fmt = '%s_flux_all_%d_for_gap_filling.txt';
end

if isempty( fname )
    fname = fullfile( get_site_directory( sitecode ), ...
                      'processed_flux', ...
                      sprintf( fmt, get_site_name( sitecode ), year ) );
    fprintf( 'parsing %s\n', fname );
end

infile = fopen( fname, 'r' );
headers = fgetl( infile );
col_headers = regexp( headers, '[ \t]+', 'split' );
n_cols = numel( col_headers );  %how many columns?
fclose( infile );

fmt = [ repmat( '%f ', 1, n_cols-1 ), '%f' ];
ds = dataset( 'File', fname, ...
              'format', fmt, ...
              'delimiter', '\t', ...
              'MultipleDelimsAsOne', true, ...
              'HeaderLines', 0 );

ds_names = ds.Properties.VarNames;
ds_dbl = double( ds );
ds_dbl = replace_badvals( ds_dbl, [ -9999.0 ], 1e-6 );
clear ds;

ds = dataset( { ds_dbl, col_headers{:} } );

% create a matlab datenum timestamp column
ts = datenum( ds.year, ds.month, ds.day, ds.hour, ds.minute, 0 );
ds.timestamp = ts;