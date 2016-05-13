function [ result, all_data ] = UNM_process_10hz_main( sitecode, ...
                                                  t_start, ...
                                                  t_end, ...
                                                  varargin )
% UNM_PROCESS_10HZ_MAIN: top-level function for matlab processing of 10-hz data
% from flux towers to 30-minute average.  
%
% t_start and t_end may not span two different calendar years.
%
% I found that attempting to process a year at a time quickly ran out of RAM on
% jemez.  To work around this I added the period_n_days parameter argument to
% divide the processing into smaller "chunks".  I find that 30 days (the default
% for period_n_days) works nicely on Jemez and on my laptop with 8GB RAM.  5
% days seems to be about all my laptop with 2GB RAM can handle.  --TWH
%   
%USAGE
%    result = UNM_process_10hz_main( sitecode, t_start, t_end )
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, lag)
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, ..., rotation)
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, ..., ts_data_dir)
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, ..., period_n_days)
%    [ result, data ] = UNM_process_10hz_main( sitecode, t_start, t_end, ... )
%
%INPUTS
%    sitecode ( UNM_sites object or integer ): sitecode to process
%    t_start (matlab datenum): data timestamp for starting processing
%    t_end (matlab datenum): data timestamp for ending processing
%
% PARAMETER-VALUE PAIRS
%    lag (integer): optional, 1 or 0 (default 0)
%    rotation (sonic_rotation object): sonic_rotation.planar or 
%        sonic_rotation.threeD (default threeD)
%    ts_data_dir: directory containing the TOB1 files.  Defaults to
%        $FLUXROOT/SITENAME/ts_data 
%    period_n_days: size of "chunks" to process in one go, in days.  Default
%        is 30
%
% OUTPUTS:
%    result: 0 on success, non-zero on failure
%    all_data: dataset array containing the averaged data
%
% SEE ALSO
%    UNM_sites, sonic_rotation, dataset
%
% author: Timothy W. Hilton, UNM, April 2012

% -----
% define inputs, with defaults for optionals, and with type-checking
% -----
p = inputParser;
p.addRequired( 'sitecode', @( x ) ( isnumeric( x ) | isa( x, 'UNM_sites' ) ) ); 
p.addRequired( 't_start', @isnumeric );
p.addRequired( 't_end', @isnumeric );
p.addParameter( 'lag', ...
                 0, ...
                 @( x ) isnumeric( x ) );
p.addParameter( 'rotation', ...
                 sonic_rotation.threeD, ...
                 @( x ) isa( x, 'sonic_rotation' ) );
p.addParameter( 'ts_data_dir', ...
                 [], ...
                 @ischar );
p.addParameter( 'period_n_days', ...
                 30, ...
                 @(x) isnumeric( x ) & ( x > 0 ) );
    
% parse optional inputs
p.parse( sitecode, t_start, t_end, varargin{ : } );
    
sitecode = p.Results.sitecode;
t_start = p.Results.t_start;
t_end = p.Results.t_end;
lag = p.Results.lag;
rotation = p.Results.rotation;
ts_data_dir = p.Results.ts_data_dir;
period_n_days = p.Results.period_n_days;
% -----
% if called with more than two output arguments, throw exception
% -----
nargoutchk( 0, 2 );


% -----
% start processing
% -----

t0 = now();  % track running time

result = 1;  % initialize to failure -- will change on successful completion
print_memory_message = false;

[ year_start, ~, ~, ~, ~, ~ ] = datevec( t_start );
[ year_end, ~, ~, ~, ~, ~ ] = datevec( t_end );
if ( year_start ~= year_end )
    error( '10-hz data processing may not span different calendar years' );
else
    year = year_start;
end

%process a few days at a time -- a whole year bogged down for lack of memory
process_periods = t_start : period_n_days : t_end;
if ( process_periods( end ) < t_end )
    process_periods = [ process_periods, t_end ];
end
n_pds = numel( process_periods ) - 1;
chunks_list = cell( 1, n_pds );

for i = 1 : n_pds

    this_t_start = process_periods( i );
    this_t_end = process_periods( i + 1 );

    if( isempty( ts_data_dir ) )
        ts_data_dir = fullfile( get_site_directory( sitecode ), 'ts_data' );
    end
    
    % process 30-minute averages
    chunks_cell{ i } = process_TOB1_chunk( sitecode, ...
                                          this_t_start, ...
                                          this_t_end, ...
                                          lag, ...
                                          rotation, ...
                                           ts_data_dir );

    if isempty( chunks_cell{ i } )
        chunks_cell( i ) = [];
    end
    
    if print_memory_message
        fprintf( '==================================================\n');
        fprintf( 'iteration %d/%d\n', i, n_pds );
        memory
        fprintf( '==================================================\n');
    end
end

% Concatenate chunks into one dataset
all_data = vertcat( chunks_cell{ : } );
all_data.timestamp = datenum( all_data.year, all_data.month, all_data.day, ...
                              all_data.hour, all_data.min, all_data.second );
all_data = dataset_fill_timestamps( all_data, ...
                                    'timestamp', ...
                                    't_min', min( all_data.timestamp ), ...
                                    't_max', t_end );
[ all_data.year, all_data.month, all_data.day, ...
  all_data.hour, all_data.min, all_data.second ] = ...
    datevec( all_data.timestamp );
all_data.date = datestr( all_data.timestamp, 'mmddyy' );
all_data.jday = all_data.timestamp - datenum( year, 1, 1 ) + 1;

% this last part takes a long time -- save results so we can restart if one
% of the following steps issues an error
outfile = fullfile( get_out_directory( sitecode ), ...
                    'TOB1_data', ...
                    sprintf( '%s_TOB1_%d.mat', ...
                             get_site_name( sitecode ), year ) );
save( outfile, 'all_data' );

    
% format to match existing FLUX_all_YYYY.xls files
% for some reason, two time columns
timestamp2 = all_data.timestamp;
timestamp2 = dataset( timestamp2) ;
all_data = [ timestamp2, all_data ];
% only one iok column
if size( all_data.iok, 2 ) > 1
    all_data.iok = all_data.iok( :, 2 );
end

% -----
% write filled data to disk
% -----

disp( 'exporting dataset' );
export( all_data, ...
        'file', strrep( outfile, '.mat', '_filled.txt' ) );
disp( 'writing .mat file' );
save( strrep( outfile, '.mat', '_filled.mat' ), 'all_data' );

%--------------------------------------------------

fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );

result = 0;

varargout = { result };
if nargout == 2
    varargout = { result, all_data };
end