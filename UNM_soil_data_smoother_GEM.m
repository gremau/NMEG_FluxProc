function data_out = UNM_soil_data_smoother( data_in, ...
                                            win, ...
                                            debug_plots )
%
% Smooths its input data by removing outliers and applying a running
% average, ignoring NaNs in input.
%
% USAGE
%   data_out = UNM_soil_data_smoother( data_in, win, debug_plots )
%
% INPUTS
%   data_in: input data; matrix or dataset object.  If data_in is
%       two-dimensional, operates on each column separately. 
%   win: scalar.  1/2 the moving average window (number of elements on
%       either side to consider when calculating average) for smoothing.
%   debug_plots: true|false: if true, draws plots after pass one and pass three.
%
% OUTPUTS
%   data_out: data with outlier elements removed.  Has same type as data_in
%       (dataset array or numeric array)
%
% SEE ALSO
%   dataset
%
% author: Gregory E. Maurer, UNM, Oct. 2014

% Check if datatype, get varnames, convert to double array
input_is_dataset = isa( data_in, 'dataset' );

if input_is_dataset
    data_input = data_in;
    data_vars = data_in.Properties.VarNames;
    data_in = double( data_in );
end
% Preallocate cleaned data output array
data_out = repmat( NaN, size( data_in ) );

% Get varnames

for i = 2:size( data_in, 2 )
    % if no valid data, there is nothing to do
    if all( isnan( data_in( :, i ) ) )
        data_out( :, i ) = data_in( :, i );
    else
        % valid data exist -- smooth them
        this_in = data_in( :, i );
        varname = data_vars{i};
        
        if ~isempty(regexp(varname, 'SWC'))
            smax = 0.5;
            smin = 0;
        elseif ~isempty(regexp(varname, 'SoilT'))
            smax = 45;
            smin = -45;
        end
        % Remove absurd values (impossible or beyond sensors range)
        test = this_in > smax | this_in <= smin;
        in_filtered = this_in;
        in_filtered(test) = nan;
        
        % Get array marking nans
        nan_idx = isnan(in_filtered);
        
        % Filter the data with a 24hour, 3 std. dev filter
        in_filtered = filterseries(in_filtered, 'sigma', win, 3);
        % Fill in nan values
        in_filtered_filled = inpaint_nans( in_filtered, 4 );
        %
        data_out( :, i ) = in_filtered_filled;
        
        last_valid_data_in = max( find( not( nan_idx ) ) );
        data_out( (last_valid_data_in + 1):end, i ) = NaN;
        
        first_valid_data_in = min( find( not( nan_idx ) ) );
        if first_valid_data_in > 0
            data_out( 1:(first_valid_data_in - 1), i ) = NaN;
        end
    end
    
    if debug_plots
        figure( 'Name', data_input.Properties.VarNames{ i } )
        h_in = plot( this_in, '.r' );
        hold on;
        h_filled = plot( data_out( :, i ), '.b' );
        h_filt = plot(in_filtered, '.k');
        legend( [ h_in, h_filled, h_filt ], ...
                'removed', 'filled', 'original', ...
                'Location', 'best' );
    end
end

if input_is_dataset
    data_out = replacedata( data_input, data_out );
end
