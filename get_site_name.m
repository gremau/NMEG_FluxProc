function [ site_name ] = get_site_name( this_site_code, varargin )
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
%     name_type: optional string indicating which name type 
%                ( {nmeg} | aflx ) to use
%
% OUTPUTS
%     site_name: character string; the abbreviation for the site name
%
% author: Timothy W. Hilton, UNM, Aug 2011
% Modified by Gregory E. Maurer, UNM, Feb 2016

args = inputParser;
args.addRequired( 'this_site_code', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addOptional( 'name_type', 'nmeg', @(x) ischar( x ) );
args.parse( this_site_code, varargin{ : } );

this_site_code = args.Results.this_site_code;
name_type = args.Results.name_type;

fluxrc = UNM_flux_process_config();
nmeg_names = fluxrc.site_names;
aflx_names = fluxrc.aflx_names;

if ~isintval(this_site_code) || (this_site_code < 1) ||  ...
	(this_site_code > length(nmeg_names))  
    %if this_site_code is not in the config file, throw an exception and
    %list the valid <site code - site name> pairs
    err_str = build_sitecode_name_string(nmeg_names);
    err_str = [sprintf('%d is not a valid side code.\n', this_site_code),  ...
               'Note site names are case-sensitive\n', ...
               'valid site code -- site name pairs are:\n', ...
               err_str];
    throw(MException('UNM_Flux_processing:get_site_name', err_str));
end

if strcmpi( name_type, 'nmeg' )
    site_name = nmeg_names{this_site_code};
elseif strcmpi( name_type, 'aflx' )
    site_name = aflx_names{this_site_code};
else
    error( 'there is no such name_type' );
end
    

% ============================================================
function [str] = build_sitecode_name_string(nmeg_names)
% returns a string containing specified site code -- site name pairs
% formatted for pretty printing, one pair per line.
%
% USAGE
%    [ str ] = build_sitecode_name_string( nmeg_names );
% 
% INPUTS:
%    nmeg_names: cell array containing site name strings ordered by site code
%        -- i.e. nmeg_names{1} should correspond to site code 1
%        e.g. { 'GLand', 'SLand' }
%
% OUTPUTS
%    str: string; site code --site name pairs separated by newline characters
% 
% author: Timothy W. Hilton, UNM, Aug 2011

str = '';
for i=1:numel(nmeg_names)
    str = [str, sprintf('%d - %s\n', i, nmeg_names{i})];
end
