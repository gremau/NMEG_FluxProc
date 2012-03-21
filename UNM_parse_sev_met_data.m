function met_data = UNM_parse_sev_met_data( year )
% parse Valles Caldera met data file to matlab dataset
%
% USAGE
%     met_data = UNM_parse_valles_met_data( year )
%
% (c) Timothy W. Hilton, UNM, March 2012
    
    fname = fullfile( '/Users/tim/UNM/Data/Valles_Met_Data', ...
                      sprintf( 'sev_met_data_%d.dat', year ) );
    
    infile = fopen( fname, 'r' );
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
