function dn = get_TOA5_TOB1_file_date( fname )
% returns a matlab datenum for the date contained in a filename of format
% 'TOB1_site_year_month_day_hrmin.dat'.  Helper function for
% get_TOB1_file_names, TOA5_file_headers_2_csv, etc.
%
% USAGE
%   dn = get_TOA5_TOB1_file_date( fname )
%
% author: Timothy Hilton, UNM, Feb 2012
    
    %tokenize the filename into the year, month, etc. components
    [ toks, sz, errmsg, nxtidx ] = sscanf( fname, ...
                                           strcat( '%*[a-zA-Z15]_', ...
                                                   '%*[a-zA-Z]_', ...
                                                   '%d_%d_%d_%2d%2d.dat' ) );
    
    %tokenize the filename into the year, month, etc. components
    re = 'TO(A5|B1)_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
    toks = regexp( fname, re, 'tokens' );
    % pull out year, month, day, hour, minute tokens
    ymdhm = str2double( toks{ 1 }( 2:6 ) );
    seconds = 0;
    % form a matlab datenum
    dn = datenum( [ ymdhm, seconds ] );
    

