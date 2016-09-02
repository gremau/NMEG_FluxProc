function result = download_gapfilled_partitioned_flux( job_num)
% DOWNLOAD_GAPFILLED_PARTITIONED_FLUX - download the output of the online
%   gapfiller/flux partitioner to the local disk.  
%
% Calls a bash script to do the downloading -- clicking "save file as" within a
% web browser seems to hang after 25 MB of downloaded data and results in a
% truncated file (as of Nov 2012, at least).  I'm not sure if the problem is on
% the Max Planck Institute end or the UNM end - I suspect MPI.  The bash script
% knows to retry the download to get the complete file.
%
% MAK SURE WGET IS INSTALLED (through cygwin)
%
% NOTE: Deprecated as of July 2013 -- REddyProc performs gapfill and
% partitioning locally.
%
% NOTE 2: Actually - we still use MPI EddyProc to get Lasslop partitioning,
% so this file is still useful - GEM
%
% USAGE
%   result = download_gapfilled_partitioned_flux( job_num )
%
% INPUTS
%   job_num: the online gapfiller/flux partitioner job number.
%
% OUTPUTS
%   result: 0 on success, non-zero on failure
%
% (c) Timothy W. Hilton, UNM, Nov 2012

success = 1; % initialize to failure

% create a "blocking" file so Matlab won't continue until the system call
% finishes
blk_fname = create_blocking_file( sprintf( ['blocking file for online ' ...
                    'gapfiller/ flux partitioner output download %s'], ...
                                           job_num ) );
blk_fname_unix = strrep( blk_fname, 'C:\', '/cygdrive/c/' );
blk_fname_unix = strrep( blk_fname, '\', '/' );

% bash script to perform the download
% beginning with "start" causes a dos window to open and display the progress
cmd = sprintf( ['start C:\\cygwin64\\bin\\bash --login -c ' ...
                '"/cygdrive/c/Code/NMEG_FluxProc/scripts/' ...
                'download_partitioned_fluxes %d && rm -f %s"'], ...
               job_num, blk_fname_unix );

% make system call
[s, r] = dos(cmd);

fprintf( 'Downloading gapfilled & partitioned fluxes...\n' );
fprintf( 'If this hangs try dos2unix.exe trick on the bash script...\n' );

% do not continue until the blocking file is removed
pause on;
while( exist( blk_fname ) == 2 )
    pause( 5 );
end
pause off

fprintf( 'done!\n)' );

success = 0;  % success