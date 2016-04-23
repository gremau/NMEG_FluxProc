function T  = UNM_parse_fluxall_xls_file( sitecode, year, varargin )
% UNM_PARSE_FLUXALL_XLS_FILE - parse fluxall data and timestamps from
% Excel spreadsheet file to matlab dataset.
%
% T  = UNM_parse_fluxall_xls_file( sitecode, year )
% T  = UNM_parse_fluxall_xls_file( sitecode, year, 'file', file )
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
% PARAMETER-VALUE PAIRS
%    file: character string; full path to the fluxall file to be read.  If
%    not specified, default is
%    get_site_directory( sitecode )/SITE_FLUX_all_YEAR.xls
%
% OUTPUTS
%    T: dataset array: the data from the fluxall file
%
% SEE ALSO
%    UNM_sites, dataset, get_site_directory
%
% Timothy W. Hilton, UNM, January 2012

warning('This file is deprecated')

[ this_year, ~, ~ ] = datevec( now );

% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParameter( 'file', '', @ischar );
args.parse( sitecode, year, varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
% -----

% Get file properties
[ lastcolumn, filelength_n ] = get_FluxAll_File_Properties( sitecode, year );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if no file specified, use default
if isempty( args.Results.file )
    fname = sprintf( '%s_FLUX_all_%d.xls', get_site_name(sitecode), year );
    full_fname = fullfile( get_site_directory( sitecode ), fname );
else
    %Check if file exists
    if not( exist( args.Results.file ) )
        error( sprintf( 'file ''%s'' does not exist', args.Results.file ) );
    end
    fname = args.Results.file;
    full_fname = args.Results.file;
end

fluxrc = UNM_flux_process_config();
site = get_site_name( sitecode );

row1=5;  %first row of data to process - rows 1 - 4 are header
range = sprintf( 'B%d:%s%d', row1 ,lastcolumn, filelength_n );
headerrange = sprintf( 'A2:%s5',lastcolumn );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open file and parse out dates and times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iswindows = not( isempty( regexp( computer(), 'WIN' ) ) );

disp( sprintf( 'reading %s...', fname ) );

%create an array of headers in the format ColNNN -- these will be used to
%fill in missing headers

%% read the headertext ( windows only )
%% outside of windows, xlsread operates in 'basic' mode, and can only
%% read the numeric portions of the spreadsheet in their entirety.
if ( iswindows )
    [ num, headertext ] = xlsread( full_fname, headerrange );
    headertext = fluxall_extract_column_headers( headertext );
    [ data, ~ ] = xlsread( full_fname, '', '', 'basic' );
    
    empty_headers = find( cellfun( @isempty, headertext ) );
    dummyheaders = arrayfun( @(x) sprintf('Col_%03d', x), ...
        empty_headers( : ), ...
        'UniformOutput', false );
    headertext( empty_headers ) = dummyheaders;
else
    [ data, discard ] = xlsread( full_fname, '', '', 'basic' );
    %% create cell array of variable names -- Col_001, Col_002, ... Col_N
    dummyheaders = arrayfun( @(x) sprintf('Col_%03d', x), ...
        1:size( data, 2 ), ...
        'UniformOutput', false );
    headertext = dummyheaders;
end

%% replace -9999s with NaN using floating point test with tolerance of 0.0001.
data = replace_badvals( data, [ -9999 ], 0.0001 );

disp( 'file read' );

headertext = genvarname( headertext );
ncols = numel( headertext );
if ncols < size( data, 2 )
    data( :, ( ncols + 1 ):end ) = [];
end
T = array2table( data, 'VariableNames', headertext );

%% convert excel serial dates to matlab datenums (as per
%% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s)
T.timestamp2 = excel_date_2_matlab_datenum( data( :, 1 ) );
T.timestamp = excel_date_2_matlab_datenum( data( :, 2 ) );

%% reject data without a timestamp
T = T( ~isnan( T.timestamp ), : );

%--------------------------------------------------
function headertext = fluxall_extract_column_headers( headertext )
% FLUXALL_EXTRACT_COLUMN_HEADERS - locate and return the column headers for a
%   fluxall xls file.  The headers for the Matlab sections and 30-minute
%   sections to not always appear on the same line, so locate them by searching
%   for the two "timestamp" headers.  Helper function for
%   UNM_parse_fluxall_xls_file.

[ row, col ] = find( cellfun( @(x) ~isempty(x), ...
    regexpi( headertext, 'timestamp' ) ) );
headertext{ row(end), col(end) } = 'TOA5_timestamp';
headertext = [ headertext( row(1), col(1):col(end)-1 ), ...
    headertext( row(end), col(end):end ) ];
% headertext = [ headertext( row(1), col(1):col(2)-1 ), ...
%                headertext( row(2), col(2)+1:end ) ];

%-------------------------------------------------------
function dn = excel_date_2_matlab_datenum(esd)
% EXCEL_DATE_2_MATLAB_DATENUM - convert Microsoft Excel serial date to a Matlab
% serial datenumber.
%
% See
% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s.
%
% dn = excel_date_2_matlab_datenum(esd)
%
% INPUTS
%    esd: MxN array of Excel serial dates
% OUTPUTS
%    dn: MxN array of Matlab datenums
%
% SEE ALSO
%    datenum
%
% Timothy W. Hilton, UNM, January 2012


% convert the serial date as per
% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s
dn = esd + datenum( '30-Dec-1899' )
