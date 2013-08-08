function [ Tsoil, SWC ] = remove_problematic_soil_probe_data( sitecode, year, Tsoil, SWC )
% REMOVE_PROBLEMATIC_SOIL_PROBE_DATA - remove specific periods from specific
%   soil probes where data are obviously bogus
%
% USAGE
%   [ Tsoil, SWC ] = remove_problematic_soil_probe_data( sitecode, ...
%                                                        year, 
%                                                        Tsoil, 
%                                                        SWC )
%
% INPUTS:
%    sitecode: integer or UNM_sites object; the site to process
%    year: numeric; the year to process
%    Tsoil: dataset array object; soil temperature data for the specified 
%        site-year
%    SWC: dataset array object; soil water content data for the specified 
%        site-year
%
% OUTPUTS:
%    Tsoil: dataset array object; soil temperature data for the specified 
%        site-year with the periods specified below removed
%    SWC: dataset array object; soil water content data for the specified 
%        site-year with the periods specified below removed
%
% author: Timothy W. Hilton, UNM, Sep 2012

if isnumeric( sitecode )
    sitecode = UNM_sites( sitecode );
end

% note: 0x2E is the hexadecimal character code for '.' -- need to fix dataset
% creation to put in something for readable

switch sitecode
  case UNM_sites.GLand
    switch year
      case 2007
        SWC.cs616SWC_open_2_12p5( 7480:7672 ) = 0.09; % fill from previous
                                                      % good value
        SWC.cs616SWC_open_2_22p5( 7480:7672 ) = 0.086; % fill from previous
        SWC.cs616SWC_grass_3_12p5( : ) = NaN;
        SWC.cs616SWC_grass_3_37p5( 1:7763 ) = NaN;
        SWC.cs616SWC_open_3_37p5( 1:7758 ) = NaN;
        
      case 2009
        % remove all data after index 2800
        data = double( SWC );
        data( 2800:end, : ) = NaN;
        SWC = replacedata( SWC, data );
    end %GLand years
        
  case UNM_sites.SLand
    switch year
      case { 2007, 2008 }
        SWC.cs616SWC_open_2_12p5( : ) = NaN;
        SWC.cs616SWC_open_2_22p5( : ) = NaN;
      case 2009
        SWC.cs616SWC_open_2_12p5( : ) = NaN;
        SWC.cs616SWC_open_2_22p5( : ) = NaN;
        SWC.cs616SWC_open_2_52p5( 1:4300 ) = NaN;
        SWC.cs616SWC_cover_2_12p5( : ) = NaN;
        SWC.cs616SWC_cover_2_22p5( 1:4300 ) = NaN;
      case 2010
        SWC.cs616SWC_open_2_12p5( : ) = NaN;
        SWC.cs616SWC_cover_2_12p5( : ) = NaN;
    end %SLand years

    %
    % JSav looks good
    %
    
  case UNM_sites.PJ
    
    switch year
      case 2009
        Tsoil.soilT_P_2_5( 1:6350 ) = NaN;
        Tsoil.soilT_J_1_5( 1:6350 ) = NaN;
        Tsoil.soilT_J_1_10( 1:6350 ) = NaN;
        Tsoil.soilT_J_2_30( 1:6450 ) = NaN;
        Tsoil.soilT_O_1_5( 1:7330 ) = NaN;
        Tsoil.soilT_O_1_10( 1:7330 ) = NaN;
        Tsoil.soilT_O_2_5( 1:6470 ) = NaN;
        Tsoil.soilT_O_2_10( 1:6470 ) = NaN;
        Tsoil.soilT_O_2_30( 1:6370 ) = NaN;
        
        SWC.cs616SWC_O_2_30( 6500:7230 ) = 0.078;
      
      case 2010
        SWC.cs616SWC_J_3_5( : ) = NaN;
      
      case 2011
        SWC.cs616SWC_J_1_30( 17000:end ) = 0.083;
    end %PJ years
    
end %switch sitecode
        