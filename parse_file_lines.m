function [n, flines] = parse_file_lines(fpath)
% PARSE_FILE_LINES - parse an ASCII text file line-by-line into a cell array of
% character strings.
%
% USAGE
%    [ n, flines ] = parse_file_lines( fpath );
%
% INPUTS
%    fpath: character string; full path to the file to be parsed.
%
% OUTPUTS
%    n: numeric; the number of lines parsed from the file
%    flines: cell array of strings; the text from the file, one line per
%        element
%
% author: Timothy W. Hilton, UNM, Oct 2011 

n = 0;

[fid, msg] = fopen( fpath, 'r' );
if fid >= 0
    while ischar(fgetl(fid))
        n = n + 1;
    end

    frewind(fid);
    flines = {};
    tline = 'a';
    while ischar(tline)
        tline = fgetl(fid);
        if (ischar(tline))
            flines(end+1) = cellstr(tline);
        end
    end
    
    fclose(fid);
    
else
    error( msg );
end
