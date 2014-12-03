%close all;
%clear all;
%
%sitelist = {UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ_girdle,...
%    UNM_sites.GLand, UNM_sites.MCon, UNM_sites.PJ,...
%    UNM_sites.PPine};
% sitelist = {UNM_sites.MCon, UNM_sites.PPine, UNM_sites.PJ, UNM_sites.JSav}
% yearlist = 2007:2013;
% sitelist = {UNM_sites.PJ_girdle, UNM_sites.GLand, UNM_sites.SLand}
% yearlist = 2009:2013;
sitelist = {UNM_sites.PJ_girdle}
yearlist = 2009:2013;
partmethod = 'eddyproc';%'Reddyproc'

for i = 1:length(sitelist);
    close all;
    for j = 1:length(yearlist);
        % Set site and year
        sitecode = sitelist{i};
        year = yearlist(j);
        
        if strcmp(partmethod, 'eddyproc');
        
            UNM_Ameriflux_File_Maker_TWH(sitecode, year,...
                'write_daily_file', false);
            
        elseif strcmp(partmethod, 'Reddyproc');
            
            UNM_Ameriflux_File_Maker(sitecode, year,...
                'write_daily_file', false);
            
        end
        
        % New files go into FLUXROOT - look at the file you made
        %UNM_Ameriflux_Data_Viewer( sitecode, year, 'AFlux_dir',...
        %    fullfile(getenv('FLUXROOT'), 'FluxOut' ));
        %clear year;
    end
    clear sitecode;
end

