% script to look into problems with nighttime LE observations

pal = cbrewer( 'qual', 'Dark2', 8 );

figure( 'Name', 'LE Debug', ...
        'Units', 'Normalized', ...
        'Position', [ 0.1, 0.15, 0.60, 0.70 ] );
ax_LE_all = subplot( 3, 1, 1 );
h_all = plot( decimal_day, HL_wpl_massman, '.k' );
ylabel( 'LE [W/m^2]' );
ylim( [ -150, 500] );
xlim( [ 0, 366 ] );

hold on
h_maxmin = plot( decimal_day( LH_maxmin_flag ), HL_wpl_massman( LH_maxmin_flag ), '.', ...
                 'Color', pal( 1, : ) );
h_day = plot( decimal_day( LH_day_flag ), HL_wpl_massman( LH_day_flag ), '.', ...
      'Color', pal( 2, : ) );
h_night = plot( decimal_day( LH_night_flag ), HL_wpl_massman( LH_night_flag ), '.', ...
                'Color', pal( 3, : ) );
legend( [ h_all, h_maxmin, h_day, h_night ], 'all', 'maxmin', 'day', 'night' );

% LE & PAR
%figure( 'Name', 'LE & PAR debug')

ax_par = subplot( 3, 1, 2 );
h_all = plot( decimal_day, Par_Avg, 'k.' );
hold on
h_filtered = plot( decimal_day( Par_Avg < 20 ), Par_Avg( Par_Avg < 20 ), '.',...
                   'Color', pal( 1, : ) );
ylabel( 'PAR [umol/m^2/s]' );
xlim( [ 0, 366 ] );
legend( [ h_all, h_filtered ], 'all', 'PAR < 20' );

ax_LE = subplot( 3, 1, 3 );
h_all = plot( decimal_day, HL_wpl_massman, 'k.' );
ylabel( 'LE [W/m^2]' );
xlim( [ 0, 366 ] );
hold on
idx = ( Par_Avg < 20 ) & ( abs( HL_wpl_massman ) > 20 );
h_filtered = plot( decimal_day( idx ), HL_wpl_massman( idx ), '.',...
                   'Color', pal( 1, : ) );
ylabel( 'LE [W/m^2]' );
ylim( [ -500, 500 ] );
xlabel( 'DOY' );
xlim( [ 0, 366 ] );

legend( [ h_all, h_filtered ], 'all', 'PAR < 20 & abs(LE) > 20' );

linkaxes( [ ax_LE_all, ax_par, ax_LE ], 'x' );
