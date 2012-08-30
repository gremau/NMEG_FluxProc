function data_out = diff_filter( data_in, delta )
% DIFF_FILTER - remove elements whose difference from the previous non-nan
%   element is > delta

nan_idx = isnan( data_in );
data_no_nans = data_in( ~nan_idx );
data_no_nans( find( diff( data_no_nans ) < delta ) + 1 ) = NaN;
data_out = data_in;
data_out( ~nan_idx ) = data_no_nans;