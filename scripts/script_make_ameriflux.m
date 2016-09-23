%close all;
%clear all;
%

 sitelist_1 = {UNM_sites.MCon, UNM_sites.JSav, UNM_sites.PJ, UNM_sites.PJ_girdle, ...
     UNM_sites.SLand, UNM_sites.GLand, UNM_sites.PPine, UNM_sites.New_GLand};
 yearlist_1 = 2010:2015;
 
 sitelist_2 = {UNM_sites.JSav, ...
     UNM_sites.SLand, UNM_sites.GLand, UNM_sites.PPine, UNM_sites.MCon};
 yearlist_2 = 2007:2009;
 
sitelist_3={UNM_sites.PJ};
% Years to create files for
yearlist_3 = 2008:2009;

sitelist_4 = {UNM_sites.PJ_girdle}
yearlist = 2009 ;
% Partitioned data source
partmethod = 'eddyproc'; %'Reddyproc'
% Make daily files? All AF files should be in $FLUXROOT$/Ameriflux_files
make_daily = false;
write_files = true;
process_soil = false;

for k = 1:4
    % Automatically cycles through earlier site years to account for
    % different startup dates.
    switch k
        case 1
            sitelist = sitelist_1;
            yearlist = yearlist_1;
        case 2
            sitelist = sitelist_2;
            yearlist = yearlist_2;
        case 3
            sitelist = sitelist_3;
            yearlist = yearlist_3;
        case 4
            sitelist = sitelist_4;
            yearlist = yearlist_4;
    end

for i = 1:length(sitelist);
    %close all;
    for j = 1:length(yearlist);
        % Set site and year
        sitecode = sitelist{i};
        year = yearlist(j);
        
        if strcmp(partmethod, 'eddyproc');
        
            UNM_Ameriflux_File_Maker( sitecode, year, ...
                'write_files', write_files, ...
                'write_daily_file', make_daily, ...
                'process_soil_data', process_soil );
            
        elseif strcmp(partmethod, 'Reddyproc');
            %error( ' not implemented yet ' );
            UNM_Ameriflux_File_Maker(sitecode, year,...
                'write_daily_file', make_daily, ...
                'process_soil_data', process_soil, ...
                'gf_part_source', 'Reddyproc');
            
        end
        
        % New files go into FLUXROOT - look at the file you made
        %UNM_Ameriflux_Data_Viewer( sitecode, year, 'AFlux_dir',...
        %    fullfile(getenv('FLUXROOT'), 'FluxOut' ));
        %clear year;
    end
    
    close all;
    clear sitecode;
end
end

