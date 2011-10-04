function fnames = get_ts_file_names(site, date_start, date_end)
% GET_TS_FILE_NAMES - returns the full paths of all TOB1 time series data files
%   in the site's directory that contain data recorded between start_date and
%   end_date

    data_dir = get_site_directory(get_site_code(site));
    if exist(data_dir) ~= 7
        error('get_ts_file_names:dir_not_found',...
              'the requested data directory does not exist');
    else
        fnames = dir(fullfile(data_dir, 'ts_data', 'TOB1*.DAT'));
    end
    
    %read the time stamps from the file names into matlab datenums
    tstamp_strings = strrep({fnames.name}, 'TOB1_TX_', '');
    tstamp_strings = strrep(tstamp_strings, '.DAT', '');
    dn = datenum(tstamp_strings, 'yyyy_mm_dd_HHMM');
    
    % find and return file names from the requested date range
    idx = find(dn >= date_start & dn <= date_end);
    fnames = arrayfun(@(x) getfield(x, 'name'), fnames(idx), 'UniformOutput', false);
    % append the full path to the beginning of each filename
    fnames = cellfun(@(this_f, data_dir) fullfile(data_dir, 'ts_data', this_f), ...
                  fnames, ...
                  repmat({data_dir}, [length(idx), 1]),...
                  'UniformOutput', false);