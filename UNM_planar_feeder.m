%reads from file "data to run.xls" and feeds to fluxesfreemanKA
clc;
clear;

drive='c:'
filein=strcat(drive,'\Research_Flux_Towers','\data to run')
matrix=xlsread(filein,'current','A1:I100');
site=matrix(:,1);
year=matrix(:,2);
f_jday=matrix(:,5);
l_jday=matrix(:,8);
starttime_num=matrix(:,9);
n=size(matrix,1);
dircode=1;  %enter '0' if files in same directory as matlab program, '1' if different folder.

for i=1:n
    UNM_planar_file_in(drive,site(i),year(i),f_jday(i),l_jday(i),starttime_num(i),dircode)
    pack
    i=i+1;
end

disp('DONE!!!')