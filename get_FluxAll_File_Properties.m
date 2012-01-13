% This function simply hardcodes in the number of columns and the number of
% lines in the FluxAll file by site-year.  I pulled this code out of
% UNM_Ameriflux_File_Builder into it's own function to make
% Ameriflux_File_Building more compact and to pave the way for reading this
% information on the fly.
%
% Timothy W. Hilton, University of New Mexico, Jan 2012

function [ lastcolumn, filelength_n ] = ...
        get_FluxAll_File_Properties( sitecode, year )
    
    switch sitecode
      case 1 % grassland
        switch year
          case 2006
            filelength_n = 11594;
          case 2007
            filelength_n = 17523;
            lastcolumn='HG';
          case 2008
            filelength_n = 17572;
            lastcolumn = 'HJ';
          case 2009
            filelength_n = 17520;
            lastcolumn='IC';
          case 2010 % added by MF
            filelength_n = 17523;
            lastcolumn = 'IC';  % correspohds to Tsoil_avg; there are more
                                % cols to the right 
          case 2011 % added by MF
            filelength_n = 14572;
            lastcolumn='IL';
        end
        
      case 2; % shrubland
        switch year
          case 2006
            
          case 2007
            filelength_n = 17523;
            lastcolumn='GX';
          case 2008
            filelength_n = 17572;
            lastcolumn='GZ';
          case 2009
            filelength_n = 17523;
            lastcolumn='IL';
          case 2010
            filelength_n =  17523;
            lastcolumn='IE';
          case 2011
            filelength_n = 14576;
            lastcolumn='IQ';
        end
        
      case 3; % Juniper savanna
        switch year 
          case 2007
            filelength_n = 11595;
            lastcolumn='HR';
          case 2008
            filelength_n = 17571;
            lastcolumn='HJ';
          case 2009
            filelength_n = 17523;
            lastcolumn='IE';
          case 2010
            filelength_n = 17523;
            lastcolumn='IE';
          case 2011   % added by MF
            filelength_n = 14381;
            lastcolumn='IE';
        end
        
      case 4 % Pinyon Juniper
        switch year 
          case 2007
            lastcolumn = 'HO';
            filelength_n = 2514;
          case 2008
            lastcolumn = 'HO';
            filelength_n = 17571;
          case 2009
            lastcolumn = 'HJ';
            filelength_n = 17524;
          case 2010
            lastcolumn = 'EZ';
            filelength_n = 17524;
          case 2011
            lastcolumn = 'HA';
            filelength_n = 14674;
        end
        
      case 5 % Ponderosa Pine
        switch year 
          case 2006
            filelength_n = 11594;
          case 2007
            filelength_n = 17524;
            lastcolumn='FV';
          case 2008;
            filelength_n = 17572;
            lastcolumn='HB';
            ustar_lim = 0.08;
          case 2009;
            filelength_n = 12029;
            lastcolumn='FX';
            ustar_lim = 0.08;
          case 2010;
            filelength_n = 17517;
            lastcolumn='FW';
          case 2011;
            filelength_n = 13705;
            lastcolumn='FY';
        end
        
      case 6 % Mixed conifer
        switch year 
          case 2006
            filelength_n = 4420;
            lastcolumn='GA';
          case 2007
            filelength_n = 17524;
            lastcolumn='GX';
          case 2008;
            filelength_n = 17420;
            lastcolumn='GX';
          case 2009;
            filelength_n = 17524;
            lastcolumn='GF';
          case 2010 
            filelength_n = 17523; % updated by MF Feb 25, 2011
            lastcolumn='GI'; % updated to GI by MF Feb 25, 2011
          case 2011  % added by MF
            filelength_n = 13716;
            lastcolumn='GI';
        end
        
      case 7;
        switch year
          case 2005
            filelength_n = 17523;
            lastcolumn='GF';
          case 2006
            filelength_n = 17523;
            lastcolumn='GF';
          case 2007
            filelength_n = 17524;
            lastcolumn='GH';
          case 2008;
            filelength_n = 17452;
            lastcolumn='GP';
          case 2009;
            filelength_n = 17523;
            lastcolumn='GP';
        end
        
      case 8;
        switch year 
          case 2005
            filelength_n = 17523;
            lastcolumn='DO';
          case 2006
            filelength_n = 17524;
            lastcolumn='DO';
          case 2007
            filelength_n = 17524;
            lastcolumn='DO';
          case 2008;
            filelength_n = 17521;
            lastcolumn='ET';
          case 2009;
            filelength_n = 17523;
            lastcolumn='ET';
        end
        
      case 9;
        switch year
          case 2005
            filelength_n = 17524;
            lastcolumn='DT';
          case 2006
            filelength_n = 17523;
            lastcolumn='DO';
          case 2007
            filelength_n = 17524;
            lastcolumn='DO';
          case 2008;
            filelength_n = 16253;
            lastcolumn='GP';
          case 2009;
            filelength_n = 16253;
            lastcolumn='GP';
        end
        
      case 10; % Pinyon Juniper girdle
        lastcolumn = 'FE';
        switch year 
          case 2009
            filelength_n = 17523;
          case 2010
            filelength_n = 17523; 
          case 2011
            filelength_n = 14595; 
        end
        
      case 11; % new Grassland
        switch year 
          case 2010
            lastcolumn = 'HF';
            filelength_n = 17523;
          case 2011
            lastcolumn = 'HU';
            filelength_n = 14573; % updated Aug 9, 2011
        end
    end  % switch sitecode
    
                            
