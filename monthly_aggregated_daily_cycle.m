function mm = monthly_aggregated_daily_cycle( t, x, aggfun)
% MONTHLY_MEAN_DAILY_CYCLE - aggregate data into hourly values by month.  That
%   is, within each month calculate monthly mean value at hour 1, hour 2,
%   etc.
%
% INPUTS:
%   t: timestamp, matlab datenums (see help datenum)
%   x: data to be aggregated
%   aggfun: function handle with which to aggregate (e.g. @mean)
%
% OUTPUTS:
%   mm: monthly mean data. dataset array with variables year, month, hour,
%       val, with val the aggregated values of x.
%
% (c) Timothy W. Hilton, UNM, May 2013

[ y, m, ~, h, ~, ~ ] = datevec( t );
[ tcon, ycon ] = consolidator( [ y, m, h ], x, aggfun );
var_names =  { 'year', 'month', 'hour', 'val' };
mm = dataset( { [ tcon, ycon ], var_names{ : } } );
