function met_data = UNM_parse_valles_met_data( year )
% parse Valles Caldera met data file to matlab dataset
%
% USAGE
%     met_data = UNM_parse_valles_met_data( year )
%
% (c) Timothy W. Hilton, UNM, March 2012
    
    fname = fullfile( '/Users/tim/UNM/Data/Valles_Met_Data', ...
                      sprintf( 'valles_met_data_%d.dat', year ) );
    
    infile = fopen( fname, 'r' );
    headers = fgetl( infile );
    n_cols = numel( regexp( headers, '[ \t]+', 'split' ) );  %how many columns?
    fclose( infile );
    
    fmt = [ repmat( '%f\t', 1, n_cols -1 ), '%f' ];
    met_data = dataset( 'file', fname, ...
                        'TreatAsEmpty', '.', ...
                        'format', fmt, ...
                        'MultipleDelimsAsOne', true );
