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

if year < 2011
    fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data', ...
        'sev1_meteorology_2006-2010.txt' );
    metTable = readtable( fname, 'Delimiter', ',' );
elseif year > 2010
    fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data', ...
        'sev1_meteorology_2011-2015.txt' );
    metTable = readtable( fname, 'Delimiter', ',' );
end

% Determine site id (if requested)
if length( varargin ) > 0
    siteid = varargin{ 1 };
elseif length( varargin ) == 0
    siteid = [];
else
    error( 'Invalid number of arguments' )
end

% Remove bad values
metTable = replace_badvals( metTable, [-999, -888, 6999, -6999], 1e-4);

% Trim out extra sites from the table if requested
if ~isempty( siteid )
    metTable = metTable( metTable.StationID == siteid, : );
end

% Trim to year and add a timestamp
metTable = metTable( metTable.Year == year, : );

ts = datenum( metTable.Year, 1, 1 ) + ...
    ( metTable.Julian_Day - 1 ) + ...
    ( metTable.Hour / 24.0 );

metTable.timestamp = ts;
% Observations are in funny order sometimes...
metTable = sortrows( metTable, { 'StationID', 'timestamp' } );

% Clear out duplicate timestamps (remove second one)
[ idx, dup ] = find_duplicates( metTable.timestamp );
metTable( idx,: ) = [];

