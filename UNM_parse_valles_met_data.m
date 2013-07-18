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
    
    fmt = [ repmat( '%f\t', 1, n_cols -1 ), '%f' ];
    met_data = dataset( 'file', fname, ...
                        'TreatAsEmpty', '.', ...
                        'format', fmt, ...
                        'MultipleDelimsAsOne', true );
    
    met_data.Properties.VarNames = headers;
    
    
