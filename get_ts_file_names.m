function fnames = get_ts_file_names(site, date_start, date_end)
% GET_TS_FILE_NAMES - returns the full paths of all TOB1 time series data files
%   in the site's directory that contain data recorded between start_date and
%   end_date

    data_dir = get_site_directory(get_site_code(site));
    if exist(data_dir) ~= 7
        error('get_ts_file_names:dir_not_found',...
              'the requested data directory does not exist');
    else
        fnames = list_files( fullfile( data_dir, 'ts_data' ), ...
                             'TOB1.*(\.DAT$|\.dat$)');
    end
    
    %read the time stamps from the file names into matlab datenums
    % prefix = sprintf( 'TOB1_%s_', site );
    % tstamp_strings = strrep({fnames.name}, prefix, '');
    % tstamp_strings = regexprep(tstamp_strings, '\.DAT', '', 'ignorecase');
    tstamp_strings = regexp( fnames, ...
                             '\d\d\d\d_\d\d_\d\d_\d\d\d\d', ...
                             'match' );
    dn = cellfun( @( x ) datenum(x, 'yyyy_mm_dd_HHMM'), ...
                  tstamp_strings, ...
                  'UniformOutput', false );
    dn = [ dn{:} ];
    
    % find and return file names from the requested date range
    idx = find(dn >= date_start & dn <= date_end);
    fnames = fnames( idx );

