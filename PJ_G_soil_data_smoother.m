clear all
close all

% Read in the data, converted to .csv
datain=dlmread('PJ_G_CO2_data_for_Dan.csv',',',1,0);        

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
        for j = firstd:365
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
        for j = 1:365
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
dlmwrite('Filled_PJ_G_CO2_data_for_Dan.csv',data_filled);

%%
% Read in previously filled file, just use this cell for playing around with the
% filter below to save having to re-run the above code

data_filled=dlmread('Filled_PJ_G_CO2_data_for_Dan.csv');

% Bring in the SWC data
vwc2=data_filled(:,32:58);

% Remove any negative SWC values
vwc2(vwc2<0)=nan;

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
pinon_mean=nanmean(vwc4(:,1:9)');
juniper_mean=nanmean(vwc4(:,10:18)');
open_mean=nanmean(vwc4(:,19:27)');

% Calculate site wide depth means - these won't very smooth
shallow_mean=nanmean(vwc4(:,[1 4 7 10 13 16 19 22 25])');
medium_mean= nanmean(vwc4(:,[2 5 8 11 14 17 20 23 26])');
deep_mean=   nanmean(vwc4(:,[3 6 9 12 15 18 21 24 27])');

figure;
plot(pinon_mean); hold on
plot(juniper_mean,'r'); hold on
plot(open_mean,'g')

figure;
plot(shallow_mean); hold on
plot(medium_mean,'r'); hold on
plot(deep_mean,'g')

%         
%         figure;
%         plot(SWC_1); hold on
%         plot(SWC_2,'r'); hold on
%         plot(SWC_3,'g'); hold on
              
        % Replace nans with missing value
        vwc4(isnan(vwc4))=-9999; 
        
        %Write out file with time stamp
        dlmwrite('PJ_G_SWC.txt',cat(2,data_filled(:,2:4),vwc4,pinon_mean',juniper_mean',open_mean',shallow_mean',medium_mean',deep_mean'))
        
        
        
        