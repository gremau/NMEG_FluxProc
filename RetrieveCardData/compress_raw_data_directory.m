function success = compress_raw_data_directory(raw_data_dir)
% COMPRESS_RAW_DATA_DIRECTORY - compresses a directory containing raw flux
% data
    
    blk_fname = create_blocking_file();
    
    seven_zip = 'C:\Program Files\7-Zip\7z.exe';
    cmd = sprintf('"%s" a "%s" "%s" & del %s &', ...
                  seven_zip, raw_data_dir, raw_data_dir, blk_fname );
    
    [result, output] = dos(cmd);
    
    pause on;
    while( exist( blk_fname ) == 2 )
        pause( 5 );
    end
    pause off;

    % % need to implement some sort of blocking scheme here to make Matlab wait
    % % until compression is done.  This will work, but requires a click when
    % % compression is complete.
    % h = warndlg('press OK when file compression is complete', ...
    %             'compressing data');
    % waitfor(h);
    
    fprintf(1, 'output: %s', output);
    
    if (result == 0)  %indicates compression successful
        delete(fullfile(raw_data_dir, '*'));
        rmdir(raw_data_dir);
        fprintf(1, 'removed %s\n', raw_data_dir);
    end