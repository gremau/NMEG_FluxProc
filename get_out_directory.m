function [ outfolder, result ] = get_out_directory( sitecode )
% GET_OUT_DIRECTORY - return site-specific directory for Matlab-generated
% output
%
% if 'outfolder' field is specified in UNM_flux_process_config that value is
% returned.  Otherwise a default directory of $FLUXROOT/SITE/matlab_output is
% returned.  outfolder is created if it does not exist.  Issues error if
% outfolder does not exist and could not be created successfully.
%
% USAGE
%     [ outfolder, result ] = get_out_directory( sitecode );
%
% INPUTS
%    sitecode: UNM_sites object
%
% OUTPUTS
%    outfolder: full path to the output folder
%    result: 1 if outfolder exists or was create successfully
%
% SEE ALSO
%    UNM_flux_process_config, UNM_sites

fluxrc = UNM_flux_process_config();

% determine output folder
if any(strcmp('outfolder', fields(fluxrc)))
    outfolder = fluxrc.outfolder;
    result = 1;
else
    % if user did not specify output folder in config, use default value and
    % create if it does not exist
    outfolder = fullfile(getenv('FLUXROOT'), char( sitecode ), ...
			 'matlab_output');
end

%create outfolder if it does not exist
if exist(outfolder) ~= 7
    disp(['creating ', outfolder]);
    [result, msg, msgid] = mkdir(outfolder);
end
