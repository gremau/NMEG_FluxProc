function met_data_ds = UNM_parse_valles_met_data( metstn, year )
% Parse ancillay Valles Caldera met data files to matlab dataset.  
%
% For MCon the met data for year YYYY must be located in
% $FLUXROOT/AncillaryData/MetData/valles_met_data_YYYY.dat. The Valles
% meteorological data may be downloaded from
% http://sev.lternet.edu/research/climate/meteorology/VCNP/index.html.
% 
% For PPine the met data for year YYYY must be located in
% $FLUXROOT/AncillaryData/MetData/Jemez_DRI_06-current.dat. The DRI
% Jemez meteorological data may be downloaded from
% http://.   FIXME - where does this data come from?
%
% The script issues an error if these files are not found. See README in
% the target folder for instructions on downloading/formatting this data
%
% USAGE
%     met_data = UNM_parse_valles_met_data( sitecode, year );
%
% INPUTS
%     metstn: string; 'DRI' or 'VCP' - met station to retrieve data from
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
    case 'DRI'
        fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
            'MetData', sprintf( 'Jemez_DRI_06-current.dat' ) );
        % Get data from the DRI Jemez met station. This station is very
        % near PPine
        T = readtable(fname, 'Delimiter', ',');

        met_data_ds = table2dataset(T);
        
        
    case 'VCP'
        fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData',...
            'MetData', sprintf( 'valles_met_data_%d.dat', year ) );
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
        
        % Read in entire file as char array and replace '.' fields
        fprintf( 'parsing %s\n', fname );
        whole_file = fileread( fname );
        whole_file = regexprep( whole_file, '(?<![0-9])\.(?![0-9])', '~' );
        
        % separate headers (first line) from data
        newline_pos = regexp( whole_file, '\n' );   % find newlines
        end_of_first_line = min( newline_pos );
        headers = whole_file( 1:end_of_first_line );% get headers
        data = whole_file( end_of_first_line+1:end );   % rest of data
        
        % Split the headers (by spaces or tabs) and count the columns.  Some
        % Valles met files are tab-delimited, others use both tabs and multiple
        % spaces at different points in the file.
        headers = regexp( headers, '[ \t]+', 'split' );
        n_cols = numel( headers );  %how many columns?
        
        fmt = [ repmat( '%f\t', 1, n_cols -1 ), '%f' ];
        % File is acutally delimited with spaces, but treating it as tabs
        % still works ok 
        met_data = textscan( data, ...
            fmt, ...
            'TreatAsEmpty', '~', ...
            'delimiter', '\t', ...
            'MultipleDelimsAsOne', true ); % Read multiple delimiters as 1
        met_data_ds = dataset( { cell2mat( met_data ), headers{ : } } );
end




