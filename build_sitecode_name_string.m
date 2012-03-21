function [str] = build_sitecode_name_string(site_names)
% builds a string listing site code -- site name pairs separated by newlines
% INPUTS:
%    site_names: cell array containing site name strings ordered by site code
%    -- i.e. site_names{1} should correspond to site code 1
% Timothy W. Hilton, UNM, Aug 2011
  
  str = '';
  for i=1:numel(site_names)
    str = [str, sprintf('%d - %s\n', i, site_names{i})];
  end
