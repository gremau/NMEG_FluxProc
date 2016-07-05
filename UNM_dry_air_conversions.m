function   [CO2,H2O,PW,TOUT,RHO,IRGADIAG,IRGAP,P,removedco2]= ...
            UNM_dry_air_conversions(co2,h2o,P,T,num,sitecode)
%
% 10-15-2001 - Fix the pressure signal here if it is spiking - this
%             could be the cause of some of the spikes we are
%             seeing - a lot of half hour intervals are showing
%             hundreds of spikes
%  
% 3-22-2001 - Add despiking to temperature signal because it is
%             required for drying equations. The IRGADIAG also
%             modified to be bad data when Sonic T is spiking
%
% converts from LI7500 output 
%
% INPUTS: co2 - mmol/m^3 wet air
%         h2o - mmol/m^3 wet air 
%         P   - total pressure (KPa)
%         Ts  - sonic temperature (C or K)
%
% OUTPUTS: 
%
%  CO2 - 3XN array 
%      ROW 1: co2 in umol/mol dry air 
%      ROW 2: co2 in umol/mol wet air
%      ROW 3: co2 in umol/m^3 wet air
%
%  H2O - 3XN array 
%      ROW 1: h2o in mmol/mol dry air  
%      ROW 2: h2o in mmol/mol wet air
%      ROW 3: H2O in mmol/m^3 wet air
%
%  PW - 1XN - partial pressure of water vapor (kPa)  
%        1/15/2001 -  PW is output in KPa, not Pa !!!
%
%  RHO - 3XN array 
%      ROW 1: mol dry air/m^3 wet air 
%      ROW 2: mol wet air/m^3 wet air 
%      ROW 3: Kg  moist air/m^3 moist air
% 
%  TOUT - 2XN - temperatures
%      ROW 1: measured sonic temperature (C)
%      ROW 2: dried sonic temperature (K) 
% 
%  IRGADIAG - 2XN - diagnostic variable for the open path irga for each sample
%             contains a 1 if the measurement is good and a zero for a spike

% - Convert temperature if sent in Celcius

if median(T)<100
    T = T + 273.15;
end

%%%%%%%%%%%%%%%%%%%%%%%%%
% DESPIKE
%%%%%%%%%%%%%%%%%%%%%%%%%
%this puts median values in for P in cases where pressure instrument drops out
P(find(P==0)) = median(P)*ones(size(find(P==0)));

[ico2,removedco2] = UNM_despike(co2,6,10,20,'CO2',1);
co2(find(~ico2)) = NaN*ones(size(find(~ico2))); %NaN's in co2 vector when ic02=0      
[ih2o,removedh2o] = UNM_despike(h2o,6,5,2000,'H2O',2);
h2o(find(~ih2o)) = NaN*ones(size(find(~ih2o)));           
[it,removedt]   = UNM_despike(T,6,253,323,'T',3);
T(find(~it))     = NaN*ones(size(find(~it)));

if sitecode == 1 || sitecode == 2 || sitecode == 11
    [ip,removedp]   = UNM_despike(P,6,75,86,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 3
    [ip,removedp]   = UNM_despike(P,6,75,85,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 4  || sitecode == 14
    [ip,removedp]   = UNM_despike(P,6,75,80,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 5
    [ip,removedp]   = UNM_despike(P,6,72,78,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 6
    [ip,removedp]   = UNM_despike(P,6,65,75,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 7 || sitecode == 8 || sitecode == 9
    [ip,removedp]   = UNM_despike(P,6,65,101,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 10
    [ip,removedp]   = UNM_despike(P,6,70,85,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
elseif sitecode == 13 % FIXME - Guessing here for new site, should check it
    [ip,removedp]   = UNM_despike(P,6,70,77,'P',4);
    P(find(~ip))    = NaN*ones(size(find(~ip)));
end

IRGADIAG = [ico2&it ih2o&it ip&it];

%  The press channel sometimes returns a (nonphysical) zero or it
%  goes to 98.5 kpa - interpolate these samples linearly - dont
%  do anything with this for now

%[ip]=despike(P,6,96,103,'Pressure');

%P=interp1(find(ip),P(find(ip)),[1:length(P)]);

% calculate the partial pressure of h2o vapor. Use the sonic
% temperaure to approximate the dry air temperature. This is
% shown below to give a maximum error (for this day) in the
% partial pressure of 0.95 percent 
%
% Pw (KPa) = (n/V) * R_u * T * 1.0e-6
%
%   - n/V   = LI7500 output in mmol/m^3 wet air
%   - R_u   = 8.314 J/mol K
%   - T     = dry air temp in K
%   - 1.0e-6 = converts mmol to mol and Pa to KPa
IRGAP = mean(P);
PW = (1.0e-6*8.314) .* h2o .* T;

% calculate dry air temperature from sonic temperature 
% using Gaynor eq:

Td    = T ./ (ones(size(T)) + 0.321 .* PW ./ P);

% Make an iteration on the calculation of Pw, using the
% dry air temperature

PW    = (1.0e-6*8.314) .* h2o .* Td;

% recalculate dry temperature w/new pressure

TD    = T ./ (ones(size(T)) + 0.321 .* PW ./ P);

% calculate wet air molar density (mol wet air / m^3 wet air)
%
%  (n/V)_a = P/R_u/T
%  
%          = 1e3 / 8.314 * P /T

rhomtotal    = (1.0e3 / 8.314) .* P ./ TD;

% calculate mol fraction of water vapor (mmol h2o/mol moist air)
% in wet air

h2owet = h2o ./ rhomtotal;

% calculate mol fraction of co2 (umol co2/mol moist air)
% in moist air

co2wet = 1.0e3 .* co2 ./ rhomtotal;

% calculate partial pressure of dry air - This is where
% the fortran code differs from mine.  That code assumes 
% the open path irga outputs mols / m^3 of DRY air;
% however, i think (and Licor confirmed) that it is 
% mols / m^3 of wet air. Since i assume wet air,
% the partial pressure of dry air is the output of the
% irga minus the vapor pressure

Pa = P - PW;

% calculate dry air molar density (mol dry air / m^3 wet air)
%
%  (n/V)_a = Pa/R_u/T
%  
%          = 1e3 / 8.314 * Pa /T

rhomdry = (1.0e3 / 8.314) .* Pa ./ TD;

rhomwater = rhomtotal - rhomdry;

rhotot = rhomdry .* (29/1000) + rhomwater .* (18/1000);

% calculate mol fraction of water vapor (mmol h2o/mol dry air)
% in dry air

h2odry = h2o ./ rhomdry;

% calculate mol fraction of co2 (umol co2/mol dry air)
% in dry air

co2dry = 1.0e3 .* co2 ./ rhomdry;

% calculate dry air density Kg dry air/m^3 moist air

CO2  = [co2dry co2wet co2*1000];
H2O  = [h2odry h2owet h2o];
RHO  = [rhomdry rhomtotal rhotot];
TOUT = [T TD];

