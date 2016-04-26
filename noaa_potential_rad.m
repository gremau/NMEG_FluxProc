function radPotDay = noaa_potential_rad( latitude, longitude, ...
                                               date)
% Calculates and returns 30 min potential radiation in W/m^2 for
% specified location and date. Based on NOAA solar model.
%
% All calculations are based on those supplied by NOAA in the excel
% worksheet (one day version) found at this website:
%
%   http://www.esrl.noaa.gov/gmd/grad/solcalc/
%
% Gregory E. Maurer, UNM, March 2015

toa_wm2 = 1365; % Top of atmosphere radiation (direct)

% Make a 1 day, 30 minute datenum array
date30min = ( date + 1/48 : 1/48 : date + 1 )';

% Get the hourly NOAA solar calculations for this day
solCalcs = noaa_solar_calcs( latitude, longitude, date30min );
% Extract solar zenith angle
zenithAngle = solCalcs.solarZenithAngleDeg;

% Calculate potential radiation
radPot = cosd( zenithAngle ) .* toa_wm2;
radPot( radPot < 0 ) = 0;

% Return time of day and potential radiation
radPotDay = [ mod( date30min, floor( date30min )) * 24, radPot ];
radPotDay( radPotDay( :, 1 ) == 0, 1 ) = 24;

end


