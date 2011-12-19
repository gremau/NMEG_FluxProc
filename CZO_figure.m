close all
clear all


% sitecode key
afnames(1,:) = 'US-Seg'; % 1-GLand
afnames(2,:) = 'US-Ses'; % 2-SLand
afnames(3,:) = 'US-Wjs'; % 3-JSav
afnames(4,:)='US-Mpj'; % 4-PJ
afnames(5,:)='US-Vcp'; % 5-PPine
afnames(6,:)='US-Vcm'; % 6-MCon
afnames(7,:)='US-FR2'; % 7-TX_savanna

colour(1,:)=[0.9 0.5 0.0];
colour(2,:)=[0.6 0.2 0];
colour(3,:)=[0.25 1.0 0.0];
colour(4,:)=[0.0 0.5 0.0];
colour(5,:)=[0.5 0.5 1.0];
colour(6,:)=[0.0 0.0 0.6];


for jj = 5:6
sitecode=jj;

year = 2007;

     month(1,:)=[1 31]; month(2,:)=[32 59]; month(3,:)=[60 90]; month(4,:)=[91 120]; month(5,:)=[121 151]; month(6,:)=[152 180];
     month(7,:)=[181 212]; month(8,:)=[213 243]; month(9,:)=[244 273]; month(10,:)=[274 304]; month(11,:)=[305 334]; month(12,:)=[335 364];

year_s=num2str(year);
filename = strcat(afnames(sitecode,:),'_',year_s,'_gapfilled.txt');

%header=dlmread(filename,'',[3 0 3 0]);
data=dlmread(filename,'',5,0);

data(1,6)=0;
data(1,11)=0;
data(1,17)=0;
data(1,33)=0;
data(1,41)=0;
data(1,43)=0;
data((data(:,22)==-9999),22)=0;
data(data==-9999)=nan;




% 2257 kj/kg
evap_mm=(((data(:,17).*60.*30))./1000)./2257;

for i = 1:12
%    start=(month(i,1).*48)-47; stop=month(i,2).*48;
    found=find(month(i,1)<=data(:,2) & data(:,2)<=month(i,2));
    found2=find(month(i,1)<=data(:,2) & data(:,2)<=month(i,2) & 800<=data(:,3) & data(:,3)<=1600);
    NEE_m(i)=(sum(data(found,11))).*0.0216; % convert from mumol/m2/sec to gC/month
    NEEd_m(i)=(sum(data(found2,11))).*0.0216;
    GPP_m(i)=(sum(data(found,43))).*0.0216;
    GPPd_m(i)=(sum(data(found2,43))).*0.0216;
    RE_m(i)=(sum(data(found,41))).*0.0216;
    LE_m(i)=nanmean(data(found,17));
    evap_m(i)=sum(evap_mm(found));
    evapd_m(i)=sum(evap_mm(found2));
    par_m(i)=((sum(data(found,30))).*60.*30)./1000; % mol photons
    Rg_m(i)=(sum(data(found2,33)).*60.*30)./1000000;
    Ppt_m(i)=sum(data(found,22));
    ta_m(i)=mean(data(found,6));
    ts_m(i)=nanmean(data(found,21));
    sm_m(i)=nanmean(data(found,28));
end


clear data


year = 2008;

 month(1,:)=[1 31]; month(2,:)=[32 60]; month(3,:)=[61 91]; month(4,:)=[92 121]; month(5,:)=[122 152]; month(6,:)=[153 181];
 month(7,:)=[182 213]; month(8,:)=[214 244]; month(9,:)=[245 274]; month(10,:)=[275 305]; month(11,:)=[306 335]; month(12,:)=[336 365];

year_s=num2str(year);
filename = strcat(afnames(sitecode,:),'_',year_s,'_gapfilled.txt');

%header=dlmread(filename,'',[3 0 3 0]);
data=dlmread(filename,'',5,0);

data(1,6)=0;
data(1,11)=0;
data(1,17)=0;
data(1,33)=0;
data(1,41)=0;
data(1,43)=0;
data((data(:,43)==-9999),43)=0;
data((data(:,33)==-9999),33)=0;
data((data(:,22)==-9999),22)=0;
data(data==-9999)=nan;

% jan=(1:31); feb=(32:60); mar=(61:91); apr(92:121); may(122:152); jun(153:181)
% jul(182:213); aug(214:244); sep(245:274); oct(275:305); nov(306:335); dec(336:366)

% 2257 kj/kg
evap_mm=(((data(:,17).*60.*30))./1000)./2257;

for i = 13:24
    found=find(month(i-12,1)<=data(:,2) & data(:,2)<=month(i-12,2));
    found2=find(month(i-12,1)<=data(:,2) & data(:,2)<=month(i-12,2) & 800<=data(:,3) & data(:,3)<=1600);
    NEE_m(i)=(sum(data(found,11))).*0.0216; % convert from mumol/m2/sec to gC/month
    NEEd_m(i)=(sum(data(found2,11))).*0.0216;
    GPP_m(i)=(sum(data(found,43))).*0.0216;
    GPPd_m(i)=(sum(data(found2,43))).*0.0216;
    RE_m(i)=(sum(data(found,41))).*0.0216;
    LE_m(i)=nanmean(data(found,17));
    evap_m(i)=sum(evap_mm(found));
    evapd_m(i)=sum(evap_mm(found2));
    par_m(i)=((sum(data(found,30))).*60.*30)./1000000; % mol photons
    Rg_m(i)=(sum(data(found2,33)).*60.*30)./1000000;
    Rw_W(i)=(nanmean(data(found2,33)));
    Ppt_m(i)=sum(data(found,22));
    ta_m(i)=mean(data(found,6));
    ts_m(i)=nanmean(data(found,21));
    sm_m(i)=nanmean(data(found,28));
end



clear data


year = 2009;

     month(1,:)=[1 31]; month(2,:)=[32 59]; month(3,:)=[60 90]; month(4,:)=[91 120]; month(5,:)=[121 151]; month(6,:)=[152 180];
     month(7,:)=[181 212]; month(8,:)=[213 243]; month(9,:)=[244 273]; month(10,:)=[274 304]; month(11,:)=[305 334]; month(12,:)=[335 364];

year_s=num2str(year);
filename = strcat(afnames(sitecode,:),'_',year_s,'_gapfilled.txt');

%header=dlmread(filename,'',[3 0 3 0]);
data=dlmread(filename,'',5,0);

data(1,6)=0;
data(1,11)=0;
data(1,17)=0;
data(1,33)=0;
data(1,41)=0;
data(1,43)=0;
data((data(:,43)==-9999),43)=0;
data((data(:,33)==-9999),33)=0;
data((data(:,22)==-9999),22)=0;
data(data==-9999)=nan;

% jan=(1:31); feb=(32:60); mar=(61:91); apr(92:121); may(122:152); jun(153:181)
% jul(182:213); aug(214:244); sep(245:274); oct(275:305); nov(306:335); dec(336:366)

% 2257 kj/kg
evap_mm=(((data(:,17).*60.*30))./1000)./2257;

for i = 25:36
    found=find(month(i-24,1)<=data(:,2) & data(:,2)<=month(i-24,2));
    found2=find(month(i-24,1)<=data(:,2) & data(:,2)<=month(i-24,2) & 800<=data(:,3) & data(:,3)<=1600);
    NEE_m(i)=(sum(data(found,11))).*0.0216; % convert from mumol/m2/sec to gC/month
    NEEd_m(i)=(sum(data(found2,11))).*0.0216;
    GPP_m(i)=(sum(data(found,43))).*0.0216;
    GPPd_m(i)=(sum(data(found2,43))).*0.0216;
    RE_m(i)=(sum(data(found,41))).*0.0216;
    LE_m(i)=mean(data(found,17));
    evap_m(i)=sum(evap_mm(found));
    evapd_m(i)=sum(evap_mm(found2));
    par_m(i)=((sum(data(found,30))).*60.*30)./1000000; % mol photons
    Rg_m(i)=(sum(data(found2,33)).*60.*30)./1000000;
    Rw_W(i)=(mean(data(found2,33)));
    Ppt_m(i)=sum(data(found,22));
    ta_m(i)=mean(data(found,6));
    ts_m(i)=nanmean(data(found,21));
    sm_m(i)=nanmean(data(found,28));
end

clear data


year = 2010;

     month(1,:)=[1 31]; month(2,:)=[32 59]; month(3,:)=[60 90]; month(4,:)=[91 120]; month(5,:)=[121 151]; month(6,:)=[152 180];
     month(7,:)=[181 212]; month(8,:)=[213 243]; month(9,:)=[244 273]; month(10,:)=[274 304]; month(11,:)=[305 334]; month(12,:)=[335 364];

year_s=num2str(year);
filename = strcat(afnames(sitecode,:),'_',year_s,'_gapfilled.txt');

%header=dlmread(filename,'',[3 0 3 0]);
data=dlmread(filename,'',5,0);

data(1,6)=0;
data(1,11)=0;
data(1,17)=0;
data(1,33)=0;
data(1,41)=0;
data(1,43)=0;
data((data(:,43)==-9999),43)=0;
data((data(:,33)==-9999),33)=0;
data((data(:,22)==-9999),22)=0;
data(data==-9999)=nan;

% jan=(1:31); feb=(32:60); mar=(61:91); apr(92:121); may(122:152); jun(153:181)
% jul(182:213); aug(214:244); sep(245:274); oct(275:305); nov(306:335); dec(336:366)

% 2257 kj/kg
evap_mm=(((data(:,17).*60.*30))./1000)./2257;

for i = 37:48
    found=find(month(i-36,1)<=data(:,2) & data(:,2)<=month(i-36,2));
    found2=find(month(i-36,1)<=data(:,2) & data(:,2)<=month(i-36,2) & 800<=data(:,3) & data(:,3)<=1600);
    NEE_m(i)=(sum(data(found,11))).*0.0216; % convert from mumol/m2/sec to gC/month
    NEEd_m(i)=(sum(data(found2,11))).*0.0216;
    GPP_m(i)=(sum(data(found,43))).*0.0216;
    GPPd_m(i)=(sum(data(found2,43))).*0.0216;
    RE_m(i)=(sum(data(found,41))).*0.0216;
    LE_m(i)=mean(data(found,17));
    evap_m(i)=sum(evap_mm(found));
    evapd_m(i)=sum(evap_mm(found2));
    par_m(i)=((sum(data(found,30))).*60.*30)./1000000; % mol photons
    Rg_m(i)=(sum(data(found2,33)).*60.*30)./1000000;
    Rw_W(i)=(mean(data(found2,33)));
    Ppt_m(i)=sum(data(found,22));
    ta_m(i)=mean(data(found,6));
    ts_m(i)=nanmean(data(found,21));
    sm_m(i)=nanmean(data(found,28));
end


NEE_S(jj,:)=NEE_m;
NEED_S(jj,:)=NEEd_m;
GPP_S(jj,:)=GPP_m;
RE_S(jj,:)=RE_m;
GPPD_S(jj,:)=GPPd_m;
LE_S(jj,:)=LE_m;
EVAP_S(jj,:)=evap_m;
EVAPD_S(jj,:)=evapd_m;
RG_S(jj,:)=Rg_m;
PPT_S(jj,:)=Ppt_m;
TA_S(jj,:)=ta_m;
TS_S(jj,:)=ts_m;
SM_S(jj,:)=sm_m;


clear     NEE_m GPP_m RE_m LE_m evap_m par_m Rg_m Ppt_m ta_m ts_m sm_m evapd_m NEEd_m

end

% monthly_bar_chart_v2(NEE_S,GPP_S,RE_S,PPT_S,TA_S)
monthly_bar_chart_v4(NEE_S,GPP_S,RE_S,PPT_S,TA_S,RG_S,EVAP_S)


