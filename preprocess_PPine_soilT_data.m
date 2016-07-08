function SoilT = preprocess_PPine_soil_data( year )
% PREPROCESS_PPINE_SOIL_DATA - parse soil data for Ponderosa Pine site to a
% dataset array and extract the observations for a specified year.
%
% FIXME - Deprecated. This function will be superceded by 
%                     parse_PPine_soil_data.m
%
% The PPine soil data are parsed from
% $FLUXROOT/SiteData/PPine/soil_data/PPine_soil_data_20080101_20120522.dat.
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

warning( 'This function ( preprocess_PPine_soilT_data ) is deprecated ');

fname = fullfile( get_site_directory( UNM_sites.PPine ), ...
                  'soil', ...
                  'PPine_soil_data_20080101_20141118.dat' );

fmt = repmat( '%f', 1, 89 );
ds = dataset( 'File', fname, ...
              'format', fmt, 'Delimiter', '\t' );


          
%Marcy added 6/17/14          
[ SoilTvars, SoilTidx ] = regexp_header_vars( ds, 'SoilT_C' );
SoilT = ds( :, { 'timestamp', SoilTvars{ : } } );

%SoilT.Properties.VarNames = regexprep( SoilT.Properties.VarNames, ...
 %                                    'SoilT_C','SoilT_C' );

arr = double( SoilT );

SoilT = replacedata( SoilT, arr );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( SoilT.timestamp );
SoilT = SoilT( datayear == year, : );          
% %----------------------------------------------          
%           
%           
%           
%           
% [ SWCvars, SWCidx ] = regexp_header_vars( ds, 'VWC' );
% SWC = ds( :, { 'timestamp', SWCvars{ : } } );
% 
% SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
%                                      'VWC', 'cs616SWC' );
% 
% arr = double( SWC );
% arr( arr < 0 ) = NaN;
% SWC = replacedata( SWC, arr );
% 
% % return data for requested year
% [ datayear, ~, ~, ~, ~, ~ ] = datevec( SWC.timestamp );
% SWC = SWC( datayear == year, : );
% 


