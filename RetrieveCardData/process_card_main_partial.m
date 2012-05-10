function main_success = process_card_main_partial( this_site )
% PROCESS_CARD_MAIN - main function for retrieving flux tower data from a flash
%   card:
%    * Copies the raw data from the card to the appropriate 'Raw data from
%      cards' directory
%    * converts 30-minute data to a TOA5 file
%    * converts 10 hz data to TOB1 files
%    * copies the uncompressed TOB1 files to MyBook USB hard drive
%    * copies uncompressed raw data to Story USB hard drive
%    * compresses the raw data on the internal hard drive
%    * FTPs the compressed raw data to EDAC
%
% Timothy W. Hilton, UNM, Dec 2011

    %--------------------------------------------------------------------------
    site_dir = get_site_directory(get_site_code(this_site));

    % % copy the data from the card to the computer's hard drive
    % fprintf(1, '\n----------\n');
    % fprintf(1, 'COPYING FROM CARD TO LOCAL DISK...\n');
    % [card_copy_success, raw_data_dir, mod_date] = ...
    %     retrieve_tower_data_from_card(this_site);

    % use these lines if you need to do a partial transfer or something
    raw_data_dir = fullfile('C:', ...
                            'Research_Flux_Towers', ...
                            'Flux_Tower_Data_By_Site',...
                            this_site, ...
                            'Raw_data_from_cards', ...
                            'Raw_Data_2012', ...
                            'PJ_04-26-12');
    mod_date = datenum(2012, 04, 26, 12, 08, 00 );

    % % convert the thirty-minute data to TOA5 file
    % fprintf(1, '\n----------\n');
    % fprintf(1, 'CONVERTING THIRTY-MINUTE DATA TO TOA5 FORMAT...');
    % [fluxdata_convert_success, toa5_fname] = thirty_min_2_TOA5(this_site, ...
    %                                                   raw_data_dir);
    % fprintf(1, ' Done\n');

    % %make diagnostic plots of the raw flux data from the card
    % fluxraw = toa5_2_dataset(toa5_fname);
    % flux_raw_diagnostic_plot(fluxraw, this_site, mod_date);
    % clear('fluxraw');

    % %convert the time series (10 hz) data to TOB1 files
    % fprintf(1, '\n----------\n');
    % fprintf(1, 'CONVERTING TIME SERIES DATA TO TOB1 FILES...');
    % [tsdata_convert_success, ts_data_fnames] = ...
    %     tsdata_2_TOB1(this_site, raw_data_dir);
    % fprintf(1, ' Done\n');

    % %copy uncompressed TOB1 data to MyBook
    % fprintf(1, '\n----------\n');
    % fprintf(1, 'COPYING UNCOMPRESSED TOB1 DATA TO MYBOOK...\n');
    % copy_uncompressed_TOB_files(this_site, ts_data_fnames);
    % fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');

    % %copy uncompressed raw data to Story
    % fprintf(1, '\n----------\n');
    % fprintf(1, 'COPYING UNCOMPRESSED RAW CARD DATA TO STORY...\n');
    % copy_uncompressed_raw_card_data(this_site, raw_data_dir);
    % fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');

    %compress the raw data on the local drive
    fprintf(1, '\n----------\n');
    fprintf(1, 'COMPRESSING RAW DATA ON INTERNAL DRIVE...\n');
    compress_raw_data_directory(raw_data_dir);
    fprintf(1, 'Done compressing\n');

    % % transfer the compressed raw data to edac
    fprintf(1, '\n----------\n');
    fprintf(1, 'transfering compressed raw data to edac...\n');
    transfer_2_edac(this_site, sprintf('%s.7z', raw_data_dir))
    fprintf(1, 'Done transferring.\n');

