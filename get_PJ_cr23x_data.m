function cr23xData = get_PJ_cr23x_data( sitecode, year )
% GET_PJ_CR23X_DATA - parse CR23X soil data for PJ or PJ_girdle.
%
% Creates table of cr23x data for the PJ sites, including soil 
% temperature, soil water content, and soil heat flux. Dataset has a
% complete 30-minute timestamp record and duplicate timestamps removed via
% table_fill_timestamps.  When duplicate timestamps are detected, the 
% first is kept and subsequent duplicates are discarded.
%
% USAGE
%    cr23xData = get_PJ_cr23x_data( sitecode, year )
%
% INPUTS
%    sitecode: integer or UNM_sites object; either PJ or PJ_girdle
%    year: integer; year of data to preprocess
%
% OUTPUTS:
%    cr23xData: matlab table array containing all observations from the
%               cr23x logger in the specified year
%
% SEE ALSO
%    table, table_fill_timestamps
%
% author: Gregory E. Maurer, UNM, March 2015
% based on code by: Timothy W. Hilton, Dec 2012 (PREPROCESS_PJ_SOIL_DATA)

if isa( sitecode, 'UNM_sites' )
    sitecode = int8( sitecode );
end

% determine file path
sitename = get_site_name( sitecode );

filePath = fullfile( getenv( 'FLUXROOT' ), ...
    'Flux_Tower_Data_by_Site', sitename, 'secondary_loggers' );

% if year < 2009
%     % From early years use the cr23x compilations made by Laura Morillas
%     directoryName = 'yearly_cr23x_compilations';
%     fileName = sprintf( 'cr23x_%s_%d_compilation.dat', sitename, year );
%     fileName = fullfile( filePath, directoryName, fileName );
%     % Get the data - note that there is NO HEADER RESOLUTION
%     % We are assuming headers in the compiled files are ok
%     cr23xData = combine_and_fill_datalogger_files( ...
%         'file_names', fileName, 'datalogger_type', 'cr23x', ...
%         'resolve_headers', false);
% else

directoryName = 'cr23x_files';
dataDirectory = fullfile(filePath, directoryName);
% IMPORTANT: Make sure the files have the format:
% 'cr23x_$sitename$_YYYY_MM_DD_HHMM.dat'
regularExpr = ...
    '^cr23x_PJ.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
fileNames = list_files( dataDirectory, regularExpr );

% Make datenums for the dates
fileDateNumbers = tstamps_from_filenames(fileNames);

% Sort by datenum
[ fileDateNumbers, idx ] = sort( fileDateNumbers );
fileNames = fileNames( idx );

% Choose data files containing data from requested year, which should
% include the last file of the previous year ( by filename ).
s = datenum( year, 0, 0 );
e = datenum( year + 1, 0, 0 );
chooseFiles = find( fileDateNumbers > s & fileDateNumbers < e );
if min( chooseFiles ) ~= 1
    chooseFiles = [ min( chooseFiles ) - 1, chooseFiles ];
end

% Get the data and resolve headers in process
cr23xData = combine_and_fill_datalogger_files( ...
    'file_names', fileNames( chooseFiles ), ...
    'datalogger_type', 'cr23x', 'resolve_headers', true );
%end

% replace -9999 and -99999 with NaN
badValues = [ -9999, 9999, -99999, 99999 ];
cr23xData = replace_badvals( cr23xData, badValues, 1e-6 );
