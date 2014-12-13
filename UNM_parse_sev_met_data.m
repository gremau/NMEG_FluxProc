function metT = UNM_parse_sev_met_data( year )
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
%
% OUTPUTS
%    met_data: matlab dataset array; the Sevilleta data for the specified
%        year 
%
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, March 2012
if year < 2013
    fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
        'sev_met_data_2007_2012.dat' );
elseif year > 2012
    fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
        'sev_met_data_2013_2014_2site.dat' );
end
infile = fopen( fname, 'r' );
if ( infile == -1 )
    error( sprintf( 'failed to open %s\n', fname ) );
end
headers = fgetl( infile );
var_names = regexp( headers, ',', 'split' );
n_cols = numel( var_names );  %how many columns?
fclose( infile );

fmt = [ repmat( '%f', 1, n_cols -1 ), '%f' ];
met_data = dataset( 'file', fname, ...
    'format', fmt, ...
    'Delimiter', ',', ...
    'HeaderLines', 1, ...
    'TreatAsEmpty', '.' );

data_dbl = double( met_data );
data_dbl = replace_badvals( data_dbl, [ -999 ], 1e-6 );

met_data = dataset( { data_dbl, var_names{ : } } );

% Assign to table and add a matlab timestamp
metT = dataset2table(met_data);

% There are some discrepancies in the header names between the 2 files
if year > 2012
    metT.Properties.VariableNames{'StationID'} = 'Station_ID';
    metT.Properties.VariableNames{'Julian_Day'} = 'Jul_Day';
    metT.Properties.VariableNames{'Relative_Humidity'} = 'RH';
    metT.Properties.VariableNames{'Solar_Radiation'} = 'Solar_Rad';
    metT.Properties.VariableNames{'Precipitation'} = 'Precip';
end

ts = datenum( metT.Year, 1, 1 ) + ...
    ( metT.Jul_Day - 1 ) + ...
    ( metT.Hour / 24.0 );
metT.timestamp = ts;
