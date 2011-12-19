%reads from file "data to run.xls" and feeds to fluxesfreemanKA
clc;
clear;

clf;

drive='c:';
filein=strcat(drive,'\Research - Flux Towers','\data to run');
matrix=xlsread(filein,'current','A1:I100');
site=matrix(:,1);
year=matrix(:,2);
f_jday=matrix(:,5);
l_jday=matrix(:,8);
starttime_num=matrix(:,9);
n=size(matrix,1);

%options
figures = 0;  %0 off, 1 on
rotation = 1; %0 3d, 1 planar
lag = 0;  %0 off, 1 on. Adjust the number of steps in flux7500freeman_lag.m at ~line 130 ('stemps
writefluxall = 1; %1 to write to FLUX_all file, 0 skips
dircode = 1;  %enter '0' if files in same directory as matlab program, '1' if different folder.

for i=1:n
    UNM_filebuilder(drive,figures,rotation,lag,writefluxall,site(i),year(i),f_jday(i),l_jday(i),starttime_num(i),dircode);
    pack;
    i=i+1;
end

disp('DONE!!!')