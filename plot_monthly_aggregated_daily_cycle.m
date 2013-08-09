function plot_monthly_aggregated_daily_cycle( mm, varargin )
% PLOT_MONTHLY_AGGREGATED_DAILY_CYCLE - plot monthly aggregated daily cycle
% data to a 3-row, 4-column panel figure, each panel showing the daily cycle
% for a month.
%   
% INPUTS
%    mm: dataset with variables year, month, hour, and val, with val the
%        aggregated value to be plotted.  mm is usually the output of
%        monthly_aggregated_daily_cycle.
%
% PARAMETER-VALUE PAIRS
%    main_title: string, optional; title to appear above entire plot
%    figure_file_name: string, optional; specifies full path for plot to be saved to an
%        encapsulated postscript (eps) file.  If not specified plot is not
%        saved. 
%
% OUTPUTS
%    none
%
% author: Timothy W. Hilton, UNM, May 2013

args = inputParser;
args.addRequired( 'mm', @(x) isa( x, 'dataset' ) );
args.addParamValue( 'main_title', '', @ischar );
args.addParamValue( 'figure_file_name', '', @ischar );
args.parse( mm, varargin{ : } );
mm = args.Results.mm;

%need a year, day to feed datenum to convert numeric months (01-12) to strings
%("January" to "December")
dummy_year = 2010; 
dummy_day = 1; 

% user Color Brewer's Dark2 palette
pal = cbrewer( 'qual', 'Dark2', 8 );

h_fig = figure( 'NumberTitle', 'Off', ...
               'Units', 'Normalized', ...
               'Position', [ 0, 0.1, 0.8, 0.6 ], ...
                'DefaultAxesColorOrder', pal );

y_max = nanmax( mm.val );
vals = reshape( mm.val, 24, 12, [] );
for this_month = 1:12
    h_ax = subplot( 3, 4, this_month );
    h_lines = plot( squeeze( vals( :, this_month, : ) ), '-o',...
                    'MarkerSize', 8 );
    % set axis limits
    ylim( [ 0, y_max ] );
    xlim( [ 1, 24 ] );
    % title, axis labels
    title( datestr( datenum( dummy_year, this_month, dummy_day ), 'mmmm' ) );
    if this_month > 8
        xlabel( 'hour of day' );
    end
    if ismember( this_month, [ 1, 5, 9 ] )
        ylabel( 'Rg, W m^{-2}' );
    end    
end

% legend and main title
h_leg = legend( h_lines, num2str( unique( mm.year ) ) );
set( h_leg, 'Units', 'Normalized', 'Position', [ 0.9, 0.4, 0.1, 0.2 ] );

if not( isempty( args.Results.main_title ) )
    suptitle( args.Results.main_title );
end

if not( isempty( args.Results.figure_file_name ) )
    file_path = fullfile( getenv( 'PLOTS' ), ...
                          args.Results.figure_file_name );
    figure_2_eps( h_fig, file_path );
    fprintf( 'saved %s\n', file_path );
end