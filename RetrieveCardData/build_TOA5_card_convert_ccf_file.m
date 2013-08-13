function success = build_TOA5_card_convert_ccf_file( ccf_file, ...
                                                  raw_data_dir, ...
                                                  toa5_data_dir )
% BUILD_TOA5_CARD_CONVERT_CCF_FILE - writes a configuration file for Campbell
% Scientific card convert for 30-minute datalogger files.
%
% This file format was derived by following the instructions in the manual for
% LoggerNet v 4.1 (section 8.3.5; Running CardConvert From a Command Line).  I
% just copied everything from lastrun.ccf -- TWH.
%
% USAGE:
%    build_TOA5_card_convert_ccf_file(ccf_file, raw_data_dir, toa5_data_dir);
%
% INPUTS
%    ccf_file: string; the full path of the configuration file to be written.
%    raw_data_dir: the full path to the directory containing the raw card
%        data
%    toa5data_dir: the directory in which to place the converted TOA5 files.
%
% OUTPUTS
%    success: 1 on success, 0 on failure
%
%   Timothy W. Hilton, University of New Mexico, Oct 2011

success = 0;

fid = fopen(ccf_file, 'w+t');
if (fid < 0)
    error('build_TOA5_card_convert_ccf_file: unable to open ccf file.');
else
    fprintf(fid, '[main]\n');
    fprintf(fid, 'SourceDir=%s\\\n', raw_data_dir);
    fprintf(fid, 'TargetDir=%s\\\n', toa5_data_dir);
    fprintf(fid, 'Format=0\n');
    fprintf(fid, 'FileMarks=0\n');
    fprintf(fid, 'RemoveMarks=0\n');
    fprintf(fid, 'RecNums=0\n');
    fprintf(fid, 'Timestamps=1\n');
    fprintf(fid, 'CreateNew=1\n');
    fprintf(fid, 'DateTimeNames=1\n');
    fprintf(fid, 'ColWidth=463\n');
    fprintf(fid, 'ListHeight=169\n');
    fprintf(fid, 'ListWidth=190\n');
    fprintf(fid, 'BaleCheck=0\n');
    fprintf(fid, 'CSVOptions=6619599\n');
    fprintf(fid, 'BaleStart=38718\n');
    fprintf(fid, 'BaleInterval=32875\n');
    fprintf(fid, 'DOY=0\n');
    fprintf(fid, 'Append=0\n');
    fprintf(fid, 'ConvertNew=0\n');
    fclose(fid);
    success = 1;
end

