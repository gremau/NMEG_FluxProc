function [ avg_soil_data, avg_by_cover, avg_by_depth ] = ...
    soil_data_averager( soil_data, varargin )
% SOIL_DATA_AVERAGER - calculates average soil data (moisture or temperature)
% within cover type, depth groups.  Also computes average by cover type.
%   
% USAGE:
%    [ avg_soil_data, avg_by_cover, avg_by_depth ] = ...
%         soil_data_averager( soil_data )
%
% INPUTS:
%    soil_data: dataset; one column per soil observation.  Variables must be
%        named with format obs_cover_idx_depth_*, where obs is the measurmement
%        (e.g. 'soilT', 'VWC', etc., cover is the cover type ('open', 'pinon',
%        etc.), depth is the depth (2p5, 12p5, etc.), and * is arbitrary
%        text.
%    optional parameter arguments:
%      draw_plots: logical; if true produce plots for debugging
%      fill_type: 'interp' or 'run_avg'
%           interp: returns the mean of the probes in this_data (ignoring NaNs),
%                and linearly interpolates gaps (where none of the probes have
%                an observation).
%           run_avg: calculates the mean of the probes (ignoring NaNs), then
%                takes the running average of that mean.  This approach works better
%                when there are frequent small gaps in all of the probes.
%
% OUTPUTS:
%    avg_soil_data: dataset containing average observations for each
%         cover/depth pair.
%    avg_by_cover: average across all depths by cover type
%    avg_by_depth: average across all covers by depth
%
% author: Timothy W. Hilton, UNM, April 2012

%-----
% parse arguments
args = inputParser;
args.addRequired( 'soil_data', @(x) ( isnumeric( x ) | ...
                                      isa( x, 'dataset' ) ) );
args.addParamValue( 'draw_plots', false, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParamValue( 'fill_type', 'interp', ...
                    @(x) ismember( lower( x ), { 'interp', 'run_avg' } ) );
args.addParamValue( 't_str', 'soil\_data', @ischar );
args.parse( soil_data, varargin{ : } );
soil_data = args.Results.soil_data;
%-----


% if there is only one column of data, there is no averaging to do
if ( size( soil_data, 2 ) == 1 )
    avg_soil_data = soil_data;
    avg_by_cover = soil_data;
    avg_by_depth = soil_data;
    return;
end

original_vars = soil_data.Properties.VarNames;

grp_vars = regexp( soil_data.Properties.VarNames, '_', 'split' );
grp_vars = vertcat( grp_vars{ : } ); 

var = unique( grp_vars( :, 1 ) );  %variable (Tsoil, cs616) is 1st
                                   %underscore-delimited field
covers = unique( grp_vars( :, 2 ) );  %cover is 2nd underscore-delimited field
depths = unique( grp_vars( :, 4 ) );  %depth is 4th underscore-delimited field
                
switch var{ 1 }
  case 'cs616SWC'
    prefix = 'VWC';
  case 'soilT'
    prefix = 'Tsoil';
  case 'SHF'
    prefix = 'SHF';
  otherwise
    error( sprintf( [ 'label prefix should be either' ...
                      '"cs616SWC", "soilT", or "SHF".  It is "%s".' ], ...
                    var{ 1 } ) );
end

% -----
% calculate average at each depth by cover type
% -----

avg_soil_data_vars = cell( 1, numel( covers) * numel( depths ) );
avg_soil_data = repmat( NaN, ...
                        size( soil_data, 1 ), ...
                        numel( avg_soil_data_vars ) );

soil_data = double( soil_data );
fprintf( 'AVERAGING BY COVER AND DEPTH\n' );
count = 1;
for this_cov = 1:numel( covers )
    for this_depth = 1:numel( depths )
        avg_soil_data_vars{ count } = sprintf( '%s_%s_%s_Avg', ...
                                               prefix, ...
                                               covers{ this_cov }, ...
                                               depths{ this_depth } );
        idx = strcmp( grp_vars( :, 4 ), depths( this_depth ) ) & ...
              strcmp( grp_vars( :, 2 ), covers( this_cov ) );
        
        t_str = regexprep( avg_soil_data_vars{ count }, '_', '\\_' );
        
        avg_soil_data( :, count ) = ...
            soil_probe_mean( soil_data( :, idx ),...
                             'draw_plots', args.Results.draw_plots, ...
                             'fill_type', args.Results.fill_type, ...
                             't_str', t_str );

        fprintf( '%s: \t', avg_soil_data_vars{ count } );
        for i = find( idx )
            fprintf( '%s ', original_vars{ i } );
        end
        fprintf( '\n--------------------------------------------------\n' );
        
        count = count + 1;
    end
end

avg_soil_data = dataset( { avg_soil_data, avg_soil_data_vars{ : } } );

% -----
% calculate average across all depths by cover type
% -----

avg_by_cover_vars = cell( 1, numel( covers ) );
avg_by_cover = repmat( NaN, size( soil_data, 1 ), numel( covers ) );

fprintf( 'AVERAGING BY COVER\n' );
for this_cov = 1:numel( covers )
    idx = strcmp( grp_vars( :, 2 ), covers( this_cov ) );
    avg_by_cover_vars{ this_cov } = sprintf( '%s_%s_Avg', ...
                                             prefix, covers{ this_cov } );
    t_str = regexprep( avg_by_cover_vars{ this_cov }, '_', '\\_' );
    avg_by_cover( :, this_cov ) = ...
        soil_probe_mean( soil_data( :, idx ),...
                         'draw_plots', args.Results.draw_plots, ...
                         'fill_type', args.Results.fill_type, ...
                         't_str', t_str );

    fprintf( '%s: \t', avg_by_cover_vars{ this_cov } );
    for i = find( idx )        
        fprintf( '%s ', original_vars{ i } );
    end
    fprintf( '\n--------------------------------------------------\n' );
end

avg_by_cover = dataset( { avg_by_cover, avg_by_cover_vars{ : } } );

fprintf( 'AVERAGING BY DEPTH\n' );
for this_depth = 1:numel( depths )

    idx = strcmp( grp_vars( :, 4 ), depths( this_depth ) );

    % % display the groupings for debugging 
    % disp( grp_vars( find( idx ) , : ) );
    % disp( '----------' );

    avg_by_depth_vars{ this_depth } = sprintf( '%s_%s_Avg', ...
                                             prefix, depths{ this_depth } );
    t_str = regexprep( avg_by_depth_vars{ this_depth }, '_', '\\_' );
    
    avg_by_depth( :, this_depth ) = ...
        soil_probe_mean( soil_data( :, idx ),...
                         'draw_plots', args.Results.draw_plots, ...
                         'fill_type', args.Results.fill_type, ...
                         't_str', t_str );
    
    fprintf( '%s: \t', avg_by_depth_vars{ this_depth } );
    for i = find( idx )
        fprintf( '%s ', original_vars{ i } );
    end
    fprintf( '\n--------------------------------------------------\n' );
end

avg_by_depth = dataset( { avg_by_depth, avg_by_depth_vars{ : } } );


%==================================================
function soil_probe_mean = soil_probe_mean( this_data, varargin )
% SOIL_PROBE_MEAN - calculate the mean among a number of soil probes.  Where not
%   all of the probes have a valid observations, takes the six-hour running mean
%   of the average.  By doing this, a long gap results in a gap in the mean, but
%   a short gap caused by one or two probes allows the average to continue
%   smoothly (unlike simply using nanmean, which causes a step change in the
%   average when one or more probes drops out.
%
% optional parameter arguments:
%   fill_type: 'interp' or 'run_avg'
%        interp: returns the mean of the probes in this_data (ignoring NaNs),
%                and linearly interpolates gaps (where none of the probes have
%                an observation).
%        run_avg: calculates the mean of the probes (ignoring NaNs), then
%                takes the running average of that mean.  This approach works better
%                when there are frequent small gaps in all of the probes.

%-----
% parse arguments
args = inputParser;
args.addRequired( 'this_data', @isnumeric );
args.addParamValue( 'draw_plots', false, @(x) ( islogical(x) & ...
                                               numel( x ) ==  1 ) );
args.addParamValue( 'fill_type', 'interp', ...
                    @(x) ismember( lower( x ), { 'interp', 'run_avg' } ) );
args.addParamValue( 't_str', 'soil\_data', @ischar );
args.parse( this_data, varargin{ : } );
this_data = args.Results.this_data;
%-----

% number of probes with valid readings at each time step
n_valid = reshape( sum( not( isnan( this_data' ) ) ), [], 1 );

% if a probe has no valid data, do not consider it
all_nan = find( all( isnan( this_data ) ) );
this_data( :, all_nan ) = [];

this_avg = nanmean( this_data, 2 );  %row-wise mean
rle_avg = rle( isnan( this_avg ) );

% fill in gaps of less than three days in the averaged probe
window = 25;
row_wise = 1;
fill_NaNs = 1;
run_avg = nanmoving_average( this_avg, window, row_wise, fill_NaNs );
this_avg = inpaint_nans( this_avg, 4 );

% replace interpolated data with NaN where gaps > 5 days
orig_size = size( this_avg );
rle_filled = rle( reshape( this_avg, [], 1 ) );
five_days = 48 * 5;  % five days in units of 30-minute periods
rle_filled{ 1 }( rle_avg{ 1 } & rle_avg{ 2 } > five_days ) = NaN;
nan_idx = rle( rle_filled );
this_avg = reshape( rle( rle_filled ), orig_size );


switch args.Results.fill_type
  case 'interp'
    soil_probe_mean = this_avg;
  case 'run_avg'
    soil_probe_mean = run_avg;
end

if args.Results.draw_plots
    h = figure();
    set( h, 'DefaultAxesColorOrder', cbrewer( 'qual', 'Dark2', 8 ) );
    h_data = plot( this_data, '.' );
    set( h_data, 'MarkerSize', 12 );
    hold on;    
    h_runmean = plot( run_avg, 'ok' );
    h_nanmean = plot( this_avg, '+r', 'MarkerSize', 8 );
    legend( [ h_nanmean, h_runmean ], 'nanmean', 'runmean', ...
            'location', 'best' );
    title( args.Results.t_str );
    waitfor( h );
end


function soil_probe_fit = soil_probe_fit_curve(this_data)
% SOIL_PROBE_FIT_CURVE - 
%   

% do not consider probes with no valid measurements
all_nan = find( all( isnan( this_data ) ) );
this_data( :, all_nan ) = [];

% number of probes with valid readings at each time step
n_valid = reshape( sum( not( isnan( this_data' ) ) ), [], 1 );

data_mean = nanmean( this_data, 2 );

coeff = glmfit( this_data, data_mean );
soil_probe_fit = glmval( coeff, this_data, 'identity' );

h = figure();
plot( this_data, '.' );
hold on;
plot( data_mean, '.r' );
plot( soil_probe_fit, 'ok' );
waitfor( h );

