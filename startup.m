% add Peter Acklam's utilities to path
addpath(genpath('/Users/tim/Software/Acklam_Utils/'));

if exist('/Volumes/Untitled/home/tim') == 7
    setenv('FLUXROOT', '/Volumes/Untitled/home/tim/Data/DataSandbox');
else
    setenv('FLUXROOT', getenv('DATASANDBOX'));
end
    