function ds = toa5_2_dataset(fname)
% TOA5_2_DATASET - parse a TOA5 file to a matlab dataset
% 
% INPUTS:
%    fname: full path of file to be parsed
% OUTPUTS:
%    ds: matlab dataset
%
% Timothy W. Hilton, UNM, Oct 2011
    
    n_header_lines = 4;
    first_data_line = n_header_lines + 1;
    
    % read the header one line at a time
    fid = fopen(fname, 'rt');
    file_lines = textscan(fid, '%s', 'delimiter', '\n', 'BufSize', 1e6);
    fclose(fid);
    file_lines = file_lines{1,1};
    
    %remove quotations from the file text
    file_lines = strrep(file_lines, '"', '');
    
    % separate out variable names and types
    var_names = regexp(file_lines{2}, ',', 'split');
    var_units = regexp(file_lines{3}, ',', 'split');

    %make variable names into valid Matlab variable names -- change '.' (used
    %in soil water content depths) to 'p' and (,) to _
    var_names = strrep(var_names, '.', 'p');
    var_names = strrep(var_names, ')', '_');
    var_names = strrep(var_names, '(', '_');

    % scan the data portion of the matrix into a matlab array
    n_numeric_vars = length(var_names) - 1; % all the variables except
                                            % the timestamp

    fmt = ['%d-%d-%d %d:%d:%d', repmat(',%f', 1, n_numeric_vars)];
    [data, count] = cellfun(@(x) sscanf(x, fmt), ...
                            file_lines(first_data_line:end), ...
                            'UniformOutput', false);
    data = [data{:}]';
    timestamps = data(:, 1:6);
    data = data(:, 7:end);
    
    %build matlab datenums from the timestamps (first six columns of data are
    %year, month, day, hour, minute, second)
    mdn = datenum(timestamps(:, 1:6));
    data = [mdn, data];
    
    ds = dataset({data, var_names{:}});
    ds.Properties.Units = var_units;
    
    
    