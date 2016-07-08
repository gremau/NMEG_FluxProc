function parsedConfig = parse_yaml_config( sitecode, yaml_name, ...
    varargin )
% Parse a YAML site configuration file, parsing out configuration variables
% for a selected individual years if requested.
%
% INPUTS:
%       sitecode : UNM_sites object
%       yaml_name: string - filename for the desired YAML config file
% OPTIONAL INPUTS
%       date_range: MATLAB array of datenums indicating the start and end
%           of configuration period to retrieve.
% OUTPUT
%       parsedConfig: structure - contains field:value pairs from the
%       configuration file
%
% Gregory E. Maurer, UNM, February 2015

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'yaml_name', @ischar );
date_validation = @(x) isnumeric(x) && x(1) > datenum('2005-12-31') ...
    && length(x) < 3;
args.addOptional( 'date_range', [], date_validation );

% parse optional inputs
args.parse( sitecode, yaml_name, varargin{ : } );
site = args.Results.sitecode;
yaml_name = args.Results.yaml_name;
date_range = args.Results.date_range;

% Path to YAML files
yamlPath = fullfile( getenv('FLUXROOT'), 'FluxProcConfig', ...
    'YAML_ConfigFiles', get_site_name( sitecode ));

% Load the configuration file using YAMLMatlab
addpath( yamlPath);

rawConfig = ReadYaml( fullfile(yamlPath, [ yaml_name, '.yaml' ]));

rmpath( yamlPath );

% The yaml parser reads some field in as a cellarray of structs. Its easier
% to work with struct arrays, so convert them. This throws an error if the
% structs in input cellarray don't have the same fields (improperly
% formatted yaml file).
fnames = fieldnames( rawConfig );
for i = 1:length( fnames )
    f = fnames{ i };
    if iscell(rawConfig.( f ))
        try
            rawConfig.(f) = cell2mat( rawConfig.( f ));
        catch
            error( sprintf(['Error converting %s, fields in %s \n', ...
                'cannot be converted to a stucture array'], yaml_name, f ));
        end
    end
end

% Check that the config file is for the correct site
if strcmpi( rawConfig.config_site, get_site_name( sitecode ));
    fprintf( 'parsing %s configuration file for %s \n', ...
        yaml_name, get_site_name( sitecode ));
else
    error( 'The YAML config file is for the wrong site!' );
end

% Standardize the date_range variable
if length(date_range)==1
    date_range(2) = datenum( now );
    warning( sprintf('Configuration end date not provided, using today \n') );
end

% Determine whether to parse configurations by date
date_range_given = length( date_range ) > 0;
date_parse_required = isfield( rawConfig, 'config_by_date' ) && ...
    rawConfig.config_by_date;

% Set flag for required date parsing if date_range provided
if date_parse_required && date_range_given
    parse_by_date = true;
elseif date_parse_required && ~date_range_given
    % If date_range not provided, but YAML file contains config_by_date
    % information, issue an error.
    error( 'Configuration requires date parsing, no date range given!');
elseif ~date_parse_required && date_range_given
    % If date_range provided, but YAML file contains no config_by_date
    % information, issue a warning and do not parse by date
    warning( sprintf(['YAML config file contains no config_by_date info!\n', ...
        'Ignoring date_range argument.\n'] ));
    parse_by_date = false;
else % No parse_by_date field and no date range given
    parse_by_date = false;
end

% Now parse configuration by date if needed
if parse_by_date;
    sprintf( 'Parsing config data from %s to %s...\n', ...
        datestr( date_range(1) ), datestr( date_range(2)));
    parsedConfig =  struct();
    for i = 1:length( fnames )
        fname = fnames{ i };
        if isstruct( rawConfig.( fname ))
            confStart = datenum( { rawConfig.( fname ).start_date } );
            % First check confEnd for None and assign current date
            convert = strcmpi({rawConfig.(fname).end_date}, 'None');
            [rawConfig.(fname)(convert).end_date] = ...
                deal(datestr( now, 'yyyy-mm-dd HH:MM'));
            confEnd = datenum( { rawConfig.( fname ).end_date } );
            % Check if either the start date or end date is 
            % inside date_range
            keep_confStart =  confStart <= date_range( 2 );
            keep_confEnd = confEnd >= date_range( 1 );
            keep = keep_confStart & keep_confEnd;
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


    

