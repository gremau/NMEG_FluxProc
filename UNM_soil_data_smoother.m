function [ vwc2, vwc3, vwc4 ] = UNM_soil_data_smoother( raw_soil_data )
%
% USAGE
%    result = UNM_soil_data_smoother( raw_soil_data )
%
% (c) Timothy W. Hilton, UNM, Apr 2012
    
% not temperature corrected
vwc2 = repmat( -0.0663, size( raw_soil_data ) ) -  0.00636 .* raw_soil_data + 0.0007 .* ( raw_soil_data .* raw_soil_data );

% Remove any negative SWC values
vwc2( vwc2 < 0 ) = nan;
vwc2( vwc2 > 1 ) = nan;

% gap fill and smooth SWC using filter    
aa = 1;
nobs = 12; % 6 hr filter
bb = ( ones( nobs, 1 ) / nobs );
vwc3 = vwc2;
vwc4 = vwc2;
[ l w ] = size( vwc2 );
for n = 1:w
    for m = 11:l-11
        average = nanmean( vwc2( ( m-10:m+10 ), n ) );
        standev = nanstd( vwc2( ( m-10:m+10 ), n ) );
        if ( vwc2( m, n ) > ( average + ( standev * 3 ) ) || ...
             vwc2( m, n ) < ( average - ( standev * 3 ) ) )
            vwc2(m,n)=nan;
        end
        if isnan( vwc2( m, n ) )
            vwc3( m, n ) = average;
        end
    end
    vwc4( :, n ) = filter( bb, aa, vwc3( :, n ) );
    vwc4( 1:( l - ( nobs / 2 ) ) + 1, n ) = vwc4( nobs/2:l, n );
end

