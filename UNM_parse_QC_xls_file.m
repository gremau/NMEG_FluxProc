function qc_num = UNM_parse_QC_xls_file( sitecode, year )
%% UNM_PARSE_QC_XLS_FILE - 
%%   

    site = get_site_name( sitecode );
    
    qcfile = fullfile( get_site_directory( sitecode ), ...
                       'processed_flux', ...
                       sprintf( '%s_flux_all_%d_qc.xls', site, year ) );

    [ qc_num, discard ] = xlsread( qcfile, 'data', '', 'basic');
    