function precipDataT = UNM_parse_PRISM_met_data( siteID, year )
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
%     met_data = UNM_parse_PRISM_met_data( siteID, year );
%
% INPUTS
%     siteID: String indicating site go get data for (ameriflux style)
%     year: numeric; the year to parse
%
% OUTPUTS:
%     met_data_ds: dataset array; the met data



precipFname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data',...
    'PRISM_daily', sprintf( 'PRISM_Daily_ppt_%d.csv', year ));

% Get data
precipDataT = readtable( precipFname, 'Delimiter', ',' );

% Parse out year
precipDataT = precipDataT( : , { 'date',  siteID });

% Change variable name
precipDataT.Properties.VariableNames{ siteID } = 'Precip';

% Add a timestamp
precipDataT.timestamp = datenum( precipDataT.date, 'yyyy-mm-dd' );



