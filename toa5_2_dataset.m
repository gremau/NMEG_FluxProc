function ds = toa5_2_dataset(fname)
% TOA5_2_DATASET - 
%   
    % read the header one line at a time
    fid = fopen(fname);
    n_header_lines = 4;
    header_lines = cell(n_header_lines, 1);
    for i = 1:n_header_lines
        this_line = fgetl(fid);
        header_lines{i} = strrep(this_line, '"', '');
    end
    
    data_start = ftell(fid);
    
    % separate out variable names and types
    var_names = regexp(header_lines{2}, ',', 'split');
    var_units = regexp(header_lines{3}, ',', 'split');

    % read the data portion of the file using textread
    n_numeric_vars = length(var_names) - 1; %all the variables except the timestamp
    fmt = ['"%d-%d-%d %d:%d:%d"', repmat(',%f', 1, n_numeric_vars), ',%s'];
    [data, count] = fscanf(fid, fmt, inf); 

    keyboard()
    
    fmt = ['"%d-%d-%d %d:%d:%d"' repmat('%f', 1, n_numeric_vars)];
    data = cell(1, n_numeric_vars + 6);
    [data{:}] = textread(fname, fmt, 'delimiter', ',', 'headerlines', 4, ...
                         'emptyvalue', NaN);
    