function delim = detect_delimiter(fpath)
% DETECT_DELIMITER - makes a best guess at the delimiter used in the file
%   
    
    [n, lines] = parse_file_lines(fpath);
    
    n_tab = cellfun(@(x) length(strfind(x, '\t')), lines);
    n_comma = cellfun(@(x) length(strfind(x, ',')), lines);
    n_semicolon = cellfun(@(x) length(strfind(x, ';')), lines);

    