% need to convert mV to W/m2!

load( '/Users/tim/UNM/Data/DataSandbox/GLand_TOA5.mat');

% plot sensor output in mV
plot( GLand_TOA5.par_Avg, GLand_TOA5.par_lite_Avg, '.k' );
xlim = get( gca, 'XLim');
h_11_line = line( xlim, xlim, 'Color', [ 255, 42, 0 ] / 255 );
xlabel( 'par\_Avg (mV)' );
ylabel( 'par\_Lite (mV)' );
title( 'GLand PAR sensor comparison' );

% fit lines
[r, c ] = find( not( isnan( [ GLand_TOA5.par_lite_Avg, ...
                    GLand_TOA5.par_Avg ]  ) ) );
coef = polyfit( GLand_TOA5.par_Avg( r ), GLand_TOA5.par_lite_Avg( r ), 1 );
x = xlim(1) : 0.25 : xlim(2);
line( x, polyval( coef, x ), ...
      'Color', 'blue', ...
      'LineWidth', 2 );

% convert mV to umol/m2/s

par_li190 = ( GLand_TOA5.par_Avg * 1000 ) / ( 5.7 * 0.604 );
%par_lite = ( GLand_TOA5.par_lite_Avg * 1000 ) / ( 4.9 );
par_lite =  1000 * ( 173.44 / GLand_TOA5.par_lite_Avg );

% plot PAR values against each other

fig2 = figure();
plot( par_li190, par_lite, '.k' );
xlim = get( gca, 'XLim');
h_11_line = line( xlim, xlim, 'Color', [ 255, 42, 0 ] / 255 );
xlabel( 'LI190 PAR (\mumol m^{-2} s^{-1})' );
ylabel( 'par_lite PAR (\mumol m^{-2} s^{-1})' );