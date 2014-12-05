function met_data_T = UNM_parse_PRISM_met_data( sitecode, year )
% Parse ancillary PRISM data files to matlab table.  
%
% We currently have daily PRISM precip data for all sites. 
%
% For each year YYYY data are located in
% $FLUXROOT/AncillaryData/MetData/PRISM_precip_daily_YYYY.csv
% Updated data can be obtained by downloading zipped directories of
% daily .bil files from http://prism.oregonstate.edu/recent/
% Spatial coverage of these sites is 4km for the continental US, so 
% pixel data can be extracted by running getPrismPrecip.py in the same
% directory.
%
% The script issues an error if these files are not found. See README in
% the target folder for instructions on downloading/formatting this data
%
% USAGE
%     met_data = UNM_parse_PRISM_met_data( sitecode, year );
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
sitename = sitecode;

fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
    'MetData', sprintf( 'PRISM_precip_daily_%d.csv', year ));

% Get data
met_data_T = readtable(fname, 'Delimiter', ',');



