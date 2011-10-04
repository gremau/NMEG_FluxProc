function [n, flines] = parse_file_lines(fpath)
% DETECT_DELIMITER - makes a best guess at the delimiter character for a
%   delimited ascii data file
%fpath='~/UNM/Data/DataSandbox/TOA5_New_GLand_2010_01_28_1500.dat';    
    n = 0;
    
    [fid, msg] = fopen(fpath);
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
    end
    