function check_ameriflux_data( sitecode, years, varargin )
% CHECK_AMERIFLUX_DATA - scan Ameriflux data for problems
%   
% Runs a series of checks on completed Ameriflux files to makes sure that some
% things that ORNL has pointed out to us in the past are, in fact, corrected:
%
% USAGE: 
%    check_ameriflux_data( sitecode, years );
%    check_ameriflux_data( sitecode, years, 'parse_files', T_or_F );
%    check_ameriflux_data( sitecode, years, ..., 'check_FH2O', T_or_F );
%    check_ameriflux_data( sitecode, years, ..., 'check_Rg_daily', T_or_F );
%    check_ameriflux_data( sitecode, years, ..., 'check_precip', T_or_F );
%
% INPUTS: 
%    sitecode: UNM_sites object; specify site
%    years: vector of four-digit years; specify years to check Ameriflux
%        files
%
% PARAMTER-VALUE PAIRS
%    parse_files: {true}|false; if true, parse text Ameriflux files
%    check_FH2O: {true}|false; if true, write the maximum FH2O value for each
%        requested site-year to stdout
%    check_Rg_daily_cycle: {true}|false; if true, draw a 12-panel figure showing
%        the mean daily Rg cycle for each month of the requested site-years.  A
%        "reference" line is also drawn; this is the mean solar-angle daily
%        cycle for the month with the maximum solar angle normalized to [0,
%        max_Rg], with max_Rg the maximum Rg value for the month.  Thus the
%        absolute magnitude of reference is meaningless (because it is a
%        normalized angle) BUT the timing of its daily cycle should match the
%        timing of the Rg daily cycle if the datalogger clock is set correctly
%        (or properly adjusted during processing).
%    check_precip: {true}|false; if true, write the total annual precip for
%        each requested site-year to stdout
%
% SEE ALSO
%    UNM_sites
%
% author: Timothy W. Hilton, UNM, August 2013

% what year is it now?
[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'years', ...
                  @(x) ( all( arrayfun( @isintval, x ) ) & ...
                         all( x >= 2006 ) & ...
                         all( x <= this_year ) ) );
% parameter-value pair "data" is currently undocumented.  It allows an already
% parsed dataset to be passed directly in to check_ameriflux_data. If provided
% it will still be preempted by parsed data unless parse_files is set to false.
% Data would usually be set to the output from assemble_multiyear_ameriflux.
% This option is useful for debugging if binary data from
% assemble_multiyear_ameriflux are not available.
args.addParamValue( 'data', [], @(x) isa( x, 'dataset' ) );
args.addParamValue( 'parse_files', true, @true_or_false );
args.addParamValue( 'check_FH2O', true, @true_or_false );
args.addParamValue( 'check_Rg_daily_cycle', true, @true_or_false );
args.addParamValue( 'check_precip', true, @true_or_false );

% parse optional inputs
args.parse( sitecode, years, varargin{ : } );

if args.Results.parse_files
    data = assemble_multi_year_ameriflux( args.Results.sitecode, args.Results.years,...
                                          'suffix', 'with_gaps', ...
                                          'binary_data', false );
else
    data = args.Results.data;
end


%----------------------------------------------------------------------
% plot H2O flux to check values are <= 200
%----------------------------------------------------------------------
if args.Results.check_FH2O
    fprintf( 'Maximum FH2O\n' );
    fprintf( '%s: %f\n', ...
             char( args.Results.sitecode ), ...
             nanmax( data.FH2O ) );
    
    % h = figure();
    % plot( data.FH2O, '.' );
    % title( sprintf( '%s FH2O', char( args.Results.sitecode ) ) );
    % waitfor( h );
end


%----------------------------------------------------------------------
% plot monthly mean daily Rg cycle
%----------------------------------------------------------------------
if args.Results.check_Rg_daily_cycle

    mm = monthly_aggregated_daily_cycle( data.timestamp, ...
                                         data.Rg, ...
                                         @nanmean );

    sol_ang = get_solar_elevation( args.Results.sitecode, data.timestamp );
    mean_sol_ang = monthly_aggregated_daily_cycle( data.timestamp, ...
                                                   sol_ang, ...
                                                   @nanmean );
    % reference solar angle does not change; only need one year
    ref_sol_ang = mean_sol_ang.val( mean_sol_ang.year == min( args.Results.years ) );
    
    fname = fullfile( 'Monthly_mean_Rg', ...
                      sprintf( '%s_monthly_Rg_cycle_fromAflux.eps', ...
                               char( args.Results.sitecode ) ) );
    fname = '';  % empty fname causes figure not to be saved
    plot_monthly_aggregated_daily_cycle( mm, ...
                                         'main_title', char( args.Results.sitecode ), ...
                                         'figure_file_name', fname, ...
                                         'ref_vals', ref_sol_ang );
    set( gcf, 'Name', sprintf( '%s mean monthly daily Rg cycles', ...
                               char( args.Results.sitecode ) ) );
end

if args.Results.check_precip    
        annual_precip = annual_aggregate( data.timestamp, ...
                                          data.PRECIP, ...
                                          @nansum );
        fprintf( '\n%s annual total precipitation (mm)\n', char( args.Results.sitecode ) );
        disp( annual_precip );
end