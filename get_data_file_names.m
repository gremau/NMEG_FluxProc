function fnames = get_data_file_names( date_start, date_end, site_code, type )
% GET_TOB1_FILE_NAMES - generates a list of filenames containing all TOB1 or
% TOA5 files within the site's data directory that contain data from between
% start date and end date
%
% USAGE:
%   fnames = get_data_file_names( date_start, date_end, site_code, type )
%   
% INPUTS:
%   date_start: matlab datenumber; the starting date
%   date_end: matlab_datenumber; the ending date
%   site_code: integer; the site numeric code
%   type: string; TOA5 or TOB1
% OUTPUTS:
%   fnames: cell array of strings; list of complete paths of TOB1 files
%
% (c) Timothy W. Hilton, UNM, Dec 2011
    
    switch type
      case 'TOA5'
        data_subdir = 'TOA5';
      case 'TOB1'
        data_subdir = 'ts_data';
      otherwise
        err = MException('get_data_file_names:BadDataType', ...
                         'datatype must be either ''TOB1'' or ''TOA5''');
        throw( err );
    end
        
    data_dir = fullfile( get_site_directory( site_code ), ...
                         data_subdir );
    re = '^TO(A5|B1)_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
    fnames = list_files( data_dir, re );
    
    % make datenums for the dates
    dns = cellfun( @get_TOA5_TOB1_file_date, fnames );

    % find the files that are within the date range requested
    idx = find( ( dns >= date_start ) & ( dns <= date_end ) );
    fnames = fnames( idx );

%------------------------------------------------------------
