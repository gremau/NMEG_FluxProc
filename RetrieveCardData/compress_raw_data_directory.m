function success = compress_raw_data_directory(raw_data_dir)
% COMPRESS_RAW_DATA_DIRECTORY - compresses a directory containing raw flux
% data
    
    seven_zip = 'C:\Program Files (X86)\7-Zip\7z.exe';
    cmd = sprintf('"%s" a "%s" "%s" &', seven_zip, raw_data_dir, raw_data_dir);
    [result, output] = dos(cmd, '-echo');
    
    fprintf(1, output);
    
    if (result == 0)
        delete(raw_data_dir)
    end