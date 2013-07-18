function success = compress_raw_data_directory( raw_data_dir )
% COMPRESS_RAW_DATA_DIRECTORY - compresses a directory using 7-zip.  Wait
% until compression is complete before resuming Matlab execution.
%
% USAGE:
%    compress_raw_data_directory( raw_data_dir );
%
% INPUTS:
%    raw_data_dir: string; complete path to the directory to be compressed.    
%
% OUTPUTS:
%    success: 0 on success, 1 on failure.
%
% (c) Timothy W. Hilton, UNM, Oct 2011
    
success = 1;

try

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
    
catch err
    disp( getReport( err ) );
    success = 0;
end

    