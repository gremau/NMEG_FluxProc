function data = shift_data( data, offset_hours, varargin )
% SHIFT_DATA - shifts the timestamps within a dataset by a specified number
% of hours.
%
% Helper function for UNM_fix_datalogger_timestamps, UNM_Ameriflux_file_maker
% to deal with various datalogger clock problems.
%
% USAGE
%    data = shift_data( data, offset_hours )
%    data = shift_data( data, offset_hours, 'cols_to_shift', N )
%
% INPUTS
%    data: numeric; array of data to be "shifted"
%    offset_hours: integer; number of hours to shift
% PARAMETER-VALUE PAIRS
%    cols_to_shift: which columns to shift.  defaults to [ 74: size( data, 2 ) ]
%            -- this corresponds to the 30-minute portion of the FLUXALL files.
%
% OUTPUTS:
%    data: input arguemnt data, with timestamps shifted
%
% author: Timothy W. Hilton, UNM, June 2012

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
    

