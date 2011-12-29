function fnames = get_data_file_names( date_start, date_end, site_code, type )
% GET_TOB1_FILE_NAMES - generates a list of filenames containing all TOB1 or
% TOA5 files within the site's data directory that contain data from between
% start date and end date
%   
% INPUTS:
%   date_start: matlab datenumber; the starting date
%   date_end: matlab_datenumber; the ending date
%   site_code: integer; the site numeric code
%   type: string; TOA5 or TOB1
% OUTPUTS:
%   fnames: cell array of strings; list of complete paths of TOB1 files
%
% Timothy W. Hilton, UNM, Dec 2011
    
    switch type
      case 'TOA5'
        data_dir = 'TOA5';
      case 'TOB1'
        data_dir = 'ts_data';
      otherwise
        err = MException('get_data_file_names:BadDataType', ...
                         'datatype must be either ''TOB1'' or ''TOA5''');
        throw( err );
    end
        
    dlst = dir( fullfile( get_site_directory( site_code ), ...
                          data_dir, ...
                          'TOB1*.dat' ) );
    % assign the file names from struct array dlst to a cell array
    fnames = cell( numel( dlst ), 1 );
    [ fnames{ : } ] = dlst( : ).name;
    
    % make datenums for the dates
    dns = cellfun( @get_TOB1_file_date, fnames );  

    % find the files that are within the date range requested
    idx = find( ( dns >= date_start ) & ( dns <= date_end ) );
    fnames = fnames( idx );

%------------------------------------------------------------
function dn = get_TOB1_file_date( fname )
% returns a matlab datenum for the date contained in a filename of format
% 'TOB1_site_year_month_day_hrmin.dat'.  Helper function for get_TOB1_file_names
    
    %tokenize the filename into the year, month, etc. components
    [ toks, sz, errmsg, nxtidx ] = sscanf( fname, ...
                                           strcat( 'TOB1_', ...
                                                   '%*[a-zA-Z]_%d_%d_%d_%2d%2d.dat' ) );
    
    % create the matlab datenum, add 0 for seconds
    dn = datenum( [ toks', 0 ] );
