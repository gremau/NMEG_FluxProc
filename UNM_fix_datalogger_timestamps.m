function data = UNM_fix_datalogger_timestamps( sitecode, year, data )
% UNM_FIX_DATALOGGER_TIMESTAMPS - 
%   

switch sitecode
  case UNM_sites.JSav
    switch year
      case 2009
        idx = 1 : DOYidx( 97.5 );
        offset = -1.0;
        data( idx, : ) = shift_data( data( idx, : ),  offset );
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
first_data_column = 9; % columns one through eight are timestamp stuff --
                       % leave these alone
nan_filler = repmat( NaN, ...
                     offset_idx, ...
                     size( data( :, first_data_column:end ), 2 ) );

% shift the part of the array containing *data* by offset_idx rows
data( :, first_data_column:end ) = ...
    circshift( data( :, first_data_column:end ), ...
               [ -offset_idx, 0 ] );

% insert the NaN filler
if offset_hours < 0
    % observed radiation sunrise is offset_hours too *early* - make data
    % later
    data( 1:offset_idx, first_data_column:end ) = nan_filler;
else
    data( ( end - ( offset_idx - 1 ) ) : end, first_data_column:end ) = nan_filler;
end
    

