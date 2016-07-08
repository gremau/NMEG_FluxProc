function Rad_out = model_rad_in( sitecode, dt, Tair, press, rH, sw_in )

% Much of this method for all-sky longwave irradiance is taken from this 
% paper:
%
% Crawford, Todd M., and Claude E. Duchon. "An improved parameterization 
% for estimating effective atmospheric emissivity for use in calculating 
% daytime downwelling longwave radiation." Journal of Applied Meteorology 
% 38.4 (1999): 474-480.
%
% This is itself an all-sky formulation of the Brutsaert 1975 
% parameterization of atmospheric emmissivity, but with adaptations. 
% For a comparison of the merits of different clear-sky and all-sky 
% longwave models see:
% 
% Kjærsgaard, Jeppe Hvelplund, F. L. Plauborg, and Søren Hansen. 
% "Comparison of models for calculating daytime long-wave irradiance using
% long term data set." Agricultural and forest Meteorology 143.1 (2007): 
% 49-63.

% First calculate clear sky irradiance

% Effective solar constant -  could be modified based on seasonally 
% changing solar distance, but I am ignoring this.
Io = 1365;

% Calculate cosine of solar Zenith angle - this part seems a little strange
% in the Crawford Duchon paper.
conf = parse_yaml_config(sitecode, 'SiteVars');
solcalcs = noaa_solar_calcs(conf.latitude, conf.longitude, dt);
% Solcalcs contains, in order, [datenums, solarNoonLST, sunriseTimeLST, 
%                               sunsetTimeLST, solarZenithAngleDeg, 
%                               sunDeclinDeg, hourAngleDeg ];

% Here we are not calculating cosine of max zenith angle, but actual angle
% at that time of day?
cosZ = ( sind(conf.latitude) .* sind(solcalcs.sunDeclinDeg) ) + ...
    (cosd(conf.latitude) .* cosd(solcalcs.sunDeclinDeg) .* ...
    cosd(solcalcs.hourAngleDeg));

cosZ(cosZ < 0) = 0;
% Try with calculated hour angle - not working
% H = (pi/12).*( 24 * ( solcalcs( :,2 )-( solcalcs(:,1) - floor(solcalcs(:,1) ))));
%cosZ = ( sind(conf.latitude) .* sind(solcalcs(:,6)) ) + ...
%    (cosd(conf.latitude) .* cosd(solcalcs(:,6)) .* cosd(H));

% Calculate TrTpg transmission coefficients (a combined empirical one - 
% See Atwater and Brown 1974)

% Optical air mass at 1013 mb pressure
m = 35 * (cosZ .* (1224 * cosZ.^2 + 1)).^(-1/2);
%m = 35 * ((1224 * cosZ.^2 + 1)./cosZ).^(1/2)
% Combine into one coefficient
TrTpg = 1.021 - 0.084 * ( m .* ( 0.000949 * press + 0.051 )).^(1/2);

% Calculate Tw transmission coefficient from McDonald 1960

% First get gamma value from Smith 1966 for latitude band 30-40
G = 3.0;
% Calculate dewpoint using the Magnus formula and the Bolton 1980 constant
% set (a, b, c). See Wikipedia Dew point page
a = 6.112;
b = 17.67;
c = 243.5;
gammaDp = log(rH/100) + ((b  * Tair)./(c + Tair));
Td = (c * gammaDp)./(b - gammaDp); % Dewpoint in C
Tdf = (Td * 1.8) + 32; % Convert to F
% Precipitable water
u = exp( 0.1133 - log( G + 1 ) + 0.0393 * Tdf);
% Put together 
Tw = 1 - 0.077 * ( u .* m ).^0.3;

% Houghton 1954 and Meyers and Dale 1983

Ta = 0.935.^m;

% Now put these together into modeled clear sky SW_IN
I = Io .* cosZ .* TrTpg .* Tw .* Ta;

% Take the ratio of measured to clear-sky irradiance and calculate a
% cloudiness fraction
s = sw_in./I; 
s(s>1) = 1; % Make sure ratio stays at or below 1
clf = 1 - s;

% Crawford and Duchon all sky longwave

% Get months for seasonal component
months = datevec(dt);
months = months(:,2);
% Constants/empirically derived coefficients
stefboltz = 5.670367e-8;
A = 1.22;
B = 0.06;
% Get vapor pressure using priestley taylor method and bolton constant set
% see http://agsys.cra-cin.it/tools/evapotranspiration/help/Actual_vapor_pressure.html
ea = a * exp(( b*Td )./( Td+c ));
% Convert air T to Kelvin
TairK = Tair + 273.15;
% Now calculate Logwave incoming radiation
clsky_e = (A + B .* ( sin( (months+2).*(pi/6) ))).*(ea./TairK).^(1/7);
allsky_e = clf + ( 1-clf ) .* clsky_e;
Lio = allsky_e .* stefboltz .* TairK.^4;

% Ditch values above 420 and less than 50
Lio( Lio > 450 | Lio < 50 ) = nan;

Rad_out = [I, Lio];

