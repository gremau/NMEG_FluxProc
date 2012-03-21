clear all
close all

% sitecode key
% 1-GLand
% 2-SLand
% 3-JSav
% 4-PJ
% 5-PPine
% 6-MCon
% 7-TX_savanna
% 8-TX_forest
% 9-TX_grassland

sitecode = 10;
year = 2009;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify some details about sites and years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode==1; % grassland
    site='GLand';
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='HC';
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='HD';
    elseif year == 2009;
        filelength_n = 2763;
        lastcolumn='HD';
    end

elseif sitecode==2; % shrubland
    site='SLand'    
    if year == 2006
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='GX';   
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='GZ';
    elseif year == 2009
        filelength_n = 6074;
        lastcolumn='HR';
    end
     
elseif sitecode==3; % Juniper savanna
    site = 'JSav'   
    if year == 2007
        filelength_n = 11596;
        lastcolumn='HR';
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='HJ';
    elseif year == 2009
        filelength_n = 4639;
        lastcolumn='HN';
    end
    
elseif sitecode == 4; % Pinyon Juniper
    site = 'PJ'
    if year == 2007
        lastcolumn = 'HO';
        filelength_n = 2516;
    elseif year == 2008
        lastcolumn = 'HO'; 
        filelength_n = 17572;
    elseif year == 2009
        lastcolumn = 'HJ';
        filelength_n = 7382;
    end    
    
elseif sitecode==5; % Ponderosa Pine
    site = 'PPine'
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FV';
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='FU';
    elseif year == 2009;
        filelength_n = 2954;
        lastcolumn='FU';
    end
    
elseif sitecode==6; % Mixed conifer
    site = 'MCon'
    if year == 2006
        filelength_n = 2129; 
        lastcolumn='GB';
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='GB';
    elseif year == 2008;
        filelength_n = 16301;
        lastcolumn='GB';
    elseif year == 2009;
        filelength_n = 2913;
        lastcolumn='GB';
    end
    
elseif sitecode == 7;
    site = 'TX'
    if year == 2005
        filelength_n = 17524;  
        lastcolumn='GF';
    elseif year == 2006
        filelength_n = 17524;  
        lastcolumn='GF';
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FZ';
    elseif year == 2008;
        filelength_n = 16253;
        lastcolumn='GP';
    end

elseif sitecode == 8;
    site = 'TX_forest'
    if year == 2005
        filelength_n = 17524;  
        lastcolumn='CA';
    elseif year == 2006
        filelength_n = 17524;  
        lastcolumn='CA';
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='DO';
    elseif year == 2008;
        filelength_n = 16253;
        lastcolumn='GP';
    end
    
elseif sitecode == 9;
    site = 'TX_grassland'
    if year == 2005
        filelength_n = 17524;  
        lastcolumn='DT';
    elseif year == 2006
        filelength_n = 17524;  
        lastcolumn='CA';
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='CA';
    elseif year == 2008;
        filelength_n = 16253;
        lastcolumn='GP';
    end

    elseif sitecode == 10; % Pinyon Juniper girdle
    site = 'PJ_girdle'
    lastcolumn = 'FE';
    if year == 2009
        filelength_n = 7596;
    end    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

drive='c:';
row1=5;  %first row of data to process - rows 1 - 4 are header
filename = strcat(site,'_flux_all_',num2str(year))
filelength = num2str(filelength_n);
datalength = filelength_n - row1 + 1; 
filein = strcat(drive,'\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\',filename)
outfolder = strcat(drive,'\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\processed_flux\');
range = strcat('B',num2str(row1),':',lastcolumn,filelength);
headerrange = strcat('B2:',lastcolumn,'2');
time_stamp_range = strcat('A5:A',filelength);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open file and parse out dates and times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('reading data...')
[num text] = xlsread(filein,headerrange);
headertext = text;
[num text] = xlsread(filein,range);  %does not read in first column because it's text!!!!!!!!
data = num;
ncol = size(data,2)+1;
[num text] = xlsread(filein,time_stamp_range);
timestamp = text;
[year month day hour minute second] = datevec(timestamp);
datenumber = datenum(timestamp);
disp('file read');


%%
% NDVI anaylsis

ndvi = data(:,150:157);
date = data(:,2:4);
ndvi = cat(2,date,ndvi);
found = find(~isnan(ndvi(:,11)) & (ndvi(:,4)>0));
ndvi_part = ndvi(found,:);
figure;
subplot(2,2,1)
plot(ndvi_part(:,3),ndvi_part(:,4:11),'.')

ndvi_part=ndvi_part(find(ndvi_part(:,4)<400),:);

% for i = 4:11
%     ndvi_part=ndvi_part(find(ndvi_part(:,i)>0),:);
% end

subplot(2,2,2)
 plot(ndvi_part(:,3),ndvi_part(:,4:11),'.')
 
 ndvi_part(:,12)=ndvi_part(:,7) ./ ndvi_part(:,11)
 ndvi_part(:,13)=ndvi_part(:,6) ./ ndvi_part(:,10);
 ndvi_part(:,14)=ndvi_part(:,12) .* 4.12;
 ndvi_part(:,15)=ndvi_part(:,13) .* 3.86;
 
 subplot(2,2,3)
 plot(ndvi_part(:,3),ndvi_part(:,12:13),'o'); hold on
 plot(ndvi_part(:,3),ndvi_part(:,14:15),'.')
 
 
 ndvi_part(:,16)=ndvi_part(:,14)-ndvi_part(:,15);
 ndvi_part(:,17)=ndvi_part(:,14)+ndvi_part(:,15);
 ndvi_part(:,18)=ndvi_part(:,16)./ndvi_part(:,17);
 
 subplot(2,2,4)
 plot(ndvi_part(:,3),ndvi_part(:,18),'.')
 
 
 
 
 
 
 
 











