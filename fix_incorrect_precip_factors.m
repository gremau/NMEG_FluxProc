function pcp_fixed = fix_incorrect_precip_factors(site_code, year, doy, pcp_in)
% FIX_INCORRECT_PRECIP_FACTORS - several sites had incorrect conversion factors
% in their datalogger programs at various times.  This code fixes those
% problems.
%  
% Timothy W. Hilton, UNM, Nov 2011

pcp_fixed = pcp_in;  %initialize pcp_fixed to original values

%%-------------------------
%% fix GLand
% datalogger used multiplier of 0.254 for 2009 to 2011.  Correct multiplier is
% 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) = 0.394.
if site_code == 1     % Gland
    idx = intersect( year, 2009:2011 );
    pcp_fixed = pcp_in * 0.394;

%%-------------------------
%% fix SLand
elseif site_code == 2      %SLand
    idx = find( year == 2011 );
    pcp_fixed( idx ) = -9999;
    % now fill in precip record from Sevilleta meteo station 49 
    

%%-------------------------
% fix JSav
% datalogger used multiplier of 0.254 for 2010 and 2011.  Correct multiplier is
% 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) = 0.394.
elseif site_code == 3   %JSav
    idx = find( intersect( year, [ 2010, 2011 ] ) );
    pcp_fixed( idx ) = pcp_in * 0.394;

%%-------------------------
%% fix PJ
% datalogger used multiplier of 0.254 for 1 Jan to 12 May 2010.  Correct
% multiplier is 0.1.  Therefore apply a correction factor of ( 0.1 / 0.254 ) =
% 0.394.
elseif site_code == 4     % PJ
    May12 = datenum( 2010, 5, 12 ) - datenum( 2010, 1, 1 ) + 1;
    idx = find( ( year == 2010 ) & ( doy <= May12 ) );
    pcp_fixed( idx ) = pcp_fixed( idx ) * 0.394;
end


