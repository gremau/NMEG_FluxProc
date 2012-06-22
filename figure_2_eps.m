function figure_2_eps( h_fig, fname )
% FIGURE_2_EPS - save a figure to an eps file
%
% USAGE
%   figure_2_eps( h_fig, fname )
%
% INPUTS
%   h_fig: matlab figure handle
%   fname: string; file name for the eps file
%
% OUTPUTS
%   no outputs
%
% (c) Timothy W. Hilton, UNM, June 2012

% force matlab to respect the figure size (without this, it "pads" the figure
% margins so the eps image will occupy an entire 8.5 by 11 inch piece of paper
set( h_fig, 'PaperPositionMode', 'auto' );

% save the figure
print( h_fig, '-depsc2', fname );
