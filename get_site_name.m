function [site_name] = get_site_name(this_site_code)
  
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