function figure_2_eps( h_fig, fname )
% FIGURE_2_EPS - 
%   

set( h_fig, 'PaperPositionMode', 'auto' );
print( h_fig, '-depsc2', fname );
