% File Edits by M Fuller (based on version: Cumulative_uncertainty_plotter_022811.
% Mar 17, 2011
% MF comments in ALL CAPS
% Edited to include PJ_girdle site

close all
clear all+

% sitecode key
afnames(1,:) = 'US-Seg'; % 1-GLand
afnames(2,:) = 'US-Ses'; % 2-SLand
afnames(3,:) = 'US-Wjs'; % 3-JSav
afnames(4,:)='US-Mpj'; % 4-PJ
afnames(5,:)='US-Vcp'; % 5-PPine
afnames(6,:)='US-Vcm'; % 6-MCon
afnames(7,:)='US-FR2'; % 7-TX_savanna
afnames(10,:)='US-Mpg'; % 10 PJ_GIRDLE, ADDED MAR 17, 2011

colour(1,:)=[0.9 0.5 0.0];
colour(2,:)=[0.6 0.2 0];
colour(3,:)=[0.25 1.0 0.0];
colour(4,:)=[0.0 0.5 0.0];
colour(5,:)=[0.5 0.5 1.0];
colour(6,:)=[0.0 0.0 0.6];

% UPDATE SITE CODE FOR EACH RUN
sitecode = 10;

% Input file name
% filename = strcat(afnames(sitecode,:),'_2007_gapfilled.txt');
% PJ_girdle_07 = dlmread(filename,'',5,0);
% filename = strcat(afnames(sitecode,:),'_2008_gapfilled.txt');
% PJ_girdle_08 = dlmread(filename,'',5,0);
filename = strcat(afnames(sitecode,:),'_2009_gapfilled.txt');
PJ_girdle_09 = dlmread(filename,'',5,0);
filename = strcat(afnames(sitecode,:),'_2010_gapfilled.txt');  
PJ_girdle_10 = dlmread(filename,'',5,0);


% PJ_girdle_07(PJ_girdle_07==-9999)=nan; 
% PJ_girdle_08(PJ_girdle_08==-9999)=nan; 
PJ_girdle_09(PJ_girdle_09==-9999)=nan; 
PJ_girdle_10(PJ_girdle_10==-9999)=nan;

                                       % MAR 17, 2011
% cum_nee(:,1)=PJ_girdle_07(1:17524,10); % THE LENGTH AND COL NEEDS TO BE CHECKED
% cum_nee(:,2)=PJ_girdle_08(1:17524,10); % THE LENGTH AND COL NEEDS TO BE CHECKED
cum_nee(:,3)=PJ_girdle_09(1:17524,9);  % CHECKED FOR CORRECTNESS
cum_nee(:,4)=PJ_girdle_10(1:17524,10); % CHECKED FOR CORRECTNESS


cum_nee=cum_nee.*0.0216;  % IS THIS THE CORRECT VALUE FOR PJ_GIRDLE?

cum_nee(isnan(cum_nee))=0;

% THIS CODE BLOCK APPEARS TO BE ONLY FOR YEAR 2007
% ensem_07=(randn(13800,1000));
% test = PJ_girdle_07(1:13800,10);
% tester=repmat(test,1,1000);
% tester2=tester.*0.15;
% ensem_07=(ensem_07.*tester2)+tester;
% ensem_07=ensem_07.*0.0216;
% 
% for j = 1:1000
%     cum_ens_07(:,j)=cumsum(cum_ens_07(:,j));
% end

% cum_nee(:,4)=cumsum(cum_nee(:,1)); 
% cum_nee(:,5)=cumsum(cum_nee(:,2));
cum_nee(:,6)=cumsum(cum_nee(:,3));
cum_nee(:,7)=cumsum(cum_nee(:,4));

month_ticks = ['Jan';
'Feb';
'Mar';
'Apr';
'May';
'Jun';
'Jul';
'Aug';
'Sep';
'Oct';
'Nov';];
                            
xtck=linspace(1,14400,11);  % ARE THESE VALUES CORRECT? WHAT DO THEY REPRESENT?
                           

figure;
aa=gcf;
% plot(cum_nee(:,4),'r'); hold on
% plot(cum_nee(:,5),'b'); hold on
plot(cum_nee(:,6),'g'); hold on
plot(cum_nee(:,7),'g'); hold on
ylabel('Cumulative NEE (g C m^-^2)');
xlim([1 14400]); set(gca,'XTick',xtck,'xticklabel',month_ticks)

ndays=363;
                                                                        
for i =1:ndays                                                           
%    daily_values(i,1)=sum(PJ_girdle_07(PJ_girdle_07(:,2)==i,11).*0.0216); 
%    daily_values(i,2)=sum(PJ_girdle_08(PJ_girdle_08(:,2)==i,11).*0.0216); 
   daily_values(i,3)=sum(PJ_girdle_09(PJ_girdle_09(:,2)==i,11).*0.0216);  
   daily_values(i,4)=sum(PJ_girdle_10(PJ_girdle_10(:,2)==i,11).*0.0216); 
end

daily_values(isnan(daily_values))=0;

figure;
% plot(daily_values(:,1),'ro'); hold on
% plot(daily_values(:,2),'bo'); hold on
plot(daily_values(:,3),'go'); hold on
plot(daily_values(:,4),'go'); hold on

% daily_noise_1=randn(ndays,1000);
% daily_noise_2=randn(ndays,1000);
daily_noise_3=randn(ndays,1000);
daily_noise_4=randn(ndays,1000);

% daily_noise_1=daily_noise_1.*0.5;
% daily_noise_2=daily_noise_2.*0.5;
daily_noise_3=daily_noise_3.*0.5;
daily_noise_4=daily_noise_4.*0.5;

% adder=repmat(daily_values(:,1),1,1000);
% daily_noise_1=daily_noise_1+adder;
% adder=repmat(daily_values(:,2),1,1000);
% daily_noise_2=daily_noise_2+adder;
adder=repmat(daily_values(:,3),1,1000);
daily_noise_3=daily_noise_3+adder;
adder=repmat(daily_values(:,4),1,1000);
daily_noise_4=daily_noise_4+adder;

% cum_dn_1=cumsum(daily_noise_1);
% cum_dn_2=cumsum(daily_noise_2);
cum_dn_3=cumsum(daily_noise_3);
cum_dn_4=cumsum(daily_noise_4);

figure;
% plot(cum_dn_1,'r'); hold on
% plot(cumsum(daily_values(:,1)),'ko')
% plot(cum_dn_2,'b'); hold on
% plot(cumsum(daily_values(:,2)),'ks')
plot(cum_dn_3,'g'); hold on
plot(cumsum(daily_values(:,3)),'k*')
plot(cum_dn_4,'g'); hold on
plot(cumsum(daily_values(:,4)),'k*')

% out_07=prctile(cum_dn_1',[2.5 50 97.5]); % MEDIAN AND CONFIDENCE INTERVALS
% out_08=prctile(cum_dn_2',[2.5 50 97.5]);
out_09=prctile(cum_dn_3',[2.5 50 97.5]);
out_10=prctile(cum_dn_4',[2.5 50 97.5]);

% THIS PLOTTING BLOCK INCLUDES STRANGE REDUNDANT CALLS
figure;
% plot(out_07(2,:),'r','linewidth',3); hold on % for legend; PLOTTED IN RED
% plot(out_07(2,:),'b','linewidth',3); hold on % for legend; REDUNDANT, REPLOTTED IN BLUE
% plot(out_07(2,:),'g','linewidth',3); hold on % for legend; REDUNDANT, REPLOTTED IN GREEN
% plot(out_07(2,:),'k','linewidth',3); hold on % for legend; REDUNDANT, REPLOTTED IN BLACK

% plot(out_07(1,:),'r','linewidth',1); hold on % ALL 3 PLOTS IN SAME COLOR (RED)
% plot(out_07(2,:),'r','linewidth',3); hold on
% plot(out_07(3,:),'r','linewidth',1); hold on

% plot(out_08(1,:),'b','linewidth',1); hold on % ALL 3 PLOTS IN SAME COLOR (BLUE)
% plot(out_08(2,:),'b','linewidth',3); hold on
% plot(out_08(3,:),'b','linewidth',1); hold on

plot(out_09(1,:),'g','linewidth',1); hold on % ALL 3 PLOTS IN SAME COLOR (GREEN)
plot(out_09(2,:),'g','linewidth',3); hold on
plot(out_09(3,:),'g','linewidth',1); hold on

plot(out_10(1,:),'k','linewidth',1); hold on
plot(out_10(2,:),'g','linewidth',3); hold on
plot(out_10(3,:),'k','linewidth',1); hold on

%legend('2007','2008','2009'); hold on
legend('2009','2010'); hold on
ylabel('Cumulative NEE with 95% CI (g C m^-^2)','fontsize',16);
xtck=linspace(0,335,12);
% month_ticks = ['Jan';
% 'Feb';
% 'Mar';
% 'Apr';
% 'May';
% 'Jun';
% 'Jul';
% 'Aug';
% 'Sep';
% 'Oct';
% 'Nov';
% 'Dec'];
month_ticks = ['J';
'F';
'M';
'A';
'M';
'J';
'J';
'A';
'S';
'O';
'N';
'D'];

set(gca,'XTick',xtck,'xticklabel',month_ticks)

set(gca,'fontweight','bold','fontsize',16);
orient landscape
print -dpdf 'PJ_girdle_cumfig.pdf'














    