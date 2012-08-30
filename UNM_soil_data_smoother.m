function data_out = UNM_soil_data_smoother( data_in, win, minmax, delta_filter )
%
% Smooths its input data by removing outliers and applying a running
% average.  NaNs in input are ignored when calculating running average.
%
% USAGE
%   [ data2, data3, run_avg ] = UNM_soil_data_smoother( data_in )
%
% INPUTS
%   data_in: input data; matrix or dataset object.  If data_in is
%       two-dimensional, operates on each column separately. 
%   win: 3-element vector.  1/2 the moving average window (number of elements on
%       either side to consider when calculating average) for each of three
%       smoothing passes.
%   minmax: 2-element matrix.  values outside of minmax are removed before
%       smoothing.
%   delta_filter: 1x2 array: maximum decrease and maximum increase to allow
%       between consecutive data points.  decrease should be negative,
%       increase should be positive.  [ NaN, NaN ] turns this filter off. 
%
% OUTPUTS
%   data_out: data with outlier elements removed.
%
% (c) Timothy W. Hilton, UNM, Apr 2012

debug_plots = true;  % if true, draw some plots for debugging
%debug_plots = any( isnan( delta_filter ) );  %draw plots for T, not SWC

input_is_dataset = isa( data_in, 'dataset' );

if input_is_dataset
    data_input = data_in;
    data_in = double( data_in );
end

% remove extreme values
data_in( data_in < min( minmax ) ) = NaN;
data_in( data_in > max( minmax ) ) = NaN;

% where three or more identical (to machine precision) values occur, replace
% them with NaNs
orig_size = size( data_in );
data_in = reshape( data_in, 1, [] );
idx = rle( data_in );
idx{ 1 }( idx{ 2 } >= 3 ) = NaN;
data_in = rle( idx );
data_in = reshape( data_in, orig_size );

columnwise = 1;
fillnans = 1;

% return 3 different smoothing approaches:
% pass one
n_std = 1.5;
mov_avg = column_inpaint_nans( nanmoving_average( data_in, ...
                                                  win( 1 ), ...
                                                  columnwise, ...
                                                  fillnans ) );
mov_std = real( column_movingstd( data_in, win( 1 ) ) );
idx1 = ( data_in > ( mov_avg + ( n_std * mov_std ) ) ) | ...
       ( data_in < ( mov_avg - ( n_std * mov_std ) ) );

if debug_plots
    col_idx = size( data_in, 2 );
    h = figure();
    ax1 = subplot( 2, 1, 1 );
    plot( find( idx1( :, col_idx ) == false ), ...
          data_in( ~idx1( :, col_idx ), col_idx ), '.k' );
    hold on
    plot( find( idx1( :, col_idx ) ), ...
          data_in( idx1( :, col_idx ), col_idx ), '*b' );
    plot( mov_avg( :, col_idx ), '-k' )
    plot( mov_avg( :, col_idx ) + ( n_std * mov_std( :, col_idx ) ), '-r' )
    plot( mov_avg( :, col_idx ) - ( n_std * mov_std( :, col_idx ) ), '-r' )
    title( 'pass one' );
end

data_in( idx1 ) = NaN;

% pass two
n_std = 2.0;
mov_avg = column_inpaint_nans( nanmoving_average( data_in, ...
                                                  win( 2 ), ...
                                                  columnwise, ...
                                                  fillnans ) );
mov_std = real( column_movingstd( mov_avg, win( 2 ) ) );
idx2 = ( data_in > ( mov_avg + ( n_std * mov_std ) ) ) | ...
       ( data_in < ( mov_avg - ( n_std * mov_std ) ) );

data_in( idx2 ) = NaN;

% pass three
n_std = 2.0;
mov_avg = column_inpaint_nans( nanmoving_average( data_in, ...
                                                  win( 3 ), ...
                                                  columnwise, ...
                                                  fillnans ) );
mov_std = real( column_movingstd( mov_avg, win( 3 ) ) );
idx3 = ( data_in > ( mov_avg + ( n_std * mov_std ) ) ) | ...
       ( data_in < ( mov_avg - ( n_std * mov_std ) ) );
data_in( idx3 ) = NaN;

if debug_plots
    ax2 = subplot( 2, 1, 2 );
    plot( find( idx2( :, col_idx ) == false ), ...
          data_in( ~idx2( :, col_idx ), col_idx ), '.k' );
    hold on
    plot( find( idx2( :, col_idx ) ), ...
          data_in( idx2( :, col_idx ), col_idx ), '*b' );
    plot( mov_avg( :, col_idx ), '-k' )
    plot( mov_avg( :, col_idx ) + ( n_std * mov_std( :, col_idx ) ), '-r' )
    plot( mov_avg( :, col_idx ) - ( n_std * mov_std( :, col_idx ) ), '-r' )
    title( 'pass three' );
    linkaxes( [ ax1, ax2 ], 'xy' );
    waitfor( h );
end


data_in = diff_filter( data_in, delta_filter );

data_out = data_in;

if input_is_dataset
    data_out = replacedata( data_input, data_out );
end
        
%==================================================
function mov_std = column_movingstd( arr, win )
% ARRAY_MOVINGSTD - apply movingstd to the columns of an array
%   

mov_std = repmat( NaN, size( arr ) );
for i = 1:size( arr, 2 )
    mov_std( :, i ) = movingstd( inpaint_nans( arr( :, i ) ), ...
                                 win, ...
                                 'central' );
end


%==================================================
function data_out = column_inpaint_nans( data_in )
% COLUMN_INPAINT_NANS - applys inpaint_nans to each column of a matrix.
%   

data_out = repmat( NaN, size( data_in ) );

for i = 1:size( data_in, 2 )
    data_out( :, i ) = inpaint_nans( data_in( :, i ) );
end

%==================================================
function data_out = diff_filter( data_in, delta )
% DIFF_FILTER - remove elements of data_in whose difference from the previous
% non-nan element is greater than max( delta ) or less than min( delta ).
% Passing delta of [ NaN, NaN ] turns the filter off.

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
