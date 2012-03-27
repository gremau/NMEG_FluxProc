function dir_path = get_local_raw_data_dir(site, mod_date)
% GET_LOCAL_RAW_DATA_DIR - builds path to directory for local raw data from
%   cards
    
    site_dir = get_site_directory(get_site_code(site));
    dir_path = fullfile(site_dir, 'Raw_data_from_cards', ...
                        sprintf('Raw_Data_%s', datestr(mod_date, 'YYYY')), ...
                        sprintf('%s_%s', site, datestr(mod_date, 'mm-dd-yy')));
