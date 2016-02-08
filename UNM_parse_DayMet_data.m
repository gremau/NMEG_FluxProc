function met_data_T = UNM_parse_DayMet_data( sitecode, year )
% Parse ancillary DayMet data files to matlab table.  
%
% We currently have daily DayMet met data for all sites. 
%
% For each year YYYY data are located in
% $FLUXROOT/AncillaryData/MetData/DayMet_SITECODE.csv
% Updated data can be obtained by downloading the multiple
% point data download script (see daymet subdirectory), editing the
% latlon.txt file to include our site coordinates, and runing the 
% 'daymet_multiple_extraction' script or .jar file.
%
% Updates to that script or the data can be found at:
%             http://daymet.ornl.gov/
%
% This script issues an error if these files are not found. See README in
% the target folder for instructions on downloading/formatting this data
%
% USAGE
%     met_data = UNM_parse_DayMet_data( sitecode, year );
%
% INPUTS
%     sitecode: UNM_sites object
%     year: numeric; the year to parse
%
% OUTPUTS:
%     met_data_ds: dataset array; the met data
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, March 2012

fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data',...
    'DayMet', sprintf( 'DayMet_%s.csv', get_site_name( sitecode ) ));

% Get data
met_data_T = readtable( fname, 'Delimiter', ',', 'HeaderLines', 7 );

% Parse out year
met_data_T = met_data_T( met_data_T.year == year, : );

% Add a timestamp
met_data_T.timestamp = datenum( met_data_T.year - 1 , 12, 31, 0, 0, 0 )...
    + met_data_T.yday;





