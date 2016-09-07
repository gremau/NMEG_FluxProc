function metData_T = UNM_parse_GHCN_met_data( metstn, year )
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
%     metData_T = UNM_parse_GHCN_met_data( sitecode, year );
%
% INPUTS
%     metstn: string; 'ESTANCIA' or 'PROGRESSO' (station name)
%     year: numeric; the year to parse
%
% OUTPUTS:
%     metData_T: table; the met data
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, March 2012
switch metstn
    case 'ESTANCIA'
        fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data',...
            sprintf( 'GHCND_ESTANCIA_DailySumm_20060101-20160831.csv' ));
        % Get data from the ESTANCIA - station is north of Hwy 60
        metData_T = readtable( fname, 'Delimiter', ',' );
        
    case 'PROGRESSO'
        fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data',...
            sprintf( 'GHCND_PROGRESSO_DailySumm_20070101-20120731.csv' ));
        % Get data from the PROGRESSO - station is a few miles W of tower
        metData_T = readtable( fname, 'Delimiter', ',' );
end

% Trim data to year
dvec = datevec( num2str( metData_T.DATE ), 'yyyymmdd' );
yearIdx = dvec( :, 1 ) == year;
metData_T = metData_T( yearIdx, : );

% Create a matlab timestamp
metData_T.timestamp = datenum( num2str( metData_T.DATE ), 'yyyymmdd' );




