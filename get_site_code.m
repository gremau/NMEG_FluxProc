function site_code = get_site_code(this_site_name)
  
if ischar( this_site_name )
    site_code = UNM_sites.( this_site_name );
else
    site_code = UNM_sites( this_site_name );
end