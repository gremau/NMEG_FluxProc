function ds = parse_forgapfilling_file( sitecode, year, varargin )
% PARSE_FORGAPFILLING_FILE - parse an ASCII for_gapfilling file to a matlab dataset
%   
% USAGE
%    ds = parse_forgapfilling_file( sitecode, year, ... )
%
% INPUTS
%     sitecode [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%     OPTIONAL PARAMETERS
%     use_filled [logical]: use forgapfilling file with T, RH, Rg filled from
%          nearby site.  Default is true.
%     fname: character; path to file to read.  If unspecified, looks for
%          $FLUXROOT/Flux_Tower_Data_by_Site/SITE/processed_flux/SITE_flux_all_YYYY_for_gapfilling[_filled].txt 
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
              'HeaderLines', 2, ...
              'readVarNames', false );

ds_names = ds.Properties.VarNames;
ds_dbl = double( ds );
ds_dbl = replace_badvals( ds_dbl, [ -9999.0 ], 1e-6 );
clear ds;

ds = dataset( { ds_dbl, col_headers{:} } );

% create a matlab datenum timestamp column

%detect time format
if all( ismember( { 'year', 'month', 'day', 'hour', 'minute' }, ...
                  ds.Properties.VarNames ) )
    ts = datenum( ds.year, ds.month, ds.day, ds.hour, ds.minute, 0 );
elseif all( ismember( { 'Year', 'DoY', 'Hour' }, ...
                      ds.Properties.VarNames ) )
    HOURS_PER_DAY = 24.0;
    ts = datenum( ds.Year, 1, 0 ) + ...
         ds.DoY + ...
         ( ds.Hour / HOURS_PER_DAY );
else
    error( 'unrecognized time format' );
end

ds.timestamp = ts;