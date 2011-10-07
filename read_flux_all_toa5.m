function data = read_flux_all_toa5(site, year)
% READ_FLUX_ALL_TOA5 - read FLUX_all toa5 data for year
% INPUTS
%   fname: string, full path of fluxall file
%   year: integer, year to read

    fname = fullfile(get_site_directory(get_site_code(site)), ...
                     sprintf('%s_FLUX_all_%d_toa5.csv.gz', site, year))
    unzipped_fname = gunzip(fname, tempdir())
    %fid = fopen(unzipped_fname, 'r')
    
    %data = dataset('file', tmp_file, 'delimiter', ',')
    keyboard()
    data = dlmread(unzipped_fname, ',', 4, 0);

    


