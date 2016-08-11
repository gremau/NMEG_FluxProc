function success = modify_tob1_eddypro_proj_file( proj_file, ...
                                                  raw_data_dir, ...
                                                  tsdata_dir )% BUILD_TOA5_CARD_CONVERT_CCF_FILE - writes a configuration file for Campbell
% Scientific card convert for 10 hz datalogger file.
%
% FIXME - documentation and cleanup
%
% USAGE:
%   modify_tob1_eddypro_proj_file( ccf_file,raw_data_dir,tsdata_dir)
% INPUTS
%    ccf_file: string; the full path of the configuration file to be written.
%    raw_data_dir: the full path to the directory containing the raw card
%        data
%    tsdata_dir: the directory in which to place the converted 10 hz TOB1 files.
%
% OUTPUTS
%    success: 1 on success, 0 on failure
%
%   Timothy W. Hilton, University of New Mexico, Oct 2011

success = 0;

fid = fopen(proj_file, 'w+t');
if (fid < 0)
    error('modify_tob1_eddypro_proj_file: unable to open eddypro proj file.');
else
    %Change data_path on line 129 in project file...somehow...
    fclose(fid);
    success = 1;
end

