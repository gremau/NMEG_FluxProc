function site_code = get_site_code( this_site_name )
% GET_SITE_CODE - return UNM_sites object for a specified site name or
% integer code.
%
% see UNM_sites for recognized site name -- site code pairs.
%
% USAGE:
%    site_code = get_site_code( this_site_name );
%
% INPUTS
%    this_site_name: a site name character string or integer site code
%
% OUTPUTS
%    site_code: UNM_sites object
%
% SEE ALSO
%    UNM_sites
%
% author: Timothy W. Hilton, UNM, Aug 2011
  
if ischar( this_site_name )
    site_code = UNM_sites.( this_site_name );
else
    site_code = UNM_sites( this_site_name );
end