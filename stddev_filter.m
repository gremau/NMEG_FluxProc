function [ filtered_array, sdflag ] = stddev_filter( array_in, ...
                                                     filter_windows, ...
                                                     std_dev, varargin )

% Initialize the output array and remove-data flag
if isa( array_in, 'table' );
    filtered_array = table2array( array_in );
else
    filtered_array = array_in;
end
sdflag = repmat( false, length( filtered_array ), 1 );

% Initialize the figure to plot to
if length( varargin ) > 0
    fig_title = sprintf( '%s %d standard deviation filter', ...
        get_site_name( varargin{1} ), varargin{2} );
else
    fig_title = 'Standard deviation filter';
end
h_fig1 = figure( 'Name', fig_title, ...
    'Position', [150 150 1050 550], 'Visible', 'on' );
hold on;
% Colors and legend strings for plotting
colors = { '.r', '.m', '.b', '.y' };
leg_strings = {};

% Loop through each filter window and filter/plot
for i=1:length( filter_windows );
    
    window = filter_windows( i );
    
    % Slightly increase the std deviation threshold each round
    if i > 1
        std_dev = std_dev + .15;
    end
    
    % Plot the previously filtered array for contrast and add legend
    plot( 1:length( filtered_array ), filtered_array, colors{i} );
    leg_string{ i } = sprintf( '%1.1f Days, SD = %1.2f', window, std_dev );
    
    % Filter the array
    [ filtered_array, rem_idx ] = filterseries( filtered_array, ...
        'sigma', 48*window, std_dev, true, false );
    
    % Add remove indices to std_flag
    sdflag = sdflag | rem_idx;
end
    
% Plot final points
plot( 1:length( filtered_array ), filtered_array, '.k' );
leg_string{ i + 1 } = 'Filtered data';
legend( leg_string, 'Location', 'SouthWest' );

% If needed, convert back to table
if isa( array_in, 'table' );
    filtered_array = array2table( filtered_array, ...
        'VariableNames', array_in.Properties.VariableNames );
end