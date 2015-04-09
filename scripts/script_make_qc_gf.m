%close all;
%clear all;
% sitelist = {UNM_sites.SLand, UNM_sites.JSav, ...
%     UNM_sites.GLand, UNM_sites.PPine, UNM_sites.MCon,...
%    UNM_sites.PJ};
sitelist = {UNM_sites.MCon};
%sitelist = {UNM_sites.MCon};
yearlist = 2013:2014;

for i = 1:length(sitelist);
    for j = 1:length(yearlist)
        site = sitelist{i};
        year = yearlist(j);
        % Run remove bad data, view the time offsets, and run the
        % nearby site met gap filler
        UNM_RemoveBadData(site, year, 'draw_plots', 3);
        
        %UNM_site_plot_fullyear_time_offsets( site, year );
        
        % WARNING - if the "for_gapfilling" files from other NMEG sites are
        % not created AND correct (timeshifts especially) this script will
        % not do a good job of filling the data.
        %UNM_fill_met_gaps_from_nearby_site( site, year );
        
        %UNM_RemoveBadData( site, year, 'draw_plots', 0);
        
        % Fill in gaps using the REddyProc package
        % UNM_run_gapfiller(sitecode, year);
        % 
        % Otherwise, send the resulting for_gapfilling files to
        % the MPI eddyproc web service.
        close all;
    end
end