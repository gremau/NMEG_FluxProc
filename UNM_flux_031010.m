function [ CO2OUT, H2OOUT, FCO2, FH2O, HSENSIBLE, HLATENT, RHOM, TDRY, OKNUM, ...
           zoL, UVWTVAR, COVUVWT, HBUOYANT, USTAR, TRANSPORT, u_vector, ...
           w_mean ] =  ...
        UNM_flux_031010( year_ts, month_ts, day_ts, UVW2, uvwmean, ...
                         SONDIAG, CO2, H2O, TD, RHO, irgadiag, rotation, ...
                         site, sitecode, num, PWATER, uvwmeanrot, ...
                         IRGAP, speed, temp2, theta )
    
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


% Calculate a datenum from inputs to check against time periods that
% require corrections (PJ_girdle 2009 only at this point)
ts_date = datenum( year_ts, month_ts, day_ts );

% PJ_girdle correction end date
 pjg_2009_date = datenum( 2009, 9, 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate covariance matrix of sonic measurements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% in the odd case where there is exactly one valid SONDIAG, u is a 1 by 4 matrix
% and cov treats it as a vector of observations, returning the 1 by 1 covariance
% of the four elements.  In this oddball case, set the covariance matrix to a 4
% by 4 matrix of zeros.  We are looking at you, 28 Nov 2009 from 23:00 to
% 23:29:59 at PJ_girdle...
if numel( find( SONDIAG ) ) == 1
    u = zeros( 4, 4 );
elseif isempty( find( SONDIAG ) )
    u = repmat( NaN, 4, 4 );
else
    %covariance between (1) rotated coordinates (good values only) and (2)sonic
    %temperature (good values only)
    u = cov([UVW2(:,find(SONDIAG)); temp2(find(SONDIAG))]');  
end

if rotation == sonic_rotation.threeD
    UVWTVAR = diag(u);
    COVUVWT = [ u(1,3); u(2,3); u(1,2); u(1,4); u(2,4); u(3,4)];
    USTAR = sqrt(sqrt(u(1,3)^2 + u(2,3)^2));
    
    qsqr = 0.5*( sum( UVW2(:,find(SONDIAG) ).^2 ) );
    TRANSPORT = mean(UVW2(3,find(SONDIAG)).*qsqr); % calculate turbulent transport term
    
    [hs]  = cov( UVW2(3,find(SONDIAG)) , TD(2,find(SONDIAG)));
    hsout = u(1,2);
    HBUOYANT =  29/1000*38.6*1004*hsout; % BUOYANCY  FLUX , approximate (W/m^2)
%    USTAR = sqrt(sqrt(uw^2 + vw^2));
    u_vector = mean( UVW2( :, find(SONDIAG) ), 2 );
    w_mean = u_vector( 3 );
    
    % UVWTVAR - 4X1 -  variances of ROTATED wind components and the sonic temperature
    %    ROW 1: along-wind velocity variance
    %    ROW 2: cross-wind velocity variance
    %    ROW 3: vertical-wind velocity variance
    %    ROW 4: sonic temperature variance
    %
    % COVUVWT - 6X1 - covariances of ROTATED wind components and the sonic temperature
    %    ROW 1: uw co-variance
    %    ROW 2: vw co-variance
    %    ROW 3: uv co-variance
    %    ROW 4: ut co-variance
    %    ROW 5: vt co-variance
    %    ROW 6: wt co-variance
    
elseif rotation == sonic_rotation.planar
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Specify planar coefficients here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if length(u(~isnan(u))) == 16 && isnan(speed) == 0
        
        if sitecode == 1 % grassland
            if speed >= 5
                b0 = 0.152528949;
                b1 = -0.00082989;
                b2 = 0.002517913;
                k(1) = 0.000829887;
                k(2) = -0.002517904;
                k(3) = 0.999996486;
            elseif speed < 5
                b0 = 0.025221417;
                b1 = 0.011187435;
                b2 = 0.005053646;
                k(1) = -0.011186592;
                k(2) = -0.005053265;
                k(3) = 0.999924659;
            end
            
        elseif sitecode == 2 % shrubland
            if speed >= 5 
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
            
        elseif sitecode == 3 % juniper savanna
            if speed >= 5
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
            
        elseif sitecode == 4 % pinyon juniper
            if speed >= 5
                b0 = 0.000545198;
                b1 = 0.03902567;
                b2 = 0.023237575;
                k(1) = -0.038985478;
                k(2) = -0.023213642;
                k(3) = 0.998970099;
            else
                b0 = -0.016562191;
                b1 = 0.042138681;
                b2 = 0.016933381;
                k(1) = -0.042095294;
                k(2) = -0.016915946;
                k(3) = 0.998970388;
            end
            
        elseif sitecode == 5 % ponderosa pine
            if speed >= 5            
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
            
        elseif sitecode == 6 % mixed conifer
            if speed >= 5            
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
        
        elseif sitecode == 7 && year_ts(1) == 2005 && month_ts(1) < 5 % use one set of values for
            % first seven months, not separated out by windspeed, then use the same values as 2006         
            b0 = 0.024873451;
            b1 = 0.002279925;
            b2 = 0.002839777;
            k(1) = -0.00227991;
            k(2) = -0.002839758;
            k(3) = 0.999993369;

        elseif sitecode == 7 && year_ts(1) == 2005 && month_ts(1) >= 5 % latter half of 2005
            % use same as 2006
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;
            
        elseif sitecode == 7 && year_ts(1) == 2006 % all of 2006 looks pretty consistent, use one set of data
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) < 3 % first 2 months of 2007
            % use same as 2006
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;
            
        elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) == 3 || month_ts(1) == 4
            % March and April 2007 has their own set of coefficients
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year_ts(1) == 2007 && month_ts(1) >= 5 %after that, use a new set of
            % coefficients calculated with only the data in the last 6 months of 2007 
            b0 = -0.007905583;
            b1 = 0.012986531;
            b2 = -0.000801434;
            k(1) = -0.012985432;
            k(2) = 0.000801367;
            k(3) = 0.999915365;
                
         elseif sitecode == 7 && year_ts(1) == 2008 % Using the same as the latter part of 2007 
            b0 = -0.007905583;
            b1 = 0.012986531;
            b2 = -0.000801434;
            k(1) = -0.012985432;
            k(2) = 0.000801367;
            k(3) = 0.999915365;

         elseif sitecode == 7 && year_ts(1) == 2011 % Using the same as
                                                    % the latter part of
                                                    % 2007 ??? -TWH 30
                                                    % Sep 2011
            b0 = -0.007905583;
            b1 = 0.012986531;
            b2 = -0.000801434;
            k(1) = -0.012985432;
            k(2) = 0.000801367;
            k(3) = 0.999915365;
            
            
        elseif sitecode == 8 % TX_forest
            if theta >= 0 && theta <= 60
                b0 = 0.224838191;
                b1 = 0.051189541;
                b2 = -0.031249502;
                k(1) = -0.046221527;
                k(2) = 0.014738558;
                k(3) = 0.998206387;
            elseif theta > 60 && theta <= 210
                b0 = 0.094117303;
                b1 = 0.03882402;
                b2 = 0.011170481;
                k(1) = -0.038792377;
                k(2) = -0.011161377;
                k(3) = 0.999184955;
            elseif theta > 210 && theta <= 270
                b0 = 0.070326918;
                b1 = -0.026290012;
                b2 = -0.009114614;
                k(1) = 0.02627984;
                k(2) = 0.009111088;
                k(3) = 0.999613104;
            elseif theta > 270 && theta <= 360
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
               
        elseif sitecode == 10 % pinyon juniper - girdled _UPDATED_ Febuary 2010
            
            
            if speed >= 5
                b0 = -0.0344557038769674;
                b1 = -0.0128424391588686;
                b2 =  0.0160405052917033;
                k(1) = 0.012839728810921;
                k(2) =-0.0160371200040598;
                k(3) = 0.99978895380277;
            else
                b0 =  -0.0473758714816513;
                b1 =  -0.0128600161662158;
                b2 =   0.0101393306242113;
                k(1) = 0.0128582920745777;
                k(2)= -0.0101379712841514;
                k(3) = 0.99986593394473;
            end    
            
            elseif sitecode == 11 % New_GLand
            b0 = 0.0430287;
            b1 = 0.351210;
            b2 = -0.0336278;
            k(1) = -0.0350796;
            k(2) = 0.0335881;
            k(3) = 0.9988199;
            
            
%             if speed >= 5
%                 b0 = 0.000545198;
%                 b1 = 0.03902567;
%                 b2 = 0.023237575;
%                 k(1) = -0.038985478;
%                 k(2) = -0.023213642;
%                 k(3) = 0.998970099;
%             else
%                 b0 = -0.016562191;
%                 b1 = 0.042138681;
%                 b2 = 0.016933381;
%                 k(1) = -0.042095294;
%                 k(2) = -0.016915946;
%                 k(3) = 0.998970388;
%             end
            
            
        end         
        
    %determine unit vectors i,j (parallel to new coordinate x and y axes)
    j = cross(k,uvwmean);
    j = j/(sum(j.*j))^0.5;
    i = cross(j,k);
    
    uu=i(1)^2*u(1,1)+i(2)^2*u(2,2)+i(3)^2*u(3,3)+...                                                                                                                                                                                                         
       2*(i(1)*i(2)*u(1,2)+i(1)*i(3)*u(1,3)+i(2)*i(3)*u(2,3));
    vv=j(1)^2*u(1,1)+j(2)^2*u(2,2)+j(3)^2*u(3,3)+...
       2*(j(1)*j(2)*u(1,2)+j(1)*j(3)*u(1,3)+j(2)*j(3)*u(2,3));
    ww=k(1)^2*u(1,1)+k(2)^2*u(2,2)+k(3)^2*u(3,3)+...
       2*(k(1)*k(2)*u(1,2)+k(1)*k(3)*u(1,3)+k(2)*k(3)*u(2,3));
    uw=i(1)*k(1)*u(1,1)+i(2)*k(2)*u(2,2)+i(3)*k(3)*u(3,3)+...
       (i(1)*k(2)+i(2)*k(1))*u(1,2)+(i(1)*k(3)+i(3)*k(1))*u(1,3)+...
       (i(2)*k(3)+i(3)*k(2))*u(2,3);   % momentum flux
    vw=j(1)*k(1)*u(1,1)+j(2)*k(2)*u(2,2)+j(3)*k(3)*u(3,3)+...
       (j(1)*k(2)+j(2)*k(1))*u(1,2)+(j(1)*k(3)+j(3)*k(1))*u(1,3)+...
       (j(2)*k(3)+j(3)*k(2))*u(2,3);
    
    %mean w --fix for lag!!!!!
    u_vector = [uvwmean(1);uvwmean(2);uvwmean(3)-b0]; %in implementing planar fit, this will need to be changed to use the mean of lag values. difference should be tiny, however.
    w_mean = b0 + (b1*uvwmean(1)) + (b2*uvwmean(2));
    UVWTVAR = diag(u);
    
    qsqr = 0.5*( sum( UVW2(:,find(SONDIAG) ).^2 ) );
    TRANSPORT = mean(UVW2(3,find(SONDIAG)).*qsqr); % calculate turbulent transport term
    
    [hs]  = cov( UVW2(3,find(SONDIAG)) , TD(2,find(SONDIAG)));
    hsout = u(1,2);
    HBUOYANT =  29/1000*38.6*1004*hsout; % BUOYANCY  FLUX , approximate (W/m^2)
    USTAR = sqrt(sqrt(uw^2 + vw^2));

    else    
    UVWTVAR   = NaN*ones(4,1);
    COVUVWT   = NaN*ones(6,1);
    USTAR     = NaN;
    HBUOYANT  = NaN;
    TRANSPORT = NaN;
    u_vector  = NaN*ones(3,1);
    w_mean    = NaN;
    
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters for sensor separation and spectral corrections (Massman)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == 1    
    z_CSAT = 3.2; sep2 = 0.191; angle = 28.94; h_canopy = 0.25;  %angle was 4 before, sep2 was .157,
elseif sitecode == 2
    z_CSAT = 3.2; sep2 = 0.134; angle = 11.18; h_canopy = 0.8;
elseif sitecode == 3
    z_CSAT = 10.35; sep2 = .2; angle = 25; h_canopy = 3;
elseif sitecode == 4 || sitecode == 14 %PJ/TestSite
    z_CSAT = 8.2; sep2 = .143; angle = 19.3; h_canopy = 4;
elseif sitecode == 5
    z_CSAT = 24.02; sep2 = 0.15; angle = 15.266; h_canopy = 17.428;
elseif sitecode == 6
    z_CSAT = 23.9; sep2 = 0.375; angle = 71.66; h_canopy = 16.56;
elseif sitecode == 7
    z_CSAT = 8.75; sep2 = .241; angle = 31.37109; h_canopy = 2.5;
elseif sitecode == 8
    z_CSAT = 15.24; sep2 = .11; angle = 13.79; h_canopy = 7.62;
elseif sitecode == 9
    z_CSAT = 4; sep2 = .19; angle = 31.59; h_canopy = 1;
elseif sitecode == 10 % here for PJ_girdle
  % These heights need checking/changin
  z_CSAT = 5.5; sep2 = 0.194; angle = 13.3; h_canopy = 4;
  % adjust instrument height and angle starting 11 Aug 2011
  if datenum(year_ts(1), month_ts(1), day_ts(1)) >= datenum(2011, 8, 11)
      %fprintf(1, 'using instrument angle & height for 11 Aug 2011 onward\n');
      z_CSAT = 6.5; sep2 = 0.194; angle = 16.71; h_canopy = 4;
  end
elseif sitecode == 11 % for New_GLand
    z_CSAT = 3.2; sep2 = 0.142; angle = 21.67; h_canopy = 0.25; %z_CSAT unknown as of 100610
elseif sitecode == 13 % for MCon_SS , FIXME - these are wrong!!!
    z_CSAT = 29.9; sep2 = 0.375; angle = 71.66; h_canopy = 18.56;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up lag for-loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        
        uvwlag=UVW2;
        TDlag=TD;
        SONDIAGlag=SONDIAG;
        
        iok = find(SONDIAGlag & idiaglag(1,:) & idiaglag(2,:) & idiaglag(3,:));
        
        irgaok = find(idiaglag(1,:) & idiaglag(2,:) & idiaglag(3,:));
        
        notok = find(SONDIAGlag==0 | idiaglag(1,:)==0 | idiaglag(2,:)==0);
        co2values = length(CO2lag);
        okvalues = length(iok);
        
        count = 1;
        
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
    iirga = find(idiaglag(1,:) & idiaglag(2,:));  %?
    ok = size(iok);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START WITH SOME THINGS THAT ONLY REQUIRE THE IRGA: CO2 & H2O
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(find(irgaok)) > 6000  %gives NaN for CO2 & H2O if less than 9000 good irga readings
    x=CO2lag(1,irgaok);    %ROW 1: co2 in umol/mol dry air 
    CO2OUT = [min(x); max(x); median(x); mean(x); std(x) ];
    x=H2Olag(1,irgaok);    %ROW 1: h2o in mmol/mol dry air  
    H2OOUT = [min(x); max(x); median(x); mean(x); std(x) ];
else    
    CO2OUT=NaN*ones(5,1);
    H2OOUT=NaN*ones(5,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATIONS THAT REQUIRE BOTH SONIC/IRGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(iok) < 6000  %length(find(iok))<6000
    FCO2=NaN*ones(5,1);
    FH2O=NaN*ones(6,1);
    HSENSIBLE=NaN*ones(4,1);
    HLATENT=NaN*ones(3,1);
    RHOM=NaN*ones(3,1);
    Lv=NaN;
    COVCHT=NaN*ones(3,1);
    TDRY = mean(TDlag(2,iok));
    OKNUM = ok;
    ORIGFLUXLAG=NaN*ones(2,1); % needs to be greater if lag is involved, was going to do 1*steps, but steps is 0 now
    zoL=NaN;
    UVWTVAR   = NaN*ones(4,1);
    COVUVWT   = NaN*ones(6,1);
    USTAR     = NaN;
    HBUOYANT  = NaN;
    TRANSPORT = NaN;
    u_vector  = NaN*ones(3,1);
    w_mean    = NaN;
    
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
    % SPECIFIC HEAT CAPACITY
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Dry air Cp - not a moist air Cp because we use dried air
    Cp = 1004.67 + (mean(TDlag(2)).^2./3364); % J/Kg K dry air
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALCULATE SOME STATISTICS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    cht = [CO2lag(1,iok);H2Olag(1,iok);TDlag(2,iok)]';
    covs = cov(cht);
    COVCHT = [covs(1,2); covs(1,3); covs(2,3)];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LATENT HEAT OF VAPORIZATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % (J/Kg) from Stull p 641
    Lv = mean( (2.501*ones(size(iok))-0.00237*(TDlag(2,iok)-273.15))*10^3); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % UNCORRECTED WATER VAPOR FLUX AND LATENT HEAT FLUX
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate the water vapor density in (moles H2o/m^3 moist air)
    % and raw water vapor flux (mmol/m^2/s)
    % and raw latent heat flux (W/m^2)
    
    rho_v = H2Olag(3,:)/1000;
    [uhl2] = cov( uvwlag(1,iok) , rho_v(iok));
    [vhl2] = cov( uvwlag(2,iok) , rho_v(iok));
    [whl2] = cov( uvwlag(3,iok) , rho_v(iok));
    uhl2max=(uhl2(1,2));
    vhl2max=(vhl2(1,2));
    whl2max=(whl2(1,2));
    if rotation == sonic_rotation.threeD; 
        %3D rotation-- keep variables the same
        uhl2max2=uhl2max;
        vhl2max2=vhl2max;
        whl2max2=whl2max;
    elseif rotation == sonic_rotation.planar;  
        %planar rotation: determine scalar flux in new coordinate (code from
        %HANDBOOK OF MICROMETEOROLOGY P. 63)
        H = [uhl2max vhl2max whl2max];
        uhl2max2=sum(i.*H);
        vhl2max2=sum(j.*H);
        whl2max2=sum(k.*H);
    end
        
    E_raw  = whl2max2*1000; % this is now moles h2o m-2 s-1
    HL_raw = 18.016/1000*Lv*E_raw;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%% Corrections for bad IRGA prior to 1 Sept 2009 Developed March 2010 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if sitecode == 10 && ts_date < pjg_2009_date
%         HL_raw = (HL_raw.*1.1484)+3.6589; % Correction based on regression in Futher_flux_corrections .xls file
%         E_raw = ((HL_raw./Lv)./18.016).*1000;
%     end
    
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
    if rotation == sonic_rotation.threeD; 
        %3D rotation-- keep variables the same
        uco2max2=uco2max;
        vco2max2=vco2max;
        wco2max2=wco2max;
    elseif rotation == sonic_rotation.planar;  
        %planar rotation: determine scalar flux in new coordinate (code from
        %HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uco2max vco2max wco2max];
        uco2max2=sum(i.*H);
        vco2max2=sum(j.*H);
        wco2max2=sum(k.*H);
    end
    
    Fc_raw = wco2max2;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%% Corrections for bad IRGA prior to 1 Sept 2009 Developed March 2010 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   if sitecode == 10 && ts_date < pjg_2009_date
       % Correction based on regression in Futher_flux_corrections .xls file
       Fc_raw=(Fc_raw.*1.1623)-0.096; 
   end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SENSIBLE HEAT FLUX (W/m^2)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Mar 8 2001 - adding a second heat flux calculated
    % with the sonic temperature (not dried) - this is 
    % technically not the sensible heat flux, but i think
    % it is assumed to be in the fortran code   
       
    [uTd] = cov( uvwlag(1,iok) , TDlag(2,iok));
    [vTd] = cov( uvwlag(2,iok) , TDlag(2,iok));
    [wTd] = cov( uvwlag(3,iok) , TDlag(2,iok));
    uTdmax=(uTd(1,2));
    vTdmax=(vTd(1,2));
    wTdmax=(wTd(1,2));
    if rotation == sonic_rotation.threeD
        %3D rotation-- keep variables the same
        uTdmax2=uTdmax;
        vTdmax2=vTdmax;
        wTdmax2=wTdmax;
    elseif rotation == sonic_rotation.planar  
        %planar rotation: determine scalar flux in new coordinate (code from
        %HANDBOOK OF MICROMETEOROLOGY P. 63)
        H= [uTdmax vTdmax wTdmax];
        uTdmax2=sum(i.*H);
        vTdmax2=sum(j.*H);
        wTdmax2=sum(k.*H);

        COVUVWT = [ u(1,3); u(2,3); u(1,2); uTdmax2; vTdmax2; wTdmax2];
    end

    % calculate the sensible heat flux -- modify dry temp covariance to correct units
    HSdry = 28.966/1000*rho_a*Cp*wTdmax2;
    TDRY = mean(TDlag(2,iok));

    [uhs] = cov( uvwlag(1,iok), TDlag(1,iok));
    [vhs] = cov( uvwlag(2,iok), TDlag(1,iok));
    [whs] = cov( uvwlag(3,iok), TDlag(1,iok));
    uhsmax=(uhs(1,2));
    vhsmax=(vhs(1,2));
    whsmax=(whs(1,2));
    if rotation == sonic_rotation.threeD 
        %3D rotation-- keep variables the same
        uhsmax2=uhsmax;
        vhsmax2=vhsmax;
        whsmax2=whsmax;
    elseif rotation == sonic_rotation.planar
        %planar rotation: determine scalar flux in new coordinate (code from
        %HANDBOOK OF MICROMETEOROLOGY P. 63) 
        H= [uhsmax vhsmax whsmax];
        uhsmax2=sum(i.*H);
        vhsmax2=sum(j.*H);
        whsmax2=sum(k.*H);
    end

    HSwet =  28.966/1000*rho_a*Cp*whsmax2;
    HSwetwet =  28.966/1000*rho_w*Cp*whsmax2;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Water vapor density flux
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    [urhov] = cov( uvwlag(1,iok), rhov(iok) );
    [vrhov] = cov( uvwlag(2,iok), rhov(iok) );
    [wrhov] = cov( uvwlag(3,iok), rhov(iok) );
    urhovmax=(urhov(1,2));
    vrhovmax=(vrhov(1,2));
    wrhovmax=(wrhov(1,2));
    if rotation == sonic_rotation.threeD
        %3D rotation-- keep variables the same
        urhovmax2=urhovmax;
        vrhovmax2=vrhovmax;
        wrhovmax2=wrhovmax;
    elseif rotation == sonic_rotation.planar
        %planar rotation: determine scalar flux in new coordinate (code from
        %HANDBOOK OF MICROMETEOROLOGY P. 63) 
        H= [urhovmax vrhovmax wrhovmax];
        urhovmax2=sum(i.*H);
        vrhovmax2=sum(j.*H);
        wrhovmax2=sum(k.*H); % units are what mols m-2 s-1
    end
           
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Massman CORRECTIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
       
    co2_1 =  mean(CO2lag(1,iok)); % means needed for massman 
    co2_2 =  mean(CO2lag(2,iok));
    co2_3 =  mean(CO2lag(3,iok));
    MEANCO2= [co2_1 co2_2 co2_3];
    MEANPWATER = mean(PWATER); % vapor pressure measured by IRGA in kPa
    td_1 =  mean(TDlag(1,iok));
    td_2 =  TDRY;
    MEANTD = [td_1 td_2];
    
    [ Uz_co2_c, Uz_h2o_c, Uz_Ts_c, Fc_c, LE_c, Hs_wet_c, Hs_dry_c, H_wet_c, ...
      James_water_term, James_heat_term, zoL, Uz_rhov_c ] = ...
        UNM_WPLMassman( uvwmean, wTdmax2, E_raw*0.018, Fc_raw*0.044, ...
                        MEANCO2, MEANTD, MEANRHO, USTAR, hsout, sep2, ...
                        angle, z_CSAT, IRGAP*1000, MEANPWATER, Lv, ...
                        h_canopy, wrhovmax2*0.018);
    
    % Put Massman-corrected raw fluxes back in units we need
    Fc_raw_massman = Uz_co2_c/0.044;
    E_raw_massman = Uz_h2o_c/0.018;
    HSdry_massman =  28.966/1000*rho_a*Cp*Uz_Ts_c;
    HL_raw_massman = 18.016/1000*Lv*E_raw_massman;
    E_rhov_massman = Uz_rhov_c/0.018;

    Hs_wet_massman = Hs_wet_c; %should be in W m-2
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % WPL CORRECTIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    mu    = 28.966/18.016;
    sigma =  mean(rhov(iok))/mean(rhoa(iok));
    % sigma =  mean(rhov(iok))/(mean(rhoa(iok))+7)
    
    
    Fc_water_term = mu*mean(rhoc(iok))/mean(rhoa(iok))*E_rhov_massman*(10^6/44);
    Fc_heat_term_massman = (1+mu*sigma)*mean(rhoc(iok))/mean(TDlag(2,iok))*Uz_Ts_c*(10^6/44);
    % Fc_heat_term_massman = (1+mu*sigma)*(mean(rhoc(iok))+0.05)/mean(TDlag(2,iok))*Uz_Ts_c*(10^6/44)
    Fc_corr_massman_ourwpl = Fc_raw_massman  + Fc_water_term + Fc_heat_term_massman;
    
    E_water_term = (1+mu*sigma)*E_rhov_massman*(10^3/18.016);
    E_heat_term_massman  = (1+mu*sigma)*mean(rhov(iok))/mean(TDlag(2,iok))*Uz_Ts_c*(10^3/18.016);
    E_wpl_massman = E_water_term + E_heat_term_massman;
    
    % this needs to be fixed to include the E_heat_term_massman!  Right now
    % (as a bandaid) this correction is in UNM_Remove_Bad_Data.  Make sure to
    % remove that when you include the correction here!  -TWH, 8 Mar 2012
    HL_wpl_massman = 18.016/1000*Lv*(E_raw_massman);% + E_heat_term_massman );

    if i==0
        HLATENT = [HL_raw; HL_raw_massman; HL_wpl_massman];
        HSENSIBLE = [HSdry; HSwet; HSwetwet; HSdry_massman];
        FCO2 = [Fc_raw;Fc_raw_massman;Fc_water_term;Fc_heat_term_massman;Fc_corr_massman_ourwpl];
        FH2O = [E_raw;E_raw_massman;E_water_term;E_heat_term_massman;E_wpl_massman;E_rhov_massman];
        OKNUM = ok;
    end
end

end

