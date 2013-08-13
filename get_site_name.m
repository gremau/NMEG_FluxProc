function [ site_name ] = get_site_name( this_site_code )
% GET_SITE_NAME - return the site name abbreviation for a specified integer site
% code.  
%
% Issues error and displays a list of valid site name - site code pairs if input
% argument is not a valid site code.
%
% USAGE
%     [ site_name ] = get_site_name( this_site_code );
%
% INPUTS
%     this_site_code: integer code for site
%
% OUTPUTS
%     site_name: character string; the abbreviation for the site name
%
% author: Timothy W. Hilton, UNM, Aug 2011

fluxrc = UNM_flux_process_config();
site_names = fluxrc.site_names;

if ~isintval(this_site_code) || (this_site_code < 1) ||  ...
	(this_site_code > length(site_names))  
    %if this_site_code is not in the config file, throw an exception and
    %list the valid <site code - site name> pairs
    err_str = build_sitecode_name_string(site_names);
    err_str = [sprintf('%d is not a valid side code.\n', this_site_code),  ...
               'Note site names are case-sensitive\n', ...
               'valid site code -- site name pairs are:\n', ...
               err_str];
    throw(MException('UNM_Flux_processing:get_site_name', err_str));
end

site_name = site_names{this_site_code};

% ============================================================
function [str] = build_sitecode_name_string(site_names)
% returns a string containing specified site code -- site name pairs
% formatted for pretty printing, one pair per line.
%
% USAGE
%    [ str ] = build_sitecode_name_string( site_names );
% 
% INPUTS:
%    site_names: cell array containing site name strings ordered by site code
%        -- i.e. site_names{1} should correspond to site code 1
%        e.g. { 'GLand', 'SLand' }
%
% OUTPUTS
%    str: string; site code --site name pairs separated by newline characters
% 
% author: Timothy W. Hilton, UNM, Aug 2011

str = '';
for i=1:numel(site_names)
    str = [str, sprintf('%d - %s\n', i, site_names{i})];
end
