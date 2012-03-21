function success = copy_uncompressed_raw_card_data(site, raw_data_dir)
% COPY_UNCOMPRESSED_TOB_FILES to MyBook drive
    success = true;
    
    [dir_path, dir_name] = fileparts(raw_data_dir);
    
    mybook_letter = locate_drive('story');
    dest_dir = fullfile(sprintf('%c:', mybook_letter), ...
                        'Raw uncompressed data folders', site);
    
    %make a directory on the external drive for the data files
    [mkdir_success,msg,msgid] = mkdir(dest_dir, dir_name);
    success = mkdir_success & success;
    if (mkdir_success) 
        dest_dir = fullfile(dest_dir, dir_name);
    else
        error(msgid, msg);
    end
    
    % if the directory was made successfully, copy the files there
    fprintf(1, '%s --> %s\\%s\n', raw_data_dir, dest_dir);
    [copy_success, msg, msgid] = copyfile(raw_data_dir, dest_dir);
    success = success & copy_success;
    if not(success)
        error(msgid, msg);
    end

    
            

    