function met_data = UNM_parse_valles_met_data( year )
% parse Valles Caldera met data file to matlab dataset
%
% USAGE
%     met_data = UNM_parse_valles_met_data( year )
%
% (c) Timothy W. Hilton, UNM, March 2012
    
    fname = fullfile( getenv( 'FLUXROOT' ), 'AncillaryData', 'MetData', ...
                      sprintf( 'valles_met_data_%d.dat', year ) );
    
    fprintf( 'parsing %s\n', fname );
    infile = fopen( fname, 'r' );
    headers = fgetl( infile );
    headers = regexp( headers, '[ \t]+', 'split' );
    n_cols = numel( headers );  %how many columns?
    fclose( infile );

    delim = detect_delimiter( fname );
    
    fmt = repmat( '%f', 1, n_cols );
    met_data = dataset( 'file', fname, ...
                        'TreatAsEmpty', '.', ...
                        'format', fmt, ...
                        'MultipleDelimsAsOne', true, ...
                        'delimiter', delim, ...
                        'TreatAsEmpty', { '**', '.' } );
    
    met_data.Properties.VarNames = headers;
    
    
