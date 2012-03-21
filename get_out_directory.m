function [outfolder, result] = get_out_directory(sitecode)

  fluxrc = UNM_flux_process_config();
  
  % determine output folder
  if any(strcmp('outfolder', fields(fluxrc)))
    outfolder = fluxrc.outfolder;
    result = 1;
  else
    % if user did not specify output folder in config, use default value and
    % create if it does not exist
    outfolder = fullfile(getenv('UNM_FLUXDATA_ROOT'), get_site_name(sitecode), ...
			 'matlab_output');
  end
  
  %create outfolder if it does not exist
  if exist(outfolder) ~= 7
    disp(['creating ', outfolder]);
    [result, msg, msgid] = mkdir(outfolder);
  end
  