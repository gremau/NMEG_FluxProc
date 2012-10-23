classdef card_data_processor
properties
    sitecode;
    date_start;
    date_end;
    lag;
    rotation;
    data_10hz_avg;
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
    args = p.parse( sitecode, varargin{ : } );
    
    % -----
    % assign arguments to class fields
    
    obj.sitecode = p.Results.sitecode;    
    obj.date_start = p.Results.date_start;
    obj.date_end = p.Results.date_end;
    obj.lag = p.Results.lag;
    obj.rotation = sonic_rotation( p.Results.rotation );
    obj.data_10hz_avg = [];
    obj.data_30min = [];
   
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
    
    tob1_files = get_data_file_names( obj.date_start, ...
                                      obj.date_end, ...
                                      obj.sitecode, ...
                                      'TOB1' );
    tstamps = cellfun( @get_TOA5_TOB1_file_date, tob1_files );
    obj.date_end = min( max( tstamps ), obj.date_end );
    
    load( ['C:\Research_Flux_Towers\FluxOut\TOB1_data\' ...
           'JSav_TOB1_2012_filled.mat'] )
    all_data.date = str2num( all_data.date );
    all_data = all_data( all_data.timestamp < obj.date_end, : );
    obj.data_10hz_avg = all_data;

    
    % [ result, obj.data_10hz_avg ] = UNM_process_10hz_main( obj.sitecode, ...
    %                                                   obj.date_start, ...
    %                                                   obj.date_end, ...
    %                                                   'lag', obj.lag, ...
    %                                                   'rotation', obj.rotation);
    
    end  % process_10hz_data

% --------------------------------------------------

    function obj = process_data( obj )
    % Force reprocessing of all data between obj.date_start and obj.date_end.
    
    warning( 'This method not yet implemented\n' );
    
    end  % process_data

% --------------------------------------------------

    function obj = update_data( obj )
    
    [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
    fprintf( '---------- parsing fluxall file ----------\n' );
    flux_all = UNM_parse_fluxall_txt_file( obj.sitecode, year );
    
    %obj.date_end = min( max( flux_all.timestamp ), now() );
    
    fprintf( '---------- concatenating 30-minute data ----------\n' );
    [ obj, TOA5_files ] = get_30min_data( obj );
    fprintf( '---------- processing 10-hz data ----------\n' );
    obj = process_10hz_data( obj );
        
    save( 'CDP_test_restart.mat' )
    
    % align 30-minute timestamps and fill in missing timestamps
    two_mins_tolerance = 2; % for purposes of joining averaged 10 hz and 30-minute
                            % data, treat 30-min timestamps within two mins of
                            % each other as equal
    t_max = max( [ reshape( obj.data_30min.timestamp, [], 1 ); ...
                   reshape( obj.data_10hz_avg.timestamp, [], 1 ) ] );

    [ obj.data_30min, obj.data_10hz_avg ] = ...
        merge_datasets_by_datenum( obj.data_30min, ...
                                   obj.data_10hz_avg, ...
                                   'timestamp', ...
                                   'timestamp', ...
                                   two_mins_tolerance, ...
                                   obj.date_start, ...
                                   t_max );
    
    new_data = horzcat( obj.data_30min, obj.data_10hz_avg );
    flux_all = dataset_append_common_vars( flux_all, new_data );
    
    fprintf( '---------- writing FLUX_all file ----------\n' );
    write_fluxall( obj, flux_all );
    
    end   % update_data

% --------------------------------------------------

    function write_fluxall( obj, fluxall_data )
    [ year, ~, ~, ~, ~, ~ ] = datevec( obj.date_start );
    fname = sprintf( '%s_FLUX_all_%d_new.txt', char( obj.sitecode ), year );
    full_fname = fullfile( get_site_directory( obj.sitecode ), fname );
    t0 = now();
    export( fluxall_data, 'file', full_fname );
    t_elapsed = round( ( now() - t0 ) * 24 * 60 * 60 );
    fprintf( 'wrote %s (%d seconds)\n', full_fname, t_elapsed );
    end   % write_fluxall

% --------------------------------------------------


end % methods

end  % classdef