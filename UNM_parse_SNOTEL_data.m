function metTable = UNM_parse_SNOTEL_data( sitecode, year )
% Parse ancillary SNOTEL data files to matlab table.  
%
% We currently have daily SNOTEL met data from 3 sites in the Valles. 
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
%     met_data = UNM_parse_SNOTEL_data( sitecode, year );
%
% INPUTS
%     sitecode: numeric; SNOTEL site identifier
%     year: numeric; the year to parse
%
% OUTPUTS:
%     metData_ds: dataset array; the met data
%
% SEE ALSO
%     dataset
%
% author: Gregory E. Maurer, UNM, December 2014

%sitecode = str(sitecode);

fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
    'MetData', 'SNOTEL_daily', sprintf( '%d_STAND_YEAR=%d.csv',...
    sitecode, year ));

% Get data
metTable = readtable( fname, 'Delimiter', ',', 'HeaderLines', 2 );

% clunky way to rename bizarre headers
headers = metTable.Properties.VariableNames;
metTable.Properties.VariableNames{ find( ...
    strncmp( 'WTEQ', headers, 4 ))} = 'WTEQ';
metTable.Properties.VariableNames{ find( ...
    strncmp( 'PREC', headers, 4 ))} = 'PREC_CUM';
metTable.Properties.VariableNames{ find( ...
    strncmp( 'TOBS', headers, 4 ))} = 'TOBS';
metTable.Properties.VariableNames{ find( ...
    strncmp( 'SNWD', headers, 4 ))} = 'SNWD';

% Convert cumulative precip to hourly increments in mm
p_diff = [ 0; diff( metTable.PREC_CUM )] * 25.4;
% Remove negative increments
p_diff( p_diff < 0 ) = 0;

metTable.Precip = p_diff;

% Parse out year
% metTable = metTable( met_data_T.year == year, : );

% Add a timestamp
metTable.timestamp = datenum( metTable.Date, 'yyyy-mm-dd' );





