function process_card_JSav_CR1000_main()
% PROCESS_CARD_MAIN_JSAV_CR1000_MAIN - integrates JSav soil water content data
%   from raw datalogger file into fluxall file.  Performs these steps:
% 1) copies raw file from card to local disk
% 2) converts raw file to TOA5 file on local disk
% 3) compresses raw file using 7zip
% 4) integrates data into fluxall file
%
% (c) Timothy W. Hilton, UNM, Dec 2012

[ data_dir, mod_date ] = retrieve_JSav_CR1000_data();
[success, toa5_fname] = JSavCR1000_2_TOA5( 'raw_data_dir', data_dir );
success = compress_raw_data_directory( data_dir );

h = msgbox( 'click to begin FTP transfer', '' );
waitfor( h );
success = transfer_2_edac( UNM_sites.JSav, sprintf('%s.7z', data_dir) );

[ y, ~, ~, ~, ~, ~ ] = datevec( mod_date );
ds = JSav_CR1000_to_dataset( y );

fluxall = UNM_parse_fluxall_txt_file( UNM_sites.JSav, y );

keyboard
% now merge ds and fluxall
