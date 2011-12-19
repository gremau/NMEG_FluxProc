clc; clear;

root_dir = 'J:\ZippedS05_part3\Documents and Settings\Jim Kjelgaard\Desktop\S2005\';
out_dir = 'C:\Research - Flux Towers\Flux Tower Data by Site\TX_grassland\2005';
s_folders = dir([root_dir 'S05*']);

for i=1:length(s_folders)  
    a = [root_dir s_folders(i).name '\CR23X\105_2005_*']
    s_files = dir([root_dir s_folders(i).name '\CR23X\105_2005_*'])
    for ii=1:length(s_files)
        parsename = textscan(s_files(ii).name,'%s','delimiter','_');
        %file_month = parsename{1}(3);  %'105_2007_02_03_0815.dat'
        from_dir = [root_dir s_folders(i).name '\CR23X\' s_files(ii).name];
        to_dir   = [out_dir '\' num2str(i)];
        if isdir(to_dir) == 0;mkdir(to_dir);end
        copyfile(from_dir,to_dir);
    end
end

