function ds = toa5_2_dataset( fname )
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
    delim = detect_delimiter( fname );
    
    % read file one line at a time into a cell array of strings
    fid = fopen(fname, 'rt');
    file_lines = textscan(fid, '%s', 'delimiter', '\n', 'BufSize', 1e6);
    fclose(fid);
    file_lines = file_lines{1,1};
    
    % if quotes are present in the header line, use them to separate variable names
    % and units.  Some TOA5 files contain quoted variable names that contain the
    % delimiter (!) (e.g. "soil_water_T(8,1)" in a comma-delimited file).
    if isempty( strfind( file_lines{2}, '"' ) )
        % separate out variable names and units using delimiter
        var_names = regexp(file_lines{2}, delim, 'split');
        var_units = regexp(file_lines{3}, delim, 'split');
    else
        % separate out variable names and units using quotes
        var_names = regexp(file_lines{2}, '"(.*?)"', 'tokens');
        var_names = [ var_names{ : } ];  % 'unnest' the cell array
        var_units = regexp(file_lines{3}, '"(.*?)"', 'tokens');
        var_units = [ var_units{ : } ];  % 'unnest' the cell array
    end

    %make variable names into valid Matlab variable names -- change '.' (used
    %in soil water content depths) to 'p' and (,) to _
    var_names = strrep(var_names, '.', 'p');
    var_names = strrep(var_names, ')', '_');
    var_names = strrep(var_names, '(', '_');

    % scan the data portion of the matrix into a matlab array
    n_numeric_vars = length(var_names) - 1; % all the variables except
                                            % the timestamp

    % done with header now
    file_lines = file_lines( first_data_line:end );

    %remove quotations from the file text (some NaNs are quoted)
    file_lines = strrep(file_lines, '"', '');
    
    % ---------
    % parse timestamps into matlab datenums
    %
    % There are a variety of timestamp formats in the TOA 5 files:
    % yyyy/mm/dd, mm/dd/yyyy both appear, sometimes with '-' instead of
    % '/'. Months 1 to 9 are sometimes written with one digit, sometimes two
    % (with leading zero).
    % For times, HH:MM:SS, with seconds somtimes omitted and HH and MM
    % sometimes only having one digit.  This code uses regular expressions to
    % identify the timestamps and pull the numeric components into tokens.
    %
    % match yyyy/mm/dd or mm/dd/yyyy; allow / or - as separator
    date_re = '(\d){1,4}[/-](\d){1,2}[/-](\d){2,4}';
    % match hh:mm or hh:mm:ss, allow one or two digits for all three fields
    time_re = '(\d{1,2}):(\d{1,2})(:(\d{1,2})){0,1}';
    tstamp_re = [ date_re, '\s*', time_re ];
    
    % find timestamps
    [ tstamps, data_idx ] = regexp( file_lines, ...
                                    tstamp_re, 'tokens', 'end' );
    
    % reject lines with no valid timestamp
    has_valid_tstamp = not( cellfun( @isempty, tstamps ) );
    file_lines = file_lines( has_valid_tstamp );
    tstamps = tstamps( has_valid_tstamp );
    data_idx = data_idx( has_valid_tstamp );
    
    % reformulate tstamps to Nx6 array of doubles
    t_num = cell( size( tstamps, 1 ), 6 );
    for i = 1:size( tstamps )
        t_num( i, : ) = tstamps{ i }{ 1 };
        t_num{ i, 6 }  = strrep( t_num{ i, 6 }, ':', '' );
        if isempty( t_num{ i, 6 } )
            t_num{ i, 6 } = '00';
        end
    end
    t_num = cellfun( @str2num, t_num );

    % year could be in column 1 or column 3
    temp = sum( t_num > 2000 );
    year_col = find( temp == max( temp ) );
    if year_col == 1
        month_col = 2;
        day_col = 3;
    elseif year_col == 3
        month_col = 1;
        day_col = 2;
    else
        error( 'invalid_timestamp', 'Error parsing TOA5 timestamp' )
    end

    dn = datenum( t_num( :, [ year_col, month_col, day_col, 4, 5, 6 ] ) );
    
    fmt = repmat( sprintf( '%s%%f', delim ), 1, n_numeric_vars );
    [ data, count ] = cellfun( @( x, idx ) sscanf( x( (idx+1):end ), fmt ), ...
                            file_lines, ...
                            data_idx, ...
                            'UniformOutput', false);
    data = [ data{ : } ]';

    var_names = genvarname( var_names( 2:end ) );
    ds = dataset( { data, var_names{ : } } );
    ds.Properties.Units = var_units( 2:end );
    % add timestamp
    ds.timestamp = dn;
    
    
    