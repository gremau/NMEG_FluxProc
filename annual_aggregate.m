function aa = annual_aggregate( t, x, aggfun)
% ANNUAL_AGGREGATE - aggregate the values in X by applying a specified
% function to annual subsets.
%
% The aggregation is performed by consolidator.
%   
% INPUTS:
%   t: timestamp, matlab serial datenumbers
%   x: NxM numeric; data to be aggregated
%   aggfun: function handle with which to aggregate (e.g. @mean)
%
% OUTPUTS:
%   aa: annually aggregated data. dataset array with variables year, val, with
%      val the aggregated values of x.
%
% SEE ALSO
%   datenum, dataset, consolidator
%
% author: Timothy W. Hilton, UNM, May 2013

[ y, ~, ~, ~, ~, ~ ] = datevec( t );
[ tcon, ycon ] = consolidator( [ y ], x, aggfun );
var_names =  { 'year', 'val' };
aa = dataset( { [ tcon, ycon ], var_names{ : } } );