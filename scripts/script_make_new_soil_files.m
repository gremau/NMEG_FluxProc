close all;
clear all;

% Set site and year
year = 2013;
sitecode = UNM_sites.MCon;

% Start and end dates for making a new fluxall file
date_start = datenum(year, 1, 1, 0, 0, 0);
date_end = datenum(year, 12, 31, 24, 30, 0);

% Fix the resolution file if needed
%generate_header_resolution_file;

data = UNM_parse_fluxall_txt_file(sitecode, year);

% These steps should be called from UNM_prepare_soil_met
% For MCon:
% data = preprocess_MCon_soil_data( year, timestamps )

% For PJ
%[ soilT, SWC, SHF ] = preprocess_PJ_soil_data( sitecode, year, varargin )
% or
%[ soil_data ] = preprocess_PJ_soil_data_DK1( sitecode, year, varargin )

% For PPine
% SWC = preprocess_PPine_soil_data( year ) % does SWC
% and
% SoilT = preprocess_PPine_soilT_data( year ) % Does soil T


% Get the qc file
ds_qc = UNM_parse_QC_txt_file( sitecode, year );

% Generate a prepared soil dataset
soild = UNM_Ameriflux_prepare_soil_met( sitecode, year, data, ds_qc );
% Beware that this runs UNM_soil_data_smoother, which oversmooths data.


% Check this output (soild) and then run whichever version of Ameriflux
% file maker uses the TWH prepare_soil_met pipeline.