function [uvwt,SONDIAG,THETA,UVWTMEAN,speed] = UNM_csat3(uvwt,diagson,sitecode)
% processes the measured SONIC outputs from the campbell CSAT 3 (half-hourly data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% uvwt - NX4 array
%    ROW 1: measured sonic u component
%    ROW 2: measured sonic v component
%    ROW 3: measured sonic w component
%    ROW 4: measured sonic t component
% diagson - sonic diagnostics
% sitecode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUTS: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SONDIAG - NX1 -diagnostic vector for sonic for each sample contains a 1 if the 
%    measurement was good or a 0 if there was a flag in despike
%
% UVWTMEAN - 4X1 - mean values for (despiked) sonic measurements in measured (not rotated) coordinates
%    ROW 1: mean measured u component
%    ROW 2: mean measured v component
%    ROW 3: mean measured w component
%    ROW 4: mean measured sonic temperature
%
% THETA: - 1X1 - meteorological mean wind angle - it is the compass angle in degrees that 
%        the wind is blowing FROM (0 = North, 90 = east, etc)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ensure that  T is in Celsius...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isnan(median(uvwt(4,find(~isnan(uvwt(4,:)))))) && ~isempty(median(uvwt(4,:))) 
    if median(uvwt(4,find(~isnan(uvwt(4,:))))) > 100
        uvwt(4,:) = uvwt(4,:)-273.15;
    end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call despike for sonic  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[iu,removedu] = UNM_despike(uvwt(1,:),6,-20,20,'U',5);  uvwt(1,find(~iu)) = NaN*ones(size(find(~iu))); %puts NaN in for all records that were despiked to 0
[iv,removedv] = UNM_despike(uvwt(2,:),6,-20,20,'V',6);  uvwt(2,find(~iv)) = NaN*ones(size(find(~iv)));
[iw,removedw] = UNM_despike(uvwt(3,:),6,-20,20,'W',7);  uvwt(3,find(~iw)) = NaN*ones(size(find(~iw)));
[it,removedt] = UNM_despike(uvwt(4,:),6,-20,50,'T',8);  uvwt(4,find(~it)) = NaN*ones(size(find(~it)));

SONDESPIKE = ones(1,length(iu));
SONDESPIKE(find( sum([iu;iv;iw;it]) < 4 )) = 0;
SONDESPIKE(find(diagson > 0)) = 0;
SONDIAG = SONDESPIKE;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting sonic orientation by site.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == 7;       %TX
    sonic_orient=146;   %THIS IS WIND DIRECTION (way its going in degrees) & MUST BE CHANGED FOR EVERY SITE.
elseif sitecode == 1;   %gressland
    sonic_orient=180;   %check value
elseif sitecode == 2;   %shrubland
    sonic_orient=180;   %check value
elseif sitecode == 3;   %juniper savannah
    sonic_orient=225;
elseif sitecode == 4 || sitecode == 14;   %PJ and Test Site
    sonic_orient=225;   %NEED VALUE HERE
elseif sitecode == 5;   %PPine
    sonic_orient=329;   %%sonic orient number is 320  (magnetic-%probably need declination)-->329
elseif sitecode == 6;   %MCON
    sonic_orient=333;   %%%sonic orientation number is 324 (magnetic- probably%need declination)--> 333
elseif sitecode == 8;   % TX_forest
    sonic_orient=156;
elseif sitecode == 9;   % TX_grassland
    sonic_orient=120;
elseif sitecode == 10;   % PG girdle
    sonic_orient=224;
elseif sitecode == 11;   % New_GLand
    sonic_orient=180;
elseif sitecode == 13;   % MCon_SS FIXME - this needs to be verified!!!
    sonic_orient=330;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculating mean winds, temperature, and theta if enough good data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if length(find(SONDIAG))>3000
    UVWTMEAN = [ mean(uvwt(1,find(SONDIAG))); mean(uvwt(2,find(SONDIAG))); mean(uvwt(3,find(SONDIAG))); mean(uvwt(4,find(SONDIAG))) ];
    THETA = (-atan2(UVWTMEAN(2),UVWTMEAN(1)) + pi/2)*180/pi;
        if THETA < 0
            THETA = THETA + 360;
        end
    THETA = THETA - 90 + sonic_orient ;
    THETA(find(THETA > 360))= THETA(find(THETA > 360)) - 360;
    THETA(find(THETA < 0))= THETA(find(THETA < 0))+360;
    speed = sqrt((UVWTMEAN(1).^2) + (UVWTMEAN(2).^2) + (UVWTMEAN(3).^2));

    
else % case of not enough good points
    UVWTMEAN = NaN*ones(4,1);
    THETA = NaN;
    speed = NaN;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional figures.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

wantfigs=0; %change to 1 to view figures 
if wantfigs==1;
    figure(1);clf;

    subplot(321);
    plot(UVWROT(:,find(SONDIAG))');
    set(gca,'xlim',[0 size(UVWROT,2)]);
    title('U (bl), V (gr), W (r)');

    subplot(522);
    plot(uvwt(4,find(SONDIAG))');
    set(gca,'xlim',[0 size(UVWROT,2)]);
    title(['Ts']);
    drawnow;
else
end

return