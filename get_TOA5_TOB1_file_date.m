

function dn = get_TOA5_TOB1_file_date( fname )
% returns a matlab datenum for the date contained in a filename of format
% 'TOB1_site_year_month_day_hrmin.dat'.  Helper function for
% get_TOB1_file_names, TOA5_file_headers_2_csv, etc.
%
% USAGE
%   dn = get_TOA5_TOB1_file_date( fname )
%
% (c) Timothy Hilton, UNM, Feb 2012
    
    %tokenize the filename into the year, month, etc. components
    [ toks, sz, errmsg, nxtidx ] = sscanf( fname, ...
                                           strcat( '%*[a-zA-Z15]_', ...
                                                   '%*[a-zA-Z]_', ...
                                                   '%d_%d_%d_%2d%2d.dat' ) );
    
    % create the matlab datenum, add 0 for seconds
    dn = datenum( [ toks', 0 ] );
