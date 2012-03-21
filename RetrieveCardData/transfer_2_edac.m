function success = transfer_2_edac(site, compressed_data_fname)
% TRANSFER_2_EDAC - 
    
    edac_path = sprintf('/data/epscor/private/data/Upland_node/%s/Raw/', site);
    
    [fpath, fname, fext] = fileparts(compressed_data_fname);
    
    %write an sftp script to a temporary file
    calling_dir = pwd();
    cd(getenv('TMP'));
    sftp_script_file = tempname(getenv('TMP'));
    fid = fopen(sftp_script_file, 'w+');
    fprintf(fid, ['\n\n#Transfering compressed raw data to edacdata1.unm.edu.  ' ...
                  'This will likely take a few minutes.  sftp will likely say it ' ...
                  'is stalled at least once -- please ignore these messages.\n\n']);
    fprintf(fid, 'cd %s\n', edac_path);
    fprintf(fid, 'progress\n');  %enable SFTP progress updates
    fprintf(fid, ['put /cygdrive/c/Research\\ -\\ Flux\\ Towers/Flux\\ Tower', ...
                  '\\ Data\\ by\\ ' ...
                  'Site/%s/Raw\\ data\\ from\\ cards/Raw\\ Data\\ 2012/%s%s\n'], ...
            site, fname, fext);
    fprintf(fid, ['\n\n#This DOS window will not close by itself -- you may ' ...
                  'close it now by typing ''exit'' at the prompt.\n']);
    fclose(fid);
    
    % run the transfer in a dos window
    script_file_cygpath = strrep(sftp_script_file, 'C:\', '/cygdrive/c/');
    script_file_cygpath = strrep(script_file_cygpath, '\', '/');
    cmd =sprintf(['sftp -o "batchmode no" -b %s ', ...
                  'jdelong@edacdata1.unm.edu &'], ...
                 script_file_cygpath);
    [s, r] = dos(cmd);

    % need to implement some sort of blocking scheme here to make Matlab wait
    % until compression is done.  This will work, but requires a click when
    % compression is complete.
    h = warndlg('press OK when file transfer is complete', 'transfering file');
    waitfor(h);
    
    %remove the sftp script
    delete(sftp_script_file);
    
    %change matlab back to the original directory
    cd(calling_dir);
    
