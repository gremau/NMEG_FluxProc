function [datamatrix] = fluxreader(s)

%This function opens up the appropriate flux file and scans in the data

if s==1 %GLand--1--Sev grassland (NM)
    fid = fopen('c:/Research_Flux_Towers/Flux_Tower_Data_by_Site/GLand/toa5/GLand_fluxflag.dat'); %opens file for reading if need to test a 30-min card pull use GLand_fluxflag.dat
    datamatrix = textscan(fid,...
    '"%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%n%*n%*n%n%*n%n%n%*n%n%*n%*n%*n%*n%*n%n%n%n%n%*s%*s%*s%*s%*s%*s%*s%*s%*s%n%n%n%n%n%n%n%*n%*n%*n%n%n%*n%*n%*n%n%n%*n%n%n%n%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*s%*n%*n%*n%*n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    %The four lines of code above scan data in file and translates each column into string (%s) or number (%n) or skips %*...
    %headerlines specifies to skip first four rows
    fclose(fid); %close file
    clear('fid');
    
elseif s==2 %SLand--2--Sev shrubland (NM)
    fid = fopen('c:/Research_Flux_Towers/Flux_Tower_Data_by_Site/SLand/CR3000 Sland/SLand_fluxflag.dat'); %bfs_CR3000_SH_flux
    datamatrix = textscan(fid,...
    '"%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%*n%n%*n%*n%*n%n%*n%*n%n%*n%n%n%*n%n%*n%*n%*n%*n%*n%n%n%n%n%*s%*s%*s%*s%*s%*s%*s%*s%*s%n%n%n%n%n%n%n%*n%*n%*n%n%n%*n%*n%*n%n%n%*n%n%n%n%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*s%*n%*n%*n%*n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');    

elseif s==3 %JSav--3-- juniper savannah (NM)
    fid = fopen('c:/Research_Flux_Towers/Flux_Tower_Data_by_Site/JSav/toa5/JSav_fluxflag.dat'); %CR5000_JSav_flux.dat 
    %                                   ???                                                                                         34        39                           49        53                             64                        75         80        84                                                     103                              119                                                             141 ;
    datamatrix = textscan(fid,'%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%*n%n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%*n%*n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%*n%n%n%n%n%*n%*n%*n%n%n%n%*n%n%n%n%n%*n%*n%*n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%*[^\n]',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');
    
elseif s==4 %PJ--4-- pinon juniper (NM)
    fid = fopen('c:/Research_Flux_Towers/Flux_Tower_Data_by_Site/PJ/flux/PJ_fluxflag.dat');
    %                                   ???                                                                                    31    34      38   40                 47        51                           61  63  65     68         72   74  76      79   81                         90                           100                           110                           120                           130      133         ;
    datamatrix = textscan(fid,'%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%*n%n%*n%*n%*n%*n%*n%n%n%*n%*n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%*n%*n%*n%*n%n%*n%n%n%n%n%*n%*n%*n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%*[^\n]',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');

elseif s==5 %PPine--5-- Ponderosa pine in valles caldera (NM)
    fid = fopen('C:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\flux\PPine_fluxflag.dat'); %CR5000_Ppine_flux
    %                                     ???                                                                                       34        39   41               47        51                             62         67        71                     79  81                             91           
    datamatrix = textscan(fid,'"%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%*n%n%*n%*n%*n%*n%*n%n%n%*n%*n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%*n%n%n%n%n%*n%*n%*n%n%*n%*n%*n%*n%*n%*n%n%n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');
    
elseif s==6 %MCon--6-- Mixed conifer in valles caldera (NM)
    fid = fopen('c:/Research_Flux_Towers/Flux_Tower_Data_by_Site/MCon/flux/MCon_fluxflag.dat');%CR5000_MCon_flux.dat
    %                                     ???                                                                                       34        39   41               47        51                             62         67        71                     79  81                             91           
    datamatrix = textscan(fid,'"%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%*n%n%*n%*n%*n%*n%*n%n%n%*n%*n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%*n%n%n%n%n%*n%*n%*n%n%*n%*n%*n%*n%*n%*n%n%n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');
    
elseif s==7 %TX --7-- Texas freeman
    fid = fopen('C:/Research_Flux_Towers/Flux_Tower_Data_by_Site/TX_Freeman/CR5000/CR5000_flux_2008_03_21.dat');
    %                                   ???                                                                  25            32   34            39           44           49                55                      64         68  70   72   74  76                  83                                    96              104                112;
    datamatrix = textscan(fid,'%19s%*s%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%*n%n%*n%*n%*n%*n%n%n%*n%*n%*n%n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%*n%*n%*n%*n%*n%*n%n%*n%*n%*n%n%n%n%*n%*n%n%n%n%n%*n%*n%*n%*n%*n%*n%n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%*n%n%n%n%n%n%n%n%n%n%n%n%n%n%*n%*n%*n%n%n%n',...
    'delimiter', ',', 'headerlines', 4, 'treatAsEmpty', {'"NAN"','"INF"','"-INF"'});
    fclose(fid); %close file
    clear('fid');
    
end
