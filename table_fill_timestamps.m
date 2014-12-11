function T_filled = table_fill_timestamps( T, t_var, varargin )    
% table_FILL_TIMESTAMPS - fill in missing timestamps in a table containing a
% regularly-spaced time series and discard duplicate timestamps.  
%
% t_var specifies the name of the table variable containing the (unfilled)
% timestamps for the data in T.  The timestamps must be Matlab serial
% datenumbers.  That is, T.( t_var ) must contain a vector of Matlab serial datenumbers.
%
% table_fill_timestamps identifies missing timestamps in T.( t_var ),
% assuming a regular interval specified by the parameter-value pair delta_t.
% The default delta_t value is 30 minutes.  Where timestamps are added to T.(
% t_var ) to complete the time series, all other variables are populated with
% NaN.
%
% If a timestamp occurs more than once, the first row is kept and subsequent
% rows discarded. 
%
% USAGE:
%   T_filled = table_fill_timestamps( T, t_var )
%   T_filled = table_fill_timestamps( T, t_var, t_min, t_max )
%   T_filled = table_fill_timestamps( T, ..., 'tstamps_as_strings', ...
%                                                  logical_value )
%
% INPUTS:
%   T: table array; the data to be filled
%   t_var: string containing the name of the time variable in T
%       (e.g. 'TIMESTAMP').  T.( t_var ) must contain the timestamps for the
%       data as matlab serial datenumbers. 
%
% PARAMETER-VALUE PAIRS
%   delta_t: optional: interval of the time series, in days.  e.g., 30
%          mins should have delta_t value of 1/48.  Defaults to 1/48.
%   t_min: Matlab serial datenumber; timestamp at which to begin filling.
%          Defaults to the earliest timestamp in the table.
%   t_max: Matlab serial datenumber; timestamp at which to end filling.
%          Defaults to the latest timestamp in the table.
%   tstamps_as_strings: true|{false}: if true, return timestamps as strings.
%          If false (the default) return timestamps as Matlab serial
%          datenumbers. 
%
% SEE ALSO
%    table, datenum
%
% author: Timothy W. Hilton, UNM, Dec. 2011

% -----
% define optional inputs, with defaults
% -----
p = inputParser;
p.addRequired( 'T' ); %, @( x ) isa( x, 'table' ) );
p.addRequired( 't_var', @ischar );
p.addOptional( 'delta_t', ( 1 / 48), @isnumeric );
p.addOptional( 'tstamps_as_strings', false, @islogical );
p.addParamValue( 't_min', ...
                 NaN, ...
                 @( x ) isnumeric( x ) );
p.addParamValue( 't_max', ...
                 NaN, ...
                 @( x ) isnumeric( x ) );
% parse optional inputs
p.parse( T, t_var, varargin{ : } );

T = p.Results.T;
t_var = p.Results.t_var;
delta_t = p.Results.delta_t;
t_min = p.Results.t_min;
t_max = p.Results.t_max;
tstamps_as_strings = p.Results.tstamps_as_strings;

if isnan( t_min )
    t_min = min( T.( t_var ) );
end
if isnan( t_max )
    t_max = max( T.( t_var ) );
end

full_ts = ( t_min : delta_t : t_max )';
full_ts = cellstr( datestr( full_ts, 'mm/dd/yyyy HH:MM:SS' ) );

T.( t_var ) = cellstr( datestr( T.( t_var ), ...
                                 'mm/dd/yyyy HH:MM:SS' ) );

%% create a table containing the filled timestamps
T_filled = table( full_ts,  'VariableNames', {t_var} );

%% fill in the timestamps in T, adding NaNs in all variables where
%% missing timestamps were added
% [ T_filled, Aidx, Bidx ] = join( T_filled, ...
%                                   T, ...
%                                   'Keys', t_var, ...
%                                   'Type', 'LeftOuter', ...
%                                   'MergeKeys', true );
T_filled = outerjoin( T_filled, T, ...
                 'Keys', t_var, ...
                 'Type', 'Left', ...
                 'MergeKeys', true );

% timestamps (they're strings now) got sorted lexigrapically -- sort
% them now by the actual date
dn = datenum(T_filled.( t_var ), 'mm/dd/yyyy HH:MM:SS');
[ ~, idx ] = sort( dn );
T_filled = T_filled( idx, : );

if ~tstamps_as_strings
    T_filled.( t_var ) = dn ( idx );
end

%remove duplicate timestamps
dup_tol = 0.00000001;  %floating point tolerance
dup_idx = find( diff( T_filled.( t_var ) ) < dup_tol ) + 1;
T_filled( dup_idx, : ) = [];

