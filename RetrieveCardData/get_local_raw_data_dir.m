function dir_path = get_local_raw_data_dir(site, mod_date)
% GET_LOCAL_RAW_DATA_DIR - builds path to local directory for raw datalogger
% files.
%
% Data are placed within the directory returned by get_site_directory().  Within
% this root, the path returned follows the UNM convention of placing raw data in
% Raw_Data_YYYY/SITE_mm-dd-yy, with YYYY the four-digit year, mm the two-digit
% month, dd the two-digit day of month, and yy the two digit year (all dates and
% time determined from mod_date), and SITE the abbreviated site name determined
% from site argument.
%
% USAGE
%   dir_path = get_local_raw_data_dir(site, mod_date);
%
% INPUTS
%   site: integer code or UNM_sites object; specifies the UNM site.
%   mod_date: Matlab datenumber; the modification date of the datalogger files.
%   
% OUTPUTS
%   dir_path: string; full path to the raw data directory
%
% (c) Timothy W. Hilton, UNM, Oct 2011

warning( sprintf(['This file (get_local_raw_data_dir.m) is deprecated.' ...
    '\nCode moved to retrieve_card_data.m'] ));
    
site = UNM_sites( site );

site_dir = get_site_directory( get_site_code( site ) );
dir_path = fullfile(site_dir, 'Raw_data_from_cards', ...
                    sprintf('Raw_Data_%s', ...
                            datestr(mod_date, 'YYYY')), ...
                    sprintf('%s_%s', ...
                            char( site ), ...
                            datestr(mod_date, 'mm-dd-yy')));
