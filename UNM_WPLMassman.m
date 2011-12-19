function [Uz_co2_c,Uz_h2o_c,Uz_Ts_c,Fc_c,LE_c,Hs_wet_c,Hs_dry_c,H_wet_c,James_water_term,James_heat_term,zoL,Uz_rhov_c]= ...
    UNM_WPLMassman(uvw,Uz_Ts_rot,Uz_h2o_rot,Uz_co2_rot,CO2,TD,RHO,USTAR,hsout,sep2,angle,z_CSAT,pair_Pa,H2O,Lv,h_canopy,wrhovmax2);

% no e in UNM Matlab code since that is output from HMP45C  instead use H2O
% which is vapor pressure measured by IRGA in kPa

% zw: height of IRGA
% angle: angle between CSAT and IRGA

%%%%%%%%%%%%%  "CONSTANTS"  %%%%%%%%%%%%%%%%%%%%
Rd = 287.05;
cpd = 1005;
%Lv = (2.501-0.00237*(TD(2,:)-273.15))*10^3;
%pass in Lv from flug7500freeman_lag

% calculate densities in grams/m^3 moist air
rhoa =  RHO(:,1)*28.966;
rhov = (RHO(:,2)-RHO(:,1))*18.016;
rhoc = CO2(:,3)*44/10^6;
RHOM = [mean(rhoa)/28.966;mean(rhov)/18.016;mean(rhoc)/44];

% calculate z and L
z = z_CSAT/(0.7*h_canopy);
L = -((USTAR)^3*TD(2))/(0.4 * 9.81 * Uz_Ts_rot);

%%%%%%%%%%%%%%%%   CALL MASSMAN   %%%%%%%%%%%%%%%%%%%
[X_op_C,X_op_H,X_T,zoL] = UNM_massman(z,L,uvw,sep2,angle);

fid = fopen(fullfile(getenv('TMP'), 'massman.txt'), 'a');
fprintf(fid, '%0.15f', X_op_C);
fclose(fid);

Uz_Ts_c = Uz_Ts_rot ./ X_T;
Uz_h2o_c= Uz_h2o_rot ./ X_op_H;
Uz_co2_c= Uz_co2_rot ./ X_op_C;
Uz_rhov_c = wrhovmax2 ./ X_op_H;

%%%%%%%%%%%%%%%%   WPL   %%%%%%%%%%%%%%%%%%%
q = 0.622*H2O'*1000 ./ RHO(:,3) - 0.382*H2O'*1000;     % e in kPa, changed to H2O
Rm =  Rd * (1 + .608*q/1000);                   % q in g/kg
cpm = cpd* (1 + .84 *q/1000);  %specific heat of moist air                 % q in g/kg
Dda = (pair_Pa' - H2O'*1000) ./ (Rd * TD(:,2));  %density in dry air    % Td in K
Dma = pair_Pa'./(Rm.*TD(:,2)); %density in moist air

LE_c = Lv .* (1+ 1/.622 * rhov/1000 ./Dda ) .* Uz_h2o_c + rhov/1000./TD(:,2).* Uz_Ts_c;
Hs_wet_c  = Dma.*cpm.*Uz_Ts_c;
Hs_dry_c = Dda.*cpd.*Uz_Ts_c;
H_wet_c = Hs_wet_c - 0.07 * LE_c;
Fc_c = Uz_co2_c + 1/.622 * CO2(:,3)./1e6./ Dda .* Uz_h2o_c * 1000 ... 
    +  (1+ 1/.622 * rhov/1000./Dda ) .* CO2(:,3)./TD(:,2).* Uz_Ts_c;

James_water_term = 1/.622 * CO2(:,3)./1e6./ Dda .* Uz_h2o_c * 1000;
James_heat_term = (1+ 1/.622 * rhov/1000./Dda ) .* CO2(:,3)./TD(:,2).* Uz_Ts_c;

return


function [F,P,SIGOUT] = cross_spectra(a,b,sf,N)

if N>0
    
    a=a(1:end-N);size(a);
    b=b(N+1:end);size(b);
    
elseif N<0
    
    N=abs(N);
    
    a=a(N+1:end);size(a);
    b=b(1:end-N);size(b) ;
    
end

% normalize if necessary

if nargin > 5
    
    if FLAG==1
        
        P=hspec_ss(a,b,sf);
        
        covar=cov(a,b);
        
        P(:,2)=P(:,2)/std(a);
        P(:,3)=P(:,3)/std(b);
        P(:,4)=P(:,4)/covar(1,2);
        
        disp('Spectra/cospectrum normalized');
        
    end
    
else
    
    P=hspec_ss(a,b,sf);
    
end

F=P(:,1);
SIGOUT=[a;b];

return