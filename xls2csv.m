function result = xls2csv(in_xls, out_csv)
% XLS2CSV - convert an excel file to a csv file
% INPUTS
%   in_xls: string, full path of the excel file to convert
%   out_csv: string, full path of the csv file to create
%
% Timothy W. Hilton, UNM, Sep 2011

    result = 0;  %initialize
    
    % make sure input file exists
    if (exist(in_xls)) ~= 2
        throw(MException('xls2csv',...
                         sprintf('input file %s does not exist', in_xls)));
    else
    
        % read the excel file
        [data, text] = xlsread(in_xls);

        % write the csv file
        fid = fopen(out_csv, 'wt')
        if (fid < 0)
            throw(MException('UNM_Flux_processing:xls2csv',...
                             sprintf('cannot open output file %s', ...
                                     strrep(out_csv, '\', '\\'))));
        else
            % write column headers
            fprintf(fid, '%s\n', strjoin(',', text{:}));
            fclose(fid);
            % append the data
            dlmwrite(out_csv, data, '-append', 'delimiter', ',');
            result = 1;
        end
        
    end
        
        