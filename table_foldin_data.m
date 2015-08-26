function T_out = table_foldin_data( T_in1, T_in2 )
% TABLE_FOLDIN_DATA - "folds in" data from a second table array into a
% first, by timestamp.  
%
% The resulting merged table contains all variables that are present in either
% input.  Where a variable is NaN in T_in1 but has valid data in T_in2, the
% non-NaN value is kept.  Where a variable is non-NaN in both, the value from
% T_in1 is kept.  Both tables must contain a 'timestamp' variable of matlab
% serial datenumbers.  Timestamps within two minutes of each other are
% considered equal.  This function was created for (and tested on) 30-minute
% data, but should in concept work for timeseries data with any observation
% interval greater than two minutes.
%
% USAGE
%
% T_out = table_foldin_data( T_in1, T_in2 )
%
% INPUTS:
%   T_in1, T_in2: matlab table arrays
%
% OUTPUTS:
%   table array containing all data from T_in1 and T_in2 as described above.
%
% SEE ALSO
%   table, datenum
%
% author: Gregory E. Maurer, UNM, Aug 2015
% based on dataset version by Timothy W. Hilton, UNM, Dec 2012

% -----

if isempty( T_in2 )
    T_out = T_in1;
    fprintf( 'Second table was empty. Returning first table. \n' )
    return
end
% make sure the two tables have identical timestamps:
% align 30-minute timestamps and fill in missing timestamps
two_mins_tolerance = 2; % for purposes of joining data, treat timestamps
                        % within two mins of each other as equal
all_t = [ reshape( T_in1.timestamp, [], 1 ); ...
          reshape( T_in2.timestamp, [], 1 ) ];
[ T_in1, T_in2 ] = ...
    merge_tables_by_datenum( T_in1, ...
                             T_in2, ...
                             'timestamp', ...
                             'timestamp', ...
                             two_mins_tolerance, ...
                             min( all_t ), ...
                             max( all_t ) );

% -----
% for variables that exist in both tables, replace NaNs in T_in1 with
% values from T_in2.  For variables that exist only in T_in2, copy to T_out.
T_out = T_in1;
for i = 1:numel( T_in2.Properties.VariableNames )
    this_var = T_in2.Properties.VariableNames{ i };
    if ismember( this_var, T_out.Properties.VariableNames );
        data1 = T_in1.( this_var );
        data2 = T_in2.( this_var );
        idx = isnan( data1 ) & not( isnan( data2 ) );
        data1( idx ) = data2( idx );
        T_out.( this_var ) = data1;
    else
        T_out.( this_var ) = T_in2.( this_var );
    end
end



