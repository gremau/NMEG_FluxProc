function parsedConfig = parse_yaml_site_config( yamlName, sitecode, varargin )
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

% Path to YAML files
yamlPath = fullfile( pwd, 'YAML_ConfigFiles', get_site_name( sitecode ));

% Load the configuration file using YAMLMatlab
addpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );
addpath( yamlPath);

rawConfig = ReadYaml( [ yamlPath '\' yamlName ]);

rmpath( yamlPath );
rmpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );

% Check that the config file is for the correct site
if strcmpi( rawConfig.config_site, get_site_name( sitecode ));
    fprintf( 'parsing %s configuration file for %s \n', ...
        yamlName, get_site_name( sitecode ));
else
    error( 'The YAML config file is for the wrong site!' );
end

% Check if config parsing by year is needed
if length(varargin) == 0 && not( isfield( rawConfig, 'config_year' ))
    parseYear = false;
elseif length( varargin ) == 1 && isfield( rawConfig, 'config_year' )
    parseYear = true;
    year = varargin{ 1 };
else
    error( 'Mismatch between input arguments and YAML config file' );
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
    confYears = zeros( 1, length( rawConfig.config_year ));
    for i = 1:length( rawConfig.config_year )
        confYears( i ) = extractfield(rawConfig.config_year{i}, 'year');
    end
    % Get an index of usable configuration years to extract configurations
    % from. Ensure that older configurations are overwritten by new ones
    % by sorting the configurations and updating each sequential year.
    usableYears = sort( confYears( confYears <= year ));
    for i = 1:length( usableYears )
        usableYearInd = find( confYears == usableYears( i ));
        conf = rawConfig.config_year{ usableYearInd };
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


    

