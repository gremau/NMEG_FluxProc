function [ soil_data ] = preprocess_PJ_soil_data( sitecode, ...
                                                  year, ...
                                                  varargin )
% PREPROCESS_PJ_SOIL_DATA - parse CR23X soil data for PJ or PJ_girdle.
%
% Creates datasets for soil temperature, soil water content, and soil heat flux
% with complete 30-minute timestamp record and duplicate timestamps removed via
% dataset_fill_timestamps.  When duplicate timestamps are detected, the first is
% kept and subsequent duplicates are discarded.
%
% USAGE
%    [ soilT, SWC, SHF ] = preprocess_PJ_soil_data( sitecode, year )
%
% INPUTS
%    sitecode: integer or UNM_sites object; either PJ or PJ_girdle
%    year: integer; year of data to preprocess
% PARAMETER-VALUE PAIRS
%    t_min, t_max: matlab datenums; if specified, data will be truncated to
%        the interval t_min, t_max
%
% OUTPUTS:
%    soilT, SWC, SHF: matlab dataset arrays containing soil observations
%        (soil temperature, soil water content, and soil heat flux,
%        respectively)
%
% SEE ALSO
%    dataset, dataset_fill_timestamps
%
% author: Timothy W. Hilton, UNM, April 2012

args = inputParser;
args.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
args.addRequired( 'year', @isnumeric );
% PJ CR23x loggers have year/1/1/0:30:00 as first yearly observation GM
args.addParamValue( 't_min', ...
                    datenum( year, 1, 1, 0, 30, 0 ), ...
                    @isnumeric );
% Fluxall files are inconsistent in the observations they contain
% Prior to 2012 observations end at 1/1 00:30 of the next year,
% 2012 and after they end at year/12/31 23:30:00

if year < 2012
    args.addParamValue( 't_max', ...
                    datenum( year+1, 1, 1, 0, 0, 0 ), ...
                    @isnumeric );
else
    args.addParamValue( 't_max', ...
                    datenum( year, 12, 31, 23, 30, 0 ), ...
                    @isnumeric );
end
                
args.parse( sitecode, year, varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;

if isa( sitecode, 'UNM_sites' )
    sitecode = int8( sitecode );
end

% determine file path
    sitename = get_site_name( sitecode );

    fpath = fullfile( getenv( 'FLUXROOT' ), ...
                      'SiteData', ...
                      sitename,  ...
                      'soil' );
    switch sitecode
      case 4
        if year < 2012
            fname =  'PJC_23x_2009_2011 COMPILED by Laura.csv';
            n_col = 103;
        else
            fname =  sprintf( 'PJC_23X_%d_COMPILED from wireless_Laura.csv', year );
            n_col = 103;
        end
      case 10
        if year < 2012
            fname =  'PJG_CR23X_2009_2011_wireles combination_Laura_08112014.csv';
            n_col = 104;
        else
            fname = sprintf( 'PJG_CR23X_%d_wireles combination_Laura_08112014.csv', year );
            n_col = 152;
        end
    end
    fname = fullfile( fpath, fname );
    
    
    % parse data file to matlab dataset
    fmt = [ repmat( '%d', 1, 4 ), repmat( '%f', 1, 100 ) ];
    fmt = repmat( '%f', 1, n_col );
    soil_data = dataset( 'File', fname, 'Delimiter', ',', 'Format', fmt );
    
    % not sure what this column is, and its name is not a legal Matlab variable
    soil_data( :, 1 ) = [];
    
    % remove leading "x#_" and trailing __* from variable names
    disp( 'formatting variable names' );
    soil_data.Properties.VarNames = ...
        regexprep( soil_data.Properties.VarNames, '^x[0-9]*_?', '' );
    soil_data.Properties.VarNames = ...
        regexprep( soil_data.Properties.VarNames, '[HL]$', '' );
    soil_data.Properties.VarNames = ...
        regexprep( soil_data.Properties.VarNames, '__[A-Z]?$', '' );    
    % replace leading T with Tsoil in var names
    soil_data.Properties.VarNames = ...
        regexprep( soil_data.Properties.VarNames, '^T', 'soilT' );
    
    % build matlab datenums from year, day, hour, minute columns
    HH = floor( soil_data.Hour_Minute_RTM / 100 );
    MM = mod( soil_data.Hour_Minute_RTM, 100 );
    tstamps = datenum( double(soil_data.Year_RTM), 1, 0, HH, MM, 0 ) + ...
              ( soil_data.Day_RTM );
    soil_data.tstamps = tstamps;
    
    % pull out data for requested year
    soil_data = soil_data( soil_data.Year_RTM == year, : );

    % fill missing 30-minute timestamps with NaN
    disp( 'filling missing 30-minute timestamps with NaN' );
    thirty_minutes = 1 / 48;  % 30 mins expressed in units of days
    soil_data = dataset_fill_timestamps( soil_data, ...
                                         'tstamps', ...
                                         't_min', args.Results.t_min, ...
                                         't_max', args.Results.t_max );

    % replace -9999 and -99999 with NaN
    badvals = [ -9999, 9999, -99999, 99999 ];
    soil_data = replacedata( soil_data, ...
                             @(x) replace_badvals( x, badvals, 1e-6 ) );
    
    % pull out soil water content and soil temperature
    T_vars = cellfun( @(x) ~isempty( x ), ...
                      regexp( soil_data.Properties.VarNames, '^soilT_.*', 'once' ) );
    SWC_vars = cellfun( @(x) ~isempty( x ), ...
                        regexp( soil_data.Properties.VarNames, '^WC_.*', 'once' ) );
    SHF_vars = cellfun( @(x) ~isempty( x ), ...
                        regexp( soil_data.Properties.VarNames, '^shf_.*', 'once' ) );
    
    % output a csv file for all soil variables with a complete record of
    % 30-minute timestamps and with duplicate timestamps removed
    fname_complete = fullfile( getenv( 'FLUXROOT' ), ...
                               'SiteData', ...
                               'PJ', ...
                               'soil', ...
                               sprintf( '%s_%d_soil_complete.dat', ...
                                        'PJ', ...
                                        year ) );
    fprintf( 'writing %s...', fname_complete );
    write_tbl_std( fname_complete, soil_data );
    fprintf( 'done\n' );
    
    soilT = soil_data( :, T_vars );
    SWC = soil_data(  :, SWC_vars );
    SHF = soil_data(  :, SHF_vars );

    % separate cover type from index in variable names -- e.g. O1 becomes O_1
    soilT.Properties.VarNames = regexprep( soilT.Properties.VarNames, ...
                                           '([OJP])([123])', '$1_$2' );
    SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                         '([OJP])([123])', '$1_$2' );
    SHF.Properties.VarNames = regexprep( SHF.Properties.VarNames, ...
                                         '([OJP])([123])', '$1_$2' );

    % remove SWC < 0 or > 1
    SWC_temp = double( SWC );
    idx_bogus = ( SWC_temp < 0.0 ) | ( SWC_temp > 1.0 );
    SWC_temp( idx_bogus ) = NaN;
    SWC = replacedata( SWC, SWC_temp );
    
    % add timestamps to output datasets
    soilT.tstamps = soil_data.tstamps;
    SWC.tstamps = soil_data.tstamps;
    SHF.tstamps = soil_data.tstamps;
    
    soilT.Properties.VarNames = regexprep( soilT.Properties.VarNames, ...
                                           '_AVG$', '' );
    [ ~, idx ] = regexp_header_vars( soilT, '_STD$' );
    soilT( :, idx ) = [];
    
    SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                         '^WC_', 'cs616SWC_' );
    SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                         '_AVG$', '' );
    [ ~, idx ] = regexp_header_vars( SWC, '_STD$' );
    SWC( :, idx ) = [];
    
    SHF.Properties.VarNames = regexprep( SHF.Properties.VarNames, ...
                                         '_AVG$', '' );
    SHF.Properties.VarNames = regexprep( SHF.Properties.VarNames, ...
                                         '^shf', 'SHF' );
    [ ~, idx ] = regexp_header_vars( SHF, '_STD$' );
    SHF( :, idx ) = [];

    all_but_timestamps = 1:( size( SHF, 2 ) - 1 );
    SHF.Properties.VarNames( all_but_timestamps ) = ...
        cellfun( @(x) [ x, '_0' ], ...
                 SHF.Properties.VarNames( all_but_timestamps ), ...
                 'UniformOutput', false );
    
