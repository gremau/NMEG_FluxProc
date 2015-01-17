function fnames = get_data_file_names( date_start, date_end, site_code, type )
% GET_TOB1_FILE_NAMES - find all TOB1 or TOA5 files for a specified site and
% date range.
%
% generates a list of filenames containing all TOB1 or TOA5 files within the
% site's data directory that contain data from between start date and end date.
% The directories searched are SITEDIR/ts_data, SITEDIR/TOA5, or SITEDIR/soil,
% where SITEDIR is the output of get_site_directory( site_code ).
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
% SEE ALSO
%   get_site_directory
%
% author: Timothy W. Hilton, UNM, Dec 2011
    
    switch type
      case 'TOA5'
        data_subdir = 'TOA5';
      case 'TOB1'
        data_subdir = 'ts_data';
      case 'soil'
        data_subdir = 'soil';
      otherwise
        err = MException('get_data_file_names:BadDataType', ...
                         [ 'datatype must be from ', ...
                           '{''TOB1'', ''TOA5'', ''soil'' }' ] );
        throw( err );
    end
        
    data_dir = fullfile( get_site_directory( site_code ), ...
                         data_subdir );
    re = '^TO(A5|B1)_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
    fnames = list_files( data_dir, re );
    
    % make datenums for the dates
    dns = cellfun( @get_TOA5_TOB1_file_date, fnames );

    % sort by date
    [ dns, idx ] = sort( dns );
    fnames = fnames( idx );

    % find the files that are within the date range requested
    idx = find( ( dns >= date_start ) & ( dns <= date_end ) );
    % if looking at TOA5 files, included the latest file dated *before* the 
    % start date -- it could contain data from the requested range
    if all( dns < date_start ) & strcmp( type, 'TOA5' )
        idx = numel( dns );
    elseif ( not(strcmp(type, 'ts_data' ))) & ( idx( 1 ) ~= 1 )
        idx = [ idx( 1 ) - 1, idx ];
    end
    fnames = fnames( idx );

%------------------------------------------------------------
