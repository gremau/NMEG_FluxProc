function [ vwc2, vwc3, run_avg ] = UNM_soil_data_smoother( vwc1 )
%
% USAGE
%   [ vwc2, vwc3, run_avg ] = UNM_soil_data_smoother( vwc1 )
%
% (c) Timothy W. Hilton, UNM, Apr 2012

input_is_dataset = isa( vwc1, 'dataset' );

if input_is_dataset
    vwc_input = vwc1;
    vwc1 = double( vwc1 );
end

% calculate 6 hour running mean, standard deviation
nobs = 13; % 6 hr filter on either side
nobs = 25;
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

run_avg = running_mean( vwc2, nobs );

if input_is_dataset
    vwc2 = replacedata( vwc_input, vwc2 );
    vwc3 = replacedata( vwc_input, vwc3 );
    run_avg = replacedata( vwc_input, run_avg );
end
        