function delim = detect_delimiter(fpath)
% DETECT_DELIMITER - makes a best guess at the delimiter used in the file
%   
    
    [n, lines] = parse_file_lines(fpath);
    
    n_space = sum(cellfun(@(x) length(regexp(x, ' ', 'start')), lines));
    n_tab = sum(cellfun(@(x) length(regexp(x, '\t', 'start')), lines));
    n_comma = sum(cellfun(@(x) length(regexp(x, ',', 'start')), lines));
    n_semicolon = sum(cellfun(@(x) length(regexp(x, ';', 'start')), lines));

    [m, idx] = max( [ n_space, n_tab, n_comma, n_semicolon ] );

    switch( idx )
      case 1
        delim = ' ';
      case 2
        delim = '\t';
      case 3
        delim = ',';
      case 4
        delim = ';';
      otherwise
        delim = NaN;
    end
    