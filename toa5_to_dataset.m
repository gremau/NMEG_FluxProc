function ds = toa5_to_dataset(fpath)
% TOA5_TO_DATASET - convert a toa5 ascii file to a matlab dataset

    var_name_line = 2;
    var_unit_line = 3;
    n_header_lines = 4;
    data_start = n_header_lines + 1;
    
    data = readtext(fpath,'\t,');
    
    var_names = cellstr(char(data{var_name_line, :}));
    var_units = cellstr(char(data{var_unit_line, :}));

    keyboard
    
    %throw out blank columns from the input file.  readtext reads empty elements as
    %NaNs, so a blank column in the input data will come out the same as a
    %column of legitimately missing data.  Blank columns in the input data do
    %not have a header, so we can identify them by blank fields in var_names.
    blank_columns = cellfun(@length, var_names) == 0;
    data = data(:, not(blank_columns));
    var_names = var_names(not(blank_columns));
    var_units = var_units(not(blank_columns));
    
    %readtext reads "NAN" from the input file to a string -- change these to
    %Matlab NaNs
    nan_idx = find(cellfun(@(str) strcmp(str, 'NAN') , data));
    data(nan_idx) = {NaN};
    
    %convert the time stamps into year, month, day, hour, minute vectors
    [year, month, day, hour, min, sec] = datevec(char(data{data_start:end, 1}), ...
                                                 'mm/dd/yyyy HH:MM');
    date = datenum(year, month, day, hour, min, sec);

    %now that the dates, variable names, and units are read, discard these
    %rows and columns so that only numeric data remains
    data = data(n_header_lines + 1:end, 2:end);
    
    %reformat the numeric part into a matlab array
    data = cell2mat(data);
    % replace -9999 with NaN
    data(abs(data + 9999) < 0.000001) = NaN;
    
    
    %remove timestamp and add the date vectors from the numeric data, etc.
    data = [date, year, month, day, hour, min, sec, data];
    var_names = {'date', 'year', 'month', 'day', 'hour', 'min', 'sec', ...
                 var_names{2:end}};
    var_units = {'-', '-', '-', '-', '-', '-', '-', var_units{2:end}};

    %make sure var_names are valid matlab variable names
    var_names = genvarname(var_names);
    
    %build a matlab dataset
    ds = dataset({data, var_names{:}});                
    ds.Properties.Units = var_units;

