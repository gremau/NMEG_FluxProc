classdef card_data_processor
properties
    sitecode;
    date_start;
    date_end;
    lag;
    rotation;
    data_10hz_avg;
    data_10hz_already_processed;
    data_30min;
end

methods

% --------------------------------------------------
    function obj = card_data_processor( sitecode, varargin )
    % class constructor
        
    
    % -----
    % parse and typecheck arguments

    p = inputParser;
    p.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
    p.addParamValue( 'date_start', ...
                     [], ...
                     @isnumeric );
    p.addParamValue( 'date_end', ...
                     [], ...
                     @isnumeric );
    p.addParamValue( 'rotation', ...
                     sonic_rotation.threeD, ...
                     @( x ) isa( x, 'sonic_rotation' ) );
    p.addParamValue( 'lag', ...
                     0, ...
                     @( x ) ismember( x, [ 0, 1 ] ) );
    p.addParamValue( 'data_10hz_avg', ...
                     dataset([]), ...
                     @( x ) isa( x, 'dataset' ) );
    p.addParamValue( 'data_30min', ...
                     dataset([]), ...
                     @( x ) isa( x, 'dataset' ) );
    p.addParamValue( 'data_10hz_already_processed', ...
                     false, ...
                     @islogical );
    args = p.parse( sitecode, varargin{ : } );
    
    % -----
    % assign arguments to class fields
    
    obj.sitecode = p.Results.sitecode;    
    obj.date_start = p.Results.date_start;
    obj.date_end = p.Results.date_end;
    obj.lag = p.Results.lag;
    obj.rotation = sonic_rotation( p.Results.rotation );
    obj.data_10hz_avg = p.Results.data_10hz_avg;
    obj.data_30min = p.Results.data_30min;
    obj.data_10hz_already_processed  = p.Results.data_10hz_already_processed;
    
    % if start date not specified, default to 1 Jan of current year
    [ year, ~, ~, ~, ~, ~ ] = datevec( now() );
    if isempty( p.Results.date_start )
        obj.date_start = datenum( year, 1, 1, 0, 0, 0 );
    end
    
    % if end date not specified, default to right now.  This will process
    % everything through the most recent data available.
    if isempty( p.Results.date_end )
        obj.date_end = now();
    end

    % make sure date_start is earlier than date_end
    if obj.date_start > obj.date_end
        err = MException('card_data_processor:DateError', ...
                         'date_end precedes date_start');
        throw( err );
    end
    
    end   %constructor

% --------------------------------------------------

    function [ obj, toa5_files ] = get_30min_data( obj )
    
    toa5_files = get_data_file_names( obj.date_start, ...
                                      obj.date_end, ...
                                      obj.sitecode, ...
                                      'TOA5' );
    
    obj.data_30min = combine_and_fill_TOA5_files( toa5_files );
    
    end  % get_30min_data

% --------------------------------------------------

    function obj = process_10hz_data( obj )
    
    if obj.data_10hz_already_processed
        tob1_files = get_data_file_names( obj.date_start, ...
                                          obj.date_end, ...
                                          obj.sitecode, ...
                                          'TOB1' );
        tstamps = cellfun( @get_TOA5_TOB1_file_date, tob1_files );
        obj.date_end = min( max( tstamps ), obj.date_end );
        
        fname = fullfile( 'C:\Research_Flux_Towers\FluxOut\TOB1_data\', ...
                          sprintf( '%s_TOB1_2012_filled.mat', ...
                                   char( obj.sitecode ) ) );
        load( fname );
        all_data.date = str2num( all_data.date );
        all_data = all_data( all_data.timestamp < obj.date_end, : );
        obj.data_10hz_avg = all_data;
    else

        [ result, obj.data_10hz_avg ] = ...
            UNM_process_10hz_main( obj.sitecode, ...
                                   obj.date_start, ...
                                   obj.date_end, ...
                                   'lag', obj.lag, ...
                                   'rotation', obj.rotation);
    end        
    end  % process_10hz_data

% --------------------------------------------------

    function obj = process_data( obj )
    % Force reprocessing of all data between obj.date_start and obj.date_end.
    
    warning( 'This method not yet implemented\n' );
    
    end  % process_data

% --------------------------------------------------

    function obj = update_fluxall( obj, varargin )
    

    % -----
    % parse and typecheck inputs
    p = inputParser;
    p.addRequired( 'obj', @( x ) isa( x, 'card_data_processor' ) );
    p.addParamValue( 'parse_30min', false, @islogical );
    p.addParamValue( 'parse_10hz', false, @islogical );
    parse_result = p.parse( obj, varargin{ : } );
    
    obj = p.Results.obj;
    parse_30min = p.Results.parse_30min; 
    parse_10hz = p.Results.parse_10hz;
    % -----
    
    % -----
    % if obj has no new data, we must parse the TOA5 and TOB1 data files for
    % the date range requested
    if isempty( obj.data_10hz_avg )
        parse_10hz = true;
    end
    
    if isempty( obj.data_30min )
        parse_30min = true;
    end
    % -----
    
    [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
    fprintf( '---------- parsing fluxall file ----------\n' );
    try
        flux_all = UNM_parse_fluxall_txt_file( obj.sitecode, year );
    catch err
        % if flux_all file does not exist, build it starting 1 Jan
        if strcmp( err.identifier, 'MATLAB:FileIO:InvalidFid' )
            % complete the 'reading fluxall...' message from UNM_parse_fluxall
            fprintf( 'not found.\nBuilding fluxall from scratch\n' );
            flux_all = [];
            obj.date_start = datenum( year, 1, 1 );
        else
            % display all other errors as usual
            rethrow( err );
        end
    end
    
    if parse_30min
        fprintf( '---------- concatenating 30-minute data ----------\n' );
        [ obj, TOA5_files ] = get_30min_data( obj );
    end
    if parse_10hz
        fprintf( '---------- processing 10-hz data ----------\n' );
        obj = process_10hz_data( obj );
    end
        
    save( 'CDP_test_restart.mat' )
    
    fprintf( '---------- merging 30-min, 10-hz, and fluxall ----------\n' );
    
    new_data = merge_data( obj );
    
    if isempty( flux_all )
        flux_all = new_data;
    else
        flux_all = insert_new_data_into_fluxall( new_data, flux_all );
    end
    
    % remove timestamp columns -- they're redundant (because there are
    % already year, month, day, hour, min, sec columns), serial datenumbers
    % aren't human-readable, and character string dates are a pain to parse
    % in matlab
    [ tstamp_cols, t_idx ] = regexp_ds_vars( flux_all, 'timestamp.*' );
    flux_all( :, t_idx ) = [];
    
    fprintf( '---------- writing FLUX_all file ----------\n' );
    write_fluxall( obj, flux_all );
    
    end   % update_data

% --------------------------------------------------

    function new_data = merge_data( obj )
    % MERGE_DATA - merges the 10hz data and the datalogger data together
    %   

    [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );

    % align 30-minute timestamps and fill in missing timestamps
    two_mins_tolerance = 2; % for purposes of joining averaged 10 hz and 30-minute
                            % data, treat 30-min timestamps within two mins of
                            % each other as equal
    t_max = max( [ reshape( obj.data_30min.timestamp, [], 1 ); ...
                   reshape( obj.data_10hz_avg.timestamp, [], 1 ) ] );

    save( 'cdp226.mat' );
    [ obj.data_30min, obj.data_10hz_avg ] = ...
        merge_datasets_by_datenum( obj.data_30min, ...
                                   obj.data_10hz_avg, ...
                                   'timestamp', ...
                                   'timestamp', ...
                                   two_mins_tolerance, ...
                                   obj.date_start, ...
                                   t_max );
    % -----
    % make sure time columns are complete (no NaNs)
    
    % if 30-minute data extends later than the 10hx data, fill in the time
    % columns 
    [ y, mon, d, h, minute, s ] =  datevec( obj.data_10hz_avg.timestamp );
    obj.data_10hz_avg.year = y;
    obj.data_10hz_avg.month = mon;
    obj.data_10hz_avg.day = d;
    obj.data_10hz_avg.hour = h;
    obj.data_10hz_avg.min = minute;
    obj.data_10hz_avg.second = s;

    % make sure all jday and 'date' values are filled in
    obj.data_10hz_avg.jday = ( obj.data_10hz_avg.timestamp - ...
                               datenum( year, 1, 0 ) );
    obj.data_10hz_avg.date = ( obj.data_10hz_avg.month * 1e4 + ...
                          obj.data_10hz_avg.day * 1e2 + ...
                          mod( obj.data_10hz_avg.year, 1000 ) );
    % -----
    
    new_data = horzcat( obj.data_10hz_avg, obj.data_30min );

end


% --------------------------------------------------

    function write_fluxall( obj, fluxall_data )
    % write fluxall data to a tab-delimited text fluxall file
    % USAGE
    %    obj.write_fluxall( fluxall_data )
    
    [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
    t_str = datestr( now(), 'yyyymmdd_HHMM' );
    fname = sprintf( '%s_FLUX_all_%d.txt', ...
                     char( obj.sitecode ), ...
                     year );
    
    full_fname = fullfile( get_site_directory( obj.sitecode ), fname );

    if exist( full_fname )
        bak_fname = regexprep( full_fname, '\.txt', '_bak.txt' );
        fprintf( 'backing up %s\n', fname );
        [copy_success, msg, msgid] = copyfile( full_fname, bak_fname );
    end

    export_dataset_tim( full_fname, fluxall_data )
    
    end   % write_fluxall

% --------------------------------------------------


end % methods

end  % classdef