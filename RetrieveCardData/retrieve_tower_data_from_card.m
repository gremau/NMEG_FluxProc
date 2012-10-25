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
    tower_files = dir( fullfile( sprintf( '%c:', data_path ), ...
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

for i = 1:length(tower_files)
    src = fullfile( data_location, ...
                    tower_files( i ).name );
    mod_date = datenum(tower_files(i).date); %modification date for the
                                             %data file

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




