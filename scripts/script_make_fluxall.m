%close all;
%clear all;

%sitelist = {UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ_girdle,...
%    UNM_sites.GLand,UNM_sites.New_GLand, UNM_sites.MCon, UNM_sites.PJ,...
%    UNM_sites.PPine};
sitelist = {UNM_sites.MCon, UNM_sites.SLand, UNM_sites.JSav, ...
    UNM_sites.GLand, UNM_sites.PPine, UNM_sites.PJ_girdle, UNM_sites.PJ, ...
    UNM_sites.PJ_girdle};

sitelist = {UNM_sites.MCon_SS};
yearlist = 2016;%2013:2014;% 2009:2013;

proc_10hz = false;
count = 1;
for i = 1:length(sitelist);
    for j = 1:length(yearlist)
        % Set site and year
        sitecode = sitelist{i};
        year = yearlist(j);
        process_10hz = proc_10hz; %proc_10hz(count);
        
        % Fix the resolution file if needed
        % generate_header_resolution_file;
        
        if process_10hz
            % Start and end dates for making a new fluxall file
            date_start = datenum(year, 1, 1, 0, 0, 0);
            % end at 23:30 when processing tob data (not quite sure why)
            % half hour later other times
            date_end = datenum(year, 12, 31, 23, 30, 0);
            
            % Create a new cdp object.
            % Leave 'data_10hz_already_processed' false.
            new = card_data_processor(sitecode, 'date_start', date_start,...
                'date_end', date_end);
            
            % Fill in 30min and 10hz data
            new = new.get_30min_data();
            new = new.process_10hz_data(); % This takes a long time
        end
        
        % Create a new cdp object using correct start dates and set
        % 'data_10hz_already_processed' to true.
        date_start = datenum(year, 1, 1, 0, 30, 0);
        date_end = datenum(year, 12, 31, 24, 0, 0);
        
        new = card_data_processor(sitecode, 'date_start', date_start,...
            'date_end', date_end, 'data_10hz_already_processed', true );
        
        % Make a new fluxall file
        new.update_fluxall();
        
        % If fluxes need to be filled in with 30min data...
        % UNM_30_min_spooler(sitecode, year);
        
        % With the new fluxall, run RBD.m to view Fc and the 
        % current settings for removing bad data
        % UNM_RemoveBadData(sitecode, year, 'draw_plots', 1,...
        %    'write_qc', false, 'write_gf', false);
        count = count + 1;
    end
end
