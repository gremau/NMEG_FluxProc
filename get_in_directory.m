function [infolder, result] = get_in_directory(sitecode)

  %read user-supplied configuration 
  fluxrc = UNM_flux_process_config();
  
  % determine site folder
  if any(strcmp('infolder', fields(fluxrc)))
    infolder = fluxrc.infolder;
    result = 1;
  else
    % if user did not specify output folder in config, use a default value 
    infolder = fullfile(getenv('UNM_FLUXDATA_ROOT'), get_site_name(sitecode), ...
			'ts_data');
  end
  
  %create infolder if it does not exist
  if exist(infolder) ~= 7
    disp(['creating ', infolder]);
    [result, msg, msgid] = mkdir(infolder);
  end
  
  