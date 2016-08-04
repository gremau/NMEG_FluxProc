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
    flux_data_config;
    data_30min_secondary;
    insert_secondary_data;
    secondary_data_config;
end

methods

    % --------------------------------------------------
    function obj = card_data_processor( sitecode, varargin )
        % Class for processing raw datalogger data files and inserting their
        % data into UNM annual FluxAll files.
        %
        % The class constructor for card_data_processor (CDP) creates a new
        % CDP and initializes fields.  The main top-level method for the class
        % is update_fluxall.  Typical use of CDP class, then, would look
        % something like:
        %
        %     cdp = card_data_processor( UNM_sites.WHICH_SITE, options );
        %     cdp.update_fluxall();
        %
        % INPUTS:
        %    sitecode: UNM_sites object; the site to process
        % OPTIONAL PARAMETER-VALUE PAIRS:
        %    'date_start': matlab serial datenumber; date to begin processing.
        %        If unspecified default is 00:00:00 on 1 Jan of current year
        %        (that is, the year specified by now()).
        %    'date_end': Matlab serial datenumber; date to end processing.  If
        %        unspecified the default is the current system time (as
        %        provided by now()).
        %    'rotation': sonic_rotation object; specifies rotation.  Defaults
        %        to 3D.
        %    'lag': 0 or 1; lag for 10hz data processing. defaults to 0.
        %    'data_10hz_avg': table array; Allows previously processed 10hz
        %        data to be supplied for insertion into FluxAll file.  If
        %        unspecified the necessary 10-hz data files will be located
        %        and processed to 30-minute averages.
        %    'data_30min': table array; Allows 30-minute data to be supplied
        %        for insertion into FluxAll file.  If unspecified all TOA5
        %        files containing data between date_start and date_end are
        %        parsed and combined.
        %    'data_30min_secondary': table array; Allows 30-minute data from
        %        a secondary datalogger to be supplied for insertion into a
        %        FluxAll file. If unspecified, all data from the site's
        %        secondary loggers between date_start and date_end are parsed
        %        and combined. Secondary loggers are specified in a
        %        configuration file.
        %    'insert_secondary_data': {true}|false; if true and
        %        data_30min_secondary is unspecifed, CDP loads secondary
        %        datalogger files according to each site's individal parse
        %        files. If false, all secondary data processing steps ignored.
        %    'data_10hz_already_processed': true|{false}; if true and
        %        data_10hz_avg is unspecified CDP loads processed 10hz data
        %        from $FLUXROOT/FluxOut/TOB1_data/SITE_TOB1_YYYY_filled.mat,
        %        with SITE the character representation of sitecode and YYYY
        %        the present year (as returned by now())
        %
        % SEE ALSO
        %    sonic_rotation, UNM_sites, table, now, datenum
        %
        % author: Timothy W. Hilton, UNM, 2012, extensively modified by
        %         Gregory Maurer, UNM, 2014-2015

        % -----
        % parse and typecheck arguments

        p = inputParser;
        p.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
        p.addParameter( 'date_start', ...
            [], ...
            @isnumeric );
        p.addParameter( 'date_end', ...
            [], ...
            @isnumeric );
        p.addParameter( 'rotation', ...
            sonic_rotation.threeD, ...
            @( x ) isa( x, 'sonic_rotation' ) );
        p.addParameter( 'lag', ...
            0, ...
            @( x ) ismember( x, [ 0, 1 ] ) );
        p.addParameter( 'data_10hz_avg', ...
            table([]), ...
            @( x ) isa( x, 'table' ) );
        p.addParameter( 'data_30min', ...
            table([]), ...
            @( x ) isa( x, 'table' ) );
        p.addParameter( 'data_30min_secondary', ...
            table([]), ...
            @( x ) isa( x, 'table' ) );
        p.addParameter( 'data_10hz_already_processed', ...
            false, ...
            @islogical );
        p.addParameter( 'insert_secondary_data', ...
            true, ...
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
        obj.data_30min_secondary = p.Results.data_30min_secondary;
        obj.data_10hz_already_processed  = p.Results.data_10hz_already_processed;
        obj.insert_secondary_data = p.Results.insert_secondary_data;
        obj.flux_data_config = [];
        obj.secondary_data_config = [];

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
        
        obj = get_logger_config( obj );

    end %constructor

    % --------------------------------------------------

    function [ obj, toa5_files ] = get_30min_data( obj )
        % Obtain 30-minute data for a card_data_processor (CDP) from TOA5 files.
        %
        % Parses all TOA5 files containing data between obj.date_start and
        % obj.date_end, concatenates their data and makes sure timestamps
        % include all 30-minute intervals between obj.date_start and
        % obj.date_end without duplicated timestamps, and places the data into
        % obj.data_30min.
        %
        % USAGE:
        %    [ obj, toa5_files ] = get_30min_data( obj )
        % INPUTS:
        %    obj: card_data_processor object
        % OUTPUTS:
        %    obj: CDP object with data_30min field updated.
        %    toa5_files: cell array; the TOA5 files whose data were added.
        
        toa5_files = get_loggernet_filenames( obj.sitecode, ...
            obj.date_start, obj.date_end, 'TOA5' );

        obj.data_30min = combine_and_fill_datalogger_files( ...
            obj.sitecode, 'TOA5', ...
            'file_names', toa5_files, ...
            'resolve_headers', obj.flux_data_config(1).resolve_headers, ...
            'datalogger_name', obj.flux_data_config(1).name );

    end  % get_30min_data

    % --------------------------------------------------

    function obj = get_logger_config( obj )
        % Fill in the obj.flux_data_config and obj.secondary_data_config 
        % properties with info from the Dataloggers YAML config file
        
        % Get configuration from the site's YAML config file
        conf = parse_yaml_config( obj.sitecode, 'Dataloggers', ...
            [obj.date_start, obj.date_end] );
        % Separate out the secondary logger configs (not 'flux')
        dl_list = conf.dataloggers;
        if length( dl_list ) > 1
            secondaries = cellfun( @isempty, regexp(...
                {dl_list.name}, 'flux' ));
            flux_conf = dl_list( ~secondaries );
            sec_conf = dl_list( secondaries );
            obj = conf_within_dates( flux_conf, obj, 'flux_data_config' );
            obj = conf_within_dates( sec_conf, obj, 'secondary_data_config' );
        else
            obj.flux_data_config = dl_list(1);
            fprintf( 'No secondary data sources configured. Reset flag.\n');
            obj.insert_secondary_data = false;
            return
        end
        
        function obj = conf_within_dates( conf_in, obj, conf_field )
            % Initialize counter and flag indicating whether the flux or 
            % secondary data range in config overlaps obj.date_start and 
            % obj.date_end
            objConfIdx = 1;
            overlap_flag = false;
            
            % Loop through each secondary source and put a configuration
            % struct into obj.secondary_data_config for each data source
            % that overlaps obj.date_start and obj.date_end
            for i = 1:numel( conf_in );
                data_start = datenum( conf_in( i ).start_date, ...
                    'YYYY-mm-DD HH:MM');
                data_end = datenum( conf_in( i ).end_date, ...
                    'YYYY-mm-DD HH:MM');
                overlap_flag = data_start <= obj.date_end && ...
                    data_end >= obj.date_start ;
                % Merge into fluxall flag
                merge_flag = conf_in( i ).merge_30min;
                if overlap_flag && merge_flag
                    if objConfIdx==1
                        % First iteration changes empty array to struct
                        obj.( conf_field ) = conf_in( i );
                    else
                        obj.( conf_field )( objConfIdx ) = conf_in( i );
                    end
                    objConfIdx = objConfIdx + 1;
                end
            end
        end %conf_within_dates
    end %get_logger_config

    % --------------------------------------------------

    function [ obj, secondary_files ] = get_secondary_data( obj )
        % Obtain 30-minute data for a CDP from secondary datalogger files.
        %
        % Parses the data from a secondary datalogger specified for
        % each site. TOA5 and CR23X files are parsed/resolved using
        % standard methods. Only data between obj.date_start and
        % obj.date_end is preserved and all data have timestamps checked.
        % This function then places the data into obj.data_30min_secondary.
        %
        % USAGE:
        %    [ obj, secondary_files ] = get_second_logger_data( obj )
        % INPUTS:
        %    obj: card_data_processor object
        %    conf: configuration for second datalogger
        % OUTPUTS:
        %    obj: CDP object with data_30min_secondary field updated.
        %    secondary_files: cell array; the filenames whose data were added.

        % Year to get data for
        [ year, ~ ] = datevec( obj.date_start );

        table_array = {};
        for i = 1:numel( obj.secondary_data_config );
            conf = obj.secondary_data_config( i );
            %Initialize an empty table
            i_data = table([]);
            % Get the secondary data by file/datalogger type
            switch lower( conf.conv_file_fmt )
                case 'toa5'
                    % Get loggernet data (if files exist)
                    secondary_files = get_loggernet_filenames( ...
                        obj.sitecode, obj.date_start, obj.date_end, 'TOA5', ...
                        'subdir', conf.conv_file_loc );
                    if ~isempty( secondary_files )
                        i_data = combine_and_fill_datalogger_files( ...
                            obj.sitecode, 'TOA5', ...
                            'file_names', secondary_files, ...
                            'resolve_headers', conf.resolve_headers, ...
                            'datalogger_name', conf.name );
                    end
                case 'cr23x'
                    % Get cr23x data (if files exist)
                    secondary_files = get_cr23x_filenames( ...
                        obj.sitecode, obj.date_start, obj.date_end, ...
                        conf.conv_file_loc );
                    if ~isempty( secondary_files )
                        i_data = combine_and_fill_datalogger_files( ...
                            obj.sitecode, 'cr23x', ...
                            'file_names', secondary_files, ...
                            'resolve_headers', conf.resolve_headers, ...
                            'datalogger_name', conf.name );
                    end
                case 'other'
                    secondary_files = {};
                    % Get data from sites we don't manage
                    if obj.sitecode == UNM_sites.PPine;
                        i_data = get_PPine_DRI_data( year );
                    elseif obj.sitecode == UNM_sites.MCon;
                        i_data = get_MCon_SAHRA_data( year );
                    else
                        warning( 'No external data for this site' );
                    end
            end
            % Put in table array
            table_array{ i } = i_data;
        end
        % Loop through each table in table_array and merge into
        % a 30min table to add to obj.data_30min_secondary
        secondary_data = table_array{ 1 };
        if numel( table_array ) > 1
            for j = 2:numel( table_array )
                secondary_data = table_foldin_data( ...
                    secondary_data, table_array{ j });
            end
        end
        % There isn't always data available, but if there is
        % trim data to obj.date_start <==> obj.date_end
        if ~isempty( secondary_data );
            idx = ( secondary_data.timestamp >= obj.date_start ) & ...
                ( secondary_data.timestamp <= obj.date_end );
            obj.data_30min_secondary = secondary_data( idx, : );
        end

    end  % get_secondary_data

    % --------------------------------------------------

    function obj = process_10hz_data( obj )
        % Place processed 10hz data into data_10hz field of card_data_processor
        % (CDP).
        %
        % If obj.data_10hz_already_processed is false, processes all TOB1 files
        % containing data between obj.date_start and obj.date_end to 30-minute
        % averages, concatenates their data and makes sure timestamps include all
        % 30-minute intervals between obj.date_start and obj.date_end without
        % duplicated timestamps, and places the data into obj.data_10hz_avg.
        % If obj.data_10hz_already_processed is true, reads pre-processed data
        % from .mat file (see docs for card_data_processor constructor).
        %
        % USAGE:
        %    [ obj ] = process_10hz_data( obj )
        % INPUTS:
        %    obj: card_data_processor object
        % OUTPUTS:
        %    obj: CDP object with data_10hz field updated.

        if obj.data_10hz_already_processed
            tob1_files = get_loggernet_filenames( obj.sitecode, ...
                obj.date_start, obj.date_end, ...
                'TOB1' );
            % Not sure why this is here. It truncates the data if there
            % are missing TOB1 files at end of year - GEM
            %tstamps = cellfun( @get_TOA5_TOB1_file_date, tob1_files );
            %obj.date_end = min( max( tstamps ), obj.date_end );

            [ this_year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
            fname = fullfile( getenv('FLUXROOT'), 'FluxOut/TOB1_data/', ...
                sprintf( '%s_TOB1_%d_filled.mat', ...
                char( obj.sitecode ), ...
                this_year ) );
            load( fname );
            all_data.date = str2num( all_data.date );
            % This data is always missing the last 30 minute period in the
            % year (only goes to Dec 31, 23:30)
            all_data = all_data( all_data.timestamp <= obj.date_end, : );
        else
            % If receiving memory errors, reduce period_n_days
            [ result, all_data ] = ...
                UNM_process_10hz_main( obj.sitecode, ...
                obj.date_start, ...
                obj.date_end, ...
                'lag', obj.lag, ...
                'rotation', obj.rotation);%, ...
                %'period_n_days', 5);
        end
        % Card_data_processor takes tables, so change if need be
        if isa( all_data, 'dataset' )
            warning(' Converting 10hz data from dataset to table.');
            all_data = dataset2table( all_data );
        end
        % Add to cdp obj
        obj.data_10hz_avg = all_data;
    end  % process_10hz_data

    % --------------------------------------------------

    function obj = process_data( obj )
        % Force reprocessing of all data between obj.date_start and obj.date_end.
        warning( 'This method not yet implemented\n' );

    end  % process_data

    % --------------------------------------------------

    function obj = update_fluxall( obj, varargin )
        % merges new 30-minute and processed 10-hz data into the site's
        % fluxall_YYYY file.
        %
        % Moves the existing SITE_fluxall_YYYY.txt to SITE_fluxall_YYYY.bak
        % before writing SITE_fluxall_YYYY.txt with the new data.
        %
        % If obj.data_10hz_avg is empty, calls process_10_hz
        % method.  If obj.data_30min is empty, calls get_30min_data method.
        %
        % USAGE
        %    obj.update_fluxall()

        % -----
        % parse and typecheck inputs
        p = inputParser;
        p.addRequired( 'obj', @( x ) isa( x, 'card_data_processor' ) );
        p.addParameter( 'parse_30min', false, @islogical );
        p.addParameter( 'parse_30min_secondary', false, @islogical );
        p.addParameter( 'parse_10hz', false, @islogical );
        parse_result = p.parse( obj, varargin{ : } );

        obj = p.Results.obj;
        parse_30min = p.Results.parse_30min;
        parse_30min_secondary = p.Results.parse_30min_secondary;
        parse_10hz = p.Results.parse_10hz;
        % -----

        % Get the datalogger configurations
        obj = get_logger_config( obj );
        
        % if obj has no new data, we must parse the TOA5 and TOB1 data files for
        % the date range requested
        if isempty( obj.data_10hz_avg )
            parse_10hz = true;
        end

        if isempty( obj.data_30min )
            parse_30min = true;
        end

        % Check for secondary data sources ( if we are not ignoring them )
        if obj.insert_secondary_data
            % Verify that there is data to add and reset flag if needed
            if numel( obj.secondary_data_config ) == 0
                fprintf( 'Secondary data sources outside of date_start and date_end. Reset flag.\n');
                obj.insert_secondary_data = false;
            end
        end

        % If there is secondary data, parse it
        if isempty( obj.data_30min_secondary ) && obj.insert_secondary_data
            parse_30min_secondary = true;
        end

        % -----

        [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
        fprintf( '---------- parsing fluxall file ----------\n' );
        try
            flux_all = parse_fluxall_txt_file( obj.sitecode, year );
        catch err
            % if flux_all file does not exist, build it starting 1 Jan
            if strcmp( err.identifier, 'MATLAB:FileIO:InvalidFid' )
                % complete the 'reading fluxall...' message from UNM_parse_fluxall
                fprintf( 'not found.\nBuilding fluxall from scratch\n' );
                flux_all = [];
                obj.date_start = datenum( year, 1, 1, 0, 30, 0);
            else
                % display all other errors as usual
                rethrow( err );
            end
        end

        if parse_30min
            fprintf( '---------- concatenating 30-minute data ----------\n' );
            [ obj, TOA5_files ] = get_30min_data( obj );
        end
        if parse_30min_secondary
            fprintf( '--- concatenating secondary 30-minute data sources ---\n' );
            [ obj, secondary_data_files ] = get_secondary_data( obj );
            fprintf( '--- folding in 30-minute data from logger 2 ---\n' );
            obj.data_30min = table_foldin_data(...
                obj.data_30min, obj.data_30min_secondary );
        end
        if parse_10hz
            fprintf( '---------- processing 10-hz data ----------\n' );
            obj = process_10hz_data( obj );
        end

        save( fullfile( getenv( 'FLUXROOT' ), 'FluxOut', ...\
            'CDP_test_restart.mat' ));

        fprintf( '---------- merging 30-min, 10-hz, and fluxall ----------\n' );

        new_data = merge_data( obj );

        % trim new_data down so it only includes time stamps between obj.date_start and
        % obj.date_end. Without this, can introduce gaps in the fields derived from
        % 10hz observations.  TOB1 files are daily, so in the 10-hz processing phase
        % cdp will read at most <24 hours of data on either side that falls outside
        % of ( date_start, date_end ).  TOA5 files span about a month, though, so if
        % date_end falls, say, two weeks into a four-week TOA5 file new_data will
        % contain about two weeks of data (from date_end to the end of the TOA5 file
        % that contains date_end) of thirty-minute data with no accompanying data
        % for the fields derived from 10-hz observations.  This manifests itself as
        % a "gap" in the 10-hz-derived fields in the updated fluxall, when in
        % reality the data exist but were not read.  Trimming new_data avoids this
        % problem.
        idx_keep = ( new_data.timestamp >= obj.date_start ) & ...
            ( new_data.timestamp <= obj.date_end );
        new_data = new_data( idx_keep, : );
        % Should there be a table_fill_timestamps call here????

        if isempty( flux_all )
            flux_all = new_data;
        else
            flux_all = insert_new_data_into_fluxall( new_data, flux_all );
        end

        % remove timestamp columns -- they're redundant (because there are
        % already year, month, day, hour, min, sec columns), serial datenumbers
        % aren't human-readable, and character string dates are a pain to parse
        % in matlab
        [ tstamp_cols, t_idx ] = regexp_header_vars( flux_all, 'timestamp.*' );
        flux_all( :, t_idx ) = [];

        fprintf( '---------- writing FLUX_all file ----------\n' );
        write_fluxall( obj, flux_all );

    end   % update_data

    % --------------------------------------------------

    function new_data = merge_data( obj )
        % MERGE_DATA - merges the 10hz data and the 30-minute data together.
        %
        % Internal function for card_data_processor class; not really intended
        % for top-level use.

        [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );

        % align 30-minute timestamps and fill in missing timestamps
        two_mins_tolerance = 2; % for purposes of joining averaged 10 hz and 30-minute
        % data, treat 30-min timestamps within two mins of
        % each other as equal
        t_max = max( [ reshape( obj.data_30min.timestamp, [], 1 ); ...
            reshape( obj.data_10hz_avg.timestamp, [], 1 ) ] );

        save( fullfile( getenv( 'FLUXROOT' ), 'FluxOut', 'cdp226.mat' ));
        [ obj.data_30min, obj.data_10hz_avg ] = ...
            merge_tables_by_datenum( obj.data_30min, ...
            obj.data_10hz_avg, ...
            'timestamp', ...
            'timestamp', ...
            two_mins_tolerance, ...
            obj.date_start, ...
            t_max );
        % -----
        % make sure time columns are complete (no NaNs)

        % if 30-minute data extends later than the 10hx data, fill in
        % the time columns
        [ y, mon, d, h, minute, s ] =  ...
            datevec( obj.data_10hz_avg.timestamp );
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
        
        % Check if timestamps for 10hz and 30min data are identical, then
        % remove one or else MATLAB will complain
        test = sum(obj.data_10hz_avg.timestamp == obj.data_30min.timestamp);
        if test==size( obj.data_10hz_avg, 1 ) && ...
                test==size( obj.data_30min, 1 )
            obj.data_30min.timestamp = [];
            new_data = [ obj.data_10hz_avg, obj.data_30min ];
        else
            error( 'Timestamp mismatch between 10hz and 30min data' );
        end

    end


    % --------------------------------------------------

    function write_fluxall( obj, fluxall_data, varargin )
        % write CDP fluxall data to a tab-delimited text fluxall file.
        %
        % Called automatically from update_fluxall, so the only time
        % to call this function explicitly is if new fluxall data has
        % been created from the Matlab prompt and it needs to be
        % written out to the fluxall file.
        %
        % USAGE
        %    obj.write_fluxall( fluxall_data )

        [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
        t_str = datestr( now(), 'yyyymmdd_HHMM' );
        % Sometimes we want to add an extension to the fluxall filename.
        % Make this possible when extension passed to this subfunction.
        if length( varargin ) > 0
            ext = varargin{1};
            fname = sprintf( '%s_%d_fluxall_%s.txt', ...
                char( obj.sitecode ), year, ext );
        else
            fname = sprintf( '%s_%d_fluxall.txt', ...
                char( obj.sitecode ), year );
        end

        full_fname = fullfile( get_site_directory( obj.sitecode ), ...
            fname );
        
        if exist( full_fname )
            bak_fname = regexprep( full_fname, '\.txt', '_bak.txt' );
            fprintf( 'backing up %s\n', fname );
            [copy_success, msg, msgid] = copyfile( full_fname, ...
                bak_fname );
        end

        fprintf( 'writing %s\n', full_fname );
        write_table_std( full_fname, fluxall_data )

    end   % write_fluxall

    % --------------------------------------------------


end % methods
end  % classdef
