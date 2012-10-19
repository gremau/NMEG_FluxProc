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
                     0, ...
                     @( x ) ismember( x, [ 0, 1 ] ) );
    p.addParamValue( 'lag', ...
                     sonic_rotation.threeD, ...
                     @( x ) isa( x, 'sonic_rotation' ) );
    args = p.parse( sitecode, varargin{ : } );
    
    % -----
    % assign arguments to class fields
    
    obj.sitecode = p.Results.sitecode;    
    obj.date_start = p.Results.date_start;
    obj.date_end = p.Results.date_end;
    obj.lag = p.Results.lag;
    obj.rotation = p.Results.rotation;
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

    function files = get_30min_data( obj )
    
    toa5_files = get_data_file_names( obj.date_start, ...
                                      obj.date_end, ...
                                      obj.sitecode, ...
                                      'TOA5' );
    
    obj.data_30min = combine_and_fill_TOA5_files( toa5_files );
    
    end  % get_30min_data

% --------------------------------------------------

    function files = process_10hz_data( obj )
    
    [ result, obj.data_10hz ] = UNM_process_10hz_main( obj.sitecode, ...
                                                      obj.date_start, ...
                                                      obj.date_end, ...
                                                      'lag', obj.lag, ...
                                                      'rotation', obj.rotation);
    
    end  % process_10hz_data

% --------------------------------------------------

    function obj = process_data( obj )
    % Force reprocessing of all data between obj.date_start and obj.date_end.
    end  % process_data

% --------------------------------------------------

    function obj = update_data( obj )
    
    end   % update_data

% --------------------------------------------------

    function obj = write_fluxall( obj )
    
    end   % write_fluxall

% --------------------------------------------------


end % methods

end  % classdef