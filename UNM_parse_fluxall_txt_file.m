function ds  = UNM_parse_fluxall_txt_file( sitecode, year, varargin )
% UNM_PARSE_FLUXALL_TXT_FILE - parse fluxall data and timestamps from
% tab-delimited text file to matlab dataset.
%
% FIXME - Deprecated. This function is being superseded by 
% 'parse_fluxall_txt_file.m'
%   
% ds  = UNM_parse_fluxall_txt_file( sitecode, year )
% ds  = UNM_parse_fluxall_txt_file( sitecode, year, 'file', file )
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
% PARAMETER-VALUE PAIRS
%    file: character string; full path to the fluxall file to be read.  If
%    not specified, default is 
%    get_site_directory( sitecode )/SITE_FLUX_all_YEAR.txt
%
% OUTPUTS
%    ds: dataset array: the data from the fluxall file
%
% SEE ALSO
%    UNM_sites, dataset, get_site_directory
%
% Timothy W. Hilton, UNM, January 2012

warning( 'This function ( UNM_parse_fluxall_txt_file.m ) is deprecated' );

[ this_year, ~, ~ ] = datevec( now );

% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | ...
                                     isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ...
                    ( x <= this_year ) ) );
args.addParamValue( 'file', '', @ischar );
args.parse( sitecode, year, varargin{ : } );

sitecode = args.Results.sitecode;
year_arg = args.Results.year;
% -----

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fluxrc = UNM_flux_process_config(); % Not used - GEM
site = get_site_name( sitecode );

% if no file specified, use default
if isempty( args.Results.file )
    fname = sprintf( '%s_FLUX_all_%d.txt', site, year_arg );
    full_fname = fullfile( get_site_directory( sitecode ), fname );
else
    % Check if file exists
    if not( exist( args.Results.file ) )
        error( sprintf( 'file ''%s'' does not exist', args.Results.file ) );
    end
    fname = args.Results.file;
    full_fname = args.Results.file;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open file and parse out dates and times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf( 'reading %s...\n', fname );

fid = fopen( full_fname, 'r' );
headers = fgetl( fid );

% split the headers on tab characters
headers = regexp( headers, '\t', 'split' );
% remove or replace characters that are illegal in matlab variable names
headers_orig = headers;
headers = clean_up_varnames( headers_orig );

% read the numeric data
fmt = repmat( '%f', 1, numel( headers ) );
data = textscan( fid, ...
                 fmt, ...
                 'Delimiter', '\t' );
fclose( fid );
data = cell2mat( data );

% replace -9999s with NaN using floating point test with tolerance of 0.0001
data = replace_badvals( data, [ -9999 ], 0.0001 );

% create matlab dataset from data
empty_columns = find( cellfun( @length, headers ) == 0 );
headers( empty_columns ) = [];
data( :, empty_columns ) = [];
ds = dataset( { data, headers{ : } } );

% Check that there aren't multiple years in the incoming data
[ nRows, nCol ] = size( ds );
inYearRecords = ds.year == year_arg ;
%years = unique( ds.year( 1:end-1 ));
if sum( inYearRecords ) < ( nRows - 1 );
    inYearIdx = find( inYearRecords );
    keep = min( inYearIdx ) : (max( inYearIdx ) + 1 ) ;
    ds = ds( keep, : );
    warning( 'Removing data outside of requested year' )
end

ds.timestamp = datenum( ds.year, ds.month, ds.day, ...
                        ds.hour, ds.min, ds.second );

% Warn user if this is an irregular fluxall file
[ numobs, ~ ] = size( ds );
fullobs = 365 * 48;
% Chech for leapyear first
if datenum( year, 2, 29 ) ~= datenum( year, 3, 1 );
    fullobs = fullobs + 48;
end 
if numobs < fullobs
    warning( sprintf( 'file %s is missing observations!', fname ) );
elseif numobs > fullobs
    warning( sprintf( 'file %s has too many observations!', fname ) );
end
fprintf( ' file read\n' );

