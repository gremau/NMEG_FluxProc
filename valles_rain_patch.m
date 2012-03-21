% program to average 5-min rain files into 30-min rain files

clear all; clc;

data = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2007','lter met data','I2:I64329');
filelength_n = 64328;

new_value = [];
num_bins = round(filelength_n/6);
bins = 1:1:num_bins;
for i = 1:num_bins
    if i == 1
        startbin = 1;
    elseif i >= 2
        startbin = ( (i-1) * 6 + 1);
    end
    
    endbin = 5 + startbin;
    
    new_value(i) = sum(data(startbin:endbin));
    
end

xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2007',new_value','master','FZ5:FZ17524');