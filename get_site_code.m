function [site_code] = get_site_code(this_site_name)
  
  fluxrc = UNM_flux_process_config();
  site_names = fluxrc.site_names;
  
  idx = strcmp(this_site_name, site_names);
  
  if ~any(idx)
    %if this_site_name is not in the config file, throw an exception and
    %list the valid <site code - site name> pairs
    err_str = build_sitecode_name_string(site_names);
    err_str = [sprintf('%s is not a valid site name.\n', this_site_name),  ...
	               'Note site names are case-sensitive.\n', ...
		       'valid site code -- site name pairs are:\n', ...
		       err_str];
    throw(MException('UNM_Flux_processing:get_site_code', err_str)) 
  end
  
  site_code = find(idx);