function [X_op_C, X_op_H, X_T,zoL]= UNM_massman(z,L,uvw,sep2,angle)
% JAMES used the massman corrected monin-obukhov length to compute pop (for IRGA)

% computes Massman spectral correction factors
% parameters can be tweaked for comparison to Massman 2001 figs 1 and 2
eta = atan2( uvw(:,2) , uvw(:,1) );
em = angle - eta;
sem = sin(em);
cem = cos(em);
U = sqrt((uvw(1)^2) + (uvw(2)^2) + (uvw(3)^2));
zoL = z./L;

% zoL=2;      % stability parameter, either positive or negative
% U = logspace(-1, 2, 50);    % wind speed array for plotting
test = U>20;
U(test)=[];

taue_irga = sqrt(((10/100)./(8.4*U)).^2 + ((12.5/100)./(4*U)).^2 + ((sep2/100*cem)./(1.05*U)).^2 + ...
    ((sep2/100*sem)./(1.1*U)).^2);
taue_Ts = 10/100./(8.4*U);
taue_mom = sqrt(((10/100)./(5.7*U)).^2 + (5.8/100./(2.8*U)).^2 );

% this code ignores sensor separation corrections
if (zoL <= 0)           % Horst 97, Eq 12-13 (or Massman 00 eq 7)
    nm = 0.085;         % nondimensional frequency of co-spectral peak
    alpha = 0.925;      % Massman 00 Table 2 (note Horst 97 uses 0.875 here)
else
    nm = 2.0 - 1.915/(1 + 0.5*zoL);
    alpha = 1;          % Massman 00 Table 2
end

fx = nm*U/z;            % freq. of cospectral peak, Horst 97 (also Massman 00 eq 7)
%a = 2*pi*fx*1800/5.3;   % 30 min linear detrending, Massman 00 Table 1
b = 2*pi*fx*1800/2.8;   % 30 min block averaging, Massman 00 App. B

%pcp = 2*pi*fx*0.1;      % closed-path CO2, 0.1 sec
%pq = 2*pi*fx*0.1;       % closed-path H2O, 0.1 sec
% open path CO2 and H2O (LI7500) - volume averaging, cylinder
    % Massman 00 table 1
    % diam = 1.9 cm, path = 12.7 cm
    % coefficient = (0.2+0.4.*(1.9cm/12.7cm))*.127m*(U) = 0.033*(U)
    % note Massman told me the LI7500 has a 3rd order bessel filter with
    % a time constant of 0.06 sec, which is ignored here
%    pop = (2*pi*fx*0.033)./U;  % open-path CO2 and H2O from Dave
    pop = 2*pi*fx.*taue_irga;
% sensible heat - Massman suggested for the CSAT sonic that the appropriate
    % path length corrections are
    %       sensible heat: lw/10.2u where lw is the path (11 cm)
    %       momentum: lw/6.9u
    % these follow from Kristensen and Fitzjarrald (1984) JAOT 1:138-146 for 1-d
    % see also van Dijk (2002) JAOT 19:80-82 for a 3-d variant
%   pT = 2*pi*fx.*(0.11./(10.2*U));    % sensible heat Dave

    pT =   2*pi*fx.*taue_Ts;    % sensible heat 
    
    pmom = 2*pi*fx.*taue_mom;
if (zoL <= 0)   % these are from Massman 01 Table 1
    % zoL < 0 means unstable conditions
    % open path CO2
    % a removed from equation because we do not linear detrend  
 
% 	X_op_C = ((b^alpha)/((b^alpha + 1)))*...
%              ((b^alpha)/(b^alpha + pop^alpha))*...
%              (1/(pop^alpha + 1))*...
%              (1 + (pop^alpha + 1)/(b^alpha));
%  Note - fourth terms dropped out according to massman and clement chapter
%  in handbuch of micrometeorology
         
    X_op_C = ((b^alpha)/((b^alpha + 1)))*...
         ((b^alpha)/(b^alpha + pop^alpha))*...
         (1/(pop^alpha + 1));  
         
    X_op_H = X_op_C;  % open path H2O (same as open path CO2)
    
% 	X_T = ((b^alpha)/(b^alpha + 1))*...
%           ((b^alpha)/(b^alpha + pT^alpha))*...
%           (1/(pT^alpha + 1))*...
%           (1 + ((pT^alpha + 1)/b^alpha));
      
	X_T = ((b^alpha)/(b^alpha + 1))*...
          ((b^alpha)/(b^alpha + pT^alpha))*...
          (1/(pT^alpha + 1));      

	X_mom = ((b^alpha)/(b^alpha+1))*...
            ((b^alpha)/((b^alpha+pmom^alpha)))*...
            (1/(pmom^alpha+1))*...
            (1 + (pmom^alpha+1)/(b^alpha)); 

%     X_op_C = ((a.^alpha.*b.^alpha)./((a.^alpha+1).*(b.^alpha+1))).*...
%         ((a.^alpha.*b.^alpha)./((a.^alpha+pop.^alpha).*(b.^alpha+pop.^alpha))).*...
%         (1./(pop.^alpha+1)).*(1+(pop.^alpha+1)./(a.^alpha+b.^alpha)); 

    
%     closed-path CO2

%     X_cp_C = ((a.^alpha.*b.^alpha)./((a.^alpha+1).*(b.^alpha+1))).*...
%         ((a.^alpha.*b.^alpha)./((a.^alpha+pcp.^alpha).*(b.^alpha+pcp.^alpha))).*...
%         (1./(pcp.^alpha+1)).*(1+(pcp.^alpha+1)./(a.^alpha+b.^alpha)); 
%     closed-path H2O

%     X_cp_H = ((a.^alpha.*b.^alpha)./((a.^alpha+1).*(b.^alpha+1))).*...
%         ((a.^alpha.*b.^alpha)./((a.^alpha+pq.^alpha).*(b.^alpha+pq.^alpha))).*...
%         (1./(pq.^alpha+1)).*(1+(pq.^alpha+1)./(a.^alpha+b.^alpha)); 

%     sensible heat
%     X_T = ((a.^alpha.*b.^alpha)./((a.^alpha+1).*(b.^alpha+1))).*...
%         ((a.^alpha.*b.^alpha)./((a.^alpha+pT.^alpha).*(b.^alpha+pT.^alpha))).*...
%         (1./(pT.^alpha+1)).*(1+(pT.^alpha+1)./(a.^alpha+b.^alpha)); 
      
%     X_mom = ((a.^alpha.*b.^alpha)./((a.^alpha+1).*(b.^alpha+1))).*...
%         ((a.^alpha.*b.^alpha)./((a.^alpha+pmom.^alpha).*(b.^alpha+pmom.^alpha))).*...
%         (1./(pmom.^alpha+1)).*(1+(pmom.^alpha+1)./(a.^alpha+b.^alpha)); 

    
else
    % stable conditions
    % open path CO2
%    X_op_C = ((a.*b)./((a+1).*(b+1))).*((a.*b)./((a+pop).*(b+pop))).*...
%         (1./(pop+1)).*(1+(pop+1)./(a+b));
%      X_op_C = (b./(b+1)).*(b./((b+pop))).*...
%         (1./(pop+1)).*(1+(pop+1)./b);
    
       X_op_C = (b./(b+1)).*(b./((b+pop))).*...
        (1./(pop+1));      
    
     X_op_H = X_op_C; % open path H2O (same as open path CO2)
     
    % closed-path CO2
%     X_cp_C = ((a.*b)./((a+1).*(b+1))).*((a.*b)./((a+pcp).*(b+pcp))).*...
%         (1./(pcp+1)).*(1+(pcp+1)./(a+b)).*(1+0.9*pcp)./(1+pcp);
%      % closed-path H2O
%     X_cp_H = ((a.*b)./((a+1).*(b+1))).*((a.*b)./((a+pq).*(b+pq))).*...
%         (1./(pq+1)).*(1+(pq+1)./(a+b)).*(1+0.9*pq)./(1+pq);
    % sensible heat
%     X_T = ((a.*b)./((a+1).*(b+1))).*((a.*b)./((a+pT).*(b+pT))).*...
%         (1./(pT+1)).*(1+(pT+1)./(a+b));
%     X_mom = ((a.*b)./((a+1).*(b+1))).*((a.*b)./((a+pmom).*(b+pmom))).*...
%         (1./(pmom+1)).*(1+(pmom+1)./(a+b));
    
%     X_T = (b/(b+1))*(b/(b+pT))*...
%         (1/(pT+1))*(1+(pT+1)/b);

        X_T = (b/(b+1))*(b/(b+pT))*...
        (1/(pT+1));
    
    X_mom = (b./(b+1)).*(b./(b+pmom)).*...
        (1./(pmom+1)).*(1+(pmom+1)./b);
end

% figure(1);
% subplot(2,2,1); % compare this to Massman 01 Fig 1
% semilogx(U, 1./X_T);
% xlabel('wind speed (m/s)');
% ylabel('sensible heat correction factor');
% ylim([1 1.5]);
% 
% subplot(2,2,2); % compare this to Massman 01 Fig 2
% semilogx(U, 1./X_cp_C,'-b');
% hold on;
% semilogx(U, 1./X_op_C,'-g');
% hold off;
% legend('closed path', 'open path');
% xlabel('wind speed (m/s)');
% ylabel('CO2 flux correction factor');
% ylim([1 2]);
% 
% subplot(2,2,3); % for H2O vapor, similar to Massman 01 Fig 2
% semilogx(U, 1./X_cp_H,'-b');
% hold on;
% semilogx(U, 1./X_op_H,'-g');
% hold off;
% legend('closed path', 'open path');
% xlabel('wind speed (m/s)');
% ylabel('water flux correction factor');
% ylim([1 2]);