for year = 2009
    fluxall = UNM_parse_fluxall_xls_file( UNM_sites.JSav, year );
    cdp = card_data_processor( UNM_sites.JSav, ...
                               'date_start', datenum( year, 1, 1 ), ...
                               'date_end', datenum( year, 12, 31, 23, 59, 59) );
    fprintf( 'converting to ASCII text\n' );
    cdp.write_fluxall( fluxall )
end
    
    