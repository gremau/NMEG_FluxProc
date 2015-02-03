function CombinedDataset = combine_and_fill_datalogger_files( varargin )
% combine_and_fill_datalogger_files() -- combines multiple datalogger files into one matlab
% dataset, fills in any missing 30-minute time stamps and discards duplicated or
% erroneous timestamp.
%
% FIXME - documentation
%
% USAGE
%    CombinedDataset = combine_and_fill_datalogger_files();
%    CombinedDataset = combine_and_fill_datalogger_files( 'path\to\first\datalogger\file', ...
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
%    CombinedDataset: Matlab dataset array; the combined and filled data
%
% SEE ALSO
%    dataset, uigetfile, UNM_assign_soil_data_labels,
%    dataset_fill_timestamps, toa5_2_dataset, cr23x_2_table
%
% Gregory E. Maurer, UNM, Oct, 2014

% -----
% parse and typecheck inputs
p = inputParser;
p.addParameter( 'file_names', {} , @( x ) isa( x, 'cell' ) );
p.addParameter( 'datalogger_type', '', @ischar );
p.addParameter( 'resolve_headers', false, @islogical );
p.parse( varargin{ : } );

fileNames = p.Results.file_names;
dataloggerType = p.Results.datalogger_type;
resolve = p.Results.resolve_headers;
% -----

% If no files are specified; prompt user to select files
if isempty( fileNames )
    [fileNames, pathName, filterindex] = uigetfile( ...
        { '*.dat','Datalogger files (TYPE*DATE*.dat)' }, ...
        'select files to merge', ...
        fullfile( 'C:', 'Research_Flux_Towers', ...
        'Flux_Tower_Data_by_Site' ), ...
        'MultiSelect', 'on' );
    
    if ischar( fileNames )
        fileNames = { fileNames };
    end
% Otherwise parse the list of fileNames in case fileNames cellarray
% contains file names with full paths
else
    [ pathName, fileNames, ext ] = cellfun( @fileparts, fileNames, ...
        'UniformOutput', false );
    fileNames = strcat( fileNames, ext );
end

% If no dataloggerType given, prompt the user for one
if isempty( dataloggerType )
    prompt = 'Which datalogger files? ("main", "cr1000" or "cr23x"): ';
    dataloggerType = input(prompt, 's');
end

% Make sure files are sorted in chronological order
fileNames = sort(fileNames);

% Count number of files and initialize some arrays
numFiles = length( fileNames );
DatasetArray = cell( numFiles, 1 );

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
    % Add the dataset to the DatasetArray
    % FIXME - switch away from datasets in this file
    if strcmpi(dataloggerType, 'main') || strcmpi(dataloggerType, 'cr1000')
        DatasetArray{ i } = toa5_2_dataset( ...
            fullfile( thisPath, fileNames{ i } ) );
    elseif strcmpi(dataloggerType, 'cr23x')
        DatasetArray{ i } = table2dataset(cr23x_2_table(...
            fullfile( thisPath, fileNames{ i } ) ));
    end
end
% ================= HEADER RESOLUTION ==========================
% Resolve the headers if asked. If not, process
% picks up at dataset_vertcat_fill_vars
if resolve
    DatasetArray = resolve_datalogger_column_headers(DatasetArray,...
        fileNames, ...
        dataloggerType);
else
    warning(['Changes in datalogger file header columns are not', ...
        'being resolved!']);
end
%===============================================================

%CombinedDataset = dataset_append_common_vars( DatasetArray{ : } );
CombinedDataset = dataset_vertcat_fill_vars( DatasetArray{ : } );

fprintf( 1, 'filling missing timestamps\n' );
CombinedDataset = dataset_fill_timestamps( CombinedDataset, ...
                              'timestamp', ... 
                              't_min', min( CombinedDataset.timestamp ), ...
                              't_max', max( CombinedDataset.timestamp ) );

% remove duplicated timestamps (e.g., in TX 2010)
fprintf( 1, 'removing duplicate timestamps\n' );
ts = datenum( CombinedDataset.timestamp( : ) );
oneminute = 1 / ( 60 * 24 ); %one minute expressed in units of days
nonDuplicateIndex = find( diff( ts ) > oneminute );
CombinedDataset = CombinedDataset( nonDuplicateIndex, : );

% to save to file, use e.g.:
% fprintf( 1, 'saving csv file\n' );
% idx = min( find( datenum(CombinedDataset.timestamp(:))>= datenum( 2012, 1, 1)));
% tstamps_numeric = CombinedDataset.timestamp;
% CombinedDataset.timestamp = datestr( CombinedDataset.timestamp, 'mm/dd/yyyy HH:MM:SS' );
% export(CombinedDataset( idx:end, : ), 'FILE', ...
%        fullfile( get_out_directory(), 'combined_TOA5.csv' ), ...
%        'Delimiter', ',');
% CombinedDataset.timestamp = tstamps_numeric;
