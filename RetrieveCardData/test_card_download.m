this_site = 'PJ_girdle';
site_dir = get_site_directory(get_site_code(this_site));

% % copy the data from the card to the computer's hard drive
% %[card_copy_success, raw_data_dir] = retrieve_tower_data_from_card(this_site);
mod_date = datenum(2011, 9 ,17);
raw_data_dir = get_local_raw_data_dir(this_site, mod_date);

% % convert the thirty-minute data to TOA5 file
% fprintf(1, '\n----------\n');
% fprintf(1, 'CONVERTING THIRTY-MINUTE DATA TO TOA5 FORMAT...');
% [fluxdata_convert_success, toa5_fname] = thirty_min_2_TOA5(this_site, raw_data_dir);
% fprintf(1, ' Done\n');

% %convert the time series (10 hz) data to TOB1 files
% fprintf(1, '\n----------\n');
% fprintf(1, 'CONVERTING TIME SERIES DATA TO TOB1 FILES...');
% [tsdata_convert_success, ts_data_fnames] = tsdata_2_TOB1(this_site, raw_data_dir);
% fprintf(1, ' Done\n');

% %copy uncompressed TOB1 data to MyBook
% fprintf(1, '\n----------\n');
% fprintf(1, 'COPYING UNCOMPRESSED TOB1 DATA TO MYBOOK...\n');
% copy_uncompressed_TOB_files(this_site, ts_data_fnames);
% fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');

% %compress the raw data on the local drive
% fprintf(1, '\n----------\n');
% fprintf(1, 'COMPRESSING RAW DATA ON INTERNAL DRIVE...\n');
% compress_raw_data_directory(raw_data_dir);
% fprintf(1, 'Done compressing');


% transfer the compressed raw data to edac
fprintf(1, '\n----------\n');
fprintf(1, 'transfering compressed raw data to edac...\n');
transfer_2_edac(this_site, sprintf('%s.7z', raw_data_dir))
fprintf(1, 'Done transferring.\n');

