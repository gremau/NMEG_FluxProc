classdef card_data_processor
properties
    sitecode;
    date_start;
    date_end;
    data_10hz_avg;
    data_30min;
end

methods

% --------------------------------------------------
    function obj = card_data_processor( sitecode, date_start, date_end )
    
    % class constructor
    obj.sitecode = sitecode;
    obj.date_start = date_start;
    obj.date_end = date_end;
    
    obj.data_10hz_avg = [];
    obj.data_30min = [];
    
    end

% --------------------------------------------------

    function files = find_30min_files( obj );
    end
    
    function files = find_10hz_files( obj );
    end


        
    
    


