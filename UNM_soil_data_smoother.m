function [ data2, data3, run_avg ] = UNM_soil_data_smoother( data1, win, minmax )
%
% Smooths its input data by removing outliers and applying a running
% average.  NaNs in input are ignored when calculating running average.
%
% USAGE
%   [ data2, data3, run_avg ] = UNM_soil_data_smoother( data1 )
%
% INPUTS
%   data1: input data; matrix or dataset object.  If data1 is
%       two-dimensional, operates on each column separately. 
%   win: 1/2 the moving average window (number of elements on either side to
%       consider when calculating average).
%   minmax: 2-element matrix.  values outside of minmax are removed before
%       smoothing.
%
% OUTPUTS
%   data2: data with elements more than three standard deviations from the
%       mean removed.
%   data3: the running mean of data2
%   run_avg: the running mean of the input
%
% (c) Timothy W. Hilton, UNM, Apr 2012

input_is_dataset = isa( data1, 'dataset' );

if input_is_dataset
    data_input = data1;
    data1 = double( data1 );
end

% remove extreme values
data1( data1 < min( minmax ) ) = NaN;
data1( data1 > max( minmax ) ) = NaN;

% replace measurements of exactly zero with NaN
zero_idx = ( data1 < 1e-6 ) & ( data1 > -1e-6 );
data1( zero_idx ) = NaN;

columnwise = 1;
fillnans = 1;
run_avg = nanmoving_average( data1, win, columnwise, fillnans );
run_std = running_stddev( run_avg, win );

% return 3 different smoothing approaches:

% remove points greater than +- 3 SD from mean
idx = abs( data1 - run_avg ) > ( 3 * run_std );
data2 = data1;
data2( idx ) = NaN;

% replace points greater than +- 3 SD from mean with mean
data3 = data1;
data3( idx ) = run_avg( idx );

run_avg = nanmoving_average( data2, win, columnwise, fillnans );

if input_is_dataset
    data2 = replacedata( data_input, data2 );
    data3 = replacedata( data_input, data3 );
    run_avg = replacedata( data_input, run_avg );
end
        