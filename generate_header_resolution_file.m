function ds = combine_and_fill_TOA5_files( varargin )
% combine_and_fill_TOA5_files() -- combines multiple TOA5 files into one matlab
% dataset, fills in any missing 30-minute time stamps and discards duplicated or
% erroneous timestamp.
%
%
% This script is called from card_data_processor after asking for user
% input. Following the creation of a 30 minute TOA5 dataset (by
% combine_and_fill_TOA5_files.m), the combined and filled dataset is
% passed to this script. A header change log is read, and changed header
% columns are merged into one. Prior to merging, the script verifies that
% no data from either column will be overwritten.
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
% Modified by Gregory E. Maurer and Dan Krofcheck, UNM, Sept 2014

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
toa5_date_array = cell( nfiles, 1 );

for i = 1:nfiles
    fprintf( 1, 'reading %s\n', filename{ i } );
    
    if  iscell( pathname ) &&  ( numel( pathname ) == 1 )
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
        sitecode = UNM_sites.( [ toks{ 2 }, '_', toks{ 3 } ] );
        year = str2num( toks{ 4 } );
        month = str2num( toks{ 5 } );
        day = str2num( toks{ 6 } );
        isGlandOrGirdle = true;
    else
        sitecode = UNM_sites.( toks{ 2 } );
        year = str2num( toks{ 3 } );
        month = str2num( toks{ 4 } );
        day = str2num( toks{ 5 } );
        isGlandOrGirdle = false;
    end
    
    % fill in array of TOA5 dates
    toa5_date_array{ i } = datenum(year, month, day);
    
    if ( sitecode == UNM_sites.JSav ) && ( year == 2009 )
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
%picks up at dataset_vertcat_fill_vars
prompt = 'Do you want to resolve the headers for this fluxall file? Y/N [Y]: ';

str = input(prompt, 's');

if isempty(str)
    str = 'Y';
end

aff = {'Y','y','YES','yes','Yes'};

%if user input is nothing, or any form of yes, proceed
if  any(strcmp(str, aff))
    % Open a header resolution logfile.
    resolutionLog = strcat('TOA5_Header_Resolutions\', char(sitecode),...
        '_Header_Resolution_log.txt');
    logfid = fopen(resolutionLog, 'w+');
    disp(['Logging header resolution output to: ' resolutionLog]);
    fprintf(logfid, '\n\n---------- resolving %s TOA5 headers on %s ----------\n',...
        char(sitecode), datestr(now) );
    
    %Using the sitecode object, open the apropriate header resolution file
    %stored in \TOA5_Header_Resolutions\
    sensorSwapsFile = strcat(char(sitecode), '_Sensor_Swaps.csv');
    resolutionFile = strcat(char(sitecode), '_Header_Changes.csv');
    fopenmessage = strcat('---------- Opening ', resolutionFile,' ---------- \n');
    fprintf(logfid, fopenmessage );
    fprintf(1, fopenmessage );
    fopenmessage = strcat('---------- Opening ', sensorSwapsFile,' ---------- \n');
    fprintf(logfid, fopenmessage );
    fprintf(1, fopenmessage );
    
    %Scan the header line and determine the number of entries
    %(dates) in the resolution file
    fid = fopen(resolutionFile, 'r');
    header = fgetl(fid);
    toks = regexp( header, ',', 'split' );
    formatstr = repmat('%s', 1, numel(toks));
    fclose(fid);
    
    %Scan the header line and determine the number of entries
    %(dates) in the resolution file
    fid = fopen(resolutionFile, 'r');
    changelog = textscan(fid, formatstr, 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid);
    current = changelog{1};
    previous = [changelog{2:end}];

    %Read in the sensor swaps file
    fid = fopen(sensorSwapsFile, 'r');
    swaplog = textscan(fid, '%s', 'HeaderLines', 1, 'Delimiter', '\n');
    swaplog = swaplog{1};
    fclose(fid);
    
    % initialize resolution file
    t = table(current);
    
    for i = 1:numel( ds_array )
        % get the current TOA5 file header
        unresolved_TOA5_header = ds_array{i}.Properties.VarNames;
        % initialize the resolved headers array
        resolved_TOA5_header = unresolved_TOA5_header;
        % date of toa5 file
        toa5_date = toa5_date_array{i};
        %Get date string
        filename_toks = regexp( filename{ i }, '\.', 'split' );
        TOA5_date = filename_toks{1};
        TOA5_header = ds_array{i}.Properties.VarNames;
        %if isGlandOrGirdle
        %    TOA5_date = [ 'date_', toks{ 4 }, '_', toks{ 5 },'_', toks{ 6 },'_', toks{ 7 }(1:4) ];
        %else
        %    TOA5_date = [ 'date_', toks{ 3 }, '_', toks{ 4 },'_', toks{ 5 },'_', toks{ 6 }(1:4) ];
        %end
        
        new = repmat({''}, length(current), 1);
        % Should probably just make this the filename
        toa5_changes = table(new, 'VariableNames', {TOA5_date});
        
        
        % for each line in the sensor swap file, switch the headers for
        % the toa5 files that match the switched dates
        fprintf(logfid, 'Resolving sensor swaps for %s \n', filename{i});
        fprintf(1, 'Resolving sensor swaps for %s \n', filename{i});
        for j = 1:length(swaplog)
            swaps = regexp(swaplog{j}, ',', 'split');
            first_toa5_date = datenum(swaps(3), 'YYYY_mm_DD');
            last_toa5_date = datenum(swaps(4), 'YYYY_mm_DD');
            if toa5_date >= first_toa5_date && toa5_date <= last_toa5_date
                fprintf(logfid, '...Swapping %s and %s ...\n',...
                    swaps{1}, swaps{2});
                % Change in header
                loc1 = find(strcmp(resolved_TOA5_header, swaps(1)));
                loc2 = find(strcmp(resolved_TOA5_header, swaps(2)));
                unresolved_TOA5_header(loc1) = swaps(2);
                unresolved_TOA5_header(loc2) = swaps(1);
            end
                
        end
        fprintf(logfid, '...Done... \n');
        
        
        %not_present = ~ismember(s.current, unresolved_TOA5_header);
        %ismember(unresolved_TOA5_header, changelog1{2}(not_present))
        
        % for each line in the header change file, parse out the current
        % header name, then look for earlier header names in the TOA5
        % header and make them current
        fprintf(logfid, 'Resolving header changes for %s \n', filename{i});
        fprintf(1, 'Resolving header changes for %s \n', filename{i});
        for j = 1:length(current)
            curr = current(j); % current header name
            % previous names for this header, removing blanks
            prev = previous(j, ~strcmp(previous(j, :), ''));
            prevloc = ismember(unresolved_TOA5_header, prev);
            currloc = ismember(unresolved_TOA5_header, curr);
            if sum(prevloc) == 1 && sum(currloc) == 0
                resolved_TOA5_header(prevloc) = curr;
                toa5_changes.(TOA5_date)(j) = unresolved_TOA5_header(prevloc);
            elseif sum(prevloc) == 0 && sum(currloc) == 1
                toa5_changes.(TOA5_date)(j) = {'current'};
            elseif sum(prevloc) == 0 && sum(currloc) == 0
                toa5_changes.(TOA5_date)(j) = {'dne'};
            end
        end
        fprintf(logfid, '...Done... \n');
        
        % write resolved header to the dataset parameter for headers
        ds_array{i}.Properties.VarNames = resolved_TOA5_header;
        if exist('old_resolved_TOA5_header')
            still_resolved = ismember(resolved_TOA5_header, ...
                old_resolved_TOA5_header);
            not_resolved = ~still_resolved;
            fprintf(logfid, '%i changes unresolved from last TOA5 file: \n',...
                sum(not_resolved));
            fprintf(logfid, '%s \n', resolved_TOA5_header{not_resolved});
        else
            fprintf(logfid, 'First header resolved \n');
        end
            
        old_resolved_TOA5_header = resolved_TOA5_header;
        
        [t_rows, t_cols] = size(t);
        % Compare elements of most recent table column and new table for
        % changes. If they are NOT identical, append the new table.
        compare = cellfun(@strcmp, t.(t_cols), toa5_changes.(1));
        if sum(compare) < t_rows
            t = [t, toa5_changes];
        end
        clear toa5_changes
    end
    
    
    fclose(logfid);
    
    res_fname = strcat('TOA5_Header_Resolutions\', ...
        char(sitecode), '_Header_Resolutions.csv');
    writetable(t, res_fname)
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
