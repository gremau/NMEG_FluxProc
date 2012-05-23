function sites_ds = parse_UNM_site_table()
% PARSE_UNM_SITE_TABLE - parses sites name csv file into a matlab dataset
%   
    
    sites_file = fullfile( getenv( 'FLUXROOT' ), ...
                           'Tower_Information', ...
                           'UNM_flux_site_name_table.csv' );
    sites_ds = dataset( 'File', sites_file, 'delimiter', ',' );
    
