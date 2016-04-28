function tbl = parse_forgapfilling_file( sitecode, year, varargin )
% PARSE_FORGAPFILLING_FILE - parse an ASCII for_gapfilling file to a
% matlab table
%   
% USAGE
%    tbl = parse_forgapfilling_file( sitecode, year, ... )
%
% INPUTS
%     sitecode [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%     OPTIONAL PARAMETERS
%     use_filled: {true}|false; use forgapfilling file with T, RH, Rg filled from
%          nearby site.  Default is true.
%     fname: character; path to file to read.  If unspecified, looks for
%          $FLUXROOT/SiteData/SITE/processed_flux/SITE_flux_all_YYYY_for_gapfilling[_filled].txt 
%
% OUTPUTS
%     tbl [ matlab table ]: the data contained in the file
%
% SEE ALSO
%     table
%
% author: Timothy W. Hilton, UNM, March 2012
% Modified by: Gregory E. Maurer, UNM, April 2015

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParameter( 'use_filled', true, @islogical );
args.addParameter( 'fname', '', @ischar );

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

% File has column header and units, so need to separate
% FIXME - should we load in units as a table field?
infile = fopen( fname, 'r' );
headers = fgetl( infile );
col_headers = regexp( headers, '[ \t]+', 'split' );
n_cols = numel( col_headers );  %how many columns?
fclose( infile );

fmt = [ repmat( '%f ', 1, n_cols-1 ), '%f' ];
          
tbl = readtable( fname, 'Format', fmt, 'Delimiter', '\t', ...
    'MultipleDelimsAsOne', true, 'Headerlines', 2, ...
    'ReadVariableNames', false );

% Add column headers and replace NaN with -9999
tbl.Properties.VariableNames = col_headers;
tbl = replace_badvals( tbl, [ -9999.0 ], 1e-6 );

% Create a matlab datenum timestamp column

% Detect time format
if all( ismember( { 'year', 'month', 'day', 'hour', 'minute' }, ...
                  tbl.Properties.VariableNames ) )
    ts = datenum( tbl.year, tbl.month, tbl.day, tbl.hour, tbl.minute, 0 );
elseif all( ismember( { 'Year', 'DoY', 'Hour' }, ...
                      tbl.Properties.VariableNames ) )
    HOURS_PER_DAY = 24.0;
    ts = datenum( tbl.Year, 1, 0 ) + ...
         tbl.DoY + ...
         ( tbl.Hour / HOURS_PER_DAY );
else
    error( 'unrecognized time format' );
end

tbl.timestamp = ts;