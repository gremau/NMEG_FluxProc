function [ sitefolder, result ] = get_site_directory( sitecode )
% get_site_directory(sitecode) -- return full path to a site's data
% directory.
%
% Looks in 'sitefolder' field of UNM_flux_process_config() for a directory named
% for the site's abbreviation.  If that diretory does not exist, looks for such
% a directory in $FLUXROOT.

% USAGE
%    [ sitefolder, result ] = get_site_directory( sitecode )
%
% INPUTS:
%    sitecode: integer; numeric code for the site requested
%
% OUTPUTS:
%    sitefolder: full path to the site's directory
%    result: 0 if directory found or created successfully, 1 if an error
%            occured
%
% SEE ALSO
%    UNM_flux_process_config
%
% Timothy W. Hilton, UNM, Aug 2011

%read user-supplied configuration 
fluxrc = UNM_flux_process_config();

% determine site folder
if any(strcmp('sitefolder', fields(fluxrc)))
    sitefolder = fullfile(fluxrc.sitefolder, get_site_name(sitecode));
    result = 1;
else
    % if user did not specify output folder in config, use a default value 
    sitefolder = fullfile(getenv('FLUXROOT'), get_site_name(sitecode));
end

% create sitefolder if it does not exist
if exist(sitefolder) ~= 7
    % disp(['creating ', sitefolder]);
    % [result, msg, msgid] = mkdir(sitefolder);
end

