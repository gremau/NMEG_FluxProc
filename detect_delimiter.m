function delim = detect_delimiter(fpath)
% DETECT_DELIMITER - makes a best guess at the delimiter used in the file
%   
    
    [n, lines] = parse_file_lines(fpath);
    
    n_white = sum(cellfun(@(x) length(regexp(x, '\s', 'start')), lines));
    n_comma = sum(cellfun(@(x) length(regexp(x, ',', 'start')), lines));
    n_semicolon = sum(cellfun(@(x) length(regexp(x, ';', 'start')), lines));

    [m, idx] = max( [ n_white, n_comma, n_semicolon ] );

    switch( idx )
      case 1
        delim = '\s';
      case 2
        delim = ',';
      case 3
        delim = ';';
      otherwise
        delim = NaN;
    end
    