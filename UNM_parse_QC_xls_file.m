function qc_num = UNM_parse_QC_xls_file( sitecode, year )
%% UNM_PARSE_QC_XLS_FILE - 
%%   

    site = get_site_name( sitecode );
    
    qcfile = fullfile( get_site_directory( sitecode ), ...
                       'processed flux', ...
                       sprintf( '%s_flux_all_%d_qc.xls', site, year ) );

    [ qc_num, discard ] = xlsread(qcfile,'data');
    
    %% discard the first column -- these are dates as strings, and Matlab
    %% doesn't read them correctly
    
    qc_num = qc_num( :, 2:end );