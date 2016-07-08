function data = shift_data( data, offset_hours, varargin )
% SHIFT_DATA - shifts the timestamps within a dataset by a specified number
% of hours.
%
% Helper function for UNM_fix_datalogger_timestamps, UNM_Ameriflux_file_maker
% to deal with various datalogger clock problems.
% A NEGATIVE shift request means the observed event (sunrise) is happening
% too EARLY. A NEGATIVE (sign gets flipped) request actually means to shift
% the data LATER. The CURRENT time actually corresponds to the original
% data that is EARLIER.
%
% A POSITIVE shift request means the observed event (sunrise) is happening
% too LATE. A POSITIVE (sign gets flipped) request actually means to shift
% the data EARLIER. The CURRENT time actually corresponds to the original
% data that is LATER.
%
% USAGE
%    data = shift_data( data, offset_hours )
%    data = shift_data( data, offset_hours, 'cols_to_shift', N )
%
% INPUTS
%    data: numeric; array of data to be "shifted"
%    offset_hours: whole_number; number of hours to shift
% PARAMETER-VALUE PAIRS
%    cols_to_shift: which columns to shift.
%                   Defaults to [ 74: size( data, 2 ) ]
%                   Corresponds to the 30-minute portion in FLUXALL files.
%
% OUTPUTS:
%    data: input arguemnt data, with timestamps shifted
%
% Author: Timothy W. Hilton, UNM, June 2012

% -----
% Define optional inputs, with defaults and typechecking
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

% Convert hours to array rows (each row is 1/2 hour of data), or each hour
% is two (2) rows of data.
offset_idx =  offset_hours * 2.0;
if ~isintval( offset_idx )
    error( 'offset must be n/2, with n an integer' );
end

% Create an array of NaNs to replace the chunk of data removed by the
% shift.
first_10hz_data_column = 9; % columns 1 through 8 are timestamp stuff --
                       % leave these alone
first_30min_data_column = 74; % columns 1 through 73 are timestamps and
                              % 10hz data

if isempty( cols_to_shift )
    cols_to_shift = first_30min_data_column : size( data, 2 );
end

% Shift the part of the array containing *data* by offset_idx rows.
% POSITIVE shift changed to NEGATIVE so POS shift means move all the data
% UP (negative shift). The TIME row will now correspond to data that is
% LATER.
data( :, cols_to_shift ) = ...
    circshift( data( :, cols_to_shift ), [ -offset_idx, 0 ] );

% Insert the NaN filler.
% NEGATIVE offset hours so TIME row now corresponds to data that is EARLIER
% (i.e. shifted in POSITIVE direction).
if offset_hours < 0
    % Observed radiation sunrise is offset_hours too EARLY so make data
    % later.
    data( 1:offset_idx, cols_to_shift ) = NaN; % Replace TOP rows with NaN
                                               % since data shifted DOWN
else % Replace BOTTOM rows with NaN since data shifted UP
    data( ( end - ( offset_idx - 1 ) ) : end, cols_to_shift ) = NaN;
end
    

