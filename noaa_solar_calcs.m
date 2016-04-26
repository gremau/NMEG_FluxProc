function solarCalcs = noaa_solar_calcs( latitude, longitude, ...
                                               datenums )
% Calculates and returns solar noon and theoretical sunrise/sunset time for
% specified location and dates. Based on NOAA solar model.
%
% All calculations are based on those supplied by NOAA in the excel
% worksheet (one year version) found at this website:
%
%   http://www.esrl.noaa.gov/gmd/grad/solcalc/
% 
% Another useful reference and implementation is the 'SolarAzEl.m' 
% function (included in the MatlabGeneralUtilites directory). It is based
% on information here:
%
%   http://stjarnhimlen.se/comp/tutorial.html#5
%
% Gregory E. Maurer, UNM, February 2015

dates = datevec( datenums );

localtime = 12;
tzone = -7;
year = unique( dates( :, 1 ));
month = dates( :, 2 );
day = dates( :, 3 );
hours = dates( :, 4 );
min = dates( :, 5 );
%sec = dates( :, 6 );

% FIXME - need a better way to ensure correct input/output
if length( datenums ) == 48 && sum( [ hours ; min ] ) > 0
    dectime = datenums - floor( datenums ); % time past local midnight
    % Should we be adding dectime here?
    julDayNum = ( datenums - datenum( 1900, 1, -1 )) + ...
        2415018.5 - ( tzone/24 );
else 
    %dectime = localtime/24; % time past local midnight;
    dectime = datenums - floor( datenums ); % time past local midnight
    % Should we be adding dectime here?
    julDayNum = ( datenums - datenum( 1900, 1, -1 )) + ...
        2415018.5 + dectime - ( tzone/24 );
end

% Functions to convert between radians and degrees
    function r = radians( degs )
        r = ( degs .* pi ) ./ 180;
    end
    function d = degrees( rads )
        d = rads .* 180 ./ pi;
    end

% Calculate julian day from the date.
% Below is the version taken from the excel spreadsheet. This only works
% for dates after 1900. It would be good to switch to a better method,
% such as:
% 
% http://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
% or:
% http://aa.usno.navy.mil/faq/docs/JD_Formula.php
%
% There might be some discrepancy between excel and matlab. Thus the 
% negative 1900/1/-1 datenum call.


julCentury = ( julDayNum - 2451545 ) ./  36525 ;

geomMeanLongSunDeg = mod( 280.46646 + julCentury .* ...
    ( 36000.76983 + julCentury .* 0.0003032 ), 360 );

geomMeanAnomSunDeg = 357.52911 + julCentury .* ...
    ( 35999.05029 - 0.0001537 .* julCentury );

eccentEarthOrbit = 0.016708634 - julCentury .* ...
    (4.2037e-05 + 1.267e-07 .* julCentury );

sunEqnOfCtr = sin( radians( geomMeanAnomSunDeg )) .* ...
    ( 1.914602 - julCentury .* ( 0.004817 + 1.4e-05 .* julCentury )) + ...
    sin( radians( 2 .* geomMeanAnomSunDeg )) .* ...
    ( 0.019993-0.000101 .* julCentury ) + ...
    sin( radians( 3 .* geomMeanAnomSunDeg)) .* 0.000289 ;

sunTrueLongDeg = geomMeanLongSunDeg + sunEqnOfCtr;

sunTrueAnomDeg = geomMeanAnomSunDeg + sunEqnOfCtr;

sunRadVectorAUs = ( 1.000001018 .* ...
    ( 1 - eccentEarthOrbit .* eccentEarthOrbit )) ./ ...
    ( 1 + eccentEarthOrbit .* cos( radians( sunTrueAnomDeg )));

sunAppLongDeg = sunTrueLongDeg - 0.00569 - 0.00478 .* ...
    sin( radians( 125.04 - 1934.136 .* julCentury ));

meanObliqEclipticDeg = 23 + ( 26 + (( 21.448 - julCentury .* ...
    ( 46.815 + julCentury .* ( 0.00059 - julCentury .* 0.001813 )))) ./ ...
    60 ) ./60;

obliqCorrDeg = meanObliqEclipticDeg + 0.00256 .* ...
    cos( radians( 125.04 - 1934.136 .* julCentury ));

sunRtAscenDeg = degrees( atan2( cos( radians( sunAppLongDeg )), ...
    cos( radians( obliqCorrDeg )) .* sin( radians( sunAppLongDeg ))));

sunDeclinDeg = degrees( asin( sin( radians( obliqCorrDeg )) .* ...
    sin( radians( sunAppLongDeg ))));

varY = tan( radians( obliqCorrDeg ./ 2 )) .* ...
    tan( radians( obliqCorrDeg ./ 2 ));

eqnOfTimeMin = 4 .* degrees( varY .* ...
    sin( 2 .* radians( geomMeanLongSunDeg )) - 2 .* ...
    eccentEarthOrbit .* sin( radians( geomMeanAnomSunDeg )) + 4 .* ...
    eccentEarthOrbit .* varY .* sin( radians( geomMeanAnomSunDeg )) .* ...
    cos( 2 .* radians( geomMeanLongSunDeg )) - 0.5 .* varY .* varY .* ...
    sin( 4 .* radians( geomMeanLongSunDeg )) - 1.25 .* eccentEarthOrbit .* ...
    eccentEarthOrbit .* sin( 2 .* radians( geomMeanAnomSunDeg )));

HASunriseDeg = degrees( acos( cos( radians( 90.833 )) ./ ...
    ( cos( radians( latitude )) .* cos( radians( sunDeclinDeg ))) - ...
    tan( radians( latitude )) * tan( radians( sunDeclinDeg ))));

solarNoonLST = ( 720 - 4 * longitude - eqnOfTimeMin + tzone * 60) / 1440;

sunriseTimeLST = ( solarNoonLST .* 1440 - HASunriseDeg .* 4) / 1440;

sunsetTimeLST = ( solarNoonLST .* 1440 + HASunriseDeg .* 4) / 1440;

sunlightDurationMin = 8 * HASunriseDeg;

trueSolarTimeMin = mod( dectime .* 1440 + eqnOfTimeMin + 4 .* ...
    longitude - 60 .* tzone, 1440);

hourAngleDeg = trueSolarTimeMin / 4 - 180;
testST = trueSolarTimeMin / 4 < 0;
hourAngleDeg( testST ) = trueSolarTimeMin( testST ) / 4 + 180;

solarZenithAngleDeg = degrees( acos( sin( radians( latitude )) .* ...
    sin( radians( sunDeclinDeg )) + cos( radians( latitude )) .* ...
    cos( radians( sunDeclinDeg )) .* cos( radians( hourAngleDeg ))));

solarElevationAngleDeg = 90 - solarZenithAngleDeg;

% approxAtmosphericRefractionDeg = " if(AE2>85,0,if(AE2>5,58.1/tan(radians(AE2))-0.07/power(tan(radians(AE2)),3)+8.6e-05/power(tan(radians(AE2)),5),if(AE2>-0.575,1735+AE2*(-518.2+AE2*(103.4+AE2*(-12.79+AE2*0.711))),-20.772/tan(radians(AE2)))))/3600 "

% solarElevCorrForAtmRef= solarElevationAngleDeg + AF2

% solarAzimuthAngleDegCwFromN = " if(AC2>0,mod(degrees(acos(((sin(radians($B$2))*cos(radians(AD2)))-sin(radians(T2)))/(cos(radians($B$2))*sin(radians(AD2)))))+180,360),mod(540-degrees(acos(((sin(radians($B$2))*cos(radians(AD2)))-sin(radians(T2)))/(cos(radians($B$2))*sin(radians(AD2))))),360)) "


% Return a table of values
solarCalcs = table( datenums, solarNoonLST, sunriseTimeLST, sunsetTimeLST, ...
    solarZenithAngleDeg, sunDeclinDeg, hourAngleDeg );
end

