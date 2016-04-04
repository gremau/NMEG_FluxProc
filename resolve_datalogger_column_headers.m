function TArray_Out = resolve_datalogger_column_headers( ...
    TArray_In, fileNames, resFilePath )
% resolve_datalogger_column_headers() -- resolves changes in datalogger
% file column headers using a header resolution file.
%
% FIXME - documentation
%
% USAGE
%   TArray_Out = resolve_datalogger_column_headers(TArray_In, ...
%                                                       sitecode, ...
%                                                       dataloggerName);
%
% INPUTS:
%   'TArray_In': cell array; a cell array of Matlab tables, each
%       containing data and headers from a datalogger file.
%   'fileNames': cell array; array of strings indicating the data file
%       names to resolve. Filename format must be
%       'FILETYPE_SITECODE_YYYY_MM_DD_HHMM.dat', and all names in array
%       should have identical FILETYPE and SITECODE.
%   'dataloggerName': string; string designating the datalogger name.
%       Used to find the correct header resolution file
%
% OUTPUTS
%    TArray_Out: cell array; a cell array of Matlab tables, as above,
%       but with resolved headers
%
% SEE ALSO
%    combine_and_fill_datalogger_files.m, table,
%    table_fill_timestamps, toa5_2_table, cr23x_2_table
%
% Gregory E. Maurer, UNM, Oct, 2014

% == PREPROCESSING HEADER RESOLUTION ===
% Read in resolution file. These files are lookup tables of all possible
% variable names (that have existed in older program versions), which
% permit the assignment of old variables to consistent, new formats.
fprintf( '---------- resolving column headers ----------\n' );
fOpenMessage = [ 'Opening %s ... \n' ];
fprintf( fOpenMessage, resFilePath );

try
    Resolutions = readtable( resFilePath );
    % First three columns not used here - remove
    Resolutions = Resolutions( :, 4:end );
catch
    error( sprintf( '%s file does not load!', resFilePath ));
end

% Make sure files are sorted in chronological order
[~, idx] = sort( fileNames );
if not( isequal( idx, 1:length( fileNames ) ) )
    error('Files are not sorted properly');
end

% Get date array
fileDateArray = tstamps_from_filenames( fileNames );

%Read and parse the resolution file
[numHeaders, numDates] = size( Resolutions );
resColumns = Resolutions.Properties.VariableNames;
resDates = tstamps_from_filenames( resColumns( 2:end ) );

% Choose initial column to resolve headers - if the first data file to
% resolve is not named as a header in the resolution file, this will be
% the column immediately before that data file.
col = find( resDates <= fileDateArray(1) );
if isempty( col )
    error('The headers have not been resolved this far back!');
else
    resolveCol = resColumns{ max( col ) + 1 };
    fprintf( 'Beginning with headers from %s \n', resolveCol );
end

% Make a copy of the original table
TArray_Out = TArray_In;

%Initialize the loop
for i = 1:numel( TArray_In )
    toResolve = zeros( numHeaders, 1 );
    dataFileHeader = TArray_In{ i }.Properties.VariableNames;
    % Get the name of the data file
    fnameTokens = regexp( fileNames{ i }, '\.', 'split' );
    dataFileName = fnameTokens{ 1 };
    % Subsequent data files resolve the same until a new column is found
    if any(strcmp( dataFileName, resColumns ))
        resolveCol = dataFileName;
        fprintf( 'Resolving changes for %s \n', resolveCol );
    end
    % Read old headers locations into toResolve, replace with current
    for j = 1:numHeaders
        oldHeader = Resolutions.( resolveCol ){ j };
        % Resolve header only if oldHeader exists and is not current. When
        % this fails it can be pretty hard to debug, so generate some debug
        % output. Might also be nice to call up another header resolution
        % script from here...
        if ~( strcmp( oldHeader, 'dne' ) || strcmp( oldHeader, 'current' ))
            try
                toResolve( j ) = find( strcmp( dataFileHeader, oldHeader ));
            catch ME
                switch ME.identifier
                    case 'MATLAB:badRectangle'
                        fprintf( 'oldHeader "%s" not found in %s \n', ...
                            oldHeader, dataFileName );
                end
                rethrow( ME );
            end
        end
    end
    % Fill in toResolve locations with current header name
    for k = 1:length( toResolve )
        if toResolve( k ) ~= 0
            dataFileHeader{toResolve( k )} = Resolutions.current{ k };
        end
    end
    
    %Write the changes to the table parameter for headers
    TArray_Out{ i }.Properties.VariableNames = dataFileHeader;
end
end

