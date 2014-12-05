function met_data_T = UNM_parse_GHCND_met_data( metstn, year )
% Parse ancillary Global Historical Climatology Network data files
% to matlab dataset.  
%
% We currently use 2 stations to fill JSav. Estancia and Progresso. 
%
% For each site data for year YYYY must be located in
% $FLUXROOT/AncillaryData/MetData/GHCND_STNNAME_DailySumm_DATERANGE.csv
% Updated data can be obtained by downloading daily summaries for the
% sites from http://www.ncdc.noaa.gov/cdo-web/search.
%
% The script issues an error if these files are not found. See README in
% the target folder for instructions on downloading/formatting this data
%
% USAGE
%     met_data = UNM_parse_GHCND_met_data( sitecode, year );
%
% INPUTS
%     metstn: string; 'ESTANCIA' or 'PROGRESSO' (station name)
%     year: numeric; the year to parse
%
% OUTPUTS:
%     met_data_ds: dataset array; the met data
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, March 2012
switch metstn
    case 'ESTANCIA'
        fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
            'MetData',...
            sprintf( 'GHCND_ESTANCIA_DailySumm_20070101-20131231.csv' ));
        % Get data from the ESTANCIA - station is north of Hwy 60
        met_data_T = readtable(fname, 'Delimiter', ',');
        
        
    case 'PROGRESSO'
        fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
            'MetData',...
            sprintf( 'GHCND_PROGRESSO_DailySumm_20070101-20131231.csv' ));
        % Get data from the PROGRESSO - station is a few miles W of tower
        met_data_T = readtable(fname, 'Delimiter', ',');
end




