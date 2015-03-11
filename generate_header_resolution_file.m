function ds = generate_header_resolution_file( varargin )
% generate_header_resolution_file() -- takes a list of TOA5 files and
% generates a header resolution file for the site
% ({sitecode}_Header_Resolutions.csv)
%
% There are several problems with keeping track of what sensors are 
% outputting data to the TOA5 files and what header name each data 
% stream is under.
%
% 1. Header names for a sensor output change over the years as
%    datalogger programs are rewritten.
%
% 2. Sensors are added or moved, so TOA5 columns are not consistent
%    from year to year and may contain a sensor's output for only
%    limited periods. Sometimes the same headers are reused when these
%    changes occur, meaning they should be relabeled.
%
% 3. Columns may be mislabeled, ie. the program labels the sensors
%    incorrectly), or sensors may be wired in a different order than 
%    the program thinks.
%
% This script generates a header resolution file for a site using the
% headers from each TOA5 file and three configuration files. 
%
% USAGE
%    ds = generate_header_resolution_file();
%
% INPUTS
%    either a series of strings containing full paths to the TOA5
%    files to be combined.  If called with no inputs the user is presented a
%    graphical file selection dialog (via uigetfile) which allows for multiple
%    files to be selected interactively.
%
% OUTPUTS
%    ds: Matlab dataset array; the combined and filled data
% 
% SEE ALSO
%    dataset, uigetfile, UNM_assign_soil_data_labels,
%    dataset_fill_timestamps, toa5_2_dataset
%
% Gregory E. Maurer, UNM,  Sept 2014

dataloggerType = 'cr23x';
resolutionFileName = '_cr23x_Header_Resolutions.csv';

if nargin == 0
    % no files specified; prompt user to select files
    [fileNames, pathNames, filterindex] = uigetfile( ...
        { '*.dat','Datalogger files (*.dat)' }, ...
        'select files to merge', ...
        fullfile( getenv('FLUXROOT'), 'Flux_Tower_Data_by_Site') , ...
        'MultiSelect', 'on' );
    
    if ischar( fileNames )
        fileNames = { fileNames };
    end
else
    % the arguments are file names (with full paths)
    args = [ varargin{ : } ];
    [ pathNames, fileNames, ext ] = cellfun( @fileparts, ...
                                           args, ...
                                           'UniformOutput', false );
    fileNames = strcat( fileNames, ext );
end

% Make sure files are sorted in chronological order and get dates
fileNames = sort(fileNames);
datfile_date_array = tstamps_from_filenames(fileNames);

% Count number of files and initialize some arrays
nfiles = length( fileNames );
T_array = cell( nfiles, 1 );

% Read each TOA5 file, convert to dataset, load datasets into an array
for i = 1:nfiles
    fprintf( 1, 'reading %s\n', fileNames{ i } );
    % Input checks
    if  iscell( pathNames ) &&  ( numel( pathNames ) == 1 )
            this_path = pathNames{ 1 };
    elseif iscell( pathNames )
        this_path = pathNames{ i };
    else
        this_path = pathNames;
    end
    
    if strcmpi(dataloggerType, 'main') || strcmpi(dataloggerType, 'cr1000');
        T_array{ i } = toa5_2_table( fullfile( this_path, fileNames{ i } ) );
    elseif strcmp(dataloggerType, 'cr23x');
        T_array{ i } = cr23x_2_table( fullfile( this_path, fileNames{ i } ) );
    end
    tokens = regexp( fileNames{ i }, '_', 'split' );
    % deal with the two sites that have an '_' in the sitename
    if any( strcmp( tokens{ 3 }, { 'girdle', 'GLand' }  ) )
        sitecode = UNM_sites.( [ tokens{ 2 }, '_', tokens{ 3 } ] );
        year = str2num( tokens{ 4 } );
    else
        sitecode = UNM_sites.( tokens{ 2 } );
        year = str2num( tokens{ 3 } );
    end
    
end

%%%%%%%%%% Choose the header resolution file name %%%%%%%%%%%%%
% FIXME - this is clunky
resolutionFileName = strcat('HeaderResolutions\', ...
    char(sitecode), resolutionFileName );

% TOA5 Header resolution config file path
resolutionPath = fullfile(pwd, 'HeaderResolutions');

% Using the sitecode object, open the apropriate header resolution
% and sensor swap files stored in \TOA5_Header_Resolutions\
headerChangesFileName = strcat(char(sitecode), '_Header_Changes.csv');
headerChangesFile = fullfile(resolutionPath, headerChangesFileName);
sensorSwapsFileName = strcat(char(sitecode), '_Sensor_Swaps.csv');
sensorSwapsFile = fullfile(resolutionPath, sensorSwapsFileName);
sensorRenameFileName = strcat(char(sitecode), '_Sensor_Rename.csv');
sensorRenameFile = fullfile(resolutionPath, sensorRenameFileName);

fopenmessage = strcat('----- Opening ', headerChangesFileName,' ----- \n');
fprintf(1, fopenmessage );

% Read in the header changes file
changes = readtable(headerChangesFile);
[numHeaders, numPrev] = size(changes);
% Assign current and previous header columns
current = changes{:, 1};
previous = changes{:, 2:end};

%Check for sensor swaps file and open if found
swapflag = 0;
if exist(sensorSwapsFile, 'file')
    fopenmessage = ...
        strcat('----- Opening ', sensorSwapsFileName,' ----- \n');
    fprintf(1, fopenmessage );
    swapflag = 1;
    % Read in the sensor swaps file
    swaps = readtable(sensorSwapsFile);
end

%Check for sensor rename file and open if found
renameflag = 0;
if exist(sensorRenameFile, 'file')
    fopenmessage = ...
        strcat('----- Opening ', sensorRenameFileName,' ----- \n');
    fprintf(1, fopenmessage );
    renameflag = 1;
    % Read in the sensor swaps file
    renames = readtable(sensorRenameFile);
end

% Initialize new resolution file
T = table(current);

for i = 1:numel( T_array )
    % get the current TOA5 file header
    unresolved_TOA5_header = T_array{i}.Properties.VariableNames;
    % Get date, name, and header of toa5 file
    TOA5_date = datfile_date_array(i);
    fileNameTokens = regexp( fileNames{ i }, '\.', 'split' );
    TOA5_name = fileNameTokens{1};
    
    % ----------- Rename sensors if needed -----------------
    if exist(sensorRenameFile, 'file')
        first_toa5_date = datenum(renames.first, 'YYYY-mm-DD');
        last_toa5_date = datenum(renames.last, 'YYYY-mm-DD');
        % Which header changes are in this TOA5's date range
        inDateRange = floor( TOA5_date ) >= first_toa5_date &...
            floor( TOA5_date ) <= last_toa5_date;
        % Get the original and changed header names
        changeFrom = renames.changeFrom( inDateRange );
        changeTo = renames.changeTo( inDateRange );
        
        % Get the locations of headers to rename in toa5_changes
        [ ~, loc ] = ismember( changeFrom, unresolved_TOA5_header );
        
        found = loc~=0;
        loc = loc(found);
        changeTo = changeTo(found);
        
        % Make the changes
        unresolved_TOA5_header(loc) = changeTo;
    end
    % ------------------------------------------------------

    % Store header resolution in a new table
    new = repmat({''}, length(current), 1);
    toa5_changes = table(new, 'VariableNames', {TOA5_name});
    
    % for each line in the header change file, parse out the current
    % header name, then look for earlier header names in the TOA5
    % header and make them current
    fprintf(1, 'Resolving header changes for %s \n', fileNames{i});
    
    for j = 1:length(current)
        curr = current(j); % current header name
        % previous names for this header, removing blanks
        prev = previous(j, ~strcmp(previous(j, :), ''));
        prevloc = find(ismember(unresolved_TOA5_header, prev));
        multiple_previous_flag = false;
        currloc = find(ismember(unresolved_TOA5_header, curr));
        % Previous header found, current header absent
        if length(prevloc) == 1 && length(currloc) == 0
            %resolved_TOA5_header(prevloc) = curr;
            toa5_changes.(TOA5_name)(j) = unresolved_TOA5_header(prevloc);
        % Previous header absent, current header found
        elseif length(prevloc) == 0 && length(currloc) == 1
            toa5_changes.(TOA5_name)(j) = curr;
        % Neither header found
        elseif length(prevloc) == 0 && length(currloc) == 0
            toa5_changes.(TOA5_name)(j) = {'dne'};
        % Multiple possible previous headers found
%         elseif length(prevloc) > 1 && length(currloc) == 0
%             ploc = prevloc(length(prevloc) - prevloc_count)
%             toa5_changes.(TOA5_name)(j) = unresolved_TOA5_header(ploc);
%             multiple_previous_flag = true;
        % Both headers found - mark as current, neither column removed
        elseif length(prevloc) == 1 && length(currloc) == 1
            toa5_changes.(TOA5_name)(j) = curr;
            fprintf(1, 'Both %s and %s exist in this file!\n',...
                char(curr), char(unresolved_TOA5_header(prevloc)));
        else
            disp('Invalid!!!!');
        end
    end
    
    % ----------- Swap sensors if needed -----------------
    if exist(sensorSwapsFile, 'file')
        first_toa5_date = datenum(swaps.first, 'YYYY-mm-DD');
        last_toa5_date = datenum(swaps.last, 'YYYY-mm-DD');
        % Which header changes are in this TOA5's date range
        inDateRange = floor( TOA5_date ) >= first_toa5_date &...
            floor( TOA5_date ) <= last_toa5_date;
        % Get the original and changed header names
        changeFrom = swaps.changeFrom( inDateRange );
        changeTo = swaps.changeTo( inDateRange );
        
        % Get the locations of headers to rename in toa5_changes
        [ ~, loc ] = ismember( changeFrom, toa5_changes.(TOA5_name) );
        
        % Make the changes
        toa5_changes.(TOA5_name)(loc) = changeTo;
    end
    % ------------------------------------------------------
    
    % Change current headers in resolution table to "current"
    test = cellfun(@strcmp, toa5_changes.(TOA5_name), current);
    toa5_changes.(TOA5_name)(test) = {'current'};
    
    % Compare elements of most recent table column and new table for
    % changes. If they are NOT identical, append the new table.
    [T_rows, T_cols] = size(T);
    test = cellfun(@strcmp, T.(T_cols), toa5_changes.(1));
    if sum(test) < T_rows
        T = [T, toa5_changes];
    end
    clear toa5_changes
end
    
prompt = 'Overwrite the current header resolution file? Y/N [Y]: ';

str = input(prompt, 's');

if isempty(str)
    str = 'Y';
end
aff = {'Y','y','YES','yes','Yes'};
if  any(strcmp(str, aff))
    writetable(T, resolutionFileName);
end


