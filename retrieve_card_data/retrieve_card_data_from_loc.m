function [result, dest_dir, mod_date] = ...
    retrieve_card_data_from_loc( site, logger_name, data_loc, mod_date )
% RETRIEVE_CARD_DATA_FROM_LOC - copy raw datalogger data files to appropriate
% directory on local disk.
%
% Locates tower data from card or disk, creates a permanent directory for the
% data under $FLUXROOT if necessary, and copies the data to the permanent
% directory.
%
% USAGE
%    retrieve_card_data_from_loc( site, data_loc )
% INPUTS
%    site: integer or UNM_sites object; site being processed
%    logger_name: string; name of the logger
%    data_loc: string; either 'card' if the data are on a flash card or
%        the path to the directory containing the data if they are already on
%        disk
%
% OUTPUTS
%    result: 0 on success, non-zero on failure
%    dest_dir: string; the directory the data were copied to
%    mod_date: datenum; the modification date for the data
%
% (c) Timothy W. Hilton, UNM, Dec 2011
% Rewritten by Gregory Maurer, UNM, Jan 2016

site = UNM_sites( site );

result = 1;

% Get tower files
tower_files = dir( fullfile( data_loc, '*.dat' ) );

% Error if data_loc is empty
if isempty( tower_files )
    msg = sprintf( 'no data files found in %s', data_loc );
    error( msg );
end

fprintf(1, 'processing tower data files: ');
fprintf(1, '%s ', tower_files.name);
fprintf(1, '\n');

% Loop through list of files and move to directory
for i = 1:numel(tower_files)
    src = fullfile( data_loc, ...
        tower_files( i ).name );
    %create directory for files if it doesn't already exist
    dest_dir = get_local_card_data_dir( site, logger_name, mod_date );
    if exist(dest_dir) ~= 7
        [mkdir_success, msg, msgid] = mkdir(dest_dir);
        result = result & mkdir_success;
        if mkdir_success
            sprintf('created %s', dest_dir);
        else
            error(msgid, msg);
            result = mkdir_success;
        end
    end
    % Move...
    fprintf('%s --> %s...', src, dest_dir);
    [copy_success, msgid, msg] = copyfile(src, dest_dir);
    result = result & copy_success;
    if copy_success
        fprintf('done\n');
    else
        fprintf('\n');
        error(msgid, msg);
    end
end

    function dir_path = get_local_card_data_dir(site, logger_name, mod_date)
    % GET_LOCAL_CARD_DATA_DIR - builds path to local directory for raw datalogger
    % card files.
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
    %   logger_name: character string indicating identity of datalogger
    %   mod_date: Matlab datenumber; the modification date of the datalogger files.
    %
    % OUTPUTS
    %   dir_path: string; full path to the raw card data directory
    %
    % (c) Timothy W. Hilton, UNM, Oct 2011
    % Rewritten by Gregory Maurer, UNM, Jan 2016
        
        site = UNM_sites( site );
        
        card_datestr = datestr(mod_date, 'yyyymmdd');
        card_dvec = datevec( mod_date );
        card_yrstr = num2str( card_dvec( :,1 ));
        
        site_dir = get_site_directory( get_site_code( site ) );
        dir_path = fullfile(site_dir, 'raw_card_data', ...
            [logger_name, '_', card_yrstr], ...
            sprintf('%s_%s_%s', ...
            char( site ), ...
            logger_name, ...
            card_datestr));
    end
end




