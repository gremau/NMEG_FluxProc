function tbl = assemble_multi_year_ameriflux( sitecode, years, varargin )
% ASSEMBLE_MULTI_YEAR_AMERIFLUX - parses ameriflux files from a range of years
%   and appends them into one dataset
%
% If parameter 'binary_data' is set to true (the default is false), attempts
% to load $BINARYDATA/SITE_all_SUFFIX.mat', where site char( sitecode ) and
% SUFFIX is suffix (see parameter-value pairs below).
%
% USAGE:
%    ds = assemble_multi_year_ameriflux( sitecode, years )
%    ds = assemble_multi_year_ameriflux( sitecode, years, 'suffix', SUFFIX )
%    ds = assemble_multi_year_ameriflux( sitecode, years, ..., binary_data )
% INPUTS: 
%    sitecode: integer or UNM_sites object; the site to be assembled
%    years: integer array; array of years
% PARAMETER-VALUE PAIRS
%    suffix: string; 'gapfilled' | {'with_gaps'} | {'soil'}
%    binary_data: true|{false}; if true, load binary data (.mat) version
%        of data.  If false, parse ASCII Ameriflux files.
%
% OUTPUTS:
%    ds: dataset containing the amerflux data for all requested years
%
% SEE ALSO
%    dataset, parse_ameriflux_file, UNM_parse_both_ameriflux_files
%
% author: Timothy W. Hilton, UNM, May 2012

% parse user arguments & typecheck
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'years', @isnumeric );
args.addParameter( 'suffix', ...
                    'with_gaps', ...
                    @(x) ismember( x, { 'gapfilled', 'with_gaps', 'soil' } ) );
args.addParameter( 'binary_data', false, @(x) ( islogical(x) & ...
                                                  numel( x ) ==  1 ) );
args.parse( sitecode, years, varargin{ : } );
args = args.Results;

sitecode = args.sitecode;
years = args.years;

if args.binary_data
    
    if isempty( getenv( 'BINARYDATA' ) )
        warning( 'environment variable BINARYDATA is not defined' )
    end
    
    fname = fullfile( getenv( 'BINARYDATA' ), ...
                      sprintf( '%s_all_%s.mat', ...
                               char( sitecode ), ...
                               args.suffix ) );
    fprintf( 'loading %s\n', fname );
    if exist( fname )
        load( fname );
        [ data_years, ~, ~, ~, ~, ~ ] = datevec( this_data.timestamp );
        idx = data_years >= min( years ) & ...
              data_years <= max( years );
        ds = this_data( idx, : );
    else
%RJL <<<<<<< local
        error( sprintf( '%s does not exist\n', fname ) );
%RJL =======
        warn( 'file does not exist - moving on\n' );
        ds = NaN;
%RJL >>>>>>> other
    end

else   % parse ASCII Ameriflux files
    all_data = {};

    for i = 1:numel( years );
        % get this year's ameriflux data
        fname = sprintf( '%s_%d_%s.txt', ...
                         UNM_sites_info( args.sitecode ).ameriflux, ...
                         years( i ), ...
                         args.suffix );
        fprintf( 'parsing %s\n', fname );
        fname = fullfile( getenv( 'FLUXROOT' ), ...
                          'Ameriflux_files', ...
                          fname );
        if exist( fname )
            this_data = parse_ameriflux_file( fname );
            all_data{ end+1 } = this_data;
            clear this_data;
        else
            fprintf( 'file does not exist - moving on\n' );
        end
    end
    
    % now do some bookkeeping to combine the datasets.  Any variables that are
    % only present in a subset of years are filled with NaN
    vars_all = all_data{ 1 }.Properties.VarNames;
    for i = 2:numel( all_data )
        vars_all = union( vars_all, all_data{ i }.Properties.VarNames );
    end
    for i = 1:numel( all_data )
        vars_to_fill = setdiff( vars_all, all_data{ i }.Properties.VarNames );
        if not( isempty (vars_to_fill ) )
            ds_fill = dataset( { repmat( NaN, ...
                                         size( all_data{ i }, 1 ), ...
                                         numel( vars_to_fill ) ), ...
                                vars_to_fill{ : } } );
            all_data{ i } = horzcat( all_data{ i }, ds_fill );
        end
    end
    
    % combine the years into one large dataset
    ds = vertcat( all_data{ : } );
    
    % insert matlab datenum timestamps
    fprintf( 'verifying timestamps\n' );
    ds = ameriflux_dataset_get_tstamp( ds );
    ds = dataset_fill_timestamps( ...
        ds, ...
        'timestamp', ...
        't_min', datenum( min( years ), 1, 1 ), ...
        't_max', datenum( max( years ), 12, 31, 23, 59, 59 ) );
    
    ds.YEAR = str2num( datestr( ds.timestamp, 'YYYY' ) );
    ds.DTIME = ds.timestamp - datenum( ds.YEAR, 1, 1 ) + 1;
    ds.DOY = floor( ds.DTIME );
    ds.HRMIN = str2num( datestr( ds.timestamp, 'HHMM' ) );
    
    warning( 'Converting dataset to table!');
    tbl = dataset2table( ds );
end