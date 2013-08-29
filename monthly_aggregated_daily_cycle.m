function mm = monthly_aggregated_daily_cycle( t, x, aggfun)
% MONTHLY_MEAN_DAILY_CYCLE - aggregate data into hourly values by month.  
%
% Within each month calculates monthly mean value at hour 1, hour 2, etc.  The
% aggregation is performed by consolidator.
%
% Consolidator is free and open source and may be obtained here (as of Aug
% 2013): http://www.mathworks.com/matlabcentral/fileexchange/8354-consolidator
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
% SEE ALSO
%   consolidator
%
% author: Timothy W. Hilton, UNM, May 2013

[ y, mon, ~, h, minute, ~ ] = datevec( t );
[ tcon, ycon ] = consolidator( [ y, mon, h, minute ], x, aggfun );
var_names =  { 'year', 'month', 'hour', 'minute', 'val' };
mm = dataset( { [ tcon, ycon ], var_names{ : } } );
