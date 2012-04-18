function run_std = running_stddev(x, window)
% RUNNING_stddev - computes running standard deviation of its input using
% specified window size.  Pads window/2 elements at front and back of output
% with NaN.
% USAGE
%     run_std = running_stddev( x, window )
% INPUTS
%     x: N by M matrix 
%     window: integer; window size
% OUTPUTS
%    run_std: the running standard deviation.  Computed column-wise if M > 1.
%
% (c) Timothy W. Hilton, UNM, Apr 2012

    if mod( window, 2 ) ~= 1
        error( 'window must be odd integer' );
    end
    
    % if x is a column vector, transpose it for the calculation
    is_vector = false;
    if size( x, 1 ) == 1
        is_vector = true;
        x = x';
    end
    
    % calculate running variance
    run_mean_1 = filter( ones( 1, window ) / window, ...
                         1, ...
                         x .^ 2 );
    run_mean_2 = filter( ones( 1, window ) / window, ...
                         1, ...
                         x );
    run_mean_2 = run_mean_2 .^ 2;
    
    run_var = ( window / ( window - 1 ) ) * ( run_mean_1 - run_mean_2 );

    % calculate running standard deviation from variance
    run_std = sqrt( run_var );
    
    % pad first and last window/2 elements with NaN
    n_pad = floor( window / 2 );
    run_std = [ repmat( NaN, n_pad, size( x, 2 ) ); ...
                 run_std( window:end, : ); ...
                 repmat( NaN, n_pad, size( x, 2 ) ) ];

    % if x was a column vector, transpose it back    
    if is_vector
        run_std = run_std';
    end