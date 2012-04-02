function result = combine_PARavg_PARlite(headertext, data)
% COMBINE_PARAVG_PARLITE - combine Par_Avg datalogger column with Par_lite
% column

lite_col = find( strcmp( 'par_lite_avg', lower( headertext ) ) );
avg_col = find( strcmp( 'par_avg', lower( headertext ) ) );

par_lite = data( :, lite_col - 1 );
par_avg = data( :, avg_col - 1 );

% find rows containing NaN in either
nan_idx = any( isnan( [ par_lite, par_avg ] ), 2 );

% regress par_lite against par_avg to fit Par_Avg to Par_lite at timestamps
% before Par_lite was installed
linfit = polyfit( par_avg( ~nan_idx ), par_lite( ~nan_idx ), 1 );

result = par_lite;
result(nan_idx) = ( par_avg( nan_idx ) * linfit( 1 ) ) + linfit( 2 );


