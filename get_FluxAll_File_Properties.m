function [ lastcolumn, filelength_n ] = ...
        get_FluxAll_File_Properties( sitecode, year )    
% GET_FLUXALL_FILE_PROPERTIES - Specifies dimensions of UNM annual fluxall
% files.

% This function simply hardcodes in the number of columns and the number of
% lines in the FluxAll file by site-year.  I pulled this code out of
% UNM_Ameriflux_File_Builder into it's own function to make
% Ameriflux_File_Building more compact and to pave the way for reading this
% information on the fly.
%
% USAGE
% [ lastcolumn, filelength_n ] = ...
%         get_FluxAll_File_Properties( sitecode, year );
%
% INPUTS
%    sitecode: UNM_sites object
%    year: four-digit year
%
% OUTPUTS
%    lastcolumn: the last column of the site-year's xls fluxall file
%    filelength_n: the number of row in the site-year's xls fluxall file
%
% SEE ALSO
%    UNM_sites, UNM_Ameriflux_File_Builder
%
% Timothy W. Hilton, University of New Mexico, Jan 2012



if not( isa( sitecode, 'UNM_sites' ) )
    sitecode = UNM_sites( sitecode );
end

switch sitecode
  case UNM_sites.GLand
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
        lastcolumn='IM';
    end
    
  case UNM_sites.SLand
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
    
  case UNM_sites.JSav
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
      case 2012
        filelength_n = 7749;
        lastcolumn='FE';
    end
    
  case UNM_sites.PJ
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
      case 2012
        lastcolumn = 'EZ';
        filelength_n = 11893;
    end
    
  case UNM_sites.PPine
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
        filelength_n = 17524;
        lastcolumn='FY';
    end
    
  case UNM_sites.MCon
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
    
  case UNM_sites.TX
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
    
  case UNM_sites.TX_forest
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
    
  case UNM_sites.TX_grass
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
    
  case UNM_sites.PJ_girdle
    lastcolumn = 'FE';
    switch year 
      case 2009
        filelength_n = 17523;
      case 2010
        filelength_n = 17523; 
      case 2011
        filelength_n = 14595; 
      case 2012
        filelength_n = 7752;
    end
    
  case UNM_sites.New_GLand
    switch year 
      case 2010
        lastcolumn = 'HF';
        filelength_n = 17523;
      case 2011
        lastcolumn = 'HU';
        filelength_n = 14573; % updated Aug 9, 2011
    end
end  % switch sitecode


