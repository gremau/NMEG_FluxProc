function SWC = preprocess_PPine_soil_data( sitecode, year )
% PREPROCESS_PPINE_SOIL_DATA - 
%   

fname = fullfile( get_site_directory( UNM_sites.PPine ), ...
                  'soil_data', ...
                  'PPine_soil_data_20080101_20120522.dat' );

fmt = repmat( '%f', 1, 89 );
ds = dataset( 'File', fname, ...
              'format', fmt, 'Delimiter', '\t' );

[ SWCvars, SWCidx ] = regexp_ds_vars( ds, 'VWC' );
SWC = ds( :, { 'timestamp', SWCvars{ : } } );

SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                     'VWC', 'cs616SWC' );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( SWC.timestamp );
SWC = SWC( datayear == year, : );
