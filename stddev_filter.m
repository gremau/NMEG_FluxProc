function [ filtered_series, sdflag ] = stddev_filter( series_in, ...
                                                      filter_windows, ...
                                                      std_dev, varargin )

% Initialize the output series and remove-data flag
filtered_series = series_in;
sdflag = repmat( false, length( series_in ), 1 );

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
    
    % Plot the previously filtered series for contrast and add legend
    plot( 1:length( filtered_series ), filtered_series, colors{i} );
    leg_string{ i } = sprintf( '%1.1f Days, SD = %1.2f', window, std_dev );
    
    % Filter the series
    [ filtered_series, rem_idx ] = filterseries( filtered_series, ...
        'sigma', 48*window, std_dev, true, false );
    
    % Add remove indices to std_flag
    sdflag = sdflag | rem_idx;
end
    
% Plot final points
plot( 1:length( filtered_series ), filtered_series, '.k' );
leg_string{ i + 1 } = 'Filtered data';
legend( leg_string, 'Location', 'SouthWest' );