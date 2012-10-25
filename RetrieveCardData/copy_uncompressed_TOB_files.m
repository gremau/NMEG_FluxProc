function success = copy_uncompressed_TOB_files(site, tsdata_filenames)
% COPY_UNCOMPRESSED_TOB_FILES to MyBook drive

site = UNM_sites( site );

success = true;

mybook_letter = locate_drive( 'my book' );
dest_dir = fullfile( sprintf('%c:', mybook_letter), ...
                     'TOB1_TS_DATA_ARCHIVES', ...
                     char( site ) );

for i=1:length(tsdata_filenames)
    fprintf(1, '%s --> %s\n', tsdata_filenames{i}, dest_dir);
    [copy_success, msg, msgid] = copyfile(tsdata_filenames{i}, dest_dir);
    success = success & copy_success;
    if not(success)
        error(msgid, msg);
    end
end
    
            

    