I = imread('rice.png');
BW = im2bw(I, graythresh(I));
BW = isnan( n( 1:18000, 11:end ) );
CC = bwconncomp(BW);
L = labelmatrix(CC);
BB = regionprops( L, 'BoundingBox' );
area = regionprops( L, 'area' );
area = arrayfun(@(x) x.Area, area );
[ area, idx ] = sort( area );


red_cmap = [ 0 : ( 1 / length( BB ) ) : 1 ]';
red_cmap = [ red_cmap, ...
             repmat( 0, length( red_cmap ), 1 ), ...
             repmat( 0, length( red_cmap ), 1 ) ];
red_cmap = red_cmap( idx, : );
red_cmap( area(idx) > 100, 2 ) = 1;
%[B,L] = bwboundaries(BW,'noholes');
imtool(label2rgb(L, red_cmap, [0.5 0.5 0.5]), 'InitialMagnification', 100 );
% hold on
% for k = 1:length(B)
%     boundary = B{k};
%     plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
% end