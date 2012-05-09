function result = UNM_process_10hz_main( sitecode, t_start, t_end, varargin )
% UNM_PROCESS_10HZ_MAIN: top-level function for matlab processing of 10-hz data
% from flux towers to 30-minute average.  t_start and t_end may not span two
% different calendar years.
%   
%USAGE
%    result = UNM_process_10hz_main( sitecode, t_start, t_end )
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, lag)
%    result = UNM_process_10hz_main( sitecode, t_start, t_end, ..., rotation)
%
%INPUTS
%    sitecode ( integer ): sitecode to process
%    t_start (matlab datenum): data timestamp for starting processing
%    t_end (matlab datenum): data timestamp for ending processing
%    lag (integer): optional, 1 or 0 (default 0)
%    rotation (sonic_rotation object): sonic_rotation.planar or 
%        sonic_rotation.threeD (default threeD)
%
% OUTPUTS:
%    result: 0 on success
%
% (c) Timothy W. Hilton, UNM, April 2012

% -----
% define inputs, with defaults for optionals, and with type-checking
% -----
p = inputParser;
p.addRequired( 'sitecode', @isnumeric ); 
p.addRequired( 't_start', @isnumeric );
p.addRequired( 't_end', @isnumeric );
p.addParamValue( 'lag', ...
                 0, ...
                 @( x ) isnumeric( x ) );
p.addParamValue( 'rotation', ...
                 sonic_rotation.threeD, ...
                 @( x ) isa( x, 'sonic_rotation' ) );
% parse optional inputs
p.parse( sitecode, t_start, t_end, varargin{ : } );
    
sitecode = p.Results.sitecode;
t_start = p.Results.t_start;
t_end = p.Results.t_end;
lag = p.Results.lag;
rotation = p.Results.rotation;

% -----
% start processing
% -----

t0 = now();  % track running time

result = 1;  % initialize to failure -- will change on successful completion

[ year_start, ~, ~, ~, ~, ~ ] = datevec( t_start );
[ year_end, ~, ~, ~, ~, ~ ] = datevec( t_end );
if ( year_start ~= year_end )
    error( '10-hz data processing may not span different calendar years' );
else
    year = year_start;
end

%process 30 days at a time -- a whole year bogged down for lack of memory
process_periods = t_start : 30 : max( ( t_start + 30 ), t_end );
n_pds = numel( process_periods ) - 1;
chunks_list = cell( 1, n_pds );

for i = 1 : n_pds

    this_t_start = process_periods( i );
    this_t_end = process_periods( i + 1 );

    % process 30-minute averages
    chunks_cell{ i } = process_TOB1_chunk( sitecode, ...
                                          this_t_start, ...
                                          this_t_end, ...
                                          lag, ...
                                          rotation );
    fprintf( '==================================================\n');
    fprintf( 'iteration %d/%d\n', i, n_pds );
    memory
    fprintf( '==================================================\n');
end

all_data = vertcat( chunks_cell{ : } );

% this last part takes a long time -- save results so we can restart if one
% of the following steps issues an error
outfile = fullfile( get_out_directory( sitecode ), ...
                    'TOB1_data', ...
                    sprintf( '%s_TOB1_%d.mat', ...
                             get_site_name( sitecode ), year ) );
save( outfile, 'all_data' );

% fill missing timestamps with NaN so there is a complete 30-minute record
% from t_start to t_end
timestamp = dataset( { datenum( double( all_data( :, 1:6 ) ) ), ...
                    'timestamp' } );    
all_data = [ timestamp, all_data ];
all_data = dataset_fill_timestamps( all_data, ...
                                    'timestamp', ...
                                    't_min', t_start, ...
                                    't_max', t_end );
[ y, mon, d, h, m, s ] = datevec( all_data.timestamp );
all_data.year = y;
all_data.month = mon;
all_data.day = d;
all_data.hour = h;
all_data.min = m;
all_data.second = s;
all_data.date = datestr( all_data.timestamp, 'mmddyy' );
all_data.jday = all_data.timestamp - datenum( year, 1, 1 ) + 1;
    
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