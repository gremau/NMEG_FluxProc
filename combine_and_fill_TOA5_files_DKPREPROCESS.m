function ds = combine_and_fill_TOA5_files( varargin )
% combine_and_fill_TOA5_files() -- combines multiple TOA5 files into one matlab
% dataset, fills in any missing 30-minute time stamps and discards duplicated or
% erroneous timestamp.
%
% Variables not present in all datasets are filled with NaN for timestamps in
% the datasets missing them.  The combined dataset is vetted to make sure each
% thirty-minute timestamp within the period occurs exactly once.  Missing
% timestamps are added and all observed variables filled with NaN.  Where a
% timestamp is duplicated the first is kept and subsequent values for the same
% timestamp are discarded.  Timestamps within two minutes of a "round" thirty
% minute value (i.e. 0 or 30 minutes past the hour) are rounded to the nearest
% hour or half hour.  Timestamps more than two minutes from a round thirty
% minute value are deemed erroneous and discarded.
%
% USAGE
%    ds = combine_and_fill_TOA5_files();
%    ds = combine_and_fill_TOA5_files( 'path\to\first\TOA5\file', ...
%                                      'path\to\second\TOA5\file', ... );
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
% Timothy W. Hilton, UNM, Dec 2011

if nargin == 0
    % no files specified; prompt user to select files
    
    [filename, pathname, filterindex] = uigetfile( ...
        { 'TOA5*.dat','TOA5 files (TOA5*.dat)' }, ...
        'select files to merge', ...
        fullfile( 'C:', 'Research_Flux_Towers', ...
                  'Flux_Tower_Data_by_Site' ), ...
        'MultiSelect', 'on' );
    
    if ischar( filename )
        filename = { filename };
    end
else
    % the arguments are file names (with full paths)
    args = [ varargin{ : } ];
    [ pathname, filename, ext ] = cellfun( @fileparts, ...
                                           args, ...
                                           'UniformOutput', false );
    filename = strcat( filename, ext );
end
    
nfiles = length( filename );
ds_array = cell( nfiles, 1 );

for i = 1:nfiles
    fprintf( 1, 'reading %s\n', filename{ i } );
    
    if  iscell( pathname ) &  ( numel( pathname ) == 1 )
            this_path = pathname{ 1 };
    elseif iscell( pathname )
        this_path = pathname{ i };
    else
        this_path = pathname;
    end
    
    ds_array{ i } = toa5_2_dataset( fullfile( this_path, filename{ i } ) );
    
    toks = regexp( filename{ i }, '_', 'split' );
    % deal with the two sites that have an '_' in the sitename
    if any( strcmp( toks{ 3 }, { 'girdle', 'GLand' }  ) )
        isGlandOrGirdle = true;
        sitecode = UNM_sites.( [ toks{ 2 }, '_', toks{ 3 } ] );
        year = str2num( toks{ 4 } );
    else
        sitecode = UNM_sites.( toks{ 2 } );
        year = str2num( toks{ 3 } );
        isGlandOrGirdle = false;
    end
    
    if ( sitecode == UNM_sites.JSav ) & ( year == 2009 )
        ds_array{ i } = UNM_assign_soil_data_labels_JSav09( ds_array{ i } );
    else
        ds_array{ i } = UNM_assign_soil_data_labels( sitecode, ...
                                                     year, ...
                                                     ds_array{ i } );
    end
        
end

%% -- PREPROCESSING HEADER RESOLUTION -- %%
%Read in a resolution file. These files are lookup tables of all possible
%variable names (that have existed in older program versions), which 
%permit the assignment of old variables to consistent, new formats.

%Ask the user if they want to resolve the headers. If not, process
%picks up at dataset_vercat_fill_vars
prompt = 'Do you want to resolve the headers for this fluxall file? Y/N [Y]: ';

str = input(prompt, 's');

if isempty(str)
    str = 'Y';
end

aff = {'Y','y','YES','yes','Yes'};

%if user input is nothing, or any form of yes, proceed
if  any(strcmp(str, aff))
    
    fprintf( '---------- resolving TOA5 headers ----------\n' );
    
    %Using the sitecode object, open the apropriate header resolution file
    %stored in \TOA5_Header_Resolutions\
    resolutionFile = strcat(char(sitecode), '_Header_Resolutions.csv');
    fopenmessage = strcat('---------- Opening', resolutionFile,' ---------- \n');
    fprintf( fopenmessage );

    %Scan the header line and determine the number of entries
    %(dates) in the resolution file
    fid = fopen(resolutionFile, 'r');
    header = fgetl(fid);
    toks = regexp( header, ',', 'split' );
    numChanges = numel(toks);
    header = toks;
    fclose(fid);
    
    %Read, parse, and reshape the resolutions file
    resolutions_file = textread(resolutionFile, '%s', 'delimiter', ',');
    
    resolutions_length = numel(resolutions_file)/numChanges;
    resolutions_reshaped = reshape(resolutions_file, numChanges, resolutions_length);
    resolutions = resolutions_reshaped';
    
    %Initialize the loop
    count = 1;
    for i = 1:numel( ds_array )
        toks = regexp( filename{ i }, '_', 'split' );
        TOA5_header = ds_array{i}.Properties.VarNames;
        if isGlandOrGirdle
            TOA5_date = [ toks{ 4 }, '_', toks{ 5 },'_', toks{ 6 } ];
        else
            TOA5_date = [ toks{ 3 }, '_', toks{ 4 },'_', toks{ 5 } ];
        end
        if any(strcmp(TOA5_date, header))
            count = count + 1;
            fprintf('Resolving changes for %s \n', TOA5_date);
        end
        for j = 1:length(resolutions)-1
            toResolve(j) = find(strcmp(TOA5_header, resolutions(j + 1, count)));
        end
        for k = 1:length(toResolve)
            TOA5_header{toResolve(k)} = resolutions{k + 1};
        end
        
        %Write the changes to the dataset parameter for headers
        ds_array{i}.Properties.VarNames = TOA5_header;
    end
end





%%


% combine ds_array to single dataset
%ds = dataset_append_common_vars( ds_array{ : } );
ds = dataset_vertcat_fill_vars( ds_array{ : } );

fprintf( 1, 'filling missing timestamps\n' );
thirty_mins = 1 / 48;  %thirty minutes expressed in units of days
ds = dataset_fill_timestamps( ds, ...
                              'timestamp', ... 
                              't_min', min( ds.timestamp ), ...
                              't_max', max( ds.timestamp ) );%datenum( 2012, 6, 1 ) );

% remove duplicated timestamps (e.g., in TX 2010)
fprintf( 1, 'removing duplicate timestamps\n' );
ts = datenum( ds.timestamp( : ) );
one_minute = 1 / ( 60 * 24 ); %one minute expressed in units of days
non_dup_idx = find( diff( ts ) > one_minute );
ds = ds( non_dup_idx, : );

% to save to file, use e.g.:
% fprintf( 1, 'saving csv file\n' );
% idx = min( find( datenum(ds.timestamp(:))>= datenum( 2012, 1, 1)));
% tstamps_numeric = ds.timestamp;
% ds.timestamp = datestr( ds.timestamp, 'mm/dd/yyyy HH:MM:SS' );
% export(ds( idx:end, : ), 'FILE', ...
%        fullfile( get_out_directory(), 'combined_TOA5.csv' ), ...
%        'Delimiter', ',');
% ds.timestamp = tstamps_numeric;