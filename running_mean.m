function run_mean = running_mean(x, window)
% RUNNING_MEAN - computes running mean of its input using specified window
% size.  Pads window/2 elements at front and back of output with NaN.
% USAGE
%     run_mean = running_mean( x, window )
% INPUTS
%     x: N by M matrix 
%     window: integer; window size
% OUTPUTS
%    run_mean: the running mean.  Computed column-wise if M > 1.
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
    
    % calculate the running mean
    run_mean = filter( ones( 1, window ) / window, ...
                       1, ...
                       x );
    
    % pad first and last window/2 elements with NaN
    n_pad = floor( window / 2 );
    run_mean = [ repmat( NaN, n_pad, size( x, 2 ) ); ...
                 run_mean( window:end, : ); ...
                 repmat( NaN, n_pad, size( x, 2 ) ) ];

    % if x was a column vector, transpose it back    
    if is_vector
        run_mean = run_mean';
    end