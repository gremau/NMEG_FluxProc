function check_ameriflux_data( sitecode, years, data )
% CHECK_AMERIFLUX_DATA - 
%   
% this script runs a series of checks on completed Ameriflux files to makes
% sure that some things that ORNL has pointed out to us in the past are, in
% fact, corrected.  I intend to turn this into a stand-alone function to run at
% the end of Ameriflux_File_Maker.  -TWH, June 2013

sitecode = UNM_sites.PJ;
years = 2008:2013;

parse_files = isempty( data );
check_FH2O = false;
check_Rg_daily_cycle = true;
check_precip = false;
 
if parse_files
    data = assemble_multi_year_ameriflux( sitecode, years,...
                                          'suffix', 'with_gaps', ...
                                          'binary_data', false );
end


%----------------------------------------------------------------------
% plot H2O flux to check values are <= 200
%----------------------------------------------------------------------
if check_FH2O
    fprintf( 'Maximum FH2O\n' );
    fprintf( '%s: %f\n', ...
             char( sitecode ), ...
             nanmax( data.FH2O ) );
    
    % h = figure();
    % plot( data.FH2O, '.' );
    % title( sprintf( '%s FH2O', char( sitecode ) ) );
    % waitfor( h );
end


%----------------------------------------------------------------------
% plot monthly mean daily Rg cycle
%----------------------------------------------------------------------
if check_Rg_daily_cycle

    mm = monthly_aggregated_daily_cycle( data.timestamp, ...
                                         data.Rg, ...
                                         @nanmean );

    sol_ang = get_solar_elevation( sitecode, data.timestamp );
    mean_sol_ang = monthly_aggregated_daily_cycle( data.timestamp, ...
                                                   sol_ang, ...
                                                   @nanmean );
    % reference solar angle does not change; only need one year
    ref_sol_ang = mean_sol_ang.val( mean_sol_ang.year == min( years ) );
    
    fname = fullfile( 'Monthly_mean_Rg', ...
                      sprintf( '%s_monthly_Rg_cycle_fromAflux.eps', ...
                               char( sitecode ) ) );
    fname = '';  % empty fname causes figure not to be saved
    plot_monthly_aggregated_daily_cycle( mm, ...
                                         'main_title', char( sitecode ), ...
                                         'figure_file_name', fname, ...
                                         'ref_vals', ref_sol_ang );
end

if check_precip    
        annual_precip = annual_aggregate( data.timestamp, ...
                                          data.PRECIP, ...
                                          @nansum );
        fprintf( '%s\n', char( sitecode ) );
        disp( annual_precip );
end