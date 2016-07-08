function result = align_axes_zeros( ax1, ax2 )
% ALIGN_AXES_ZEROS - vertically aligns the zero on a plot with two vertical axes
%   
% USAGE
%    result = align_axes_zeros( ax1, ax2 )
%
% (c) Timothy W. Hilton, UNM, July 2012

result = -1;

ylim1 = get( ax1, 'Ylim' );
newlim = max( abs( ylim1 ) );
set( ax1, 'YLim', [ -1.0 * newlim, newlim ] );

ylim1 = get( ax2, 'Ylim' );
newlim = max( abs( ylim1 ) );
set( ax2, 'YLim', [ -1.0 * newlim, newlim ] );

result = 0;

% --------------------------------------------------
% this code doesn't work if one axis limit == 0.0
% set( ax1, 'Ylim', max( abs( get( ax1, 'YLim' ) ) ) * [ -1, 1 ] );

% % Retrieve Ylim of second axis
% ylim2 = get( ax2, 'Ylim' );
% if ylim2( 1 ) == 0
%     ylim2( 1 ) = -0.001;
% end
% if ylim2( 2 ) == 0
%     ylim2( 2 ) = 0.001;
% end

% % Ratio of negative leg to positive one (keep sign)
% ratio = ylim2( 1 ) / ylim2( 2 );
% % Set same ratio for first axis
% ylim1 = get( ax1, 'Ylim' );
% set( ax1, 'Ylim', [ ylim1( 1 ) * ratio, ylim1( 2 ) ] );
% box( 'off' ); % without this, it draws left axes' Ytick marks on both sides

% result = 0;

