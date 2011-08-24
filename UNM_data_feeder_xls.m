%reads from file "data to run.xls" and feeds to fluxes
%freemanKA
% modified by Timothy W. Hilton, Aug 2011

function [args] = UNM_data_feeder_xls()

    drive='c:'
    filein=fullfile(drive,'\Research - Flux Towers','\data to run')
    matrix=xlsread(filein,'current','A1:I100')
    site=matrix(:,1)
    year=matrix(:,2)
    start_jday=matrix(:,5)
    end_jday=matrix(:,8)
    starttime_num=matrix(:,9)
    n=size(matrix,1);

    args = struct('site', site, ...
                  'year', year, ...
                  'start_jday', start_jday, ...
                  'end_jday', end_jday, ...
                  'starttime_num', starttime_num, ...
                  'n', n)
    
    % this snippet needs to go in a main caller function
% $$$     for i=1:n
% $$$         UNM_filebuilder(drive,figures,rotation,lag,writefluxall,site(i),year(i),f_jday(i),l_jday(i),starttime_num(i),dircode)
% $$$         pack
% $$$         i=i+1;
% $$$     end
    
