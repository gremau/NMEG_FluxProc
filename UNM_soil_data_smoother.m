function [ vwc1, vwc2, vwc3, run_avg ] = UNM_soil_data_smoother( raw_soil_data )
%
% USAGE
%    result = UNM_soil_data_smoother( raw_soil_data )
%
% (c) Timothy W. Hilton, UNM, Apr 2012
    
% not temperature corrected
vwc1 = repmat( -0.0663, size( raw_soil_data ) ) -  ...
       ( 0.00636 .* raw_soil_data ) + ...
       ( 0.0007 .* ( raw_soil_data .* raw_soil_data ) );

% Remove any negative SWC values
vwc1( vwc1 < 0 ) = nan;
vwc1( vwc1 > 1 ) = nan;

% calculate 6 hour running mean, standard deviation
nobs = 13; % 6 hr filter on either side
run_avg = running_mean( vwc1, nobs );
run_std = running_stddev( vwc1, nobs );

% return 3 different smoothing approaches:

% remove points greater than +- 3 SD from mean
idx = abs( vwc1 - run_avg ) > ( 3 * run_std );
vwc2 = vwc1;
vwc2( idx ) = NaN;

% replace points greater than +- 3 SD from mean with mean
vwc3 = vwc1;
vwc3( idx ) = run_avg( idx );

