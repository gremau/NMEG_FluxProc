function [result, dest_dir, mod_date] = ...
    retrieve_tower_data_from_card( site, data_location )
% RETRIEVE_TOWER_DATA_FROM_CARD - locates tower data from card or disk, creates
% a permanent directory for the data under $FLUXROOT if necessary, and copies
% the data to the permanent directory.
%
% USAGE
%    retrieve_tower_data_from_card( site, data_location )
% INPUTS
%    site: integer or UNM_sites object; site being processed
%    data_location: string; either 'card' if the data are on a flash card or
%        the path to the directory containing the data if they are already on
%        disk
%
% OUTPUTS
%    result: 0 on success, non-zero on failure
%    dest_dir: string; the directory the data were copied to
%    mod_date: datenum; the modification date for the data
%
% (c) Timothy W. Hilton, UNM, Dec 2011

site = UNM_sites( site );

result = 1;

switch data_location
  case 'card'
    % the data are on a flash card    
    %data_path = locate_drive( 'Removable Disk' );
    %% would like a more flexible way to 
    data_location = 'g:\'; 
    tower_files = dir( fullfile( sprintf( '%s', data_location ), ...
                                 '*.dat') );
  otherwise
    tower_files = dir( fullfile( data_location, '*.dat' ) );    
end

if isempty( tower_files )
    msg = sprintf( 'no data files found in %s', data_location );
    error( msg );
end
      
fprintf(1, 'processing tower data files: ');
fprintf(1, '%s ', tower_files.name);
fprintf(1, '\n');

mod_date_arr = [];

for i = 1:numel(tower_files)
    src = fullfile( data_location, ...
                    tower_files( i ).name );
    mod_date_arr( i )  = datenum(tower_files(i).date); %modification date for ...
                                                       % the data file
    mod_date = mod_date_arr( i );
    if any( mod_date_arr > now() )
        error( 'Raw data has modification date in the future' );
    end
    if any( diff( mod_date_arr ) > 1e-6 )
        % if the raw data files have different modification dates, issue
        % warning and use the most recent
        warning( sprintf( [ 'Raw data files have different modification dates.'...
                            '  Using %s (the most recent).\n' ], ...
                          datestr( max( mod_date_arr ) ) ) );
        mod_date = max( mod_date_arr );
    end
end

for i = 1:numel(tower_files)
    src = fullfile( data_location, ...
                    tower_files( i ).name );
    %create directory for files if it doesn't already exist
    dest_dir = get_local_raw_data_dir( site, mod_date);
    if exist(dest_dir) ~= 7
        %     % if directory already exists, throw an error
        %     %error('retrieve_tower_data_from_card:destination error', ...
        %     error(sprintf('%s already exists', dest_dir));
        [mkdir_success, msg, msgid] = mkdir(dest_dir);
        result = result & mkdir_success;
        if mkdir_success
            sprintf('created %s', dest_dir);
        else
            error(msgid, msg);
            result = mkdir_success;
        end
    end
    
    fprintf('%s --> %s...', src, dest_dir);
    [copy_success, msgid, msg] = copyfile(src, dest_dir);
    result = result & copy_success;
    if copy_success
        fprintf('done\n');
    else
        fprintf('\n');
        error(msgid, msg);
    end
end




