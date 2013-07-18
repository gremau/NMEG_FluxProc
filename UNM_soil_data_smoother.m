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
        % valid data exist -- smooth them

        % d = [ NaN; diff( this_in ) ];
        % idx = find( abs( d ) > 0.01 );
        % this_in( idx ) = NaN;
        nan_idx = isnan( this_in );
        this_in = inpaint_nans( this_in, 4 );
        
        in_filtered = medfilt1( this_in, 500 );
        this_in( abs( this_in - in_filtered ) > 0.005 ) = NaN;
        this_in = inpaint_nans( this_in, 4 );
        this_out = supsmu( 1:numel( this_in ), ...
                           this_in, ...
                           'Span', 150 / numel ( this_in ) );
        % this_out = smooth( this_in, ...
        %                    ( win / size( this_in, 1 ) ), ...
        %                    'loess' ); 
        %this_out( nan_idx ) = NaN;
        data_out( :, i ) = this_out;
        
        last_valid_data_in = max( find( not( nan_idx ) ) );
        data_out( (last_valid_data_in + 1):end, i ) = NaN;
        
        first_valid_data_in = min( find( not( nan_idx ) ) );
        if first_valid_data_in > 0
            data_out( 1:(first_valid_data_in - 1), i ) = NaN;
        end
    end
    
    if debug_plots
        figure( 'Name', data_input.Properties.VarNames{ i } )
        h_in = plot( data_in( :, i ), 'ok' );
        hold on;
        h_filt = plot( this_in( : ), '.' );
        h_out = plot( data_out( :, i ), '-g', 'LineWidth', 2 );
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
