function success = copy_compressed_raw_card_data(site, local_card_archive)
% COPY_COMPRESSED_RAW_CARD_DATA - Copies compressed raw datalogger card
% files to STORY drive.

% Copies compressed raw datalogger files from arbitrary directory to 
% "raw_card_data_compressed\SITE" directory on Story drive (with SITE the
% abbreviated site name). Creates this directory if it does not exist.
% Returns true on success.  Issues error on failure.
%
% USAGE
%    success = copy_compressed_raw_card_data(site, raw_data_dir);
%
% INPUTS
%    site: integer or UNM_sites object; the site whose data are to be copied,
%        used to choose the destination directory on MyBook.
%    local_card_archive: full path to the local archive of the raw
%        datalogger files
%
% OUTPUTS
%    success: true if all files copied successfully.
%
% (c) Gregory E. Maurer, UNM, March 2016
% Based on copy_uncompressed... by Timothy W. Hilton, UNM, Nov 2011

site = UNM_sites( site );

success = true;

% Create destination directory path on Story in the form:
% "raw_card_data_compressed/SITE/LOGGERNAME_YEAR/"
[archive_path, archive_name, archive_ext] = fileparts(local_card_archive);
archive_path_tokens = strsplit( archive_path, filesep );
story_letter = locate_drive('story');
dest_dir = fullfile(sprintf('%c:', story_letter), ...
                    'raw_card_data_compressed', char( site ), ...
                    archive_path_tokens{ end } );


% Create directory on Story drive for the data files
if ~exist( dest_dir, 'dir' )
    [mkdir_success,msg,msgid] = mkdir(dest_dir);
    success = mkdir_success & success;
else
    mkdir_success = 1;
    success = mkdir_success & success;
end
% Now move files
if (mkdir_success) 
    dest_archive = fullfile(dest_dir, [archive_name, archive_ext] );
else
    error(msgid, msg);
end

% if the directory was made successfully, copy the files there
fprintf(1, '%s --> %s\\%s\n', local_card_archive, dest_archive);
[copy_success, msg, msgid] = copyfile(local_card_archive, dest_archive);
success = success & copy_success;
if not(success)
    error(msgid, msg);
end




