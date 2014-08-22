function pcp_fixed = fix_incorrect_precip_factors(site_code, year, doy, pcp_in)
% FIX_INCORRECT_PRECIP_FACTORS - fix preciptiation data collecting using
% incorrect calibration factors in datalogger code.
%
% several sites (currently thought to be GLand, JSav, and PJ) had incorrect rain
% gauge calibration factors in their datalogger programs at various times.  This
% code fixes those problems and returns the precipitation with the correct
% calibrations applied.
%  
% INPUTS
%    site_code: UNM_sites object; which site?
%    year: the year.  Either single value or N-element vector if data span
%        more than one year.
%    doy: day of year; N-element vector of DOY values (1 <= DOY <= 367)
%    pcp_in: N-element vector; precipitation observations from the datalogger
%
% OUTPUTS
%    pcp_fixed: N-element vector; corrected precipitation
%
% SEE ALSO
%    UNM_sites
%
% Timothy W. Hilton, UNM, Nov 2011

%initialize pcp_fixed to original values
pcp_fixed = pcp_in;  
% if year is one element, expand to size of pcp_in
if numel( year ) == 1
    year = repmat( year, size( pcp_in ) );
end

%%-------------------------
%% fix GLand
% datalogger used multiplier of 0.254 for 2009 to 2012.  Correct multiplier is
% 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) = 0.394.
% RJL extended to 2013 on 12/03/2013 per discussion with Marcy.
if site_code == 1     % Gland
    idx = ismember( year, [ 2009:2013 ] );
    if any( idx ) 
        pcp_fixed( idx ) = pcp_in * 0.394;
    end

%%-------------------------
%% fix SLand
% elseif site_code == 2      %SLand
%     idx = ( year == 2011 );
%     if any( idx )
%         pcp_fixed( idx ) = -9999;
%         % now fill in precip record from Sevilleta meteo station 49 
%     end
    

%%-------------------------
% fix JSav
% datalogger used multiplier of 0.254 for 2010 and 2011.  Correct multiplier is
% 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) = 0.394.
% RJL extended to 2013 on 12/03/2013 per discussion with Marcy.
elseif site_code == 3   %JSav
    idx = ismember( year, [ 2010:2013 ] );
    if any( idx ) 
        pcp_fixed( idx ) = pcp_in * 0.394;
    end

%%-------------------------
%% fix PJ
% datalogger used multiplier of 0.254 for 1 Jan to 12 May 2010.  Correct
% multiplier is 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) =
% 0.394.
% RJL extended to 2013 on 12/03/2013 per discussion with Marcy.
elseif site_code == 4     % PJ
    idx = ismember( year, [ 2010:2013 ] );
    if any( idx ) 
        pcp_fixed( idx ) = pcp_in * 0.394;
    end
end


