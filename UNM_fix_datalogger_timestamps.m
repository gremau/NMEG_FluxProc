function data = UNM_fix_datalogger_timestamps( sitecode, year, data )
% UNM_FIX_DATALOGGER_TIMESTAMPS - 
%   

switch sitecode
  case UNM_sites.GLand
    switch year
      case { 2007, 2008 }
        data = shift_data( data, -1.0 );
      case 2009
        idx = 1 : DOYidx( 58 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
        idx = DOYidx( 59 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ),  -0.5 );
      case { 2010, 2011 }
        data = shift_data( data, 1.0 );
    end

  case UNM_sites.SLand
    switch year
      case 2007 
    end
    
  case UNM_sites.JSav
    switch year
      case 2009
        idx = 1 : DOYidx( 97.5 );
        offset = -1.0;
        data( idx, : ) = shift_data( data( idx, : ),  offset );
    end
    
  case UNM_sites.MCon
    switch year
      case 2010
        data = shift_data( data, -1.0 );
      otherwise
    
end
end

%==================================================

function data = shift_data( data, offset_hours )
% SHIFT_DATA - 
%   Helper function for UNM_fix_datalogger_timestamps

if ( offset_hours == 0 )
    % nothing to do
    return
end

% convert hours to array rows (each row is 1/2 hour of data)
offset_idx =  offset_hours * 2.0;
if ~isintval( offset_idx )
    error( 'offset must be n/2, with n an integer' );
end

% create an array of NaNs to replace the chunk of data removed by the shift
first_10hz_data_column = 9; % columns one through eight are timestamp stuff --
                       % leave these alone
first_30min_data_column = 74; % columns one through 73 are timestamps and
                              % 10hz data

nan_filler = repmat( NaN, ...
                     offset_idx, ...
                     size( data( :, first_30min_data_column:end ), 2 ) );

% shift the part of the array containing *data* by offset_idx rows
data( :, first_30min_data_column:end ) = ...
    circshift( data( :, first_30min_data_column:end ), ...
               [ -offset_idx, 0 ] );

% insert the NaN filler
if offset_hours < 0
    % observed radiation sunrise is offset_hours too *early* - make data
    % later
    data( 1:offset_idx, first_30min_data_column:end ) = nan_filler;
else
    data( ( end - ( offset_idx - 1 ) ) : end, first_30min_data_column:end ) = nan_filler;
end
    

