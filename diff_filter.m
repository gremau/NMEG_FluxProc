function data_out = diff_filter( data_in, delta )
% DIFF_FILTER - remove elements of data_in whose difference from the previous
% non-nan element is greater than max( delta ) or less than min( delta ).
% Passing delta of [ NaN, NaN ] turns the filter off.
%
% USAGE
%    data_out = diff_filter( data_in, delta )
%
% INPUTS
%    data_in: 1xN numeric; data to filter
%    delta: 2-element numeric; the maximum and minimum change to allow
%
% OUTPUTS
%    data_out: data_in with elements failing the filter set to NaN
%
% (c) Timothy W. Hilton, UNM, Sep 2012

% if delta is [ NaN, NaN ] do not apply the filter.
if all( isnan( delta ) )
    data_out = data_in;
    return
end

nan_idx = isnan( data_in );
data_no_nans = data_in( ~nan_idx );
data_no_nans( find( diff( data_no_nans ) < min( delta ) ) + 1 ) = NaN;
data_no_nans( find( diff( data_no_nans ) > max( delta ) ) + 1 ) = NaN;
data_out = data_in;
data_out( ~nan_idx ) = data_no_nans;
