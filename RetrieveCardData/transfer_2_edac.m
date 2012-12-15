function success = transfer_2_edac(site, compressed_data_fname)
% TRANSFER_2_EDAC - transfer compressed tower raw data to EDAC server
%
% USAGE
%    success = transfer_2_edac(site, compressed_data_fname)
%
% INPUTS
%    site: integer code or UNM_sites object; site to process
%    compressed_data_fname: the full *cygwin* path of the compressed data file
%
% OUTPUTS
%    success: 0 on successful transfer, non-zero otherwise
%
% (c) Timothy W. Hilton, UNM, Dec 2011

site = UNM_sites( site );

success = -1; %initialize    

edac_path = sprintf('/data/epscor/private/data/Upland_node/%s/Raw/', ...
                    char( site ) );

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
fprintf(fid, ['put /cygdrive/c/Research_Flux_Towers/Flux_Tower_', ...
              'Data_by_' ...
              'Site/%s/Raw_data_from_cards/Raw_Data_2012/%s%s\n'], ...
        char( site ), fname, fext);
fprintf(fid, ['\n\n#This DOS window will not close by itself -- you may ' ...
              'close it now by typing ''exit'' at the prompt.\n']);
fclose(fid);

blk_fname = create_blocking_file( [ 'blocking file for %s FTP data ' ...
                    'transfer --> EDAC' ] );

% run the transfer in a dos window
script_file_cygpath = strrep(sftp_script_file, 'C:\', '/cygdrive/c/');
script_file_cygpath = strrep(script_file_cygpath, '\', '/');
cmd =sprintf(['sftp -o "batchmode no" -b %s ', ...
              'jdelong@edacdata1.unm.edu '], ...
             script_file_cygpath);
cmd = sprintf( '%s & del %s &', cmd, blk_fname );

[s, r] = dos(cmd);

% do not proceed until "blocking" file is removed; check every 5 seconds
pause on;
while( exist( blk_fname ) == 2 )
    pause( 5 );
end
pause off

% % need to implement some sort of blocking scheme here to make Matlab wait
% % until compression is done.  This will work, but requires a click when
% % compression is complete.
% h = warndlg('press OK when file transfer is complete', 'transfering file');
% waitfor(h);

%remove the sftp script
delete(sftp_script_file);

%change matlab back to the original directory
cd(calling_dir);

success = 0;