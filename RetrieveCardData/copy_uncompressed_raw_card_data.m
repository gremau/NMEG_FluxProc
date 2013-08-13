function success = copy_uncompressed_raw_card_data(site, raw_data_dir)
% COPY_UNCOMPRESSED_RAW_CARD_DATA - Copies uncompressed raw datalogger files to
% MyBook drive.

% Copies uncompressed raw datalogger files from arbitrary directory to "Raw
% uncompressed data folders\SITE" directory on MyBook drive (with SITE the
% abbreviated site name). Creates this directory if it does not exist. Returns
% true on success.  Issues error on failure.
%
% USAGE
%    success = copy_uncompressed_raw_card_data(site, raw_data_dir);
%
% INPUTS
%    site: integer or UNM_sites object; the site whose data are to be copied,
%        used to choose the destination directory on MyBook.
%    raw_data_dir: full path to the directory containing the raw datalogger
%        files
%
% OUTPUTS
%    success: true if all files copied successfully.
%
% (c) Timothy W. Hilton, UNM, Nov 2011

site = UNM_sites( site );

success = true;

[dir_path, dir_name] = fileparts(raw_data_dir);

mybook_letter = locate_drive('story');
dest_dir = fullfile(sprintf('%c:', mybook_letter), ...
                    'Raw uncompressed data folders', char( site ) );

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




