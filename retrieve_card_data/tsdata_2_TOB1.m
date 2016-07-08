function [success, all_ts_fnames] = tsdata_2_TOB1(site, raw_data_dir,...
    varargin)
% TSDATA_2_TOB1 - convert a datalogger 10-hz raw data file to a series of daily
% TOB1 files in the appropriate directory.
%
% Places the TOB1 files in of the output of get_site_dir().  The file to be
% converted must be named in the format *.ts_data.dat.  If no 10-hz raw data
% file is found, prompts user to select one.  Issues error if multiple files in
% raw_data_dir match *.flux_data.dat.
%
% INPUTS
%    site: integer or UNM_sites object; the site whose data are to be
%        processed
%    raw_data_dir: string; full path to the directory containing the raw
%        datalogger data files.
%
% PARAMETER-VALUE PAIRS
%    wireless: boolean; To patch 10hz data with a wireless data download,
%        create new TOB1 files and put them into a sub-directory of the
%        wireless_data directory.
% 
% OUTPUTS
%    success: logical; true if conversion successful, false otherwise.
%    all_ts_fnames: cell array of strings; full paths to all new TOB1 files.
%
% (c) Timothy W. Hilton, UNM, Oct 2012
% Rewritten by Gregory E. Maurer, UNM, March 2015

site = UNM_sites( site );

args = inputParser;
args.addRequired( 'site', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'raw_data_dir', @ischar );
args.addOptional( 'wireless', false, @islogical );

% parse optional inputs
args.parse( site, raw_data_dir, varargin{ : } );

site = args.Results.site;
raw_data_dir = args.Results.raw_data_dir;

success = true;
all_ts_fnames = '';

thirty_min_file = dir(fullfile(raw_data_dir, '*.flux.dat'));
%ts_data_file_struct = dir(fullfile(raw_data_dir, '*.ts_data.dat'));
ts_data_file_struct = dir(fullfile(raw_data_dir, '*.ts_data*'));

% Select a safe output directory for wireless patches
if args.Results.wireless
   tsdata_dir = fullfile(raw_data_dir, 'ts_data_patch');
else
    tsdata_dir = fullfile(get_site_directory( site ), 'ts_data');
end


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
    if site~=UNM_sites.SLand && site~=UNM_sites.MCon_SS;
        error('There are multiple ts_data files in the given directory');
        success = false;
        return
    else
        ts_data_file = { ts_data_file_struct.name };
    end
else
    ts_data_file =  { ts_data_file_struct.name };
end

%create a temporary directory for the tsdata output
output_temp_dir = tempname();
mkdir(output_temp_dir);

%create the configuration file and command string for CardConvert
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
% data, so if there is a 30-minute file in the directory,
% temporarily change the .dat extension so CardConvert will
% ignore it for now.
if ~isempty(thirty_min_file)
    flux_ignore = fullfile(raw_data_dir, ...
        strrep(thirty_min_file.name, '.dat', '.donotconvert'));
    fprintf(1,'%s --> %s\n', fullfile(raw_data_dir, thirty_min_file.name), ...
        flux_ignore);
    flux_file_fullpath = fullfile(raw_data_dir, thirty_min_file.name);
    % matlab's movefile takes minutes to rename a 2 GB ts data file.  The
    % java method does it instantly though
    move_success = ...
        java.io.File(flux_file_fullpath).renameTo(java.io.File(flux_ignore));
    success = success & move_success;
    if not(move_success)
        error('tsdata_2_TOB1:rename_fail', 'renaming flux data file failed');
    end
end

% run CardConvert
[convert_status, result] = system(card_convert_cmd);
success = success & (convert_status == 0);
if convert_status ~= 0
    error('tsdata_2_TOB1:CardConvert', 'CardConvert failed');
end

if ~isempty(thirty_min_file)
    %restore the .dat extension on the flux data file
    move_success = ...
        java.io.File(flux_ignore).renameTo(java.io.File(flux_file_fullpath));
    success = success & move_success;
    if not(move_success)
        error('tsdata_2_TOB1:rename_fail',...
            'restoring flux data .dat extension failed');
    end
end

% Rename the tob1 files according to the site and place it in the
% site's ts_data directory

% First get the root filename of the original ts_data files from card
ts_data_roots = regexp(ts_data_file, '.*\.ts_data', 'match', 'once');
ts_data_root = unique(ts_data_roots); % Get root filename
% Get the root filename for the converted TOB1 files
default_root = sprintf( 'TOB1_%s', char( ts_data_root ));
% Make lists of files based on the default root (ts_data and ts_data2)
default_name_irga1 = dir(fullfile(output_temp_dir, [default_root, '_*']));
default_name_irga2 = dir(fullfile(output_temp_dir, [default_root, '2_*']));

% Now move and rename all temporary TOB1 files
all_ts1_fnames = cell(1, length(default_name_irga1));
for i = 1:length(default_name_irga1)
    % Take TOB1 filename and rename to our TOB1 naming convention
    tob_fname = default_name_irga1(i).name;
    % First try to pull out the root with the new filename convention
    % (daily numbered ts_data files)
    tob_root_full = regexp(tob_fname, [default_root, '_\d{1,3}_'], ...
        'match', 'once');
    sep = '_'; % will need to replace separator
    % If this gives an empty root, use the older, non-numbered root
    if isempty( tob_root_full )
        tob_root_full = regexp(tob_fname, default_root, 'match', 'once');
        sep = ''; % no separator
    end
    % Construct new name
    newname = strrep(tob_fname, tob_root_full, ...
        [sprintf('TOB1_%s', char( site )), sep ]);
    % Set temp and destination filepaths
    default_fullpath = fullfile(output_temp_dir, tob_fname);
    newname_fullpath = fullfile(tsdata_dir, newname);
    all_ts1_fnames{i} = newname_fullpath;
    if exist(newname_fullpath) == 2
        % if file already exists, overwrite it
        delete(newname_fullpath);
    end
    fprintf(1, '%s --> %s\n', default_fullpath, newname_fullpath);
    move_success = ...
        java.io.File(default_fullpath).renameTo(java.io.File(newname_fullpath));
    success = move_success & success;
    if not(move_success)
        error('tsdata_2_TOB1:rename_fail',...
              'moving TOB1 file to TOB1 directory failed');
    end
end

% If ts_data2 files (second IRGA) are present move them too
if ~isempty(default_name_irga2)
    all_ts2_fnames = cell(1, length(default_name_irga2));
    for i = 1:length(default_name_irga2)
        tob_fname = default_name_irga2(i).name;
        % First try to pull out the root with the new filename convention
        % (daily numbered ts_data files)
        tob_root_full = regexp(tob_fname, [default_root, '2_\d{1,3}_'], ...
            'match', 'once');
        sep = '_'; % will need to replace separator
        % If this gives an empty root, use the older, non-numbered root
        if isempty( tob_root_full )
            tob_root_full = regexp(tob_fname, [default_root, '2'], 'match', 'once');
            sep = ''; % no separator
        end
        % Construct new name
        newname = strrep(tob_fname, tob_root_full, ...
            [ sprintf('TOB1_%s_irga2', char( site )), sep ]);
        default_fullpath = fullfile(output_temp_dir, tob_fname);
        newname_fullpath = fullfile(tsdata_dir, newname);
        all_ts2_fnames{i} = newname_fullpath;
        if exist(newname_fullpath) == 2
            % if file already exists, overwrite it
            delete(newname_fullpath);
        end
        fprintf(1, '%s --> %s\n', default_fullpath, newname_fullpath);
        move_success = ...
            java.io.File(default_fullpath).renameTo(java.io.File(newname_fullpath));
        success = move_success & success;
        if not(move_success)
            error('tsdata_2_TOB1:rename_fail',...
                'moving TOB1 file to TOB1 directory failed');
        end
    end
end

% Put together ts_data and ts_data2 filenames
if exist('all_ts2_fnames', 'var')
    all_ts_fnames = horzcat(all_ts1_fnames, all_ts2_fnames);
else
    all_ts_fnames = all_ts1_fnames;
end

%remove the temporary output directory & CardConvert ccf file
[rm_success, msgid, msg] = rmdir(output_temp_dir);
success = rm_success & success;
%remove the ccf file
delete(tob1_ccf_file);  %delete seems not to return an output status



