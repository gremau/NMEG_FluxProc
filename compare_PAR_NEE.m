ax1 = subplot( 2, 1, 1 )
plot( decimal_day, fc_raw_massman_wpl, '.' )
xlim( [ (48*100), (48*101) ] )
plot( decimal_day, fc_raw_massman_wpl, '.' )
ylim( [-10, 10 ] )
ax2 = subplot( 2, 1, 2 )
plot( decimal_day, Par_Avg, '.' )

linkaxes( [ ax1, ax2 ], 'x' );