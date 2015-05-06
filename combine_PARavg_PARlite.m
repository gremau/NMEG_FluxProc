function result = combine_PARavg_PARlite(headertext, data)
% COMBINE_PARAVG_PARLITE - within a dataset combine Par_Avg datalogger column
% with Par_lite column into single record.  
%
% A linear regression is performed to adjust Par_Avg observations to Par_lite
% using all timestamps that have observations from both instruments.  The output
% timeseries contains: - Par_lite measurements whenever they exist - adjusted
% (by regression, described above) Par_Avg measurements where Par_Avg
% measurement exists but Par_lite measurement does not.
%
% USAGE
%     result = combine_PARavg_PARlite( headertext, data );
%
% INPUTS
%    headertext: N-element cell array of strings; the column headers of the dataset
%        (used to identify variables)
%    data: N by M numeric array; the data corresponding to headertext.  N
%        must equal the length of headertext.
%
% OUTPUTS
%    result: M by 1 numeric array: the combined PAR time series.
%
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, Apr 2012

lite_col = find( strcmp( 'par_face_up_avg', lower( headertext ) ) );
licor_col = find( strcmp( 'par_licor', lower( headertext ) ) );

% Not sure why this had the -1
par_lite = data( :, lite_col );
par_avg = data( :, licor_col );

% find rows containing NaN in either
nan_idx = any( isnan( [ par_lite, par_avg ] ), 2 );

% regress par_lite against par_avg to fit Par_Avg to Par_lite at timestamps
% before Par_lite was installed
linfit = polyfit( par_avg( ~nan_idx ), par_lite( ~nan_idx ), 1 );

result = par_lite;
result(nan_idx) = ( par_avg( nan_idx ) * linfit( 1 ) ) + linfit( 2 );


