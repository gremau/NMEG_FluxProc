function ds  = UNM_parse_fluxall_xls_file( sitecode, year )
% UNM_PARSE_FLUXALL_XLS_FILE - parse fluxall data and timestamps from
% Excel spreadsheet file to matlab dataset.  
% 
% The fluxall file is assumed to be is 
%    get_site_directory( sitecode )/SITE_FLUX_all_YEAR.xls
%
% ds  = UNM_parse_fluxall_xls_file( sitecode, year )
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%
% OUTPUTS
%    ds: dataset array: the data from the fluxall file
%
% SEE ALSO
%    UNM_sites, dataset, get_site_directory
%
% Timothy W. Hilton, UNM, January 2012

[ lastcolumn, filelength_n ] = get_FluxAll_File_Properties( sitecode, year );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fluxrc = UNM_flux_process_config();
site = get_site_name( sitecode );

row1=5;  %first row of data to process - rows 1 - 4 are header
fname = sprintf( '%s_FLUX_all_%d.xls', site, year );
filein = fullfile( get_site_directory( sitecode ), fname );

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
    [ num, headertext ] = xlsread( filein, headerrange );
    headertext = fluxall_extract_column_headers( headertext );
    [ data, ~ ] = xlsread( filein, '', '', 'basic' );  

    empty_headers = find( cellfun( @isempty, headertext ) );
    dummyheaders = arrayfun( @(x) sprintf('Col_%03d', x), ...
                             empty_headers( : ), ...
                             'UniformOutput', false );
    headertext( empty_headers ) = dummyheaders;
else
    [ data, discard ] = xlsread( filein, '', '', 'basic' );  
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
ds = dataset( { data, headertext{:} } );

%% convert excel serial dates to matlab datenums (as per
%% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s)
ds.timestamp2 = excel_date_2_matlab_datenum( data( :, 1 ) );
ds.timestamp = excel_date_2_matlab_datenum( data( :, 2 ) );

%% reject data without a timestamp
ds = ds( ~isnan( ds.timestamp ), : );

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
