function parsedConfig = parse_yaml_config( sitecode, yaml_name, ...
    varargin )
% Parse a YAML site configuration file, parsing out configuration variables
% for a selected individual years if requested.
%
% INPUTS:
%       sitecode : UNM_sites object
%       yaml_name: string - filename for the desired YAML config file
% OPTIONAL INPUTS
%       date_range: MATLAB cellarray of date strings (yyyy-mm-dd)
%           indicating the configuration period to retrieve.
% OUTPUT
%       parsedConfig: structure - contains field:value pairs from the
%       configuration file
%
% Gregory E. Maurer, UNM, February 2015

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'yaml_name', @ischar );
args.addOptional( 'date_range', {}, @iscell );

% parse optional inputs
args.parse( sitecode, yaml_name, varargin{ : } );
site = args.Results.sitecode;
yaml_name = args.Results.yaml_name;
date_range = args.Results.date_range;

% Path to YAML files
yamlPath = fullfile( pwd, 'YAML_ConfigFiles', get_site_name( sitecode ));

% Load the configuration file using YAMLMatlab
addpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );
addpath( yamlPath);

rawConfig = ReadYaml( [ yamlPath '\' yaml_name '.yaml' ]);

rmpath( yamlPath );
rmpath( 'C:\Code\MatlabGeneralUtilities\YAMLMatlab_0.4.3\' );

% The yaml parser reads some field in as a cellarray of structs. Its easier
% to work with struct arrays, so convert them
fnames = fieldnames( rawConfig );
for i = 1:length( fnames )
    f = fnames{ i };
    if iscell(rawConfig.( f ))
        rawConfig.(f) = cell2mat( rawConfig.( f ));
    end
end

% Check that the config file is for the correct site
if strcmpi( rawConfig.config_site, get_site_name( sitecode ));
    fprintf( 'parsing %s configuration file for %s \n', ...
        yaml_name, get_site_name( sitecode ));
else
    error( 'The YAML config file is for the wrong site!' );
end

% Set flag for date parsing if date_range provided
% FIXME - the logic here works but could really use improvement
if length(date_range)==2
    parse_by_date = true;
    date_range = datenum( date_range );
elseif length(date_range) > 2 || length(date_range) == 1
    error( 'Date range variable incorrect - try {start_date, end_date}. \n');
elseif isempty( date_range )
    parse_by_date = false;
end
% If date_range not provided, but YAML file contains config_by_date
% information, issue a warning.
if isfield( rawConfig, 'config_by_date' ) && rawConfig.config_by_date && ...
        ~parse_by_date
    warning( sprintf(['YAML config file suggests date parsing! \n', ...
        'File will be parsed using default period (all configs).\n'] ));
    parse_by_date = true;
    date_range = [datenum('2005-12-31');  now];
% If date_range is provided, but YAML file contains no config_by_date
% information, issue a warning.
elseif isfield( rawConfig, 'config_by_date' ) && ~rawConfig.config_by_date && ...
        parse_by_date
    warning( sprintf(['YAML config file contains no config_by_date info!\n', ...
        'Ignoring date_range argument.\n'] ));
    parse_by_date = false;
end

% Now parse configuration by date if needed
if parse_by_date;
    parsedConfig =  struct();
    for i = 1:length( fnames )
        fname = fnames{ i };
        if isstruct( rawConfig.( fname ))
            startdates = datenum( { rawConfig.( fname ).start_date } );
            % First check enddates for None and assign current date
            convert = strcmpi({rawConfig.(fname).end_date}, 'None');
            [rawConfig.(fname)(convert).end_date] = ...
                deal(datestr( now, 'yyyy-mm-dd'));
            enddates = datenum( { rawConfig.( fname ).end_date } );
            % Check that either the start date or end date is 
            % inside date_range
            keep_startdates = startdates >= date_range(1) & ...
                startdates <= date_range(2);
            keep_enddates = enddates >= date_range(1) & ...
                enddates <= date_range(2);
            keep = keep_startdates | keep_enddates;
            % Remove the configurations outside of date_range
            parsedConfig.( fname ) = rawConfig.( fname )( keep );
        else
            parsedConfig.( fname ) = rawConfig.( fname );
        end
    end
% If there are no by_date configurations we are done
else
    parsedConfig = rawConfig;
end


    

