function [success, all_ts_names] = tsdata_2_TOB1(site, raw_data_dir)
% THIRTY_MIN_2_TOA5 - convert the thirty minute file (*.flux.dat) to a TOA5
% file

site = UNM_sites( site );

success = true;
all_ts_fnames = '';

thirty_min_file = dir(fullfile(raw_data_dir, '*.flux.dat'));
ts_data_file_struct = dir(fullfile(raw_data_dir, '*.ts_data.dat'));
tsdata_dir = fullfile(get_site_directory( site ), 'ts_data');
if isempty(ts_data_file_struct)
    
    % prompt user to select a 10-hz data file
    message = sprintf( ['Cannot find 10-hz data file.  %s does not exist.  ' ...
                        'If there is a 10-hz data file by a different ' ...
                         'name, click "ok" to select it' ], ...
                       fullfile(raw_data_dir, '*.ts_data.dat') );
    h = msgbox( message, 'cannot locate 10-hz data', 'warn', 'modal' );
    waitfor( h );
    
    ts_data_file = uigetfile( fullfile( raw_data_dir, '*' ), ...
                              'select 10-hz data file' );
    
    if ( ts_data_file == 0 )
        error('unable to locate 10-hz data');
        success = false;
        return
    end
    
elseif length(ts_data_file_struct) > 1
    error('There are multiple ts_data files in the given directory');
    success = false;
    return
else
    ts_data_file = ts_data_file_struct.name;
end

%create a temporary directory for the tsdata output
output_temp_dir = tempname();
mkdir(output_temp_dir);

%create the configuration file for CardConvert
tob1_ccf_file = tempname();
ccf_success = build_tsdata_card_convert_ccf_file(tob1_ccf_file, ...
                                                 raw_data_dir, ...
                                                 output_temp_dir);
card_convert_exe = fullfile('C:', 'Program Files (x86)', 'Campbellsci', ...
                            'CardConvert', 'CardConvert.exe');
card_convert_cmd = sprintf('"%s" "runfile=%s"', ...
                           card_convert_exe, ...
                           tob1_ccf_file);

% card convert will try to apply the ccf file to every .dat file in
% the directory.  We want to use a different ccf file for the TS
% data, so temporarily change the .dat extension so CardConvert will
% ignore it for now.
flux_ignore = fullfile(raw_data_dir, ...
                       strrep(thirty_min_file.name, '.dat', '.donotconvert'));
sprintf('%s --> %s\n', fullfile(raw_data_dir, thirty_min_file.name), ...
        flux_ignore);
flux_file_fullpath = fullfile(raw_data_dir, thirty_min_file.name);        
% matlab's movefile takes minutes to rename a 2 GB ts data file.  The
% java method does it instantly though
move_success = ...
    java.io.File(flux_file_fullpath).renameTo(java.io.File(flux_ignore));
success = success & move_success;
if not(move_success)
    error('tsdata_2_TOA5:rename_fail', 'renaming flux data file failed');
end

% run CardConvert
[convert_status, result] = system(card_convert_cmd);
success = success & (convert_status == 0);
if convert_status ~= 0
    error('tsdata_2_TOA5:CardConvert', 'CardConvert failed');
end

%restore the .dat extension on the flux data file
move_success = ...
    java.io.File(flux_ignore).renameTo(java.io.File(flux_file_fullpath));
success = success & move_success;
if not(move_success)
    error('tsdata_2_TOA5:rename_fail',...
          'restoring flux data .dat extension failed');
end

%rename the tob1 files according to the site and place it in the
%site's ts_data directory
default_root = sprintf('TOB1_%s',...
                       char(regexp(ts_data_file, ...
                                   '.*\.ts_data', 'match')));
default_name = dir(fullfile(output_temp_dir, [default_root, '*']));
all_ts_fnames = cell(1, length(default_name));
for i = 1:length(default_name)
    newname = strrep(default_name(i).name,...
                     default_root, sprintf('TOB1_%s', char( site )));
    default_fullpath = fullfile(output_temp_dir, default_name(i).name);
    newname_fullpath = fullfile(tsdata_dir, newname);
    all_ts_names{i} = newname_fullpath;
    if exist(newname_fullpath) == 2
        % if file already exists, overwrite it
        delete(newname_fullpath);
    end
    fprintf(1, '%s --> %s\n', default_fullpath, newname_fullpath);
    move_success = ...
        java.io.File(default_fullpath).renameTo(java.io.File(newname_fullpath));
    success = move_success & success;
    if not(move_success)
        error('thirty_min_2_TOA5:rename_fail',...
              'moving TOA5 file to TOA5 directory failed');
    end
end

%remove the temporary output directory & CardConvert ccf file
[rm_success, msgid, msg] = rmdir(output_temp_dir);
success = rm_success & success;
%remove the ccf file
delete(tob1_ccf_file);  %delete seems not to return an output status



