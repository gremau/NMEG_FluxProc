function metTable = UNM_parse_sev_met_data( year, varargin )
% UNM_PARSE_SEV_MET_DATA- parse Sevilleta meteorological data file to matlab
% dataset array.
%
% Sevilleta meteorological data are posted online periodically and must be
% downloaded outside of Matlab to $FLUXROOT/AncillaryData/MetData.  The met data
% for year YYYY must be located at
% $FLUXROOT/AncillaryData/MetData/sev_met_data_YYYY.dat.  Issues error if
% this file does not exist.  The Sevilleta meteorological data may be downloaded
% from  http://sev.lternet.edu.
%
% USAGE
%     met_data = UNM_parse_sev_met_data( year )
%
% INPUTS
%    year: four-digit year: specifies the year
%    optional argument is for siteid
%
% OUTPUTS
%    met_data: matlab dataset array; the Sevilleta data for the specified
%        year 
%
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, March 2012
% modified by: Gregory E. Maurer, UNM, December 2014

if year < 2013
    fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
        'sev_met_data_2007_2012.csv' );
    metTable = readtable( fname, 'Delimiter', ',', 'TreatAsEmpty', '.' );
% elseif year > 2012
%     fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
%         'sev_met_data_2013_2014_2site.csv' );
elseif year > 2012
    fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
        sprintf('sev_met_data_%s.dat', num2str(year)) );
    fid  = fopen( fname );
    headers = fgetl( fid );
    headers = strsplit( headers, ' ' );
    fmt = repmat( '%f ', 1, length( headers ));
    C = textscan( fid, fmt, 'TreatAsEmpty', '.');
    fclose(fid);
    metTable = table( C{:,:}, 'VariableNames', headers );
end

% Determine site id (if requested)
if length( varargin ) > 0
    siteid = varargin{ 1 };
elseif length( varargin ) == 0
    siteid = [];
else
    error( 'Invalid number of arguments' )
end

% Read the data into a table
%metTable = readtable( fname, 'Delimiter', ',', 'TreatAsEmpty', '.' );

% Remove bad values
badValues = metTable{ :, : } == -999 | metTable{ :, : } == -888 ;
metTable{ :, : }( badValues ) = NaN; 

% There are some discrepancies in the header names between the 2 files
if year > 2012
    metTable.Properties.VariableNames{ 'sta' } = 'Station_ID';
    metTable.Properties.VariableNames{ 'year' } = 'Year';
    metTable.Properties.VariableNames{ 'time' } = 'Hour';
    metTable.Properties.VariableNames{ 'day' } = 'Jul_Day';
    metTable.Properties.VariableNames{ 'airt' } = 'Temp_C';
    metTable.Properties.VariableNames{ 'rh' } = 'RH';
    metTable.Properties.VariableNames{ 'sol' } = 'Solar_Rad';
    metTable.Properties.VariableNames{ 'ppt' } = 'Precip';
end

% Trim out extra sites from the table if requested
if ~isempty( siteid )
    metTable = metTable( metTable.Station_ID == siteid, : );
end

% Trim to year and add a timestamp
metTable = metTable( metTable.Year == year, : );

ts = datenum( metTable.Year, 1, 1 ) + ...
    ( metTable.Jul_Day - 1 ) + ...
    ( metTable.Hour / 24.0 );

metTable.timestamp = ts;
% Observations are in funny order sometimes...
metTable = sortrows( metTable, { 'Station_ID', 'timestamp' } );

% Clear out duplicate timestamps (remove second one)
[ idx, dup ] = find_duplicates( metTable.timestamp );
metTable( idx,: ) = [];

