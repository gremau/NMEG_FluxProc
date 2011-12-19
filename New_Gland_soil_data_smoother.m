clear all
close all

% Read in the data, converted to .csv
datain=dlmread('New_Gland_2011_swc_data_no_header.csv',',',1,0);        

% Replace missing data values (-99999 and 99999) with nan
datain(datain==-99999)=nan;
datain(datain==99999)=nan;

%Check for any gaps
firsty=datain(1,2);
firstd=datain(1,3);
lasty=datain(length(datain),2);
lastd=datain(length(datain),3);
hrs=[30 100 130 200 230 300 330 400 430 500 530 600 630 700 730 800 830 900 930 1000 1030 1100 1130 1200 1230 1300 ...
    1330 1400 1430 1500 1530 1600 1630 1700 1730 1800 1830 1900 1930 2000 2030 2100 2130 2200 2230 2300 2330 2400];

[y x]=size(datain);

count = 0;
for i = firsty:1:lasty
    if i == firsty
        for j = firstd:82   %should be 365 modified for 2011
            j
            for k = 1:48
                count=count+1;
                data_filled(count,1)=100;
                data_filled(count,2)=i;
                data_filled(count,3)=j;
                data_filled(count,4)=hrs(k);
                data_filled(count,5:x)=nan;
                found=find(datain(:,2)==i & datain(:,3)==j & datain(:,4)==hrs(k));
                if ~isempty(found)
                    if ~isempty(found>1)
                        found=found(1);
                    end
                    data_filled(count,5:x)=datain(found,5:x);
                end
            end
        end
    elseif i ~= lasty
        for j = 1:82  % should be 365
            j
            for k = 1:48
                count=count+1;
                data_filled(count,1)=100;
                data_filled(count,2)=i;
                data_filled(count,3)=j;
                data_filled(count,4)=hrs(k);
                data_filled(count,5:x)=nan;
                found=find(datain(:,2)==i & datain(:,3)==j & datain(:,4)==hrs(k));
                if ~isempty(found)
                    if ~isempty(found>1)
                        found=found(1);
                    end
                    data_filled(count,5:x)=datain(found,5:x);
                end
            end
        end
    elseif i == lasty
        for j = 1:lastd
            j
            for k = 1:48
                count=count+1;
                data_filled(count,1)=100;
                data_filled(count,2)=i;
                data_filled(count,3)=j;
                data_filled(count,4)=hrs(k);
                data_filled(count,5:x)=nan;
                found=find(datain(:,2)==i & datain(:,3)==j & datain(:,4)==hrs(k));
                if ~isempty(found)
                    if ~isempty(found>1)
                        found=found(1);
                    end
                    data_filled(count,5:x)=datain(found,5:x);
                end
            end
        end
    end
end


% Save this filled file
dlmwrite('Filled_Gland_2010_swc_data.csv',data_filled);

%%
% Read in previously filled file, just use this cell for playing around with the
% filter below to save having to re-run the above code

data_filled=dlmread('Filled_NewGland_2010_swc_data.csv');

% Bring in the SWC data

x=data_filled(:,5:24);
vwc2=repmat(-0.0663,(size(x)))-0.00636.*x+0.0007.*(x.*x); % not temperature corrected




% Remove any negative SWC values
vwc2(vwc2<0)=nan; vwc2(vwc2>1)=nan;

% gap fill and smooth SWC using filter
        
        aa = 1;
        nobs = 12; % 6 hr filter
        bb = (ones(nobs,1)/nobs);
        vwc3=vwc2;
        vwc4=vwc2;
        [l w]=size(vwc2);
        for n = 1:w
            n
        for m = 11:l-11
            average=nanmean(vwc2((m-10:m+10),n));
            standev=nanstd(vwc2((m-10:m+10),n));
            if(vwc2(m,n)>average+standev*3 || vwc2(m,n)<average-standev*3)
                vwc2(m,n)=nan;
            end
            if isnan(vwc2(m,n))
                vwc3(m,n)=average;
            end
        end
        vwc4(:,n)=filter(bb,aa,vwc3(:,n));
        vwc4(1:(l-(nobs/2))+1,n)=vwc4(nobs/2:l,n);
        end
        
        for i = 1:w
            figure;
            plot(vwc2(:,i)); hold on
            plot(vwc4(:,i),'r')
        end
        
% Calculate means for cover type - these won't be very smooth        
% pinon_mean=nanmean(vwc4(:,1:9)');
% juniper_mean=nanmean(vwc4(:,10:18)');
% open_mean=nanmean(vwc4(:,19:27)');

% Calculate site wide depth means - these won't very smooth
grass_5_mean=nanmean(vwc4(:,[1 6])');
grass_12_mean=nanmean(vwc4(:,[2 7])');
grass_22_mean=nanmean(vwc4(:,[3 8])');
grass_37_mean=nanmean(vwc4(:,[4 9])');
grass_52_mean=nanmean(vwc4(:,[5 10])');

open_5_mean=nanmean(vwc4(:,[11 16])');
open_12_mean=nanmean(vwc4(:,[12 17])');
open_22_mean=nanmean(vwc4(:,[13 18])');
open_37_mean=nanmean(vwc4(:,[14 19])');
open_52_mean=nanmean(vwc4(:,[15 20])');

site_5_mean=nanmean(vwc4(:,[1 6 11 16])');
site_12_mean=nanmean(vwc4(:,[2 7 12 17])');
site_22_mean=nanmean(vwc4(:,[3 8 13 18])');
site_37_mean=nanmean(vwc4(:,[4 9 14 19])');
site_52_mean=nanmean(vwc4(:,[5 10 15 20])');




figure;
plot(grass_5_mean); hold on
plot(grass_12_mean,'r'); hold on
plot(grass_22_mean,'g');hold on
plot(grass_37_mean,'k');hold on
plot(grass_52_mean,'m');

figure;
plot(open_5_mean); hold on
plot(open_12_mean,'r'); hold on
plot(open_22_mean,'g');hold on
plot(open_37_mean,'k');hold on
plot(open_52_mean,'m');


figure;
plot(site_5_mean); hold on
plot(site_12_mean,'r'); hold on
plot(site_22_mean,'g');hold on
plot(site_37_mean,'k');hold on
plot(site_52_mean,'m');



%         
%         figure;
%         plot(SWC_1); hold on
%         plot(SWC_2,'r'); hold on
%         plot(SWC_3,'g'); hold on
              
        % Replace nans with missing value
        vwc4(isnan(vwc4))=-9999; 
        
        %Write out file with time stamp
        dlmwrite('NewGland_2010_SWC.txt',cat(2,data_filled(:,2:4),vwc4,grass_5_mean',grass_12_mean',grass_22_mean',grass_37_mean',grass_52_mean',open_5_mean',open_12_mean',open_22_mean',open_37_mean',open_52_mean',site_5_mean',site_12_mean',site_22_mean',site_37_mean',site_52_mean' ))
        
        
        
        