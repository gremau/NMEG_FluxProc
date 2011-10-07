function fluxrc =  UNM_flux_process_config()

  % defines the allowed site abbreviations and their site codes the order
  % matters -- each abbreviation's position in the list is its site code
  %  This could be changed in get_site_code.m
    

  %             Site Abbrev          Site Code
  site_names = {'GLand', ...         % 1
		'SLand', ...         % 2
		'JSav', ...          % 3
		'PJ', ...            % 4
		'PPine', ...         % 5
		'MCon', ...          % 6
		'TX', ...            % 7
		'TX_forest', ...     % 8
		'TX_grassland', ...  % 9
		'PJ_girdle', ...     % 10
		'PJG_test', ...      % 11
		'New_GLand'};        % 12
  
  FLUXROOT = getenv('FLUXROOT');
  if length(FLUXROOT) == 0
      error('environment variable fluxroot not defined');
      % want to change this to prompt for directory instead
  end
      
  sitefolder = fullfile(FLUXROOT);
  sitefolder = fullfile(FLUXROOT, 'Flux Tower Data By Site');
  outfolder = fullfile(FLUXROOT, 'FluxOut');
  
  fluxrc = struct('site_names', {site_names}, ...
                  'FLUXROOT', FLUXROOT, ...
                  'sitefolder', sitefolder, ...
                  'outfolder', outfolder);
  
  
