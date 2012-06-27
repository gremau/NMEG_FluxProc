function data = UNM_fix_datalogger_timestamps( sitecode, year, data )
% UNM_FIX_DATALOGGER_TIMESTAMPS - 
%   

switch sitecode
  case UNM_sites.GLand
    switch year
      case 2007
        data = shift_data( data, -1.0 );
        row_idx = DOYidx( 38 ) : DOYidx( 69 );
        col_idx = [ 1:144, 146:size( data, 2 ) ]; % all but incoming SW
        data( row_idx, : ) = shift_data( data( row_idx, : ), ...
                                         -1.0, ...
                                         'cols_to_shift', col_idx );
      case 2008
        data = shift_data( data, -1.0 );
      case 2009
        idx = 1 : DOYidx( 58 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
        idx = DOYidx( 82 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ),  -0.5 );
      case 2010
        col_idx = 1:size( data, 2 );
        data = shift_data( data, 1.0, 'cols_to_shift', col_idx );
      case 2011
        data = shift_data( data, 1.0 );
    end

  case UNM_sites.SLand
    switch year
      case 2008
        %idx = [ 1: DOYidx( 5 ), DOYidx( 20 ) : size( data, 1 ) ];
        %data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        data = shift_data( data, -1.0 );
      case 2009
        idx = 1 : DOYidx( 64 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
      case 2011
        idx = DOYidx( 137 ) : DOYidx( 165 );
        data( idx, : ) = shift_data( data( idx, : ),  -0.5 );
    end
    
  case UNM_sites.JSav
    switch year
      case 2007
        doy_col = 8;  % day of year column in JSav_FluxAll_2007.xls
        idx = find( ( data( :, doy_col ) >= 324 ) & ...
                    ( data( :, doy_col ) <= 335 ) );
        data( idx, : ) = shift_data( data( idx, : ),  1.0 );
      case 2009
        idx = 1 : DOYidx( 97.5 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
    end

  case UNM_sites.PJ
    switch year
      case { 2009, 2010, 2011 }
        data = shift_data( data, 1.0 );
    end
    
  case UNM_sites.MCon
    switch year
      case 2009
        idx = DOYidx( 351.5 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 1.5 );
      case 2010
        col_idx = 1:size( data, 2 );
        data = shift_data( data, 1.0, 'cols_to_shift', col_idx );
        idx = DOYidx( 25 ) : DOYidx( 47 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0, ...
                                     'cols_to_shift', col_idx );
        idx = DOYidx( 300 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 0.5, ...
                                     'cols_to_shift', col_idx);
      case 2011
        col_idx = 1:size( data, 2 );
        idx = 1 : DOYidx( 48.0 );
        data( idx, : ) = shift_data( data( idx, : ),  2.5, ...
                                     'cols_to_shift', col_idx );
    end
    
  case UNM_sites.New_GLand
    switch year
      case 2010
        col_idx = 1:size( data, 2 );
        idx = DOYidx( 179 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ),  1.0, ...
                                     'cols_to_shift', col_idx );
      case 2011
        data = shift_data( data,  1.0 );
        
    end

end

%==================================================

function data = shift_data( data, offset_hours, varargin )
% SHIFT_DATA - 
%   Helper function for UNM_fix_datalogger_timestamps

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'data', @isnumeric );
args.addRequired( 'offset_hours', @( x ) isnumeric( x ) & ( numel( x ) == 1 ) );
args.addParamValue( 'cols_to_shift', [], @isnumeric );
% parse optional inputs
args.parse( data, offset_hours, varargin{ : } );
data = args.Results.data;
offset_hours = args.Results.offset_hours;
cols_to_shift = args.Results.cols_to_shift;

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

if isempty( cols_to_shift )
    cols_to_shift = first_30min_data_column : size( data, 2 );
end

% shift the part of the array containing *data* by offset_idx rows
data( :, cols_to_shift ) = ...
    circshift( data( :, cols_to_shift ), [ -offset_idx, 0 ] );

% insert the NaN filler
if offset_hours < 0
    % observed radiation sunrise is offset_hours too *early* - make data
    % later
    data( 1:offset_idx, cols_to_shift ) = NaN;
else
    data( ( end - ( offset_idx - 1 ) ) : end, cols_to_shift ) = NaN;
end
    

