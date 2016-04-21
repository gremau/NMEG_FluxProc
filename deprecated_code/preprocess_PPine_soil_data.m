function SWC = preprocess_PPine_soil_data( year )
% PREPROCESS_PPINE_SOIL_DATA - parse soil data for Ponderosa Pine site to a
% dataset array and extract the observations for a specified year.
%
% FIXME - Deprecated. This function will be superceded by 
%                     parse_PPine_soil_data.m
%
% The PPine soil data are parsed from
% $FLUXROOT/Flux_Tower_Data_by_Site/PPine/soil_data/PPine_soil_data_20080101_20120522.dat.
%
% INPUTS:
%     year: four-digit year; specifies the year for data extraction
%
% OUTPUTS
%     SWC: dataset array; soil water content data for the specified year
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, August 2012

warning( 'This function ( preprocess_PPine_soil_data ) is deprecated ');

fname = fullfile( get_site_directory( UNM_sites.PPine ), ...
                  'soil_data', ...
                  'PPine_soil_data_20080101_20140218.dat' );

fmt = repmat( '%f', 1, 89 );
ds = dataset( 'File', fname, ...
              'format', fmt, 'Delimiter', '\t' );          
   
          
[ SWCvars, SWCidx ] = regexp_ds_vars( ds, 'VWC' );
SWC = ds( :, { 'timestamp', SWCvars{ : } } );

SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                     'VWC', 'cs616SWC' );

arr = double( SWC );
arr( arr < 0 ) = NaN;
SWC = replacedata( SWC, arr );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( SWC.timestamp );
SWC = SWC( datayear == year, : );



