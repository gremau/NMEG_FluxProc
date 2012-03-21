%reads from file "data to run.xls" and feeds to fluxesfreemanKA
clc;
clear;

clf;

t_start = now();

drive = 'c:';
filein = strcat( drive, '\Research_Flux_Towers', '\data to run' );
matrix = xlsread( filein, 'current', 'A1:I100' );
requested_sitecodes = matrix( :, 1 );
year = matrix( :, 2 );
f_jday = matrix( :, 5 );
l_jday = matrix( :, 8 );
starttime_num = matrix( :, 9 );
n = size( matrix, 1 );

%options
figures = 0;  %0 off, 1 on
rotation = 1; %0 3d, 1 planar
lag = 0;  %0 off, 1 on. Adjust the number of steps in flux7500freeman_lag.m at ~line 130 ('stemps
writefluxall = 1; %1 to write to FLUX_all file, 0 skips
dircode = 1;  %enter '0' if files in same directory as matlab program, '1' if different folder.

% create a cell array to hold the parsed data
parsed_ts_data = cell( n, 1 );

for i=1:n

    [ filename, date, jday,...
      sitename, sitecode, outfolder, parsed_ts_data{ i } ] = ...
        UNM_filebuilder( drive, figures, rotation, lag, writefluxall,  ...
                        requested_sitecodes( i ), year( i ), f_jday( i ), ...
                         l_jday( i ), starttime_num( i ), dircode );

end

all_data = vertcat( parsed_ts_data{:} );
export( all_data, 'file', ...
        fullfile( get_out_directory( requested_sitecodes( 1 ) ), ...
                  '2009_GLand_processed_TS_data.txt' ) );

fprintf( 'DONE (%d minutes)\n', ( now() - t_start ) * 24 * 60 );