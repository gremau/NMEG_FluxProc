%Program to read 30-min data in from flux_all files, make corrections, and
%write the corrected fluxes back to the flux_all files.  This is used only
%when the ts data are not available for time periods but the 30-min data
%are

%Written by John DeLong summer 2008

function [] = UNM_30min_flux_processor(sitecode,year,first_row,last_row)

if sitecode == 1
    site = 'GLand';
    z_CSAT = 3.2; sep2 = 0.191; angle = 28.94; h_canopy = 0.25;
        timestamp_col = 'CG';
    bad_variance_col = 'BP';
elseif sitecode == 2
    site = 'SLand';
    z_CSAT = 3.2; sep2 = 0.134; angle = 11.18; h_canopy = 0.8;
            timestamp_col = 'CG';
    bad_variance_col = 'BP';  
elseif sitecode == 3
    site = 'JSav';
    z_CSAT = 10.35; sep2 = .2; angle = 25; h_canopy = 3;
elseif sitecode == 4
    site = 'PJ';
    z_CSAT = 8.2; sep2 = .143; angle = 19.3; h_canopy = 4;
elseif sitecode == 5
    z_CSAT = 24.02; sep2 = 0.15; angle = 15.266; h_canopy = 17.428;
    site = 'PPine';
elseif sitecode == 6
    site = 'MCon';
    z_CSAT = 23.9; sep2 = 0.375; angle = 71.66; h_canopy = 16.56;
elseif sitecode == 7
    site = 'TX';
    z_CSAT = 8.75; sep2 = .2; angle = 25; h_canopy = 2.5;
elseif sitecode == 8
    site = 'TX_forest';
    timestamp_col = 'BV';
    z_CSAT = 15.24; sep2 = .11; angle = 13.79; h_canopy = 7.62;
elseif sitecode == 9
    site = 'TX_grassland';
    z_CSAT = 4; sep2 = .19; angle = 31.59; h_canopy = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up files and read in data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filename = strcat(site,'_flux_all_',num2str(year))
filein = strcat('C:\Research - Flux Towers\Flux Tower Data by Site\',site,'\',filename); % assemble path to file
datarange = strcat('BW',num2str(first_row),':','IL',num2str(last_row)); % specify what portion of spreadsheet to read in
headerrange = strcat('BW2:IL2'); % specify portion of spreadsheet that is headers

[num text] = xlsread(filein,headerrange); % read in the text in the header
headertext = text; % assign column headers to header text array

[num text]=xlsread(filein,datarange);  %does not read in first column because its text!!!!!!!!
data = num; % assign data to data array
ncol = size(data,2); % find number of columns for use in locating headers below
nrows = size(data,1);

[num text] = xlsread(filein,strcat(timestamp_col,num2str(first_row),':',timestamp_col,num2str(last_row))); % timestamps are text so read them in separately
timestamp = text; % assign timestamp array

[year month day hour minute second] = datevec(timestamp); %break timestamp into usable data and time variables

% I don't think this jday calculator always works
jday = ones(nrows,1);
jday(find(month == 1)) = day(find(month == 1));
jday(find(month == 2)) = day(find(month == 2)) + 31; % add jan days (31)
jday(find(month == 3)) = day(find(month == 3)) + 59; % add feb days (28)
jday(find(month == 4)) = day(find(month == 4)) + 90; % add mar days (31)
jday(find(month == 5)) = day(find(month == 5)) + 120; % add apr days (30)
jday(find(month == 6)) = day(find(month == 6)) + 151; % add may days (31)
jday(find(month == 7)) = day(find(month == 7)) + 181; % add jun days (30)
jday(find(month == 8)) = day(find(month == 8)) + 212; % add jul days (31)
jday(find(month == 9)) = day(find(month == 9)) + 243; % add aug days (31)
jday(find(month == 10)) = day(find(month == 10)) + 273; % add sep days (30)
jday(find(month == 11)) = day(find(month == 11)) + 304; % add oct days (31)
jday(find(month == 12)) = day(find(month == 12)) + 334; % add nov days (30)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 30-minute data vary in column and header name across sites and years, 
% so we are using this string comparison function to locate data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('Ts_Avg',headertext(i)) == 1 || strcmp('Ts_mean',headertext(i)) == 1 || strcmp('Ts_a',headertext(i)) == 1
        Ts_meanC = data(:,i); % read in in C 
        Ts_meanK = data(:,i) + 273.15; % converted to K
    elseif strcmp('wnd_dir_compass',headertext(i)) == 1 || strcmp('cmpss_dir',headertext(i)) == 1
        wind_direction = data(:,i); % read in in degrees and just written back out
    elseif strcmp('rslt_wnd_spd',headertext(i)) == 1 || strcmp('wnd_spd_a',headertext(i)) == 1
        wind_speed = data(:,i); % read in in m per s and just written back out
    elseif strcmp('cov_Ux_Ts',headertext(i)) == 1 || strcmp('cov_Ts_Ux',headertext(i)) == 1 || strcmp('Ux_Ts',headertext(i)) == 1
        cov_Ts_Ux = data(:,i); % this is cov b/w t and u
    elseif strcmp('cov_Uy_Ts',headertext(i)) == 1 || strcmp('cov_Ts_Uy',headertext(i)) == 1 || strcmp('Uy_Ts',headertext(i)) == 1
        cov_Ts_Uy = data(:,i); % this is cov b/w t and y
    elseif strcmp('cov_Uz_Ts',headertext(i)) == 1 || strcmp('cov_Ts_Uz',headertext(i)) == 1 || strcmp('Uz_Ts',headertext(i)) == 1
        cov_Ts_Uz = data(:,i); % this is cov b/w t and w
    elseif strcmp('co2_Avg',headertext(i)) == 1 || strcmp('co2_mean',headertext(i)) == 1 || strcmp('co2_a',headertext(i)) == 1
        co2_mean = data(:,i)./44; % read in in mg per m^3 but converted to mmol per m^3
    elseif strcmp('cov_Ux_co2',headertext(i)) == 1 || strcmp('cov_co2_Ux',headertext(i)) == 1 || strcmp('Ux_co2',headertext(i)) == 1
        cov_co2_Ux = data(:,i); % read in in mg per m^2 per s
    elseif strcmp('cov_Uy_co2',headertext(i)) == 1 || strcmp('cov_co2_Uy',headertext(i)) == 1 || strcmp('Uy_co2',headertext(i)) == 1
        cov_co2_Uy = data(:,i); % read in in mg per m^2 per s
    elseif strcmp('cov_Uz_co2',headertext(i)) == 1 || strcmp('cov_co2_Uz',headertext(i)) == 1 || strcmp('Uz_co2',headertext(i)) == 1
        cov_co2_Uz = data(:,i); % read in in mg per m^2 per s
    elseif strcmp('h2o_Avg',headertext(i)) == 1 || strcmp('h2o_mean',headertext(i)) == 1 || strcmp('h2o_a',headertext(i)) == 1
        h2o_Avg = data(:,i)./0.018; % read in in g per m^3 and converted to mmol per m^3
    elseif strcmp('cov_Ux_h2o',headertext(i)) == 1 || strcmp('cov_h2o_Ux',headertext(i)) == 1 || strcmp('Ux_h2o',headertext(i)) == 1
        cov_h2o_Ux = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    elseif strcmp('cov_Uy_h2o',headertext(i)) == 1 || strcmp('cov_h2o_Uy',headertext(i)) == 1 || strcmp('Uy_h2o',headertext(i)) == 1
        cov_h2o_Uy = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    elseif strcmp('cov_Uz_h2o',headertext(i)) == 1 || strcmp('cov_h2o_Uz',headertext(i)) == 1 || strcmp('Uz_h2o',headertext(i)) == 1
        cov_h2o_Uz = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    elseif strcmp('Ux_Avg',headertext(i)) == 1 || strcmp('Ux_a',headertext(i)) == 1
        umean = data(:,i);
    elseif strcmp('Uy_Avg',headertext(i)) == 1 || strcmp('Uy_a',headertext(i)) == 1
        vmean = data(:,i);
    elseif strcmp('Uz_Avg',headertext(i)) == 1 || strcmp('Uz_a',headertext(i)) == 1
        wmean = data(:,i);
    elseif strcmp('cov_Ux_Uy',headertext(i)) == 1 || strcmp('Ux_Uy',headertext(i)) == 1 
        uv = data(:,i); %cov_Ux_Uy aka 12 , 21, aka uv,vu
    elseif strcmp('cov_Uz_Ux',headertext(i)) == 1 || strcmp('cov_Ux_Uz',headertext(i)) == 1 || strcmp('Uz_Ux',headertext(i)) == 1
        uw = data(:,i); %cov_Ux_Uz aka 13 , 31, aka uw,wu
    elseif strcmp('cov_Uz_Uy',headertext(i)) == 1 || strcmp('cov_Uy_Uz',headertext(i)) == 1 || strcmp('Uz_Uy',headertext(i)) == 1
        vw = data(:,i); %cov_Uy_Uz aka 23 , 32, aka vw,wv
    elseif strcmp('press_Avg',headertext(i)) == 1 || strcmp('press_mean',headertext(i)) == 1
        press_mean = data(:,i); % read in in kPa
    elseif strcmp('RH',headertext(i)) == 1
        rH = 0.01.*data(:,i); % read in in kPa    
    end
end

uvwmean = [umean vmean wmean]; % pool winds for use below

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dry air corrections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate the partial pressure of h2o vapor. Use the sonic temperaure to
% approximate the dry air temperature. This is shown below to give a maximum
% error (for this day) in the partial pressure of 0.95 percent 
%
% Pw (KPa) = (n/V) * R_u * T * 10e-6%
%   - n/V   = LI7500 output in mmol/m^3 wet air
%   - R_u   = 8.314 J/mol K
%   - T     = dry air temp in K
%   - 10e-6 = converts mmol to mol and Pa to KPa
PW = 1e-6.*8.314.*h2o_Avg.*Ts_meanK;
 
% calculate dry air temperature from sonic temperature using Gaynor eq:
Td = Ts_meanK./(1 + 0.32.*PW./press_mean);

% Make an iteration on the calculation of Pw, using the dry air temperature
PW = 1e-6.*8.314.*h2o_Avg.*Td;

% recalculate dry temperature w/new pressure
TD = Ts_meanK./(1 + 0.321.*PW./press_mean);
    
% calculate wet air molar density (mol wet air / m^3 wet air)
%  (n/V)_a = P/R_u/T  
%          = 1e3/8.314*P/T
rhomtotal  = (1e3./8.314).*press_mean./TD;

% calculate mol fraction of water vapor (mmol h2o/mol moist air) in wet air
h2owet = h2o_Avg./rhomtotal;

% calculate mol fraction of co2 (umol co2/mol moist air) in moist air
co2wet = 1e3.*co2_mean./rhomtotal; 

% Assume wet air and the partial pressure of dry air is the output of the
% irga minus the vapor pressure
Pa = press_mean - PW;

% calculate dry air molar density (mol dry air / m^3 wet air)%
%  (n/V)_a = Pa/R_u/T%  
%          = 1e3 / 8.314 * Pa /T
rhomdry = (1e3/8.314).*Pa./TD;
rhomwater = rhomtotal - rhomdry;
rhotot = rhomdry.*29./1000 + rhomwater.*18./1000;

% calculate mol fraction of water vapor (mmol h2o/mol dry air) in dry air
h2odry = h2o_Avg./rhomdry;

% calculate mol fraction of co2 (umol co2/mol dry air) in dry air
co2dry = 1e3.*co2_mean./rhomdry;

% calculate relative humidity
meanTinC = TD-273.15;
es = 0.611 .* exp(17.502.*meanTinC./(meanTinC + 240.97));
rH = PW./es;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unit corrections for co2 and h2o
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

co2_mean_out = co2_mean.*1000./rhomdry;
h2o_Avg_out = h2o_Avg./rhomdry;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Planar rotation, massman, and wpl corrections, run each row at a time
% through a for looop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:nrows

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1 Planar rotation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    USTAR(i) = sqrt(sqrt(uw(i)^2 + vw(i)^2)); % calculate unrotated ustar
    speed(i) = sqrt((umean(i)^2) + (vmean(i)^2) + (wmean(i)^2));
    
    % enter planar coefficients broken down by various factors
    if sitecode == 1
        if speed(i) >= 5
            b0 = 0.152528949;
            b1 = -0.00082989;
            b2 = 0.002517913;
            k(1) = 0.000829887;
            k(2) = -0.002517904;
            k(3) = 0.999996486;
        else
            b0 = 0.025221417;
            b1 = 0.011187435;
            b2 = 0.005053646;
            k(1) = -0.011186592;
            k(2) = -0.005053265;
            k(3) = 0.999924659;
        end
        
    elseif sitecode == 2 % these are for shrubland
        if speed(i) >= 5
            b0 = 0.153116813;
            b1 = 0.016330935;
            b2 = -0.018475587;
            k(1) = -0.016325972;
            k(2) = 0.018469973;
            k(3) = 0.999696115;
        else
            b0 = 0.046197667;
            b1 = 0.024851316;
            b2 = -0.018716161;
            k(1) = -0.024839298;
            k(2) = 0.01870711;
            k(3) = 0.99951641;
        end

    elseif sitecode == 3 % these are for juniper-savanna
        
        if speed(i) >= 5
            b0 = 0.081104622;
            b1 = -0.005862329;
            b2 = -0.015991732;
            k(1) = 0.005861479;
            k(2) = 0.015989413;
            k(3) = 0.99985498;
        else
            b0 = 0.02499662;
            b1 = -0.002888242;
            b2 = -0.013527774;
            k(1) = 0.002887966;
            k(2) = 0.01352648;
            k(3) = 0.999904342;
        end

    elseif sitecode == 4
        if speed(i) >= 5
            b0 = 0.152528949;
            b1 = -0.00082989;
            b2 = 0.002517913;
            k(1) = 0.000829887;
            k(2) = -0.002517904;
            k(3) = 0.999996486;
        else
            b0 = 0.025221417;
            b1 = 0.011187435;
            b2 = 0.005053646;
            k(1) = -0.011186592;
            k(2) = -0.005053265;
            k(3) = 0.999924659;
        end
        
    elseif sitecode == 5
        if speed(i) >= 5            
            b0 = -0.201583097;
            b1 = 0.039964498;
            b2 = 0.042832557;
            k(1) = -0.039896099;
            k(2) = -0.04275925;
            k(3) = 0.998288509;
        else
            b0 = 0.008839609;
            b1 = 0.020435491;
            b2 = 0.025895171;
            k(1) = -0.020424381;
            k(2) = -0.025881093;
            k(3) = 0.999456359;
        end
            
    elseif sitecode == 6
        if speed(i) >= 5            
            b0 = 0.259543188;
            b1 = -0.004703906;
            b2 = 0.014195398;
            k(1) = 0.00470338;
            k(2) = -0.014193811;
            k(3) = 0.999888201;
        else
            b0 = 0.079961079;
            b1 = -0.024930957;
            b2 = 0.044809422;
            k(1) = 0.024898245;
            k(2) = -0.044750626;
            k(3) = 0.998687869;
        end
        
    elseif sitecode == 7 && year_ts(1) == 2004 % TX freeman
        
%     elseif sitecode == 7 && year_ts(1) == 2005 && month_ts(1) < 5 % use one set of values for
%         % first seven months, not separated out by windspeed, then use the same values as 2006         
%         b0 = 0.024873451;
%         b1 = 0.002279925;
%         b2 = 0.002839777;
%         k(1) = -0.00227991;
%         k(2) = -0.002839758;
%         k(3) = 0.999993369;
% 
%     elseif sitecode == 7 && year_ts(1) == 2005 && month_ts(1) >= 5 % latter half of 2005
%         % use same as 2006
%         b0 = 0.064455667;
%         b1 = 0.001620006;
%         b2 = 0.004444167;
%         k(1) = -0.001619988;
%         k(2) = -0.004444117;
%         k(3) = 0.999988813;            
% 
%     elseif sitecode == 7 && year_ts(1) == 2006 % all of 2006 looks pretty consistent, use one set of data
%         b0 = 0.064455667;
%         b1 = 0.001620006;
%         b2 = 0.004444167;
%         k(1) = -0.001619988;
%         k(2) = -0.004444117;
%         k(3) = 0.999988813;
% 
%     elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) < 3 % first 2 months of 2007
%         % use same as 2006
%         b0 = 0.064455667;
%         b1 = 0.001620006;
%         b2 = 0.004444167;
%         k(1) = -0.001619988;
%         k(2) = -0.004444117;
%         k(3) = 0.999988813;            
% 
%     elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) == 3 || month_ts(1) == 4
%         % March and April 2007 has their own set of coefficients
%         b0 = 0.064455667;
%         b1 = 0.001620006;
%         b2 = 0.004444167;
%         k(1) = -0.001619988;
%         k(2) = -0.004444117;
%         k(3) = 0.999988813;       
% 
%     elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) >= 5 %after that, use a new set of
%         % coefficients calculated with only the data in the last 6 months of 2007 
%         b0 = -0.007905583;
%         b1 = 0.012986531;
%         b2 = -0.000801434;
%         k(1) = -0.012985432;
%         k(2) = 0.000801367;
%         k(3) = 0.999915365;
    


    elseif sitecode == 8 % TX_forest
        if wind_direction(i) >= 0 && wind_direction(i) <= 60
            b0 = 0.224838191;
            b1 = 0.051189541;
            b2 = -0.031249502;
            k(1) = -0.046221527;
            k(2) = 0.014738558;
            k(3) = 0.998206387;  
        elseif wind_direction(i) > 60 && wind_direction(i) <= 210
            b0 = 0.094117303;
            b1 = 0.03882402;
            b2 = 0.011170481;
            k(1) = -0.038792377;
            k(2) = -0.011161377;
            k(3) = 0.999184955;  
        elseif wind_direction(i) > 210 && wind_direction(i) <= 270
            b0 = 0.070326918;
            b1 = -0.026290012;
            b2 = -0.009114614;
            k(1) = 0.02627984;
            k(2) = 0.009111088;
            k(3) = 0.999613104;  
        elseif wind_direction(i) > 270 && wind_direction(i) <= 360
            b0 = 0.215938294;
            b1 = 0.123314215;
            b2 = 0.000787889;
            k(1) = -0.122387155;
            k(2) = -0.000781966;
            k(3) = 0.992482127; 
        end    

    elseif sitecode == 9 % TX_grassland
        b0 = 0.017508885;
        b1 = -0.005871475;
        b2 = 0.017895419;
        k(1) = 0.005870434;
        k(2) = -0.017892246;
        k(3) = 0.999822687;

    end

    % determine unit vectors i,j (parallel to new coordinate x and y axes)
    j(i,:) = cross(k,uvwmean(i,:));
    j(i,:) = j(i,:)/(sum(j(i,:).*j(i,:)))^0.5;
    l(i,:) = cross(j(i,:),k); % changed i to l here to be compatible with for loop

    % rotating co2 flux
    C(i,:) = [cov_co2_Ux(i) cov_co2_Uy(i) cov_co2_Uz(i)];
    uxc_rot(i) = sum(l(i,:).*C(i,:));
    vxc_rot(i) = sum(j(i,:).*C(i,:));
    wxc_rot(i) = sum(k.*C(i,:));
    flux_co2(i) = wxc_rot(i); % in mg per m^2 s, original covariance only rotated
    
    % rotating sensible heat flux
    H(i,:) = [cov_Ts_Ux(i) cov_Ts_Uy(i) cov_Ts_Uz(i)];
    uxT_rot(i) = sum(l(i,:).*H(i,:));
    vxT_rot(i) = sum(j(i,:).*H(i,:));
    wxT_rot(i) = sum(k.*H(i,:));
    wTrot_dry(i) = wxT_rot(i)/(1 + 0.321*PW(i)/press_mean(i)); % take vertical component and convert it to dry air
    cpd = 1005;
    HSdry(i) = 28.966/1000*rhomdry(i)*cpd*wTrot_dry(i);
    HSwet(i) = 28.966/1000*rhomdry(i)*cpd*wxT_rot(i);
    HSwetwet(i) = 28.966/1000*rhomtotal(i)*cpd*wxT_rot(i);
    
    % rotating water and calculating latent heat flux from that
    W(i,:) = [cov_h2o_Ux(i) cov_h2o_Uy(i) cov_h2o_Uz(i)];
    uxh2o_rot(i) = sum(l(i,:).*W(i,:));
    vxh2o_rot(i) = sum(j(i,:).*W(i,:));
    wxh2o_rot(i) = sum(k.*W(i,:));
    flux_h2o(i) = wxh2o_rot(i); % flux still in mmol per m^2 per s
    Lv = (2.501-0.00237*(TD(i)-273.15))*10^3; % calculate latent heat of vaporization
    flux_HL(i) = 18.016/1000*Lv*wxh2o_rot(i); % calculate latent heat flux from water flux and Lv
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2 Massman
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % calculate z and L
    z = z_CSAT/(0.7*h_canopy);
    L = -((USTAR(i))^3*TD(i))/(0.4 * 9.81 * cov_Ts_Uz(i));
    
    % CALL MASSMAN
    if i == 633
        i
    end
    [X_op_C,X_op_H,X_T,zoL]= UNM_massman(z,L,uvwmean(i,:),sep2,angle);

    HSdry_massman(i) = HSdry(i)./X_T; 
    flux_h2o_massman(i) = flux_h2o(i)/X_op_H; % flux still in mmol per m^2 per s
    flux_co2_massman(i) = (flux_co2(i)/X_op_C)*1000/44; %flux still in mg per m^2 s converted to umol per m^2 s

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3 WPL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % calculate densities in grams/m^3 moist air
    rhoa(i) = rhomdry(i)*28.966;
    rhov(i) = (rhomtotal(i)-rhomdry(i))*18.016;
    rhoc(i) = co2_mean(i)*44/1000;
    rhoa_out(i) = rhoa(i)/28.966;
    rhov_out(i) = rhov(i)/18.016;
    rhoc_out(i) = rhoc(i)/44;
    
    mu = 28.966/18.016; % g per mol divided by g per mol >> unitless
    sigma = rhov(i)/rhoa(i); % g per m^3 divided by g per m^3 >> unitless
    
    % make WPL corrections for CO2 fluxes
    Fc_raw(i) = flux_co2(i).*1000./44; % convert rotated co2 flux back to umol per m^3
    Fc_water_term(i) = mu*rhoc(i)/rhoa(i)*flux_h2o(i)*0.018*(10^6/44);
    Fc_heat_term_massman(i) = (1+mu*sigma)*rhoc(i)/TD(i)*HSdry_massman(i)/28.966*1000/cpd/rhomdry(i)*(10^6/44);
    Fc_corr_massman_ourwpl(i) = flux_co2_massman(i) + Fc_water_term(i) + Fc_heat_term_massman(i);
    
    % make WPL corrections for H2O fluxes    
    E_water_term(i) = (1+mu*sigma)*flux_h2o(i)*0.018*(10^3/18.016);
    E_heat_term_massman(i) = (1+mu*sigma)*rhov(i)/TD(i)*wTrot_dry(i)*(10^3/18.016);
    %flux_h20_massman_wpl_heat(i) = (1+mu*sigma)*rhov(i)/TD(i)*HSdry_massman(i)/28.966*1000/cpd/rhomdry(i)*(10^3/18.016);
    E_corr_massman(i) = E_water_term(i) + E_heat_term_massman(i);
    
    % make WPL corrections for latent heat fluxes
    flux_HL_massman(i) = 18.016/1000*Lv*flux_h2o_massman(i);
    flux_HL_wpl_massman(i) = 18.016/1000*Lv*E_corr_massman(i);
    
    % need this for writing out to spreadsheet - see below
    blank(i) = NaN;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect things to write out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DATAOUT = [jday,blank',umean,vmean,wmean,Ts_meanC,TD,wind_direction,wind_speed,rH,blank',blank',blank',blank',blank',...
     blank',blank',blank',blank',blank',USTAR',blank',blank',blank',co2_mean_out,blank',blank',blank',blank',h2o_Avg_out,blank',...
     Fc_raw',flux_co2_massman',Fc_water_term',Fc_heat_term_massman',Fc_corr_massman_ourwpl',...
     flux_h2o',flux_h2o_massman',E_water_term',E_heat_term_massman',E_corr_massman',blank',...
     HSdry',HSwet',HSwetwet',HSdry_massman',...
     flux_HL',flux_HL_massman',flux_HL_wpl_massman',rhoa_out',rhov_out',rhoc_out'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write fluxes back out to flux_all file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fileout = filein;
xlswrite (fileout,DATAOUT,'master',strcat('J',num2str(first_row)));
disp('Wrote to flux_all file');
