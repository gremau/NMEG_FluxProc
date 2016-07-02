classdef UNM_sites_info
% This class defines a number of numerical and text constants for each UNM site.
%
% Its fields are: 
%    short_name: abbreviation used in UNM data files (fluxall, gapfilling, etc)
%    long_name: a fuller (though still short) site description, perhaps useful
%        for plot labels
%    ameriflux: abbreviation used for ameriflux files
%    ORNL: abbreviation used for Oak Ridge MODIS snapshots
%    latitude: site's latitude (deg N)
%    longitude: site's longitude (deg E -- i.e. values are negative)
%    elevation:  site's elevation (m)
%
% USAGE
%
%    site_info = UNM_sites_info( this_site )
%
% INPUTS
%    this_site: UNM_sites object, numerical site code (1-11) or character
%       string short_name
%
% EXAMPLES
%
% these three are equivalent:
% >> UNM_sites_info( UNM_sites.JSav )
% >> UNM_sites_info( 3 )
% >> UNM_sites_info( 'JSav' )
%
%  ans = 
%
%  UNM_sites_info
%
%  Properties:
%    short_name: 'JSav'
%     long_name: 'Sevilleta juniper savanna'
%     ameriflux: 'US-Wjs'
%          ORNL: 'usjunsav'
%      latitude: 34.4255
%     longitude: -105.8615
%     elevation: 1927
%
% >> UNM_sites_info( UNM_sites.PJ ).ameriflux
%
% ans =
%
% US-Mpj
%
% author: Timothy W. Hilton, UNM, Nov 2012

properties
    
    short_name = '';
    long_name = '';
    ameriflux = '';
    ORNL = '';
    latitude = NaN;
    longitude = NaN;
    elevation = NaN;
    
end %properties

methods
    
% --------------------------------------------------
    function obj = UNM_sites_info( this_site )
    % UNM_SITES_INFO - class constructor
    %   
    
    if isnumeric( this_site )
        this_site = UNM_sites( this_site );
    elseif ischar( this_site )
        this_site = UNM_sites.( this_site );
    end
    
    if this_site ==  UNM_sites.GLand
        obj.short_name = 'GLand';
        obj.long_name = 'Sevilleta burned grass';
        obj.ameriflux = 'US-Seg';
        obj.ORNL = 'ussevdeg';                            
        obj.latitude = 34.3402;
        obj.longitude = -106.68542;
        obj.elevation = 1619;
        
    elseif this_site ==  UNM_sites.SLand
        obj.short_name = 'SLand';
        obj.long_name = 'Sevilleta shrub';
        obj.ameriflux = 'US-Ses';
        obj.ORNL = 'ussevdes';                            
        obj.latitude = 34.3338;
        obj.longitude = -106.73401;
        obj.elevation = 1608;
        
    elseif this_site ==  UNM_sites.JSav
        obj.short_name = 'JSav';                            
        obj.long_name = 'Sevilleta juniper savanna';
        obj.ameriflux = 'US-Wjs';
        obj.ORNL = 'usjunsav';                            
        obj.latitude = 34.425489;
        obj.longitude = -105.861545;
        obj.elevation = 1927;
        
    elseif this_site ==  UNM_sites.PJ
        obj.short_name = 'PJ';                            
        obj.long_name = 'pinon juniper control';
        obj.ameriflux = 'US-Mpj';
        obj.ORNL = 'uspinonj';                            
        obj.latitude = 34.437; 
        obj.longitude = -106.238;
        obj.elevation = 2195;
        
    elseif this_site ==  UNM_sites.PPine
        obj.short_name = 'PPine';                            
        obj.long_name = 'Ponderosa Pine';
        obj.ameriflux = 'US-Vcp';
        obj.ORNL = 'usvalpon';                            
        obj.latitude = 35.86236;
        obj.longitude = -106.59743;
        obj.elevation = 2488;

    elseif this_site ==  UNM_sites.MCon
        obj.short_name = 'MCon';                            
        obj.long_name = 'Valles Caldera Mixed Conifer';
        obj.ameriflux = 'US-Vcm';
        obj.ORNL = 'usvalcon';                            
        obj.latitude = 35.888;
        obj.longitude = -106.532;
        obj.elevation = 3025;
    elseif this_site ==  UNM_sites.TX
        obj.short_name = 'TX';                            
        obj.long_name = 'Freeman Ranch juniper savanna';
        obj.ameriflux = 'US-FR2';
        obj.ORNL = '';                            
        obj.latitude = 29.94943333;
        obj.longitude = -97.99611667;
        obj.elevation = 264;

    elseif this_site ==  UNM_sites.TX_forest
        obj.short_name = 'TX_forest';                            
        obj.long_name = 'Freeman Ranch forest';
        obj.ameriflux = 'US-FR3';
        obj.ORNL = '';                            
        obj.latitude = 29.94943333;
        obj.longitude = -97.99611667;
        obj.elevation = 264;

    elseif this_site ==  UNM_sites.TX_grass
        obj.short_name = 'TX_grass';                            
        obj.long_name = 'Freeman Ranch grassland';
        obj.ameriflux = 'US-FR1';
        obj.ORNL = '';                            
        obj.latitude = 29.94943333;
        obj.longitude = -97.99611667;
        obj.elevation = 264;

    elseif this_site ==  UNM_sites.PJ_girdle
        obj.short_name = 'PJ_girdle';
        obj.long_name = 'PJ manipulation';
        obj.ameriflux = 'US-Mpg';
        obj.ORNL = '';
        obj.latitude = 34.437;
        obj.longitude = -106.238;
        obj.elevation = 2195;
        
        
    elseif this_site ==  UNM_sites.New_GLand
        obj.short_name = 'New_GLand';
        obj.long_name = 'Sevilleta Unburned grassland';
        obj.ameriflux = 'US-Sen';
        obj.ORNL = '';
        obj.latitude = 34.3402;
        obj.longitude = -106.68542;
        obj.elevation = 1619;
        
    elseif this_site ==  UNM_sites.SevEco
        obj.short_name = 'Sev_Eco';
        obj.long_name = 'Sevilleta ecotone';
        obj.ameriflux = '';
        obj.ORNL = '';
        obj.latitude = NaN;
        obj.longitude = NaN;
        obj.elevation = NaN;
        
    elseif this_site ==  UNM_sites.TestSite
        obj.short_name = 'TestSite';                            
        obj.long_name = 'testing site';
        obj.ameriflux = 'US-Test';
        obj.ORNL = 'ustest';                            
        obj.latitude = 34.437; 
        obj.longitude = -106.238;
        obj.elevation = 2195;
        
    end % if/then/else
    end % constructor

end %methods
end %classdef
    %--------------------------------------------------
