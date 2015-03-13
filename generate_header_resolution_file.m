function T = generate_header_resolution_file( sitecode, sourceType, ...
    varargin )
% generate_header_resolution_file() -- takes a list of TOA5 files and
% generates a header resolution file for the site
% ({sitecode}_Header_Resolutions.csv)
%
% FIXME - documentation and cleanup, possible vectorization of main for
% loop
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

sourceType = lower( sourceType );


if isempty( varargin )
    % no files specified; prompt user to select files
    [ fileNames, pathNames, filterindex ] = uigetfile( ...
        { '*.dat','Datalogger files (*.dat)' }, ...
        'select files to merge', ...
        get_site_directory( sitecode ) , ...
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
fileNames = sort( fileNames );
fileDateArray = tstamps_from_filenames( fileNames );

% Count number of files and initialize some arrays
nFiles = length( fileNames );
rawTables = cell( nFiles, 1 );

% Read each data file into a table, load tables into a cellarray
for i = 1:nFiles
    fprintf( 1, 'reading %s\n', fileNames{ i } );
    % Input checks
    if  iscell( pathNames ) &&  ( numel( pathNames ) == 1 )
            this_path = pathNames{ 1 };
    elseif iscell( pathNames )
        this_path = pathNames{ i };
    else
        this_path = pathNames;
    end
    % Load tables into table cellarray
    if strcmpi( sourceType, 'main' ) || strcmpi( sourceType, 'cr1000' );
        rawTables{ i } = toa5_2_table( fullfile( this_path, fileNames{ i } ) );
    elseif strcmp(sourceType, 'cr23x');
        rawTables{ i } = cr23x_2_table( fullfile( this_path, fileNames{ i } ) );
    end
    % Verify that the files are for the requested site
    tokens = regexp( fileNames{ i }, '_', 'split' );
    % deal with the two sites that have an '_' in the sitename
    if any( strcmp( tokens{ 3 }, { 'girdle', 'GLand' }  ) )
        sitecodeFromFile = UNM_sites.( [ tokens{ 2 }, '_', tokens{ 3 } ] );
    else
        sitecodeFromFile = UNM_sites.( tokens{ 2 } );
    end 
    if sitecodeFromFile ~= sitecode
        error( ' Files do not match requested site' );
    end
end

%%%%%%%%%% Get the header resolution files %%%%%%%%%%%%%

% Header resolution config file path
resolutionPath = fullfile( pwd, 'HeaderResolutions', char( sitecode ) );

% Get the appropriate header resolution files for each site
headerChangesFile = fullfile( resolutionPath, 'Header_Changes.csv' );
sensorSwapsFile = fullfile( resolutionPath, 'Sensor_Swaps.csv' );
sensorRenameFile = fullfile( resolutionPath, 'Sensor_Rename.csv' );

fopenmessage = [ '----- Opening ', char( sitecode ), ...
    ' Header_Changes.csv ----- \n' ];
fprintf(1, fopenmessage );

% Read in the header changes file
changes = readtable( headerChangesFile );
[ numHeaders, numPrev ] = size( changes );
% Assign current and previous header columns
current = changes{ :, 1 };
previous = changes{ :, 2:end };

%Check for sensor swaps file and open if found
swapflag = 0;
if exist( sensorSwapsFile, 'file' )
    fopenmessage = [ '----- Opening ', char( sitecode ), ...
        ' Sensor_Swaps.csv ----- \n' ];
    fprintf( 1, fopenmessage );
    swapflag = 1;
    % Read in the sensor swaps file
    swaps = readtable( sensorSwapsFile );
end

%Check for sensor rename file and open if found
renameflag = 0;
if exist( sensorRenameFile, 'file' )
    fopenmessage = [ '----- Opening ', char( sitecode ), ...
        ' Sensor_Rename.csv ----- \n' ];
    fprintf( 1, fopenmessage );
    renameflag = 1;
    % Read in the sensor swaps file
    renames = readtable( sensorRenameFile );
end

% Initialize new resolution file
T = table( current );

for i = 1:numel( rawTables )
    % Get the raw, unresolved column names for each table in the array
    unresolvedHeaders = rawTables{ i }.Properties.VariableNames;
    % Get date, name, and header of toa5 file
    fileDate = fileDateArray( i );
    fileNameTokens = regexp( fileNames{ i }, '\.', 'split' );
    fileName = fileNameTokens{1};
    
    % ----------- Rename sensors if needed -----------------
    if exist( sensorRenameFile, 'file' )
        firstRenameDate = datenum( renames.first, 'YYYY-mm-DD' );
        lastRenameDate = datenum( renames.last, 'YYYY-mm-DD' );
        % Which header changes are in this TOA5's date range
        inDateRange = floor( fileDate ) >= firstRenameDate &...
            floor( fileDate ) <= lastRenameDate;
        % Get the original and changed header names
        changeFrom = renames.changeFrom( inDateRange );
        changeTo = renames.changeTo( inDateRange );
        
        % Get the locations of headers to rename in headerChanges
        [ ~, loc ] = ismember( changeFrom, unresolvedHeaders );
        
        found = loc~=0;
        loc = loc( found );
        changeTo = changeTo( found );
        
        % Make the changes
        unresolvedHeaders( loc ) = changeTo;
    end
    % ------------------------------------------------------

    % Store header resolution in a new table
    new = repmat( {''}, length( current ), 1 );
    new = repmat( {''}, length( current ), 1 );
    headerChanges = table( new, 'VariableNames', { fileName } );
    
    % for each line in the header change file, parse out the current
    % header name, then look for earlier header names in the TOA5
    % header and make them current
    fprintf(1, 'Resolving header changes for %s \n', fileNames{i});
    
    for j = 1:length( current )
        curr = current( j ); % current header name
        % previous names for this header, removing blanks
        prev = previous( j, ~strcmp(previous( j, : ), '' ));
        prev = previous( j, ~strcmp(previous( j, : ), '' ));
        prevloc = find( ismember( unresolvedHeaders, prev ));
        multiple_previous_flag = false;
        currloc = find(ismember( unresolvedHeaders, curr ));
        
        % Previous header found, current header absent
        if length( prevloc ) == 1 && length( currloc ) == 0
            %resolved_TOA5_header(prevloc) = curr;
            headerChanges.( fileName )( j ) = ...
                unresolvedHeaders( prevloc );
            
        % Previous header absent, current header found
        elseif length( prevloc ) == 0 && length( currloc ) == 1
            headerChanges.( fileName )( j ) = curr;
            
        % Neither header found
        elseif length( prevloc ) == 0 && length( currloc ) == 0
            headerChanges.( fileName )(  j) = { 'dne' };
            
        % Multiple possible previous headers found
%         elseif length( prevloc ) > 1 && length( currloc ) == 0
%             ploc = prevloc( length( prevloc ) - prevloc_count)
%             headerChanges.( fileName )( j ) = unresolvedHeaders( ploc );
%             multiple_previous_flag = true;

        % Both headers found - mark as current, neither column removed
        elseif length( prevloc ) == 1 && length( currloc ) == 1
            headerChanges.( fileName )( j ) = curr;
            fprintf( 1, 'Both %s and %s exist in this file!\n',...
                char( curr ), char( unresolvedHeaders( prevloc )));
            
        else
            disp( 'Invalid!!!!' );
        end
    end
    
    % ----------- Swap sensors if needed -----------------
    if exist( sensorSwapsFile, 'file' )
        firstRenameDate = datenum( swaps.first, 'YYYY-mm-DD' );
        lastRenameDate = datenum( swaps.last, 'YYYY-mm-DD' );
        % Which header changes are in this TOA5's date range
        inDateRange = floor( fileDate ) >= firstRenameDate &...
            floor( fileDate ) <= lastRenameDate;
        % Get the original and changed header names
        changeFrom = swaps.changeFrom( inDateRange );
        changeTo = swaps.changeTo( inDateRange );
        
        % Get the locations of headers to rename in fileChanges
        [ ~, loc ] = ismember( changeFrom, headerChanges.( fileName ) );
        
        % Make the changes
        headerChanges.( fileName )( loc ) = changeTo;
    end
    % ------------------------------------------------------
    
    % Change current headers in resolution table to "current"
    test = cellfun( @strcmp, headerChanges.( fileName ), current );
    headerChanges.( fileName )( test ) = { 'current' };
    
    % Compare elements of most recent table column and new table for
    % changes. If they are NOT identical, append the new table.
    [ T_rows, T_cols ] = size( T );
    test = cellfun( @strcmp, T.( T_cols ), headerChanges.( 1 ));
    if sum( test ) < T_rows
        T = [ T, headerChanges ];
    end
    clear headerChanges
end
    
prompt = 'Overwrite the current header resolution file? Y/N [Y]: ';

str = input( prompt, 's' );

if isempty( str )
    str = 'Y';
end
aff = { 'Y', 'y', 'YES', 'yes', 'Yes' };
if  any( strcmp( str, aff ))
    % Make resolution file name
    resolutionFileName = fullfile( resolutionPath, ...
        [ sourceType '_Header_Resolution.csv' ]);
    
    writetable( T, resolutionFileName );
end


