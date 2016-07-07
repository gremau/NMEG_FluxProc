function sites_ds = parse_UNM_site_table()
% PARSE_UNM_SITE_TABLE - parses sites information csv file into a matlab
% dataset.  DEPRECATED.
% 
% THIS FUNCTION IS DEPRECATED!  Use UNM_sites_info instead.  
%
% The file $FLUXROOT/Tower_Information/UNM_flux_site_name_table.csv contains a
% set of information about each UNM site (latitude, longitude, elevation,
% etc.).  parse_UNM_sites_table reads that file and makes its information
% available to processing code that needs it.
%
% INPUTS
%     none
%
% OUTPUTS
%     sites_ds: dataset array containing the information in
%        UNM_flux_site_name_table.csv.
% 
% SEE ALSO
%     dataset, UNM_sites_info
%
% author: Timothy W. Hilton, UNM, Dec 2011

warning('FIXME - this is deprecated, use config files');

sites_file = fullfile( getenv( 'FLUXROOT' ), ...
                       'Tower_Information', ...
                       'UNM_flux_site_name_table.csv' );
sites_ds = dataset( 'File', sites_file, 'delimiter', ',' );
    
