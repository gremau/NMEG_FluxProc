function success = transfer_2_edac(site, compressed_data)
% TRANSFER_2_EDAC - 
    
    edac_path = sprintf('/data/epscor/private/data/Upland_node/%s/raw/', site);
    winscp = 'C:\Program Files (x86)\WinSCP\WinSCP.com';
    
    [dir_path, fname, ext] = fileparts(compressed_data);

    calling_dir = pwd();
    cd(dir_path);
        
    cmd = sprintf('"%s" jdelong@edacdata1.unm.edu:%s /command "put %s%s" &', ...
                  winscp, edac_path, fname, ext);
    dos(cmd);
    
    cd(calling_dir)
    
