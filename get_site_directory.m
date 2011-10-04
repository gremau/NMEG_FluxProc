function [sitefolder, result] = get_site_directory(sitecode)

  %read user-supplied configuration 
  fluxrc = UNM_flux_process_config();

  % determine site folder
  if any(strcmp('sitefolder', fields(fluxrc)))
      sitefolder = fullfile(fluxrc.sitefolder, get_site_name(sitecode));
      result = 1;
  else
      % if user did not specify output folder in config, use a default value 
      sitefolder = fullfile(getenv('UNM_FLUXDATA_ROOT'), get_site_name(sitecode));
  end

  % create sitefolder if it does not exist
  if exist(sitefolder) ~= 7
      disp(['creating ', sitefolder]);
      [result, msg, msgid] = mkdir(sitefolder);
  end
  
  