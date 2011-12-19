function pcp_fixed = fix_incorrect_precip_factors(site_code, year, doy, pcp_in)
% FIX_INCORRECT_PRECIP_FACTORS - several sites had incorrect conversion factors
% in their datalogger programs at various times.  This code fixes those
% problems.
%  
% Timothy W. Hilton, UNM, Nov 2011

pcp_fixed = pcp_in;  %initialize pcp_fixed to original values

%%-------------------------
%% fix GLand
if site_code == 1     % Gland
    idx = intersect( year, 2009:2011 );
    pcp_fixed = pcp_in * 0.394;

%%-------------------------
%% fix SLand
elseif site_code == 2      %SLand
    idx = find( year == 2011 );
    pcp_fixed( idx ) = -9999;

%%-------------------------
%% fix PJ
elseif site_code == 4     % PJ
    May12 = datenum( 2010, 5, 12 ) - datenum( 2010, 1, 1 ) + 1;
    idx = find( ( year == 2010 ) & ( doy <= May12 ) );
    pcp_fixed( idx ) = pcp_fixed( idx ) * 0.394;
end


