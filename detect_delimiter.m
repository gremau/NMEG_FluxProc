function delim = detect_delimiter(fpath)
% DETECT_DELIMITER - makes a best guess between space, tab, comma, and
% semicolon at the delimiter used in a text file by choosing the most
% frequently occuring within the text.
% 
% USAGE
%    delim = detect_delimiter( fpath );
%
% INPUTS
%    fpath: full path to file to analyze
% 
% OUTPUTS
%    delim: character; the best-guess delimiter
%
% (c) Timothy W. Hilton, UNM, Oct 2011
    
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
    