function ds = parse_flux_raw_file(fname)
% parse_flux_raw_file - reads data from a campbell scientific table-oriented binary
% file (TOB3), returns the data in a matlab dataset 
% written by Timothy W. Hilton, October 2011, based on existing code modified by Krista
% Anderson-Teixeira in January 2008
    
    fid=fopen(fname,'r','ieee-be'); % TOB3 data are big-endian!
    if fid == -1
        err = MException('UNM_data_processor', ...
                         'cannot open file %s\n', fname);
        throw(err);
    end

    % ----  process TOB3 file header ----
    
    headerlines = cell(5,1);
    for i=1:6
        this_line = fgetl(fid);
        headerlines{i} = strrep(this_line, '"', '');
    end

    % split header lines into tokens delimited by commas
    var_names = regexp(headerlines{3}, ',', 'split');
    var_units = regexp(headerlines{4}, ',', 'split');
    var_types = regexp(headerlines{6}, ',', 'split');

    % variable names in matlab cannot contain '.' -- replace with 'p' (for "point")
    var_names = strrep(var_names, '.', 'p');

    % ---- process TOB1 file data ----
    
    % file pointer is now at the end of the header / beginning of the data.  record
    % that position so we can return here to read each variable successively.
    data_start = ftell(fid);
    
    % Nbytes_map = struct('ULONG', 4, 'IEEE4', 4, 'IEEE4L', 4, 'SecNano', 4);
    % matlab_type_map =  struct('ULONG', 'uint32',...
    %                           'IEEE4', 'float32',...
    %                           'IEEE4L', 'float32',...
    %                           'SecNano', 'uint32');
    
    % var_nbytes = cellfun(@(x) getfield(Nbytes_map, x), var_types);
    % var_byte_offset = cumsum(var_nbytes);
    % var_matlab_type = cellfun(@(x) getfield(matlab_type_map, x), var_types);

    % Calculate the number of bytes in a record and get the
    % corresponding matlab precision
    for i=1:length(var_names)
        if strcmp(char(var_types(i)),'ULONG')
            var_nbytes(i) = 4;
            var_matlab_type{i}='uint32';
        elseif not(isempty(strfind(var_types(i), 'IEEE4')))  %IEEE4[LB]
            var_nbytes(i) = 4;
            var_matlab_type{i}='float32';
        elseif strcmp(char(var_types(i)),'SecNano')
            var_nbytes(i) = 4;
            var_matlab_type{i}='uint32';
        end       
    end
    
    %define timestamp, frame header and footer sizes.  The header and footer come before
    %and after the actual data record
    timestamp_nbytes = 8;   
    frame_header_nbytes = 12; % specified in loggernet 4.1 manual section B.4.1
    frame_footer_nbytes = 4;  % specified in loggernet 4.1 manual section B.4.1

    %calculate number of bytes from the beginning of the record to the start
    %of each variable
    var_byte_offset = [0, cumsum(var_nbytes(2:end))];
    
    %initialize empty dataset to contain data read from file
    ds = dataset();  
    for this_var = 1:length(var_names)
        status = fseek(fid, ...
                       data_start + frame_header_nbytes + var_byte_offset(this_var),...
                       'bof');
        % don't want to skip an entire record - want to skip from END of this
        % record's this_var to the BEGINNING of the next record's this_var 
        bytes_to_skip = (frame_header_nbytes + ...
                         sum(var_nbytes) - var_nbytes(this_var) + ...
                         frame_footer_nbytes);
        ds.(var_names{this_var}) = ...
            fread(fid, inf, var_matlab_type{this_var}, bytes_to_skip);
    end
    
    ds.Properties.Units = var_units;

    %read record numbers (last 4 bytes of each 12-byte frame header)
    status = fseek(fid, data_start + timestamp_nbytes, 'bof');
    bytes_to_skip = sum(var_nbytes) + frame_footer_nbytes + timestamp_nbytes;
    record_num = fread(fid, [4, inf], '4*uint8', bytes_to_skip);
    % --
    % the values read represent one 32-bit unsigned integer, least
    % significant byte first.  Now convert to the actual record number.
    %--
    % first convert each 4-element array of uint8 into their 8-bit binary values
    rn_bin = arrayfun(@(x) dec2bin(x, 8), record_num, 'UniformOutput', ...
                      false);
    % concatenate the four 8-bit binary strings together into one 32 bit string
    rn_bin = arrayfun(@(idx) strcat(rn_bin{end:-1:1,idx}), (1:size(rn_bin,2))',...
                      'Uniform', 0);
    % convert the 32-bit binary strings into the decimal record number
    rn_dec = arrayfun(@bin2dec, rn_bin);
    % add the record numbers to the data set
    ds.record_num = rn_dec;
    
    % Many of the TOB3 files contain more records than valid observations.
    % The bogus records have recornd numbers of either 0 or some really big
    % number.  Get rid of these here.
    % (a record number of 1e5 would result from 50 years of 30-minute data
    ds = ds(ds.record_num ~= 0  & ds.record_num < 1e5, :);
    
    
    
    %done reading the input file now
    fclose(fid);
    
