%function [CO2OUT,H2OOUT,FCO2,FH2O,HSENSIBLE,HLATENT,RHOM,Lv,COVCHT,AGCSTATS]=flux7500marcy(uvw,SONDIAG,CO2,H2O,TD,RHO,irgadiag,flag);
function [CO2OUT,H2OOUT,FCO2,FH2O,HSENSIBLE,HLATENT,RHOM,TDRY,OKNUM,zoL]=flux7500freeman_lag(year_ts,month_ts,uvw,uvwmean,USTAR,SONDIAG,CO2,H2O,TD,RHO,idiag,irgadiag,rotation,site,sitecode,num,PWATER,uvwmeanrot,hsout,IRGAP,speed,coefficients);

%ORIGFLUXLAG       LAGCO2,LAGH2O,

%jan 31 2002 - adding linear detrend to the 7500 calculation, so we
%can look at the effect of the detrend on the fluxes.  The flag
%input is no longer an 'agc' option because we will always
%calculate the agc statistics.  Instead, it can have a value of
%'detrend' in which case we will linear detrend the 0 MINUTE AVGD
%WEBB CORRECTION CO2 AND H2O FLUX, ONLY!!!! ALL OTHER TERMS
%INCLUDING HEAT FLUXES AND INSTANTANEOUS WEBB CORRECTIONS ARE NOT
%DETRENDED! 
%
% jan-16-2002 - fixed a few mistakes in calculating the Webb
% corrections based on averaged data, not sample by sample. 1) The 
%  covariances going into these equations were being detrended, so
%  the detrending was removed - note the sample by sample fluxes
%  are ok, there was no detrending done. 2)  The wT covariance that
%  goes into the averaged Webb equations was using the sonic
%  temperature instead of the dry temperature. 3) The mean
%  temperature going into the Webb equation (averaged) was using a
%  combination of moist and dry temperature, because the second row
%  only, corresponding to dried temperature, was not specified...
%
%    
% Oct-25-2001 - add calculation using the IRGA AGC value.  This
% eliminates a lot more points than my despiking routine, but it
% seems like it cleans up a lot of noisy intervals.  With this
% approach it is important to have the closed path IRGA to fill in
% the gaps.
%
% Oct-16-2001 - add calculation of vertical advection term for
% fluxes as an additional output
%  
% calculates fluxes of sensible and latent heat, co2, h2o from output
% of the LI7500 - returns raw fluxes, webb corrected fluxes both using
% a point by point calculation of the mol fractions and by correcting
% the raw fluxes with measured heat and moisture fluxes
%
% Definitions
%
% INPUTS:
% -uvw - sonic wind components (m/s), either rotated into the mean wind direction (3d rotation option) or raw (planar rotation option) 
%      u - along wind 
%      v - cross wind
%      w - vertical
%
% SONDIAG - diagnostic variable for the sonic for each sample, contains a 1 if the measurement
%           is good and a zero if there was a spike
%
%  CO2 - 3XN array containing the output co2 variable from AIRDRY.M
%      ROW 1: co2 in umol/mol dry air 
%      ROW 2: co2 in umol/mol wet air
%      ROW 3: co2 in umol/m^3 wet air
%
%  H2O - 3XN array containing the output h2o variable from AIRDRY.M
%      ROW 1: h2o in mmol/mol dry air  
%      ROW 2: h2o in mmol/mol wet air
%      ROW 3: H2O in mmol/m^3 wet air
%
%  RHO - 3XN array containing the output RHO variable from AIRDRY.M
%      ROW 1: mol dry air/m^3 wet air 
%      ROW 2: mol wet air/m^3 wet air 
%      ROW 3: Kg  moist air/m^3 moist air
% 
%  TD   = 2XN array containing output TD from airdry
%      ROW 1: measured sonic temperature (C)
%      ROW 2: dried sonic temperature (K) 
% 
% irgadiag - diagnostic variable for the open path irga for each sample, contains a 1 
% if the measurement is good and a zero if there was a spike

% OUTPUTS


%for planar rotation:
if rotation==1
    % tilt coefficients b1, b2 are site specific and are changed if the
    % sonic position is changed. must be calculated from 30-min u v w
    % averages according to Wilczak et al. 2001. calculated by planar_rotation.m
    
    if month_ts(1) == 1 || month_ts(1) == 2 
        b0 = coefficients(1,2);
        b1 = coefficients(1,3);
        b2 = coefficients(1,4);
        k1 = coefficients(1,5);
        k2 = coefficients(1,6);
        k3 = coefficients(1,7);
    elseif month_ts(1) == 1 || month_ts(1) == 2 
        b0 = coefficients(2,2);
        b1 = coefficients(2,3);
        b2 = coefficients(2,4);
        k1 = coefficients(2,5);
        k2 = coefficients(2,6);
        k3 = coefficients(2,7);
    elseif month_ts(1) == 1 || month_ts(1) == 2
        b0 = coefficients(3,2);
        b1 = coefficients(3,3);
        b2 = coefficients(3,4);
        k1 = coefficients(3,5);
        k2 = coefficients(3,6);
        k3 = coefficients(3,7);
    end
    
    %determine unit vectors i,j (parallel to new coordinate x and y axes)
    j = cross(k,uvwmean);
    j = j/(sum(j.*j))^0.5;
    i = cross(j,k);
    
    %mean w --fix for lag!!!!!
    u_vector = [uvwmean(1);uvwmean(2);uvwmean(3)-b0]; %in implementing planar fit, this will need to be changed to use the mean of lag values. difference should be tiny, however.
    w_mean = b0 + (b1*uvwmean(1)) + (b2*uvwmean(2)); % check this equation, different from Lee 2004 presentation
 
end

if sitecode == 7
    z_CSAT = 8.75; sep2 = .2; angle = 25; h_canopy = 2.5;
else
end

%DEAL WITH POTENTIAL LAG:
steps=0;  %number of steps forward and back that data should be shifted.  (e.g., 2 tries 5 alignments: -2, -1, 0, 1, 2)
count=0;
for i=-steps:steps
    count=count+1;
    nshift=i;
    ashift=abs(nshift);
    numlag=num-ashift;
  
     if nshift==0
        CO2lag=CO2;
        H2Olag=H2O;
        RHOlag=RHO;
        idiaglag=irgadiag;
        
        uvwlag=uvw;
        TDlag=TD;
        SONDIAGlag=SONDIAG;
        
        iok = find(SONDIAGlag & idiaglag(1,:) & idiaglag(2,:));
        
        TDnans = find(isnan(TDlag(2,:)));
        notok = find(SONDIAGlag==0 | idiaglag(1,:)==0 | idiaglag(2,:)==0);
        co2values = length(CO2lag);
        okvalues = length(iok);
        
     elseif nshift>0
        CO2lag=([CO2(:,(1+ashift:num))]);
        H2Olag=([H2O(:,(1+ashift:num))]);
        RHOlag=([RHO(:,(1+ashift:num))]);
        idiaglag=([irgadiag(:,1+ashift:num)]);
        
        uvwlag=([uvw(:,1:numlag)]);
        TDlag = ([TD(:,1:numlag)]);
        SONDIAGlag=([SONDIAG(1:numlag)]);
        
%         iok = find(SONDIAGlag & idiaglag(1,:) & idiaglag(2,:));first = length(iok)
%         iok = find(iok>steps & iok<num-steps);second = length(iok)
%         iok = iok + steps;
%         
        TDnans = find(isnan(TDlag(2,:)));
        notok = find(iok == 0);

        
     elseif nshift<0
        CO2lag=([CO2(:,1:numlag)]);
        H2Olag=([H2O(:,1:numlag)]);
        RHOlag=([RHO(:,1:numlag)]);
        idiaglag=([irgadiag(:,1:numlag)]);
        
        uvwlag=([uvw(:,(1+ashift:num))]);
        TDlag = ([TD(:,(1+ashift:num))]);
        SONDIAGlag=([SONDIAG(1+ashift:num)]);
        
        iok = find(SONDIAGlag & idiaglag(1,:) & idiaglag(2,:)); first = length(iok);
        iok = find(iok>steps & iok<num-steps); second = length(iok);
        iok = iok - steps;
        
    end 
   
     it  = find(SONDIAGlag);
     iw  = find(SONDIAGlag);

    %it  = find(SONDIAG);
    %iw  = find(SONDIAG);

%if nargin>6 & size(irgadiag,1)>2
    
    %iok   = find(SONDIAG & irgadiag(1,:)& irgadiag(2,:));
    %iirga = find(irgadiag(1,:)&irgadiag(2,:));
    
    %iok = find(SONDIAGlag & idiaglag(1,:) & idiaglag(2,:));%here, index rows to be used
    iirga = find(idiaglag(1,:) & idiaglag(2,:));  %?
    ok = size(iok);

% put together stats on the AGC value
    
%    disp('[01-NOV-2001]: NOW CALCULATING FLUXES ETC REGARDLESS OF AGC VALUE, AND RECORDING STATISTICS ON THE AGC VALUE...');
    
%  AGCSTATS = [100*length(find((agc)==62.5))/size(agc,2);
%         min(agc);max(agc);median(agc);mean(agc)]
%     
%     
% else
%     
%     iok   = find(SONDIAG&irgadiag(1,:)&irgadiag(2,:));
%     iirga = find(irgadiag(1,:)&irgadiag(2,:));
%     
%     AGCSTATS=NaN*ones(6,1);
%     
% end

%pause

%disp('[Oct-10-2001]: Linear Detrending Removed for flux calculation, Advection also Added.');
%disp('[Oct-24-2001]: 1000 point minimum put in flux7500 for calculating statistics.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPECIFIC HEAT CAPACITY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dry air Cp - not a moist air Cp
Cpd = 1004.67; %  J/Kg K;
Cpv = 1875;     %  J/Kg K  
Cp = Cpd ;  %mean(Cpd*(ones(size(Xw))-Xw) + Cpv.*Xw)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START WITH SOME THINGS THAT ONLY REQUIRE THE IRGA: CO2 & H2O
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(find(iirga)) > 9000  %gives NaN for CO2 & H2O if less than 9000 good irga readings   
%   x=CO2lag(1,iirga); CO2OUT = [min(x);  max(x); median(x);  mean(x); std(x); skewness(x); kurtosis(x) ];
%   x=H2Olag(1,iirga); H2OOUT = [min(x);  max(x); median(x);  mean(x); std(x); skewness(x); kurtosis(x) ];
    x=CO2lag(1,iirga);    %ROW 1: co2 in umol/mol dry air 
    CO2OUT = [min(x);  max(x); median(x);  mean(x); std(x) ];
    x=H2Olag(1,iirga);    %ROW 1: h2o in mmol/mol dry air  
    H2OOUT = [min(x);  max(x); median(x);  mean(x); std(x) ];
else    
    CO2OUT=NaN*ones(5,1);
    H2OOUT=NaN*ones(5,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATIONS THAT REQUIRE BOTH SONIC/IRGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(iok) < 6000  %length(find(iok))<6000
    FCO2=NaN*ones(9,1);
    FH2O=NaN*ones(9,1);
    HSENSIBLE=NaN*ones(4,1);
    HLATENT=NaN*ones(5,1);
    RHOM=NaN*ones(3,1);
    Lv=NaN;
    COVCHT=NaN*ones(3,1);
%   FCO2avg=NaN; 
%   FCO2std=NaN;
    LAGCO2 = NaN*ones(12,1);
    TDRY=mean(TDlag(2,iok));
    OKNUM = ok;
    ORIGFLUXLAG=NaN*ones(2,1); % needs to be greater if lag is involved, was going to do 1*steps, but steps is 0 now
    zoL=NaN;
    
else    
    % DRY AIR MOLAR DENSITY    
    % Dry air molar density (moles dry air / m^3 moist air)
    % The mean requires that both the sonic and the irga were 
    % not spiking. Also calculate mean wet air molar density
    % to troubleshoot difference in sensible heat flux between
    % fortran code and matlab (3/9/2001)
    
    rho_a = mean(RHOlag(1,iok));
    rho_w = mean(RHOlag(2,iok));
    rho_3 = mean(RHOlag(3,iok));
    MEANRHO= [rho_a rho_w rho_3];
        
    % calculate densities in grams/m^3 moist air for 10Hz data
    rhoa = RHOlag(1,:)*28.966;
    rhov = (RHOlag(2,:)-RHOlag(1,:))*18.016;
    rhoc = CO2lag(3,:)*44/10^6;
    RHOM = [mean(rhoa(iok))/28.966;mean(rhov(iok))/18.016;mean(rhoc(iok))/44];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALCULATE SOME STATISTICS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    cht = [CO2lag(1,iok);H2Olag(1,iok);TDlag(2,iok)]';
    covs = cov(cht);
    COVCHT = [ covs(1,2); covs(1,3); covs(2,3) ];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LATENT HEAT OF VAPORIZATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Lv - Latent heat of vaporization (J/Kg)
    %                in J/kg from Stull p 641
    
    % Feb 8 2001 - changed the index to iok, since the latent heat
    % of vaporization is based on the dried temperature which requires
    % the moisture

    Lv = mean( (2.501*ones(size(iok))-0.00237*(TDlag(2,iok)-273.15))*10^3);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % UNCORRECTED WATER VAPOR FLUX AND LATENT HEAT FLUX
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate the water vapor density in (moles H2o/m^3 moist air)
    % and raw water vapor flux (mmol/m^2/s)
    % and raw latent heat flux (W/m^2)
    
    rho_v = H2Olag(3,:) /1000;
    [uhl2] = cov( uvwlag(1,iok) , rho_v(iok));
    [vhl2] = cov( uvwlag(2,iok) , rho_v(iok));
    [whl2] = cov( uvwlag(3,iok) , rho_v(iok));
    uhl2max=(uhl2(1,2));
    vhl2max=(vhl2(1,2));
    whl2max=(whl2(1,2));
    if rotation==0; %3D rotation-- keep variables the same
        uhl2max2=uhl2max;
        vhl2max2=vhl2max;
        whl2max2=whl2max;
    elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uhl2max vhl2max whl2max];
        uhl2max2=sum(i.*H);
        vhl2max2=sum(j.*H);
        whl2max2=sum(k.*H);

        
        
        
        
        
        
        
    end
        
    Euncorr  = whl2max2*1000;
    HLuncorr = 18.016/1000*Lv*Euncorr;
    Euncorrlag(count)=Euncorr;
    HLuncorrlag(count)=HLuncorr;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CORRECTED WATER VAPOR FLUX AND LATENT HEAT FLUX
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %  E = mean( rho_a ) * <w'q'>    [millimoles h2o/m2/s]
    % 
    %  H_l = rho_a * Lv * cov(w,q)
    % 
    %     H_l   - Latent heat flux (W/m^2)
    %     rho_a - dry air density (moles dry air/m^3 moist air)
    %     w     - vertical wind (m/s)
    %     q     - H2O mixing ratio  (mmol h2o/mol dry air)
    
    Xw  = H2Olag(1,:);
    [uXw] = cov( uvwlag(1,iok) , Xw(iok));
    [vXw] = cov( uvwlag(2,iok) , Xw(iok));
    [wXw] = cov( uvwlag(3,iok) , Xw(iok));
    uXwmax=(uXw(1,2));
    vXwmax=(vXw(1,2));
    wXwmax=(wXw(1,2));
    if rotation==0; %3D rotation-- keep variables the same
        uXwmax2=uXwmax;
        vXwmax2=vXwmax;
        wXwmax2=wXwmax;
    elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uXwmax vXwmax wXwmax];
        uXwmax2=sum(i.*H);
        vXwmax2=sum(j.*H);
        wXwmax2=sum(k.*H);
    end    
    
    Ecorr = mean(RHOlag(1,iok))*wXwmax;
    HLcorr = 18.016/1000*Lv*Ecorr;
    Ecorrlag(count)=Ecorr;
    HLcorrlag(count)=HLcorr;

   
    % Add advection term...

    %if rotation==0;
    EAdvect  = mean(RHOlag(1,iok))*mean(uvwlag(3,iok))*mean(Xw(iok))*1000;
    %elseif rotation==1;
    %    EAdvect  = mean(RHOlag(1,iok))*w_mean*mean(Xw(iok))*1000; %THIS NEEDS TO BE CHANGED
    %end   
    HLAdvect = 18.016/1000*Lv*EAdvect/1000;
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % UNCORRECTED CO2 FLUX 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate the CO2 density in (micromoles CO2/m^3 moist air)
    % and raw co2 flux (micromoles/m^2/s)
    
    umolco2  = CO2lag(3,:);  % umol co2/m^3 moist air
    
    [uco2] = cov( uvwlag(1,iok), umolco2(iok));
    [vco2] = cov( uvwlag(2,iok), umolco2(iok));
    [wco2] = cov( uvwlag(3,iok), umolco2(iok));
    uco2max=(uco2(1,2));
    vco2max=(vco2(1,2));
    wco2max=(wco2(1,2));
    if rotation==0; %3D rotation-- keep variables the same
        uco2max2=uco2max;
        vco2max2=vco2max;
        wco2max2=wco2max;
    elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uco2max vco2max wco2max];
        uco2max2=sum (i.*H);
        vco2max2=sum(j.*H);
        wco2max2=sum(k.*H);
    end
    
    Fc_raw = wco2max2;
    Fc_raw_lag(count) = Fc_raw;
    % Fc_rawdt = wco2maxdt;
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CORRECTED CO2 FLUX 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Start with CO2 mole fraction in (micromoles CO2/mol dry air)
    
    Xc = CO2lag(1,:);  % umol co2/mole dry air
    
    [uXc] = cov( uvwlag(1,iok) , Xc(iok));
    [vXc] = cov( uvwlag(2,iok) , Xc(iok));
    [wXc] = cov( uvwlag(3,iok) , Xc(iok));
    uXcmax=(uXc(1,2));
    vXcmax=(vXc(1,2));
    wXcmax=(wXc(1,2));
    if rotation==0; %3D rotation-- keep variables the same
        uXcmax2=uXcmax;
        vXcmax2=vXcmax;
        wXcmax2=wXcmax;
    elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uXcmax vXcmax wXcmax];
        uXcmax2=sum(i.*H);
        vXcmax2=sum(j.*H);
        wXcmax2=sum(k.*H);
    end
    
    Fco2= rho_a*wXcmax2;
    Fluxco2(count)=Fco2;
    
    % Add advection term... 
    
    %if rotation==0;
    Fco2Advect  = rho_a*mean(uvwlag(3,iok))*mean(Xc(iok));
    %elseif rotation==1;
    %    Fco2Advect  = rho_a*w_mean*mean(Xc(iok));   %CHANGE HERE!!!!!
    %end   
     
    Fco2Advectlag(count) = Fco2Advect;
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SENSIBLE HEAT FLUX (W/m^2)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Mar 8 2001 - adding a second heat flux calculated
    % with the sonic temperature (not dried) - this is 
    % technically not the sensible heat flux, but i think
    % it is assumed to be in the fortran code
    %
    % Feb 8 2001 - changed the index to iok, since the sensible
    % heat flux is based on the dried temperature which requires
    % the moisture
        
   % if nargin>7 & findstr(flag,'detrend')
        
      %  [wTd] = cov( detrend(uvwlag(3,iok),1) , detrend(TDlag(2,iok),1));
      %  wTdmaxdt=(wTd(1,2));
        %else
       
        [uTd] = cov( uvwlag(1,iok) , TDlag(2,iok));
        [vTd] = cov( uvwlag(2,iok) , TDlag(2,iok));
        [wTd] = cov( uvwlag(3,iok) , TDlag(2,iok));
        uTdmax=(wTd(1,2));
        vTdmax=(wTd(1,2));
        wTdmax=(wTd(1,2));
        if rotation==0; %3D rotation-- keep variables the same
            uTdmax2=uTdmax;
            vTdmax2=vTdmax;
            wTdmax2=wTdmax;
        elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
            H= [uTdmax vTdmax wTdmax];
            uTdmax2=sum(i.*H);
            vTdmax2=sum(j.*H);
            wTdmax2=sum(k.*H);
        end
        %end

        % calculate the sensible heat flux without detrending

        HSdry = 28.966/1000*rho_a*Cp*wTdmax2;
        
%         tdryindex = find(~isnan(TDlag(2,:)));
%         tdryindex2 = find(isnan(TDlag(2,:)));
        %TDRY = mean(TDlag(2,tdryindex));
        %TDRY(2,tdryindex2)
        
        TDRY = mean(TDlag(2,iok));

        [uhs] = cov( uvwlag(1,iok), TDlag(1,iok));
        [vhs] = cov( uvwlag(2,iok), TDlag(1,iok));
        [whs] = cov( uvwlag(3,iok), TDlag(1,iok));
        uhsmax=(uhs(1,2));
        vhsmax=(vhs(1,2));
        whsmax=(whs(1,2));
        if rotation==0; %3D rotation-- keep variables the same
            uhsmax2=uhsmax;
            vhsmax2=vhsmax;
            whsmax2=whsmax;
        elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
            H= [uhsmax vhsmax whsmax];
            uhsmax2=sum(i.*H);
            vhsmax2=sum(j.*H);
            whsmax2=sum(k.*H);
        end

        HSwet =  28.966/1000*rho_a*Cp*whsmax2;

        HSwetwet =  28.966/1000*rho_w*Cp*whsmax2;
        
    %***************************************************    
    % insert massman corrections here
    % needs Fc_raw, Euncorr, and HSdry
    % we probably do need to deal with the lag on these too.  
    % Fc_raw here is in units of umol m-2 s-1
    % Euncorr is in units of mmol m-2 s-1
    % Hsdry is W m-2 dry air,Hswet is W m-2 wet air
    
    %Jan's massmanwpl program inputs are below and where you can find them
    % in our programs.  Everything here refers to means, not 10Hz data
   
    
    
    %uvw= rotated mean u,v,w  = passed out of csat3rot as UVWMEANROT
    %Fc_raw=   Uz_co2_rot but Jan's program expects mg m-2 s-1
    % Euncorr = Uz_h2o_rot but jan's program expects g m-2 s-1
    % HS = Uz_Ts_rot in W m-2 wet air, but need to check on this.  
    %CO2 =  output from airdrymarcyfreeman CO2 - 3XN array 
%      ROW 1: co2 in umol/mol dry air 
%      ROW 2: co2 in umol/mol wet air
%      ROW 3: co2 in umol/m^3 wet air
    %e =  HMP_e_a from 30 minute file which is vapor pressure in kPa = 
        % H2O at bottom of comments here = PWATER = value from IRGA
    %TD=  output of airdrymarcyfreeman TOUT - 2XN - temperatures
%      ROW 1: measured sonic temperature (C)
%      ROW 2: dried sonic temperature (K) 
    %RHO = 3XN array [rhomdry rhomtotal rhotot]; 
%      ROW 1: mol dry air/m^3 wet air 
%      ROW 2: mol wet air/m^3 wet air 
%      ROW 3: Kg  moist air/m^3 moist air
     % same as in our program, but these are means
 
    %USTAR = USTAR_ same as in our program
    %hsout= raw cov between rotated w and sonic t from csat3rot
    %sep2 = distance between IRGA and sonic - entered above under
    %     sitecode=7
    %angle = angle of separation between IRGA and sonic - entered above
    %      under sitecode=7
    %L = -USTAR_ * TD / (0.4 * 9.81 * Uz_Ts_rot); needs to calculated
            %somewhere
    %z_CSAT= height of sonic, entered above under sitecode=7
    %pair_Pa = pressure in Pa
    %H2O= PWATER = partial pressure of water vapor (kPa)  output in
           %airdrymarcy freeman as PW
      
           
    % means needed for massman
    
    co2_1 =  mean(CO2lag(1,iok));
    co2_2 =  mean(CO2lag(2,iok));
    co2_3 =  mean(CO2lag(3,iok));
    MEANCO2= [co2_1 co2_2 co2_3];
    MEANPWATER = mean(PWATER);  %vapor pressure measured by IRGA in kPa
    td_1 =  mean(TDlag(1,iok)); %put : instead of iok
    td_2 =  TDRY;
    MEANTD = [td_1 td_2];
    
    [Uz_co2_c,Uz_h2o_c,Uz_Ts_c,Fc_c,LE_c,Hs_wet_c,Hs_dry_c,H_wet_c,James_water_term,James_heat_term,zoL] = UNM_WPLMassman(uvwmeanrot,wTdmax2,Euncorr*0.018,Fc_raw*0.044,MEANCO2,MEANTD,MEANRHO,USTAR,hsout,sep2,angle,z_CSAT,IRGAP*1000,MEANPWATER,Lv,h_canopy);
    
    %This should put Massman-corrected raw fluxes back in units we need
    %with new _c subscripted variables
    
    Fc_raw_massman = Uz_co2_c/0.044;
    Euncorr_massman = Uz_h2o_c/0.018;
    HSdry_massman =  28.966/1000*rho_a*Cp*Uz_Ts_c;
    HLuncorr_massman = 18.016/1000*Lv*Euncorr_massman;

    Hs_wet_massman = Hs_wet_c; %should be in W m-2
    Fc_raw_massman_Jameswpl = Fc_c/0.044; %should be in umol m-2 s-1
    LH_massman_Jameswpl = LE_c; %should be in W m-2
    Hdryjan_massman = Hs_dry_c; %should be in W m-2
    Hs_massman_Jameswpl = H_wet_c; %should be in W m-2
    
    James_water_term = James_water_term/0.044;
    James_heat_term = James_heat_term/0.044;
    
    Fc_raw_massman_lag(count) = Fc_raw_massman;
    
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % WPL CORRECTIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    mu    = 28.966/18.016;
    sigma =  mean(rhov(iok))/mean(rhoa(iok));
    
%   if nargin>7 & findstr(flag,'detrend')
        
%         [wrhov] = cov( detrend(uvwlag(3,iok),1), detrend(rhov(iok),1) );
%         wrhovmaxdt=(wrhov(1,2));
%         %  else
        
    [urhov] = cov( uvwlag(1,iok), rhov(iok) );
    [vrhov] = cov( uvwlag(2,iok), rhov(iok) );
    [wrhov] = cov( uvwlag(3,iok), rhov(iok) );
    urhovmax=(urhov(1,2));
    vrhovmax=(vrhov(1,2));
    wrhovmax=(wrhov(1,2));
    if rotation==0; %3D rotation-- keep variables the same
        urhovmax2=urhovmax;
        vrhovmax2=vrhovmax;
        wrhovmax2=wrhovmax;
    elseif rotation==1;  %planar rotation: determine scalar flux in new coordinate (code from HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [urhovmax vrhovmax wrhovmax];
        urhovmax2=sum (i.*H);
        vrhovmax2=sum(j.*H);
        wrhovmax2=sum(k.*H);
    end
        %end    
    
    Fc_water_term = mu*mean(rhoc(iok))/mean(rhoa(iok))*wrhovmax2*(10^6/44);
    Fc_heat_term  = (1+mu*sigma)*mean(rhoc(iok))/mean(TDlag(2,iok))*wTdmax2*(10^6/44);
    Fc_heat_term_massman = (1+mu*sigma)*mean(rhoc(iok))/mean(TDlag(2,iok))*Uz_Ts_c*(10^6/44);
    
    Fc_corr = Fc_raw + Fc_water_term + Fc_heat_term ;
    Fc_corr_massman_ourwpl = Fc_raw_massman  + Fc_water_term + Fc_heat_term_massman;
    
    Fc_wt_lag(count)=Fc_water_term;
    Fc_ht_lag(count)=Fc_heat_term;
    Fc_corr_lag(count)=Fc_corr;
    Fc_corr_massman_ourwpl_lag(count)=Fc_corr_massman_ourwpl;
    
    E_water_term = (1+mu*sigma)*wrhovmax2*(10^3/18.016);
    E_heat_term  = (1+mu*sigma)*mean(rhov(iok))/mean(TDlag(2,iok))*wTdmax2*(10^3/18.016);
    E_heat_term_massman  = (1+mu*sigma)*mean(rhov(iok))/mean(TDlag(2,iok))*Uz_Ts_c*(10^3/18.016);
    
    E_corr = E_water_term + E_heat_term;
    E_corr_massman = E_water_term + E_heat_term_massman;
    
    HLcorr_massman = 18.016/1000*Lv*E_corr_massman;
     
    E_wt_lag(count)=E_water_term;
    E_ht_lag(count)=E_heat_term;
    E_corr_lag(count)=E_corr;

    %[Nshiftco2 Nshifth2o]

    %_____________________________________________________________________
    %THIS WHOLE CHUNK APPEARS NOT TO BE USED (commented out by KAT, Jan2008):
    %[FwXc,PwXc,sig2c] = cross_spectra(uvwlag(3,iok),Xc(1,iok),10,0);   %CHANGE HERE???????????
    %[FwXw,PwXw,sig2h] = cross_spectra(uvwlag(3,iok),Xw(1,iok),10,0);   %CHANGE HERE???????????
    
    %[Pt] = hspec_ss(TDlag(1,iok),0,10);
    
    %OgiveXc=ogive(FwXc,PwXc(:,4));
    %OgiveXw=ogive(FwXw,PwXw(:,4));    
    %________________________________________________________________
    
  % Put the signals in ouput groups with no shift
    if i==0
        %HLATENT = [HLcorr; HLuncorr; HLAdvect];
        HLATENT = [HLcorr; HLuncorr; HLAdvect;HLuncorr_massman;HLcorr_massman]; %5 x 1
        %HSENSIBLE = [HSdry;HSwet;HSwetwet];
        HSENSIBLE = [HSdry;HSwet;HSwetwet;HSdry_massman];
        %FCO2 = [Fco2;Fc_corr;Fc_raw;Fc_heat_term;Fc_water_term;Fco2Advect];
        FCO2 = [Fco2;Fc_corr;Fc_raw;Fc_heat_term;Fc_water_term;Fco2Advect;Fc_raw_massman;Fc_heat_term_massman;Fc_corr_massman_ourwpl];
        %FH2O = [Ecorr;E_corr;Euncorr;E_heat_term;E_water_term;EAdvect];
        FH2O = [Ecorr;E_corr;Euncorr;E_heat_term;E_water_term;EAdvect;Euncorr_massman;E_heat_term_massman;E_corr_massman];
        OKNUM = ok;
    end
end
%     figure(3);
%     clf;
%     subplot(5,4,9);
%     loglog(FwXc,FwXc.*PwXc(:,2));
%     hold on;loglog([.00001 100000],[(1.5*100000) (1.5*.00001) ],'r');
%     set(gca,'ylim',[1e-10 1e+0]);
% 
%     subplot(5,4,10);
%     loglog(Pt(:,1),Pt(:,1).*Pt(:,2));
%     hold on;loglog([.00001 100000],[(1.5*100000) (1.5*.00001) ],'r');
%     set(gca,'ylim',[1e-10 1e+0]);
%     
%     subplot(5,4,11);
%     loglog(FwXc,FwXc.*PwXc(:,3));
%     hold on;loglog([.00001 100000],[(1.5*100000) (1.5*.00001) ],'r');
%     set(gca,'ylim',[1e-5 1e+5]);
%     
%     subplot(5,4,12);
%     loglog(FwXw,FwXw.*PwXw(:,3));
%     hold on;loglog([.00001 100000],[(1.5*100000) (1.5*.00001) ],'r');
%     set(gca,'ylim',[1e-10 1e+0]);
%     
%     
%     subplot(527);
%     semilogx(FwXc,FwXc.*PwXc(:,4));
%     
%     subplot(528);
%     semilogx(FwXc,OgiveXc);
%     
%     subplot(529);
%     semilogx(FwXw,FwXw.*PwXw(:,4));
%     
%     subplot(5,2,10);
%     semilogx(FwXw,OgiveXw);
%     
    
%     figure(4);clf
% 
%     yunit=1/62;
%     yheight=14*yunit;
% 
%     xleft=.25;
%     xlength=.5;
% 
%     axes('position',[xleft yunit*40 xlength yheight]);
%     set(gca,'nextplot','add')
%     
%     loglog(FwXc,FwXc.*PwXc(:,3));    
%     set(gca,'xlim',[1/1800 1],'ylim',[1e-2 5]);
%     set(gca,'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);
%     
%     axes('position',[xleft yunit*25 xlength yheight]);
%     set(gca,'nextplot','add')
%     
%     semilogx(FwXc,FwXc.*PwXc(:,4));
%     
%     set(gca,'xlim',[1/1800 1],'ylim',[-.05 .2]);
%     set(gca,'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);
%     
%     axes('position',[xleft yunit*10 xlength yheight]);
%     set(gca,'nextplot','add')
%     
%   
%     semilogx(FwXc,OgiveXc);
%     
%     set(gca,'xlim',[1/1800 1],'ylim',[0 .04]);
%     set(gca,'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);
%     
%     set(gcf,'nextplot','add')
%end
    %pause

end

        
 if length(find(iok))>=6000
 
         FCO2avg=mean(Fluxco2);
         FCO2std=std(Fluxco2);
         FCO2max=FCO2avg;
         %FCO2max=Fluxco2(1);%(i);
         Fc_wtmax=NaN;
         Fc_htmax=NaN;
         Fc_corrmax=NaN;
         Fc_rawmax=NaN;
         Fco2_Advmax=NaN;
         Ecorrmax=NaN;
         HLcorrmax=NaN;
         E_wtmax=NaN;
         E_htmax=NaN;
         E_corrmax=NaN;
         %ioknumout=NaN;
         lag=NaN;
         
         for j=1:(steps*2+1)  
                if (FCO2avg > 0)
                    if Fluxco2(j) > FCO2max
                        FCO2max=Fluxco2(j);
                        Fc_wtmax=Fc_wt_lag(j);
                        Fc_htmax=Fc_ht_lag(j);
                        Fc_corrmax=Fc_corr_lag(j);
                        Fc_rawmax=Fc_raw_lag(j);
                        Fco2_Advmax=Fco2Advectlag(j);
                        Ecorrmax=Ecorrlag(j);
                        HLcorrmax=HLcorrlag(j);
                        E_wtmax=E_wt_lag(j);
                        E_htmax=E_ht_lag(j);
                        E_corrmax=E_corr_lag(j);
                        %ioknumout=oknum(j);
                        lag=(j-(steps+1));
                    end
                elseif (FCO2avg < 0 )
                    if (Fluxco2(j) < FCO2max)
                         FCO2max=Fluxco2(j);
                         Fc_wtmax=Fc_wt_lag(j);
                         Fc_htmax=Fc_ht_lag(j);
                         Fc_corrmax=Fc_corr_lag(j);
                         Fc_rawmax=Fc_raw_lag(j);
                         Fco2_Advmax=Fco2Advectlag(j);
                         Ecorrmax=Ecorrlag(j);
                         HLcorrmax=HLcorrlag(j);
                         E_wtmax=E_wt_lag(j);
                         E_htmax=E_ht_lag(j);
                         E_corrmax=E_corr_lag(j);
                         %ioknumout=oknum(j);
                        lag=(j-(steps+1));
                    end
                end    
         end


    FLUXCO2=Fluxco2';
    LAGCO2 = [FCO2max; lag;  Fc_wtmax; Fc_htmax; Fc_corrmax; Ecorrmax; HLcorrmax];  %FLUXCO2;  removed by KAT 1/08. was after 'lag'
    LAGH2O = [Ecorrmax; HLcorrmax; E_wtmax; E_htmax; E_corrmax];
 else
    LAGCO2 = [NaN; NaN; NaN; NaN; NaN; NaN; NaN];
    LAGH2O = [NaN; NaN; NaN; NaN; NaN];
 end

 

%ORIGFLUXLAG = [Fc_corr_lag,Fc_corr_massman_ourwpl_lag];


%     figure(5);clf;plot([-2:1:2],Fluxco2,'.');
%end
%end %?????????????
return

%commented out by KAT, Jan 2008
%function [F,P,SIGOUT] = cross_spectra(a,b,sf,N)
%
%if N>0
%    
%    a=a(1:end-N);size(a);
%    b=b(N+1:end);size(b);
%    
%elseif N<0
%    
%    N=abs(N)
%   
%    a=a(N+1:end);size(a);
%    b=b(1:end-N);size(b) ;      
%    
%end
%
% %normalize if necessary%
%
%if nargin > 5
%    
%   if FLAG==1
%        
%      P=hspec_ss(a,b,sf);
%        
%        covar=cov(a,b);  
%        
%        P(:,2)=P(:,2)/std(a); 
%        P(:,3)=P(:,3)/std(b); 
%        P(:,4)=P(:,4)/covar(1,2); 
%        
%        disp('Spectra/cospectrum normalized');
%        
%    end
%    
%else
%     
%   P=hspec_ss(a,b,sf);
%    
%end 
%
%F=P(:,1);
%SIGOUT=[a;b];
% 
%return

