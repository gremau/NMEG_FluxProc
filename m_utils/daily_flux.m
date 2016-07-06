function [ day_sums, year_out ] = daily_flux( tstamp, flux )
% DAILY_FLUX - calculates daily integrated fluxes from 30-minute fluxes
%
% uses nansum for aggregation
% 
% USAGE:
%   [ day_sums, year_out ] = daily_flux( tstamp, flux );
%
% INPUTS:
%   tstamp: timestamps (matlab datenums)
%   flux: timeseries of fluxes
%
% OUTPUTS:
%
%   day_sums: 366xN array of summed daily fluxes.
%   year_out: 1xN matrix of years corresponding to the columns of day_sums
%
% SEE ALSO
%   nansum
%
% author: Timothy W. Hilton, UNM, May 2012
    
% sort the data by timestamp
[ tstamp, idx ] = sort( tstamp );
flux = flux( idx );

[ year, ~, ~, ~, ~, ~ ] = datevec( tstamp );
year0 = min( year );
fday = tstamp - datenum( year, 1, 0 ); %fractional day of year since 1 Jan
iday = floor( fday ); % integral day of year

[ ~, unique_idx, yr_idx ] = unique( year );
n_yrs = numel( unique_idx );

day_sums = accumarray( [ iday, yr_idx ], ...
                       flux, ...
                       [ 366, n_yrs ], ...
                       @nansum, ...
                       NaN );

DOY = reshape( 1:size( day_sums, 1 ), [], 1 );
year_out = sort( unique( year ) );

% var_names = horzcat( 'DOY', arrayfun( @(x) { num2str( x ) }, ...
%                                       reshape( year( unique_idx ), 1, [] )  ) );
% day_sums = dataset( { [ DOY, day_sums ], var_names{ : } } );

