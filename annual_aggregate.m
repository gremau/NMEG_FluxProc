function aa = annual_aggregate( t, x, aggfun)
% ANNUAL_AGGREGATE - aggregate the values in X annually by applying funtion aggfun
%   
% INPUTS:
%   t: timestamp, matlab datenums (see help datenum)
%   x: data to be aggregated
%   aggfun: function handle with which to aggregate (e.g. @mean)
%
% OUTPUTS:
%   aa: annually aggregated data. dataset array with variables year, val, with
%      val the aggregated values of x.
%
% (c) Timothy W. Hilton, UNM, May 2013

[ y, ~, ~, ~, ~, ~ ] = datevec( t );
[ tcon, ycon ] = consolidator( [ y ], x, aggfun );
var_names =  { 'year', 'val' };
aa = dataset( { [ tcon, ycon ], var_names{ : } } );