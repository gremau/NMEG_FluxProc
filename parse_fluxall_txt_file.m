function tbl  = parse_fluxall_txt_file( sitecode, year, varargin )
% PARSE_FLUXALL_TXT_FILE - parse fluxall data and timestamps from
% tab-delimited text file to matlab table.
%
%   
% tbl  = UNM_parse_fluxall_txt_file( sitecode, year )
% tbl  = UNM_parse_fluxall_txt_file( sitecode, year, 'file', file )
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
%    tbl: table array: the data from the fluxall file
%
% SEE ALSO
%    UNM_sites,table, get_site_directory
%
% Timothy W. Hilton, UNM, January 2012
% Modified by Gregory E. Maurer, UNM, April 2015

[ this_year, ~, ~ ] = datevec( now );

% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParameter( 'file', '', @ischar );
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
    %fname = sprintf( '%s_FLUX_all_%d.txt', site, year_arg );
    fname = sprintf( '%s_%d_fluxall.txt', site, year_arg );
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
headers_orig = regexp( headers, '\t', 'split' );

% remove or replace characters that are illegal in matlab variable names
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
tbl = array2table( data, 'VariableNames', headers );

% Check that there aren't multiple years in the incoming data
[ nRows, nCol ] = size( tbl );
inYearRecords = tbl.year == year_arg ;
%years = unique( tbl.year( 1:end-1 ));
if sum( inYearRecords ) < ( nRows - 1 );
    inYearIdx = find( inYearRecords );
    keep = min( inYearIdx ) : ( max( inYearIdx ) + 1 ) ;
    tbl = tbl( keep, : );
    warning( 'Removing data outside of requested year' )
end

tbl.timestamp = datenum( tbl.year, tbl.month, tbl.day, ...
                        tbl.hour, tbl.min, tbl.second );

% Warn user if this is an irregular fluxall file
[ numobs, ~ ] = size( tbl );
fullobs = 365 * 48;
% Check for leapyear first
if datenum( year, 2, 29 ) ~= datenum( year, 3, 1 );
    fullobs = fullobs + 48;
end 
if numobs < fullobs - 1
    warning( sprintf( 'file %s is missing observations!', fname ) );
elseif numobs > fullobs + 1
    warning( sprintf( 'file %s has too many observations!', fname ) );
end
fprintf( ' file read\n' );

