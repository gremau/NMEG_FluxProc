function CombinedTable = combine_and_fill_datalogger_files( varargin )
% combine_and_fill_datalogger_files() -- combines multiple datalogger files
% into one matlab table, fills in any missing 30-minute time stamps and
% discards duplicated or erroneous timestamps.
%
% FIXME - documentation
%
% USAGE
%    CombinedTable = combine_and_fill_datalogger_files();
%    CombinedTable = combine_and_fill_datalogger_files( 'path\to\first\datalogger\file', ...
%                                      'path\to\second\datalogger\file', ... );
%
% INPUTS:
% OPTIONAL PARAMETER-VALUE PAIRS:
%    'file_names': cell array; a cell array of strings
%        containing full paths to the datalogger files.
%    'datalogger_type': string; indicates the datalogger file type.
%        Current accepted values are 'main', 'cr1000' and 'cr23x'
%    'resolve_headers': boolean (false); specifies whether to resolve
%        the column headers in the files.
%
% OUTPUTS
%    CombinedTable: Matlab table array; the combined and filled data
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
p.addParameter( 'file_names', {}, @( x ) isa( x, 'cell' ) || ischar( x ) );
p.addParameter( 'datalogger_type', '', @ischar );
p.addParameter( 'resolve_headers', false, @islogical );
p.parse( varargin{ : } );

fileNames = p.Results.file_names;
dataloggerType = p.Results.datalogger_type;
resolve = p.Results.resolve_headers;
% -----

% If no files are specified; prompt user to select files
if isempty( fileNames )
    [ fileNames, pathName, filterindex ] = uigetfile( ...
        { '*.dat','Datalogger files (TYPE*DATE*.dat)' }, ...
        'select files to merge', ...
        fullfile( 'C:', 'Research_Flux_Towers', ...
        'Flux_Tower_Data_by_Site' ), ...
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

% If no dataloggerType given, prompt the user for one
if isempty( dataloggerType )
    prompt = 'Which datalogger files? ("main", "cr1000" or "cr23x"): ';
    dataloggerType = input( prompt, 's' );
end

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
    % Add the table to the TableArray
    if strcmpi( dataloggerType, 'main' ) || ...
            strcmpi( dataloggerType, 'cr1000' )
        TableArray{ i } = toa5_2_table( ...
            fullfile( thisPath, fileNames{ i } ) );
    elseif strcmpi( dataloggerType, 'cr23x' )
        TableArray{ i } = cr23x_2_table(...
            fullfile( thisPath, fileNames{ i } ) );
    end
end
% ================= HEADER RESOLUTION ==========================
% Resolve the headers if asked. If not, processing
% picks up at table_vertcat_fill_vars
if resolve
    TableArray = resolve_datalogger_column_headers( TableArray,...
        fileNames, ...
        dataloggerType );
else
    % Warn the user, but this is ok with some datalogger files (PJ sites,
    % possibly others
    fprintf(['CHANGES IN DATALOGGER FILE HEADER COLUMNS ARE NOT BEING ' ...
        'RESOLVED!\n']);
end
%===============================================================

%CombinedTable = table_append_common_vars( TableArray{ : } );
CombinedTable = table_vertcat_fill_vars( TableArray{ : } );

fprintf( 1, 'filling missing timestamps\n' );
CombinedTable = table_fill_timestamps( CombinedTable, ...
                              'timestamp', ... 
                              't_min', min( CombinedTable.timestamp ), ...
                              't_max', max( CombinedTable.timestamp ) );

% remove duplicated timestamps (e.g., in TX 2010)
fprintf( 1, 'removing duplicate timestamps\n' );
ts = datenum( CombinedTable.timestamp( : ) );
oneminute = 1 / ( 60 * 24 ); %one minute expressed in units of days
nonDuplicateIndex = find( diff( ts ) > oneminute );
CombinedTable = CombinedTable( nonDuplicateIndex, : );

% to save to file, use e.g.:
% fprintf( 1, 'saving csv file\n' );
% idx = min( find( datenum(CombinedTable.timestamp(:))>= datenum( 2012, 1, 1)));
% tstamps_numeric = CombinedTable.timestamp;
% CombinedTable.timestamp = datestr( CombinedTable.timestamp, 'mm/dd/yyyy HH:MM:SS' );
% export(CombinedTable( idx:end, : ), 'FILE', ...
%        fullfile( get_out_directory(), 'combined_TOA5.csv' ), ...
%        'Delimiter', ',');
% CombinedTable.timestamp = tstamps_numeric;
