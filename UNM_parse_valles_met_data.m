function met_data_ds = UNM_parse_valles_met_data( year )
% parse Valles Caldera annual met data file to matlab dataset.  
%
% The met data for year YYYY must be located at
% $FLUXROOT/AncillaryData/MetData/valles_met_data_YYYY.dat.  Issues error if
% this file does not exist.  The Valles meteorological data may be downloaded
% from http://sev.lternet.edu/research/climate/meteorology/VCNP/index.html.
%
% USAGE
%     met_data = UNM_parse_valles_met_data( year );
%
% INPUTS
%     year: numeric; the year to parse
%
% OUTPUTS:
%     met_data_ds: dataset array; the met data
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, March 2012

fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
                  sprintf( 'valles_met_data_%d.dat', year ) );
fprintf( 'parsing %s\n', fname );

% these met files use "." to record missing values.  This confuses matlab
% because it is (1) not numeric, so can't be read by routines that expect
% numeric data, and (2) is the same character as the decimal used in
% actual obserations, so the "TreatAsEmpty" parameter to textscan won't
% work.  (setting TreatAsEmpty to '.' inserts a NaN into the middle of
% all observations with a decimal point...)
%
% Here I work around this problem by replacing all occurences of '.'  that
% are not between two digits 0-9 with "~".  Replacing with "~" takes less
% than one second, while replacing with "NaN" did not finish in ten minutes,
% at which point I cut it off.  I suspect (but don't know for sure) that
% Matlab is doing something dumb with memory where it is trying to increase
% the length of the string in place, and the string is long because it
% contains the whole file, so this takes a long time...  This is the only
% thing I can think of that might cause a single-character replacement to go
% fast but a multiple-character replacement to be sloooooowwwwww.
whole_file = fileread( fname );
whole_file = regexprep( whole_file, '(?<![0-9])\.(?![0-9])', '~' );

% separate headers (first line) from data
newline_pos = regexp( whole_file, '\n' );
n_lines = numel( newline_pos );
end_of_first_line = min( newline_pos );
headers = whole_file( 1:end_of_first_line );
data = whole_file( end_of_first_line+1:end );

% Split the headers (by spaces or tabs) and count the columns.  Some
% Valles met files are tab-delimited, others use both tabs and multiple
% spaces at different points in the file.
headers = regexp( headers, '[ \t]+', 'split' );
n_cols = numel( headers );  %how many columns?

fmt = [ repmat( '%f\t', 1, n_cols -1 ), '%f' ];
met_data = textscan( data, ...
                     fmt, ...
                     'TreatAsEmpty', '~', ...
                     'delimiter', '\t', ...
                     'MultipleDelimsAsOne', true );
met_data_ds = dataset( { cell2mat( met_data ), headers{ : } } );

