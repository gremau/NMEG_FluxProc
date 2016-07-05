

sitecode = UNM_sites.New_GLand;

cardPath = uigetdir( fullfile( get_site_directory( sitecode ), ...
    'Raw_data_from_cards' ), 'Pick a directory to process.' );

% cardPath = get_site_directory( sitecode, 'Raw_data_from_cards', ...
%     ['Raw_Data_' char(year)], '
    
process_card_main( sitecode, 'data_location', 'disk', ...
    'data_path', cardPath );