function [success, arch_name] = compress_raw_data_directory( raw_data_dir )
% COMPRESS_RAW_DATA_DIRECTORY - compresses a directory using 7-zip; wait until
% compression is complete before resuming Matlab execution.
%
% USAGE:
%    compress_raw_data_directory( raw_data_dir );
%
% INPUTS:
%    raw_data_dir: string; complete path to the directory to be compressed.    
%
% OUTPUTS:
%    success: 0 on success, 1 on failure.
%    arch_name: string, full path/name of created archive.
%
% (c) Timothy W. Hilton, UNM, Oct 2011
% Modified by Gregory E. Maurer, UNM, March 2016
    
success = 1;

try

    blk_fname = create_blocking_file();
    
    seven_zip = 'C:\Program Files\7-Zip\7z.exe';
    cmd = sprintf('"%s" a "%s" "%s" & del %s &', ...
                  seven_zip, raw_data_dir, raw_data_dir, blk_fname );
    
    [result, output] = dos(cmd);
    
    % do not proceed until blocking file is removed; check every 5 seconds
    pause on;
    while( exist( blk_fname ) == 2 )
        pause( 5 );
    end
    pause off;
    
    fprintf(1, 'output: %s\n', output);
    
    arch_name = sprintf('%s.7z', raw_data_dir);
    
    % This used to delete the original folder, but it is now preserved
    
catch err
    disp( getReport( err ) );
    success = 0;
    arch_name = '';
end

    