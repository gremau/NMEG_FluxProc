this_site = 'PJ_girdle';

[card_copy_success, mod_date] = retrieve_tower_data_from_card('PJ_girdle');
mod_date = datenum(2011, 9, 17);
site_dir = get_site_directory(get_site_code(this_site));
raw_data_dir = get_local_raw_data_dir(this_site, mod_date);
ts_data_dir = fullfile(site_dir, 'ts_data');
toa5_data_dir = fullfile(site_dir, 'toa5');

toa5ccf_success = build_TOA5_card_convert_ccf_file(fullfile(site_dir, 'toa5.ccf'), ...
                                                  raw_data_dir, ...
                                                  toa5_data_dir);

%"C:\Program Files (x86)\Campbellsci\CardConvert\CardConvert.exe