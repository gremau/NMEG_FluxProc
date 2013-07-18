function [success, toa5_fname] = JSavCR1000_2_TOA5( varargin )
% JSavCR1000_2_TOA5 - convert the soil water content from the CR1000 datalogger
% at JSav to a TOA5 file


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addParamValue( 'raw_data_dir', '', @ischar );
args.addParamValue( 'dryrun', false, @islogical );
args.parse( varargin{ : } );
raw_data_dir = args.Results.raw_data_dir;
% -----

if isempty( raw_data_dir );
    raw_data_dir = uigetdir( 'G:\', 'select data file directory' );
end


site = UNM_sites.JSav;

success = true;

thirty_min_file = dir(fullfile(raw_data_dir, '*.soilwcr.dat'));
toa5_data_dir = fullfile(get_site_directory( site ), 'soil');
if isempty(thirty_min_file)
    error('There is no thirty-minute data file in the given directory');
elseif length(thirty_min_file) > 1
    error('There are multiple thirty-minute data files in the given directory');
else
    %create a temporary directory for the TOA5 output
    output_temp_dir = tempname();
    mkdir(output_temp_dir);
    
    %create the configuration file for CardConvert
    toa5_ccf_file = tempname();
    ccf_success = build_TOA5_card_convert_ccf_file(toa5_ccf_file, ...
                                                   raw_data_dir, ...
                                                   output_temp_dir);
    card_convert_exe = fullfile('C:', 'Program Files (x86)', 'Campbellsci', ...
                                'CardConvert', 'CardConvert.exe');
    card_convert_cmd = sprintf('"%s" "runfile=%s"', ...
                               card_convert_exe, ...
                               toa5_ccf_file);

    % run CardConvert
    [convert_status, result] = system(card_convert_cmd);
    success = success & (convert_status == 0);
    if convert_status ~= 0
        error('thirty_min_2_TOA5:CardConvert', 'CardConvert failed');
    end
    
    %rename the TOA5 file according to the site and place it in the
    %site's TOA5 directory
    default_root = sprintf('TOA5_%s',...
                           char(regexp(thirty_min_file.name, ...
                                       '.*\.soilwcr', 'match')));
    default_name = dir(fullfile(output_temp_dir, [default_root, '*']));
    newname = strrep(default_name.name, ...
                     default_root, ...
                     'TOA5_JSav_soilwcr' );
    default_fullpath = fullfile(output_temp_dir, default_name.name);
    newname_fullpath = fullfile(toa5_data_dir, newname);
    if exist(newname_fullpath) == 2
        % if file already exists, overwrite it
        delete(newname_fullpath);
    end
    
    fprintf( '%s --> %s\n', default_fullpath, newname_fullpath );

    move_success = true;
    if not( args.Results.dryrun )
        move_success = ...
            java.io.File(default_fullpath).renameTo(java.io.File(newname_fullpath));
    end
    success = move_success & success;
    if not(move_success)
        error('thirty_min_2_TOA5:rename_fail',...
              'moving TOA5 file to TOA5 directory failed');
    end

    %remove the temporary output directory & CardConvert ccf file
    [rm_success, msgid, msg] = rmdir(output_temp_dir);
    success = rm_success & success;
    %remove the ccf file
    delete(toa5_ccf_file);  %delete seems not to return an output status
end
toa5_fname = newname_fullpath;
