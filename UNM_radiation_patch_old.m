clear all; clc;

% program to average 10-min sw incoming files into 30-min files
data = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008','10-min radiation patch','E2:F17175');
data1 = data(:,1);
data2 = data(:,2);

filelength_n = 17172;

decimal_day = [];
new_value = [];
num_bins = round(filelength_n/3);
bins = 1:1:num_bins;
for i = 1:num_bins
    if i == 1
        startbin = 1;
    elseif i >= 2
        startbin = ( (i-1) * 3 + 1);
    end
    
    endbin = 2 + startbin;
    decimal_day(i) = data1(startbin);
    new_value(i) = mean(data2(startbin:endbin));
    outdata = [decimal_day' new_value'];
    
end

xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008',outdata,'10-min radiation patch','M2:N5724');


% program to split hourly radiation files into half-hourly radiation files
% data = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008','hourly radiation patch','F2:H3242');
% filelength_n = 3241;
% 
%     for i = 1:filelength_n*2
%         decimal_day(i) = data(round(i/2),1);
%         sw_incoming(i) = data(round(i/2),2);
%         temp(i) = data(round(i/2),3);
%     end
% 
%    outdata = [decimal_day' sw_incoming' temp'];
% xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008',outdata,'hourly radiation patch','O2:Q17521');


