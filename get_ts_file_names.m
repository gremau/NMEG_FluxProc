function fnames = get_ts_file_names( site, date_start, date_end, data_dir );
% within a specified directory find all TOB1 files for a specified site and date
% range.
% 
% GET_TS_FILE_NAMES - returns the full paths of all TOB1 time series data files
%   in a specified directory that contain data recorded between start_date and
%   end_date
% 
% USAGE
%   fnames = get_ts_file_names( site, date_start, date_end )
%
% INPUTS
%   site: site name *string* -- e.g. GLand, MCon, etc.
%   date_start: matlab datenum
%   date_end: matlab datenum
%   data_dir: path to the directory containing the TOB1 files 
%
% OUTPUTS
%   fnames: cell array of file names (with full paths)
%
% SEE ALSO
%   datenum
% 
% author: Timothy W. Hilton, UNM

    if exist(data_dir) ~= 7
        error('get_ts_file_names:dir_not_found',...
              'the requested data directory does not exist');
    else
        fnames = list_files( data_dir, ...
                             'TOB1.*(\.DAT$|\.dat$)' );
    end

    %-----
    %read the time stamps from the file names into matlab datenums
    tstamp_strings = regexp( fnames, ...
                             '\d\d\d\d_\d\d_\d\d_\d\d\d\d', ...
                             'match', 'once' );
    
    % ignore files with no properly-formatted timestamp in the file name
    empty_idx = find( cellfun( @isempty, tstamp_strings ) );
    tstamp_strings( empty_idx ) = [];
    fnames( empty_idx ) = [];
    
    dn = cellfun( @( x ) datenum(x, 'yyyy_mm_dd_HHMM'), ...
                  tstamp_strings, ...
                  'UniformOutput', false );
    dn = [ dn{:} ];
    %-----
    
    % find and return file names from the requested date range
    idx = find(dn >= date_start & dn <= date_end);
    fnames = fnames( idx );

