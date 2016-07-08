function combined_tbl = combine_and_fill_datalogger_files( sitecode, ...
                                                           file_fmt, ...
                                                           varargin )
% combine_and_fill_datalogger_files() -- combines multiple datalogger files
% into one matlab table, fills in any missing 30-minute time stamps and
% discards duplicated or erroneous timestamps.
%
% FIXME - documentation
%
% USAGE
%    combined_tbl = combine_and_fill_datalogger_files();
%    combined_tbl = combine_and_fill_datalogger_files( 'path\to\first\datalogger\file', ...
%                                      'path\to\second\datalogger\file', ... );
%
% REQUIRED INPUTS:
%    'sitecode': UNM_sites object specifying 
%    'file_fmt': string; "TOA5" or "CR23X" specifying type of file to load
% OPTIONAL PARAMETER-VALUE PAIRS:
%    'file_names': cell array; a cell array of strings
%        containing full paths to the datalogger files.
%    'resolve_headers': boolean (false); specifies whether to resolve
%        the column headers in the files.
%    'datalogger_name': string; indicates the datalogger name and is
%        required for resolving headers
%
% OUTPUTS
%    combined_tbl: Matlab table array; the combined and filled data
%
% SEE ALSO
%    table, uigetfile, UNM_assign_soil_data_labels,
%    table_fill_timestamps, toa5_2_table, cr23x_2_table
%
% authors: Gregory E. Maurer, UNM, Oct, 2014. Based on 
%          combine_and_fill_TOA5_files by Timothy W. Hilton, UNM, Dec 2011

% -----
% parse and typecheck inputs
p = inputParser;
p.addRequired( 'sitecode', @(x) ( isintval(x) | isa( x, 'UNM_sites' )));
p.addRequired( 'file_fmt', @(x) strcmpi( x, 'toa5' ) | strcmpi( x, 'cr23x' ))
p.addParameter( 'file_names', {}, @( x ) isa( x, 'cell' ) || ischar( x ) );
p.addParameter( 'resolve_headers', false, @islogical );
p.addParameter( 'datalogger_name', '', @ischar );
p.parse( sitecode, file_fmt, varargin{ : } );

sitecode = p.Results.sitecode;
fileFmt = p.Results.file_fmt;
fileNames = p.Results.file_names;
resolve = p.Results.resolve_headers;
loggerName = p.Results.datalogger_name;
% -----

% If no files are specified; prompt user to select files
if isempty( fileNames )
    [ fileNames, pathName, filterindex ] = uigetfile( ...
        { '*.dat','Datalogger files (TYPE*DATE*.dat)' }, ...
        'select files to merge', ...
        get_site_directory( sitecode ), ...
        'MultiSelect', 'on' );
end
% If only a single file specified, put in cell array
if ischar( fileNames )
    fileNames = { fileNames };
end
% Now parse the list of fileNames in case fileNames cellarray
% contains file names with full paths
[ pathName, fileNames, ext ] = cellfun( @fileparts, fileNames, ...
    'UniformOutput', false );
fileNames = strcat( fileNames, ext );

% Make sure files are sorted in chronological order
fileNames = sort( fileNames );

% Count number of files and initialize some arrays
numFiles = length( fileNames );
TableArray = cell( numFiles, 1 );

for i = 1:numFiles
    fprintf( 1, 'reading %s\n', fileNames{ i } );
    % Get the path of the file FIXME (do we need this?)
%     if  iscell( pathName ) &  ( numel( pathName ) == 1 )
%         thisPath = pathName{ 1 };
    if iscell( pathName )
        thisPath = pathName{ i };
    else
        thisPath = pathName;
    end
    % Read the table and add to the TableArray. These functions should add
    % timestamps and remove bad data values
    if strcmpi( fileFmt, 'toa5' )
        TableArray{ i } = toa5_2_table( ...
            fullfile( thisPath, fileNames{ i } ) );
    elseif strcmpi( fileFmt, 'cr23x' )
        TableArray{ i } = cr23x_2_table(...
            fullfile( thisPath, fileNames{ i } ) );
    end
end
% ================= HEADER RESOLUTION ==========================
% Resolve the headers if asked. If not, processing
% picks up at table_vertcat_fill_vars
if resolve
    % If no loggerName given, prompt the user for one
    if isempty( loggerName )
        prompt = 'Resolving headers requires logger name ("flux", "soil", etc): ';
        loggerName = input( prompt, 's' );
    end
    
    % Use sitecode and loggerName find appropriate header resolution file
    resFileName = sprintf('%s_HeaderResolution.csv', loggerName);
    resFilePathName = fullfile( getenv('FLUXROOT'), 'FluxProcConfig', ...
        'HeaderResolutions', char( sitecode ), resFileName );
    % Resolve headers in TableArray using this resolution file
    TableArray = resolve_datalogger_column_headers( TableArray,...
        fileNames, resFilePathName );
else
    % Warn the user, but this is ok with some datalogger files (PJ sites,
    % possibly others
    fprintf(['CHANGES IN DATALOGGER FILE HEADER COLUMNS ARE NOT BEING ' ...
        'RESOLVED!\n']);
end
%===============================================================

%combined_tbl = table_append_common_vars( TableArray{ : } );
combined_tbl = table_vertcat_fill_vars( TableArray{ : } );

fprintf( 1, 'filling missing timestamps\n' );
combined_tbl = table_fill_timestamps( combined_tbl, ...
                              'timestamp', ... 
                              't_min', min( combined_tbl.timestamp ), ...
                              't_max', max( combined_tbl.timestamp ) );

% remove duplicated timestamps (e.g., in TX 2010)
fprintf( 1, 'removing duplicate timestamps\n' );
ts = datenum( combined_tbl.timestamp( : ) );
oneminute = 1 / ( 60 * 24 ); %one minute expressed in units of days
nonDuplicateIndex = find( diff( ts ) > oneminute );
combined_tbl = combined_tbl( nonDuplicateIndex, : );

% to save to file, use e.g.:
% fprintf( 1, 'saving csv file\n' );
% idx = min( find( datenum(combined_tbl.timestamp(:))>= datenum( 2012, 1, 1)));
% tstamps_numeric = combined_tbl.timestamp;
% combined_tbl.timestamp = datestr( combined_tbl.timestamp, 'mm/dd/yyyy HH:MM:SS' );
% export(combined_tbl( idx:end, : ), 'FILE', ...
%        fullfile( get_out_directory(), 'combined_TOA5.csv' ), ...
%        'Delimiter', ',');
% combined_tbl.timestamp = tstamps_numeric;
