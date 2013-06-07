% this script runs a series of checks on completed Ameriflux files to makes
% sure that somethings that ORNL has pointed out to us in the past are, in
% fact, corrected.  I intend to turn this into a stand-along function to run at
% the end of Ameriflux_File_Maker.  -TWH, June 2013

sites = UNM_sites( 7 );
years = 2007:2012;

parse_files = true;
check_FH2O = true;
check_Rg_daily_cycle = true;
check_precip = true;
 
if parse_files
    % initialize empty cell array
    ca = cell( 1, max( sites ) );
    for this_site = sites
        
        ca{ this_site } = ...
            assemble_multi_year_ameriflux( this_site, years,...
                                           'suffix', 'with_gaps', ...
                                           'binary_data', false );
        
    end
end


%----------------------------------------------------------------------
% plot H2O flux to check values are <= 200
%----------------------------------------------------------------------
if check_FH2O
    fprintf( 'Maximum FH2O\n' );
    for this_site = sites
        fprintf( '%s: %f\n', ...
                 char( this_site ), ...
                 nanmax( ca{ this_site }.FH2O ) );
        
        % h = figure();
        % plot( ca{ this_site }.FH2O, '.' );
        % title( sprintf( '%s FH2O', char( this_site ) ) );
        % waitfor( h );
    end
end


%----------------------------------------------------------------------
% plot monthly mean daily Rg cycle
%----------------------------------------------------------------------
if check_Rg_daily_cycle
    for this_site = sites

        mm = monthly_aggregated_daily_cycle( ca{ this_site }.timestamp, ...
                                             ca{ this_site}.Rg, ...
                                             @nanmean );

        fname = fullfile( 'Monthly_mean_Rg', ...
                          sprintf( '%s_monthly_Rg_cycle_fromAflux.eps', ...
                                   char( this_site ) ) );
        plot_monthly_aggregated_daily_cycle( mm, ...
                                             'main_title', char( this_site ), ...
                                             'figure_file_name', fname );
    end
end

if check_precip    
    for this_site = sites
        annual_precip = annual_aggregate( ca{ this_site }.timestamp, ...
                                          ca{ this_site }.PRECIP, ...
                                          @nansum );
        fprintf( '%s\n', char( this_site ) );
        disp( annual_precip );
    end
end