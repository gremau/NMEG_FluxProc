function parsedConfig = parse_yaml_site_config( yamlName, varargin )
% Parse a YAML site configuration file, parsing out configuration variables
% for a selected individual years if requested.
%
% INPUTS:
%       yamlName: string - filename for the desired YAML config file
% OPTIONAL INPUTS
%       varargin: cellarray - should only contain a 4 digit year
% OUTPUT
%       parsedConfig: structure - contains field:value pairs from the
%       configuration file
%
% Gregory E. Maurer, UNM, February 2015


% Load the configuration file using YAMLMatlab
addpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );
rawConfig = ReadYaml(yamlName);
rmpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );

if length(varargin) == 0 && not( isfield( rawConfig, 'yearConfig' ))
    parseYear = false;
elseif length( varargin ) == 1 && isfield( rawConfig, 'yearConfig' )
    parseYear = true;
    year = varargin{ 1 };
else
    error( 'There is a mismatch between input arguments and config file' );
end


if parseYear;
    % Raw configuration field names (top level of struct)
    rawConfigFields = fieldnames( rawConfig );
    % Get global config field names
    globalConfigs = rawConfigFields( ...
        ~strcmpi( 'yearconfig', rawConfigFields ));

    % Put global configurations in parsedConfig
    parsedConfig =  struct();
    for i = 1:length( globalConfigs );
        parsedConfig.( globalConfigs{ i } ) = rawConfig.( globalConfigs{ i } );
    end
    
    % Get the most recent config preceding this year by extracting year
    % from each available configuration and choosing the most recent
    % configurations relative to the selected year. Fields only update in
    % a new year if this is specified by the config file.
    confYears = zeros( 1, length( rawConfig.yearConfig ));
    for i = 1:length( rawConfig.yearConfig )
        confYears( i ) = extractfield(rawConfig.yearConfig{i}, 'year');
    end
    % Get an index of usable configuration years to extract configurations
    % from. Ensure that older configurations are overwritten by new ones
    % by sorting the configurations and updating each sequential year.
    usableYears = sort( confYears( confYears <= year ));
    for i = 1:length( usableYears )
        usableYearInd = find( confYears == usableYears( i ))
        conf = rawConfig.yearConfig{ usableYearInd };
        % Get field names for each year's conf and add to parsedConfig
        confNames = fieldnames( conf ); 
        for j = 1:length( confNames )
            parsedConfig.( confNames{ j } ) = conf.( confNames{ j } );
        end
    end
    
% If there are no yearly configurations we are done
else
    parsedConfig = rawConfig;
end


    

