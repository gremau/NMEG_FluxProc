function data_out = UNM_soil_data_smoother( data_in, ...
                                            win, ...
                                            debug_plots )
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
%   win: scalar.  1/2 the moving average window (number of elements on
%       either side to consider when calculating average) for smoothing.
%   debug_plots: logical: if true, draws plots after pass one and pass three.
%
% OUTPUTS
%   data_out: data with outlier elements removed.
%
% (c) Timothy W. Hilton, UNM, Sep 2012

input_is_dataset = isa( data_in, 'dataset' );

if input_is_dataset
    data_input = data_in;
    data_in = double( data_in );
end

data_out = repmat( NaN, size( data_in ) );
for i = 1:size( data_in, 2 )

    % if i == 6
    %     keyboard
    % end
    
    if all( isnan( data_in( :, i ) ) )
        % if no valid data, there is nothing to do
        data_out( :, i ) = data_in( :, i );
    else
        this_in = data_in( :, i );
        nan_idx = isnan( this_in );
        % valid data exist -- smooth them
        this_out = smooth( this_in, ...
                           ( win / size( this_in, 1 ) ), ...
                           'rloess' ); 
        this_out( nan_idx ) = NaN;
        data_out( :, i ) = this_out;
    end
    
    if debug_plots
        figure( 'Name', data_input.Properties.VarNames{ i } )
        h_in = plot( data_in( :, i ), '.' );
        hold on;
        h_out = plot( data_out( :, i ), '-k' );
        idx = find( isnan( data_in( :, i ) ) );
        h_nan = plot( idx, data_out( idx, i ), 'or' );
        legend( [ h_in, h_out, h_nan ], ...
                'unsmoothed', 'smoothed', 'NaN', ...
                'Location', 'best' );
    end
end

if input_is_dataset
    data_out = replacedata( data_input, data_out );
end
