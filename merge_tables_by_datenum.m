function [ tbl_out1, tbl_out2 ] = merge_tables_by_datenum( tbl_in1, tbl_in2, ...
                                                      tvar1, tvar2, ...
                                                      tol, ...
                                                      t_start, t_end )
% MERGE_TABLES_BY_DATENUM - fills in two 30-minute timeseries tables so that
% both have identical timestamps.
%
%
% Where a timestamp is present in A but not B or vice versa , adds the timestamp
% to B and fills data with NaNs.
%
% USAGE
%    [ tbl_out1, tbl_out2 ] = merge_tables_by_datenum( tbl_in1, tbl_in2, ...
%                                                      tvar1, tvar2, ...
%                                                      tol, ...
%                                                      t_start, t_end )
% INPUTS
%     tbl_in1, tbl_in2: matlab table objects containing data to be merged
%     tvar1, tvar2: strings containing names of table variables containing
%         the timestamps in tbl_in1 and tbl_in2.  These timestamps must be matlab
%         datenum objects.
%     tol: tolerance for rounding timestamps to "round 30-minute" values.
%         Timestamps within tol minutes of a "round" half hour (e.g. 00 or 30
%         minutes past the hour) are rounded to the nearest half hour.  Rows
%         with timestamps not within tol minutes of a "round" half hour are
%         discarded.
%     t_start, t_end: matlab datenums.  Start and stop times for the merge.
%         The output tables will be filled in to contain a complete set of
%         30-minute timestamps between t_start and t_end.  Timestamps outside
%         this range are discarded.
%
% OUTPUTS
%     tbl_out1, tbl_out2: matlab table objects containing the filled data.
%
% SEE ALSO
%     table
% 
% author: Timothy W. Hilton, UNM, October 2011

discard_idx = ( ( tbl_in1.( tvar1 ) < t_start ) | ...
                ( tbl_in1.( tvar1 ) > t_end ) ); 
tbl_in1( discard_idx, : ) = [];

discard_idx = ( ( tbl_in2.( tvar2 ) < t_start ) | ...
                ( tbl_in2.( tvar2 ) > t_end ) ); 
tbl_in2( discard_idx, : ) = [];

mins_per_day = 24 * 60;
days_per_30mins = 1 / 48;  %% 30 mins expressed in days

%remove duplicate timestamps
dup_tol = 0.00000001;  %floating point tolerance
[ ~, idx1 ] = sort( tbl_in1.( tvar1 ) );
tbl_in1 = tbl_in1( idx1, : );
dup_idx = find( diff( tbl_in1.( tvar1 ) ) < dup_tol ) + 1;
tbl_in1( dup_idx, : ) = [];
[ ~, idx2 ] = sort( tbl_in2.( tvar2 ) );
tbl_in2 = tbl_in2( idx2, : );
dup_idx = find( diff( tbl_in2.( tvar2 ) ) < dup_tol ) + 1;
tbl_in2( dup_idx, : ) = [];

% use 00:00 on the first date in either timeseries as the reference date
t0 = floor( min( [ double( tbl_in1.( tvar1 ) ); ...
                   double( tbl_in2.( tvar2 ) ); ...
                   t_start; ...
                   t_end ] ) );

[ ts1, keep_idx1 ] = datenum_2_round30min( tbl_in1.( tvar1 ), tol, t0 );
[ ts2, keep_idx2 ] = datenum_2_round30min( tbl_in2.( tvar2 ), tol, t0 );

% round t_end to nearest 30 min value
[ t_end_round, keep_idx_end ] = ...
    datenum_2_round30min( t_end, tol, t0 );

% replace both tables' timestamps with the "round" values
tbl_in1 = tbl_in1( keep_idx1, : );
tbl_in1.( tvar1 ) = ts1;
tbl_in2 = tbl_in2( keep_idx2, : );
tbl_in2.( tvar2 ) = ts2;

% combine timestamps & remove duplicates 
ts_all = union( ts1, ts2 );

% fill both tables so that they contain complete 30-minute timeseries
% for the entire range of ts_all
tbl_out1 = table_fill_timestamps( tbl_in1, ...
                                   tvar1, ...
                                   't_min', min( ts_all ), ...
                                   't_max', max( ts_all ) );

tbl_out2 = table_fill_timestamps( tbl_in2, ...
                                   tvar2, ...
                                   't_min', min( ts_all ), ...
                                   't_max', max( ts_all ) );


