%close all;
%clear all;
%sitelist = {UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ_girdle,...
%    UNM_sites.GLand, UNM_sites.MCon, UNM_sites.PJ,...
%    UNM_sites.PPine};
sitelist = {UNM_sites.New_GLand}
yearlist = 2010:2013;

for i = 1:length(sitelist);
    for j = 1:length(yearlist)
        site = sitelist{i};
        year = yearlist(j);
        % Run remove bad data, view the time offsets, and run the
        % nearby site met gap filler
        UNM_RemoveBadData(site, year, 'draw_plots', 0);
        
        UNM_site_plot_fullyear_time_offsets( site, year );
        
        UNM_fill_met_gaps_from_nearby_site( site, year );
        
        UNM_RemoveBadData( site, year, 'draw_plots', 1);
        
        % Fill in gaps using the REddyProc package
        % UNM_run_gapfiller(sitecode, year);
        % 
        % Otherwise, send the resulting for_gapfilling files to
        % the MPI eddyproc web service.
        
    end
end