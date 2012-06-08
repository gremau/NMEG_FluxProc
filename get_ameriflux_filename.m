function fpath = get_ameriflux_filename( sitecode, year, suffix)
% GET_AMERIFLUX_FILENAME - returns the full path to the Ameriflux file for the
%   specified site-year.  Does not confirm that the file exists -- this
%   function is meant to be used either to open an existing Ameriflux file or
%   to define the location when creating a new one.
%
% INPUTS
%    sitecode: UNM_sitecode object (or corresponding integer)
%    year: integer: four digit year
%    suffix: "gapfilled" or "with_gaps"
%
% OUTPUTS
%    fpath: char array: the full path to the requested Ameriflux file.
%
% (c) Timothy W. Hilton, UNM, May 2012

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

% check user arguments
args = inputParser;
args.addRequired( 'sitecode', ...
                  @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'suffix', ...
                  @(x) any( strcmp( x, { 'with_gaps', 'gapfilled' } ) ) ) 
args.parse( sitecode, year, suffix );

% build the Ameriflux file name
sites_info = parse_UNM_site_table();
aflx_site_name = char( sites_info.Ameriflux( args.Results.sitecode ) );
fname = sprintf( '%s_%d_%s.txt', ...
                 aflx_site_name, ...
                 args.Results.year, ...
                 args.Results.suffix );
fpath = fullfile( get_out_directory( args.Results.sitecode ), fname );
