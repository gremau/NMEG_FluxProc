% This program was created by Krista Anderson Teixeira in July 2007
% Modified by John DeLong 2008 through 2009.
% Modifed by Timothy W. Hilton, 2011 through 2013
%
% The program reads site_fluxall_year excel files and pulls in a
% combination of matlab processed ts data and data logged average 30-min
% flux data.  It then flags values based on a variety of criteria and
% writes out new files that do not have the identified bad values.  It
% writes out a site_flux_all_qc file and a site_flux_all_for_gap_filling
% file to send to the Reichstein online gap-filling program.  It can be
% adjusted to make other subsetted files too.
%
% This program is set up to run as a function where you enter the command
% along with the sitecode (1-7 see below) and the year.  This means that it
% only runs on files that are broken out by year.
%
% USAGE
%     UNM_RemoveBadData( sitecode, year )
%     UNM_RemoveBadData( sitecode, year, 'iteration', iteration )
%     UNM_RemoveBadData( sitecode, year, ..., 'write_QC', write_QC )
%     UNM_RemoveBadData( sitecode, year, ..., 'write_GF', write_GF )
%     UNM_RemoveBadData( sitecode, year, ..., 'draw_plots', draw_plots )
%
% INPUTS
%     sitecode: UNM_sites object or integer; specifies site to process
%     year: integer; year to process
%     iteration: optional, integer 1-6; defines which set of bad data tasks
%          to perform (see code for details)
%     write_QC: optional, logical (default true); if true, writes flux_all_qc 
%          file
%     write_GF: optional, logical (default true); if true, writes
%          flux_all_for_gapfilling file
%     draw_plots: optional, logical (default true); if true, draws diagnostic
%          plots.  If false, no plots are drawn.
%     draw_fingerprints: optional, logical (default true); if true, draws
%          fingerprint plot to assess observed variables vs hour of day.  If
%          false, no fingerprint plot is drawn.
%
% OUTPUTS:
%     This function has no outputs
%
% author: Timothy W. Hilton, UNM, May 2012


function [] = UNM_RemoveBadData_pre2012_txt( sitecode, year, varargin )
%clear all
%close all

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'iteration', 6, ...
                    @(x) ( isintval( x ) & ( x >= 1 ) & ( x <= 6 ) ) );
args.addParamValue( 'write_QC', true, @islogical );
args.addParamValue( 'write_GF', true, @islogical );
args.addParamValue( 'draw_plots', true, @islogical );
args.addParamValue( 'draw_fingerprints', true, @islogical );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

% place user arguments into variables
sitecode = args.Results.sitecode;
year_arg = args.Results.year;

% sitecode = 10;
% year = 2011;
iteration = int8( args.Results.iteration );

%true to write "[sitename].._qc", -- file with all variables & bad data removed
write_complete_out_file = args.Results.write_QC;
%true to write file for Reichstein's online gap-filling. SET U* LIM (including
%site- specific ones--comment out) TO 0!!!!!!!!!!
write_gap_filling_out_file = args.Results.write_GF;

draw_plots = args.Results.draw_plots;
draw_fingerprints = args.Results.draw_fingerprints;


data_for_analyses = 0; %1 to output file with data sorted for specific analyses
ET_gap_filler = 0; %run ET gap-filler program

winter_co2_min = -100;  %initialization -- will be set for specific sites later
obs_per_day = 48;  % half-hourly observations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify some details about sites and years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode==1; % grassland
    site='GLand';
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17523;
        lastcolumn='HC';
        ustar_lim = 0.06;
        co2_min = -7; co2_max = 6;
        co2_max_by_month = [2.5 2.5 2.5 2.5 3.5 3.5 3.5 3.5 3.5 2.5 2.5 2.5];
        co2_min_by_month = [-0.5 -0.5 -1 -3 -3 -4 -4 -4 -4 -1 -0.5 -0.5];
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='HD';
        ustar_lim = 0.06;
        co2_min_by_month = [ -0.4, -0.4, repmat( -10, 1, 9 ), -0.4 ];
        co2_max_by_month = 6;
    elseif year == 2009;
        filelength_n = 17520;
        lastcolumn='IC';
        ustar_lim = 0.06;
        winter_co2_min = -0.5;
        co2_min_by_month = -10;
        co2_max_by_month = [2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5];
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.06;
        winter_co2_min = -0.5;
        co2_min_by_month = [ -0.5, -0.5, repmat( -10, 1, 9 ), -0.5 ];;
        co2_max_by_month = 6;
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.06;
        co2_min_by_month = -0.8; co2_max_by_month = 6;
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;

elseif sitecode==2; % shrubland
    site='SLand'
    if year == 2006
    elseif year == 2007
        filelength_n = 17523;
        lastcolumn='HA';
        ustar_lim = 0.08;
        co2_min_by_month = [-0.7, -0.7, repmat( -4, 1, 9 ), -0.7 ];
        co2_max_by_month = [ repmat( 1.5, 1, 6 ), repmat( 3.5, 1, 6 ) ];
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='GZ';
        ustar_lim = 0.08;
        co2_min_by_month = -10;
        co2_max_by_month = repmat( 6, 1, 12 );
        co2_max_by_month( [ 7, 8 ] ) = 2.5; %remove some funny looking pts
                                            %in Jul and Aug
    elseif year == 2009
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.08;
        co2_min_by_month = -4; co2_max_by_month = 4;
    elseif year == 2010
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        winter_co2_min_by_month = -1;
        co2_min_by_month = -10; co2_max_by_month = 6;
    elseif year == 2011
        filelength_n = 17523;
        lastcolumn='IQ';
        ustar_lim = 0.08;
        co2_min_by_month = -10; co2_max_by_month = 6;
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode==3; % Juniper savanna
    site = 'JSav'
    if year == 2007
        filelength_n = 11596;
        lastcolumn='HR';
        ustar_lim = 0.09;
        co2_min_by_month = -11;
        co2_max_by_month = repmat( 7, 1, 12 );
        co2_max_by_month( 7 ) = 5; %remove some funny pts in July
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='HJ';
        ustar_lim = 0.08;
        co2_min_by_month = -10;
        co2_max_by_month = repmat( 10, 1, 12 );
        co2_max_by_month( 9 ) = 5; %remove some funny pts in Sep
    elseif year == 2009
        filelength_n = 17523;
        lastcolumn='IN';
        ustar_lim = 0.08;
        co2_min_by_month = -10; co2_max_by_month = 10;
    elseif year == 2010
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        co2_min_by_month = -10; co2_max_by_month = 10;
    elseif year == 2011
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        co2_min_by_month = -10; co2_max_by_month = 10;
    elseif year == 2012
        filelength_n = 7749;
        lastcolumn='FE';
        ustar_lim = 0.08;
        co2_min_by_month = -10; 
        co2_max_by_month = [ repmat( 2, 1, 6 ), repmat( 10, 1, 6 ) ];
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 550;
    HSmass_min = -100; HSmass_max = 550;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == 4; % Pinyon Juniper
    site = 'PJ'
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    co2_min_by_month = -10;
    co2_max_by_month = 6;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    if year == 2007
        lastcolumn = 'HO';
        filelength_n = 2514;
        ustar_lim = 0.16;
        co2_min_by_month = -5;
        co2_max_by_month = 2.5;
    elseif year == 2008
        lastcolumn = 'HO';
        filelength_n = 17571;
        ustar_lim = 0.16;
        co2_max_by_month = [ 1.5, 1.5, 1.4, repmat( 6, 1, 6 ), 3, 3, 3 ];
    elseif year == 2009
        lastcolumn = 'HJ';
        filelength_n = 17523;
        ustar_lim = 0.16;
    elseif year == 2010
        lastcolumn = 'HA';
        filelength_n = 17523;
        ustar_lim = 0.16;
    elseif year == 2011  % added this block Mar 21, 2011
        lastcolumn = 'EZ';
        filelength_n = 17523;
        ustar_lim = 0.16;
    elseif year == 2012  % added this block 15 Oct, 2012
        lastcolumn = 'EZ';
        co2_max_by_month = [ 2, 2, 2, 2.5, 3, 3, 3, repmat( 6, 1, 5 ) ];
        filelength_n = 11893;
        ustar_lim = 0.16;
    end    
    
elseif sitecode==5; % Ponderosa Pine
    site = 'PPine'
    % site default values
    co2_min_by_month = [-6 -6 -15 -15 -15 -15 -15 -15 -15 -15 -15 -5];
    if year == 2006
        filelength_n = 11594;
        lastcolumn='FT';
        ustar_lim = 0.08;
    elseif year == 2007
        filelength_n = 17523;
        lastcolumn='FV';
        ustar_lim = 0.08;
        co2_min_by_month = [-6 -6 -15 -20 -20 -20 -20 -20 -20 -20 -15 -10];
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='FU';
        ustar_lim = 0.08;
        co2_min_by_month = -18 %[-6 -6 -15 -15 -15 -15 -20 -20 -25 -25 -15 -10];
    elseif year == 2009;
        filelength_n = 17523;
        lastcolumn='FY';
        ustar_lim = 0.15;
        co2_min_by_month = [ -4, -10, -15, -20, -20, -20, ...
                            -20, -20, -20, -20, -15, -10 ];
        co2_max_by_month = 20;
        %co2_max_by_month = [ 8, 8, 8, repmat( 10, 1, 8 ), 4 ];
        
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='FW';
        ustar_lim = 0.08;
        co2_min_by_month = [ -15, -15, -15, -20, -20, -20, ...
                            -20, -20, -20, -20, -15, -4 ];
        
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='FY';
        ustar_lim = 0.08;
    elseif year == 2012  % added this block 15 Oct, 2012
        ustar_lim = 0.08;
    end
    co2_max_by_month = 30;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 119; wind_max = 179; % these are given a sonic_orient = 329;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode==6; % Mixed conifer
    site = 'MCon'
    co2_min_by_month = [ -1.5, -1.5, repmat( -12, 1, 9 ), -1.5 ];
    co2_max_by_month = 6;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 153; wind_max = 213; % these are given a sonic_orient = 333;
    Tdry_min = 250; Tdry_max = 300;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    if year == 2006
        filelength_n = 4420;
        lastcolumn='GA';
        ustar_lim = 0.12;
    elseif year == 2007
        filelength_n = 17523;
        lastcolumn='GB';
        ustar_lim = 0.12;
        co2_max_by_month = repmat( 6, 1, 12 );
        co2_max_by_month( [ 4, 5 ] )  = 2;
    elseif year == 2008;
        filelength_n = 17419;
        lastcolumn='GB';
        ustar_lim = 0.11;
        n_SDs_filter_hi = 3.5; % how many std devs above the mean NEE to allow
    elseif year == 2009;
        filelength_n = 17523;
        lastcolumn='GF';
        ustar_lim = 0.11;
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='GI';
        ustar_lim = 0.11;
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='GI';
        ustar_lim = 0.11;
    end
    
elseif sitecode == 7;
    site = 'TX'
    if year == 2005
        filelength_n = 17522;
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min_by_month = -26; co2_max_by_month = 12;
    elseif year == 2006
        filelength_n = 17524;
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min_by_month = -26; co2_max_by_month = 12;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FZ';
        ustar_lim = 0.11;
        co2_min_by_month = -26; co2_max_by_month = 12;
    elseif year == 2008;
        filelength_n = 17452;
        lastcolumn='GP';
        ustar_lim = 0.11;  % (changed from 0.11 10 Apr 2012 -- TWH )
        co2_min_by_month = -16; co2_max_by_month = 6;
    elseif year == 2009;
        filelength_n = 17282;
        lastcolumn='GP';
        ustar_lim = 0.11;
        co2_min_by_month = -16; co2_max_by_month = 6;
    elseif year == 2011;
        filelength_n = 7282;
        lastcolumn='GQ';
        ustar_lim = 0.11;
        co2_min_by_month = -16; co2_max_by_month = 6;
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 296; wind_max = 356; % these are given a sonic_orient = 146;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;

elseif sitecode == 8;
    site = 'TX_forest'
    if year == 2005
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2006
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='ET';
        ustar_lim = 0.12;
    elseif year == 2009;
        filelength_n = 17180;
        lastcolumn='EU';
        ustar_lim = 0.11;
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -26; co2_max_by_month = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == 9;
    site = 'TX_grassland'
    if year == 2005
        filelength_n = 17524;
        lastcolumn='DT';
        ustar_lim = 0.06;
    elseif year == 2006
        filelength_n = 17523;
        lastcolumn='DO';
        ustar_lim = 0.06;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.07;
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='ET';
        ustar_lim = 0.11;
    elseif year == 2009;
        filelength_n = 17180;
        lastcolumn='ET';
        ustar_lim = 0.11;
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -26; co2_max_by_month = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 35; h2o_min = 0;
    press_min = 70; press_max = 130;

elseif sitecode == 10; % Pinyon Juniper girdle
    site = 'PJ_girdle'
    lastcolumn = 'FE';
    ustar_lim = 0.16;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    if year == 2009
        co2_min_by_month = -10; co2_max_by_month = 6;
        filelength_n = 17523;
    elseif year == 2010
        co2_min_by_month = -7; co2_max_by_month = 6;
        filelength_n = 17523;
    elseif year == 2011
        co2_min_by_month = -10; co2_max_by_month = 6;
        filelength_n = 17523;
    elseif year == 2012
        co2_min_by_month = -10; 
        co2_max_by_month = [ 1, 1.5, 2, 2, 2, 2, 2, repmat( 6, 1, 5 ) ];
        filelength_n = 7752;
    end      

elseif sitecode == 11; % new Grassland
    site = 'New_GLand'
    ustar_lim = 0.06;
    if year == 2010
        lastcolumn = 'HF';
        filelength_n = 17523;
    elseif year == 2011
        lastcolumn = 'HS';
        filelength_n = 17523; % updated 10 Nov, 2011
        
    end  
    n_SDs_filter_hi = 4.5; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -7; co2_max_by_month = 6;
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


outfolder = fullfile( get_site_directory( sitecode ), ...
                      'processed_flux' );
FA = UNM_parse_fluxall_txt_file( sitecode, year_arg );
headertext = FA.Properties.VarNames;
[year month day hour minute second] = datevec( FA.timestamp );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some siteyears have periods where the observed radition does not line
% up with sunrise.  Fix this here so that the matched time/radiation
% propagates through the rest of the calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = UNM_fix_datalogger_timestamps( sitecode, year_arg, double( FA ) );
shift_t_str = 'shifted';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correction for incorrectly-calculated latent heat flux pointed out by Jim
% Heilman 8 Mar 2012.  E_heat_term_massman should have been added to the
% latent heat flux.  To do the job right, this fix should happen in
% UNM_flux_DATE.m.  Doing the correction here is a temporary fix in order to
% get Ameriflux files created soon.
% -TWH 9 Mar 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FA.Lv = ( repmat( 2.501, size( FA.E_raw_massman ) ) - ...
          0.00237 * ( FA.Tdry - 273.15 ) )  * 10^3;
FA.HL_wpl_massman = ( 18.016 / 1000 * FA.Lv ) .* ...
    ( FA.E_raw_massman + FA.E_heat_term_massman );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site-specific steps for soil temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Radiation corrections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

isnight = ( FA.Par_Avg < 20.0 ) | ( FA.sw_incoming < 20 );
%remove nighttime Rg and RgOut values outside of [ -5, 5 ]
% added 13 May 2013 in response to problems noted by Bai Yang
FA.sw_incoming( isnight & ( abs( FA.sw_incoming ) > 5 ) ) = NaN;
FA.sw_outgoing( isnight & ( abs( FA.sw_outgoing ) > 5 ) ) = NaN;

%%%%%%%%%%%%%%%%% grassland
if sitecode == 1
    if year_arg == 2007
        % this is the wind correction factor for the Q*7 used before ??/??      
        for i = 1:5766
            if FA.NR_tot(1) < 0
                FA.NR_tot(i) = FA.NR_tot(i)*11.42* ...
                    ((0.00174*FA.wnd_spd(i)) + 0.99755);
            elseif FA.NR_tot(1) > 0
                FA.NR_tot(i) = FA.NR_tot(i)*8.99*...
                    (1 + (0.066*0.2*FA.wnd_spd(i))/ ...
                     (0.066 + (0.2*FA.wnd_spd(i))));
            end
        end
        
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % >> for first couple of weeks the program had one incorrect
        % conversion factor (163.66)
        idx = find(decimal_day > 156.71 & decimal_day < 162.52);
        FA.sw_incoming( idx ) = FA.sw_incoming( idx )./163.66.*(1000./8.49);
        FA.sw_outgoing( idx ) = FA.sw_outgoing( idx )./163.66.*(1000./8.49);
        FA.lw_incoming( idx ) = FA.lw_incoming( idx )./163.66.*(1000./8.49);
        FA.lw_outgoing( idx ) = FA.lw_outgoing( idx )./163.66.*(1000./8.49);
        % then afterward it had a different one (136.99)
        idx = find(decimal_day > 162.67);
        FA.sw_incoming( idx ) = FA.sw_incoming( idx ).*(1000./8.49)./136.99;
        FA.sw_outgoing = FA.sw_outgoing.*(1000./8.49)./136.99;
        FA.lw_incoming = FA.lw_incoming.*(1000./8.49)./136.99;
        FA.lw_outgoing = FA.lw_outgoing.*(1000./8.49)./136.99;
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4;
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net radiation values
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration correction for the li190
        idx = find(decimal_day > 162.14);
        FA.Par_Avg( idx ) = FA.Par_Avg( idx ).*1000./(5.7*0.604);
        % estimate par from FA.sw_incoming
        idx = find(decimal_day < 162.15);
        FA.Par_Avg( idx ) = FA.sw_incoming( idx ).*2.025 + 4.715;
        
    elseif year_arg >= 2008
        % calibration correction for the li190
        FA.Par_Avg = FA.Par_Avg.*1000./(5.7*0.604);
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % and adjust for program error
        FA.sw_incoming = FA.sw_incoming./136.99.*(1000./8.49);
        FA.sw_outgoing = FA.sw_outgoing./136.99.*(1000./8.49);
        FA.lw_incoming = FA.lw_incoming./136.99.*(1000./8.49);
        FA.lw_outgoing = FA.lw_outgoing./136.99.*(1000./8.49);
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4;
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net radiation values
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; % calculate new net long wave
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; % calculate new net short wave
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
    end
    
    %%%%%%%%%%%%%%%%% shrubland 
elseif sitecode == 2    
    if year_arg == 2007
        % was this a Q*7 through the big change on 5/30/07? need updated
        % calibration
        may30 = 48 * ( datenum( 2007, 5, 30 ) - datenum( 2007, 1, 1 ) );
        for i = 1:may30
            %for i = 1:6816
            if FA.NR_tot(1) < 0
                FA.NR_tot(i) = FA.NR_tot(i)*10.74*...
                    ((0.00174*FA.wnd_spd(i)) + 0.99755);
            elseif FA.NR_tot(1) > 0
                FA.NR_tot(i) = FA.NR_tot(i)*8.65*...
                    (1 + (0.066*0.2*FA.wnd_spd(i))/...
                     (0.066 + (0.2*FA.wnd_spd(i))));
            end
        end
        
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % >> for first couple of weeks the program had one incorrect
        % conversion factor (163.66)
        idx = find(decimal_day >= 150.75 & decimal_day < 162.44);
        FA.sw_incoming( idx ) = FA.sw_incoming( idx )./163.66.*(1000./12.34);
        FA.sw_outgoing( idx ) = FA.sw_outgoing( idx )./163.66.*(1000./12.34);
        FA.lw_incoming( idx ) = FA.lw_incoming( idx )./163.66.*(1000./12.34);
        FA.lw_outgoing( idx ) = FA.lw_outgoing( idx )./163.66.*(1000./12.34);
        % >> then afterward it had a different one (136.99)
        idx  = find(decimal_day > 162.44);
        % adjust for program error and convert into W per m^2
        FA.sw_incoming( idx ) = FA.sw_incoming( idx )./136.99.*(1000./12.34); 
        FA.sw_outgoing = FA.sw_outgoing./136.99.*(1000./12.34); 
        FA.lw_incoming = FA.lw_incoming./136.99.*(1000./12.34); 
        FA.lw_outgoing = FA.lw_outgoing./136.99.*(1000./12.34); 
        % temperature correction just for long-wave        
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4; 
        
        % calculate new net radiation values
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; % calculate new net long wave
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; % calculate new net short wave
        idx = find(decimal_day >= 150.75);
        FA.NR_tot( idx ) = FA.NR_lw( idx ) + FA.NR_sw( idx );
        FA.NR_tot(find(decimal_day >= 150.75 & isnan(FA.NR_sw)==1)) = NaN;
        
        % calibration correction for the li190
        idx = find(decimal_day > 150.729);
        FA.Par_Avg( idx ) = FA.Par_Avg( idx ).*1000./(6.94*0.604);
        % estimate par from FA.sw_incoming
        find(decimal_day < 150.729)
        FA.Par_Avg( idx ) = FA.sw_incoming( idx ).*2.0292 + 3.6744;
        
    elseif any( intersect ( year_arg, 2008:2011 ) )
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % adjust for program error and convert into W per m^2
        FA.sw_incoming = FA.sw_incoming./136.99.*(1000./12.34);
        FA.sw_outgoing = FA.sw_outgoing./136.99.*(1000./12.34);
        FA.lw_incoming = FA.lw_incoming./136.99.*(1000./12.34);
        FA.lw_outgoing = FA.lw_outgoing./136.99.*(1000./12.34);
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4;
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; % calculate new net long wave
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; % calculate new net short wave
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration correction for the li190
        FA.Par_Avg = FA.Par_Avg.*1000./(6.94*0.604);
    end

    %%%%%%%%%%%%%%%%% juniper savanna
elseif sitecode == 3 
    if year_arg == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % convert into W per m^2
        FA.sw_incoming = FA.sw_incoming./163.666.*(1000./6.9); 
        FA.sw_outgoing = FA.sw_outgoing./163.666.*(1000./6.9); 
        FA.lw_incoming = FA.lw_incoming./163.666.*(1000./6.9); 
        FA.lw_outgoing = FA.lw_outgoing./163.666.*(1000./6.9);         
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4; 
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration for par-lite
        FA.Par_Avg = FA.Par_Avg.*1000./5.48;
    elseif year_arg >= 2008
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % convert into W per m^2
        FA.sw_incoming = FA.sw_incoming./163.666.*(1000./6.9); 
        FA.sw_outgoing = FA.sw_outgoing./163.666.*(1000./6.9); 
        FA.lw_incoming = FA.lw_incoming./163.666.*(1000./6.9); 
        FA.lw_outgoing = FA.lw_outgoing./163.666.*(1000./6.9); 
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4; 
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration for par-lite
        FA.Par_Avg = FA.Par_Avg.*1000./5.48;
    end
    
    % all CNR1 variables for Jsav need to be (value/163.666)*144.928

    %%%%%%%%%%%%%%%%% pinyon juniper
elseif sitecode == 4
    if year_arg == 2007
        % this is the wind correction factor for the Q*7
        idx = find(FA.NR_tot < 0);
        FA.NR_tot( idx ) = FA.NR_tot( idx ).*10.74.*((0.00174.*FA.wnd_spd( idx )) + 0.99755);
        FA.NR_tot(find(FA.NR_tot > 0)) = FA.NR_tot(find(FA.NR_tot > 0)).*8.65.*(1 + (0.066.*0.2.*FA.wnd_spd(find(FA.NR_tot > 0)))./(0.066 + (0.2.*FA.wnd_spd(find(FA.NR_tot > 0)))));
        % now correct pars
        FA.Par_Avg = FA.NR_tot.*2.7828 + 170.93; % see notes on methodology (PJ) for this relationship
        FA.sw_incoming = FA.Par_Avg.*0.4577 - 1.8691; % see notes on methodology (PJ) for this relationship
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;

    elseif year_arg == 2008
        % this is the wind correction factor for the Q*7
        idx = find(decimal_day < 172 & FA.NR_tot < 0);
        FA.NR_tot( idx ) = FA.NR_tot( idx ).*10.74.*...
            ((0.00174.*FA.wnd_spd( idx )) + 0.99755);
        idx = find(decimal_day < 172 & FA.NR_tot > 0);
        FA.NR_tot( idx ) = FA.NR_tot( idx ).*8.65.*...
            (1 + (0.066.*0.2.*FA.wnd_spd( idx )) ./ ...
             (0.066 + (0.2.*FA.wnd_spd( idx ))));
        % now correct pars
        idx = find(decimal_day < 42.6);
        FA.Par_Avg( idx ) = FA.NR_tot( idx ).*2.7828 + 170.93;
        % calibration for par-lite installed on 2/11/08
        idx = find(decimal_day > 42.6);
        FA.Par_Avg( idx ) = FA.Par_Avg( idx ).*1000./5.51;
        idx = find(decimal_day < 172);
        FA.sw_incoming( idx ) = FA.Par_Avg( idx ).*0.4577 - 1.8691;

        % temperature correction just for long-wave
        idx = find(decimal_day > 171.5);
        FA.lw_incoming( idx ) = FA.lw_incoming( idx ) + ...
            0.0000000567.*(FA.CNR1TK( idx )).^4; 
        FA.lw_outgoing( idx ) = FA.lw_outgoing( idx ) + ...
            0.0000000567.*(FA.CNR1TK( idx )).^4;        
        % calculate new net radiation values
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot( idx ) = FA.NR_lw( idx ) + FA.NR_sw( idx );
    
    elseif year_arg >= 2009
        % calibration for par-lite installed on 2/11/08
        FA.Par_Avg = FA.Par_Avg.*1000./5.51;
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + ...
            ( 0.0000000567 .* ( FA.CNR1TK .^ 4 ) );
        FA.lw_outgoing = FA.lw_outgoing + ...
            ( 0.0000000567 .* ( FA.CNR1TK .^ 4 ) );
        % calculate new net radiation values
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
    end

    %%%%%%%%%%%%%%%%% ponderosa pine
elseif sitecode == 5
    if year_arg == 2007
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4; 
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % Apply correct calibration value 7.37, SA190 manual section 3-1
        FA.Par_Avg=FA.Par_Avg.*225;  
        % Apply correction to bring in to line with Par-lite from mid 2008 
        % onwards
        FA.Par_Avg=FA.Par_Avg+(0.2210.*FA.sw_incoming); 
        
    elseif year_arg == 2008
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration for Licor sesor  
        % Apply correct calibration value 7.37, SA190 manual section 3-1
        FA.Par_Avg(1:10063)=FA.Par_Avg(1:10063).*225;  
        FA.Par_Avg(1:10063)=FA.Par_Avg(1:10063)+ ...
            (0.2210.*FA.sw_incoming(1:10063));
        % calibration for par-lite sensor
        FA.Par_Avg(10064:end) = FA.Par_Avg(10064:end).*1000./5.25;
        
    elseif year_arg == 2009 || year_arg ==2010 || year_arg == 2011
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration for par-lite sensor
        FA.Par_Avg = FA.Par_Avg.*1000./5.25;
    end


    
    
    %%%%%%%%%%%%%%%%% mixed conifer
elseif sitecode == 6
    if year_arg == 2006 || year_arg == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4; 
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        
    elseif year_arg > 2007
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites   
        % temperature correction just for long-wave
        FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4;
        FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
        % calculate new net long wave
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
        % calibration for par-lite sensor
        FA.Par_Avg = FA.Par_Avg.*1000./5.65;
        
    end
    
    %%%%%%%%%%%%%%%%% texas
elseif sitecode == 7
    % calibration for the li-190 par sensor - sensor had many high
    % values, so delete all values above 6.5 first
    FA.Par_Avg(find(FA.Par_Avg > 13.5)) = NaN;
    FA.Par_Avg = FA.Par_Avg.*1000./(6.16.*0.604);
    if year_arg == 2007 || year_arg == 2006 || year_arg == 2005
        % wind corrections for the Q*7
        FA.NR_tot( idx ) = FA.NR_tot( idx ).*10.91.*...
            ((0.00174.*FA.wnd_spd( idx )) + 0.99755);
        idx = find(FA.NR_tot > 0)
        FA.NR_tot( idx ) = FA.NR_tot( idx ).*8.83.* ...
            (1 + (0.066.*0.2.*FA.wnd_spd( idx ))./ ...
             (0.066 + (0.2.*FA.wnd_spd( idx ))));

        % no long-wave data for TX
        FA.lw_incoming(1:datalength,1) = NaN;
        FA.lw_outgoing(1:datalength,1) = NaN;
        % pyrronometer corrections
        FA.sw_incoming = FA.sw_incoming.*1000./27.34;
        FA.sw_outgoing = FA.sw_outgoing.*1000./19.39;
        % calculate new net short wave
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
        % calculate new net long wave from total net minus sw net
        FA.NR_lw = FA.NR_tot - FA.NR_sw;
    elseif year_arg == 2008 || year_arg == 2009
        % par switch to par-lite on ??
        FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
        FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
        FA.NR_tot = FA.NR_lw + FA.NR_sw;
    end
    
elseif sitecode == 8 
    % for TX forest 2009, there was no PAR observation in the fluxall file on
    % 15 Mat 2012.  We substituted in PAR from the TX savana site. --  TWH &
    % ML
    if year == 2009
        FA.Par_Avg(find(FA.Par_Avg > 13.5)) = NaN;
        FA.Par_Avg = FA.Par_Avg.*1000./(6.16.*0.604);
    end
    FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
    FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
    FA.NR_tot = FA.NR_lw + FA.NR_sw;
    
elseif sitecode == 9
    FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
    FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
    FA.NR_tot = FA.NR_lw + FA.NR_sw;
elseif sitecode == 10
    % temperature correction just for long-wave
    FA.lw_incoming = FA.lw_incoming + ( 0.0000000567 .* ( FA.CNR1TK .^ 4 ) )
    FA.lw_outgoing = FA.lw_outgoing + ( 0.0000000567 .* ( FA.CNR1TK .^ 4 ) )
    % recalculate net radiation with T-adjusted longwave
    FA.NR_lw = FA.lw_incoming - FA.lw_outgoing;
    FA.NR_sw = FA.sw_incoming - FA.sw_outgoing;
    FA.NR_tot = FA.NR_lw + FA.NR_sw;
    
    %%%%%%%%%%%%%%%%% New Grassland
elseif sitecode == 11 
    % calibration correction for the li190
    FA.Par_Avg = FA.Par_Avg.*1000./(5.7*0.604);
    % calibration and unit conversion into W per m^2 for CNR1 variables
    % and adjust for program error
    FA.sw_incoming = FA.sw_incoming./136.99.*(1000./8.49);
    FA.sw_outgoing = FA.sw_outgoing./136.99.*(1000./8.49);
    FA.lw_incoming = FA.lw_incoming./136.99.*(1000./8.49);
    FA.lw_outgoing = FA.lw_outgoing./136.99.*(1000./8.49);
    % temperature correction just for long-wave
    FA.lw_incoming = FA.lw_incoming + 0.0000000567.*(FA.CNR1TK).^4;
    FA.lw_outgoing = FA.lw_outgoing + 0.0000000567.*(FA.CNR1TK).^4;
    % calculate new net radiation values
    FA.NR_lw = FA.lw_incoming - FA.lw_outgoing; 
    FA.NR_sw = FA.sw_incoming - FA.sw_outgoing; 
    FA.NR_tot = FA.NR_lw + FA.NR_sw;
end

% normalize PAR to account for calibration problems at some sites
if ismember( sitecode, [ 1, 2, 3, 4, 10, 11 ] );
    if ( sitecode == 3 ) & ( year_arg == 2008 )
        % there is a small but suspicious-looking step change at DOY164 -
        % normalize the first half of the year separately from the second
        doy164 = DOYidx( 164 );
        FA.Par_Avg1 = normalize_PAR( sitecode, ...
                                  FA.Par_Avg( 1:doy164 ), ...
                                  decimal_day( 1:doy164 ), ...
                                  draw_plots );
        FA.Par_Avg2 = normalize_PAR( sitecode, ...
                                  FA.Par_Avg( (doy164 + 1):end ), ...
                                  decimal_day( (doy164 + 1):end ), ...
                                  draw_plots );
        FA.Par_Avg = [ FA.Par_Avg1; FA.Par_Avg2 ];

    elseif ( sitecode == 10 ) & ( year_arg == 2010 )
        % two step changes in this one
        doy138 = DOYidx( 138 );
        doy341 = DOYidx( 341 );
        FA.Par_Avg1 = normalize_PAR( sitecode, ...
                                  FA.Par_Avg( 1:doy138 ), ...
                                  decimal_day( 1:doy138 ), ...
                                  draw_plots );
        FA.Par_Avg2 = normalize_PAR( sitecode, ...
                                  FA.Par_Avg( doy138+1:doy341 ), ...
                                  decimal_day( doy138+1:doy341 ), ...
                                  draw_plots );
        FA.Par_Avg = [ FA.Par_Avg1; FA.Par_Avg2; FA.Par_Avg( doy341+1:end ) ];
    else
        FA.Par_Avg = normalize_PAR( sitecode, ...
                                 FA.Par_Avg, ...
                                 decimal_day, ...
                                 draw_plots );
    end
end
% fix calibration problem at JSav 2009
if ( sitecode == 3 ) & ( year_arg == 2009 )
    FA.Par_Avg( 1:1554 ) = FA.Par_Avg( 1:1554 ) + 133;
end
FA.Par_Avg( FA.Par_Avg < -50 ) = NaN;

% remove negative Rg_out values
FA.sw_outgoing( FA.sw_outgoing < -50 ) = NaN;

% make sure net radiation is less than incoming shortwave
% added 13 May 2013 in response to problems noted by Bai Yang1
FA.NR_tot( FA.NR_tot > FA.sw_incoming ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply Burba 2008 correction for sensible heat conducted from 7500
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define some constants
R = 8.3143e-3; % universal gas constant  [J / kmol / K ]
Rd = 287.04; % dry air gas constant [J / kg / K]
MWd = 28.97; % dry air molecular weight [g / mol]
R_h2o = 461.5; % water vapor gas constant [J / kg / K]
MW_h2o = 16; % water vapor molecular weight [g / mol]

% This is the conversion from mumol mol to mg m3 for CO2
hh = (1 ./ ( R .* ( FA.t_meanK ./ FA.atm_press ) .* 1000 ) ) .* 44;
% convert umol CO2 / mol dry air to mg CO2 / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_co2 = ( ( MWd * Rd * FA.t_meanK ) / ( 1000 * FA.atm_press ) ) * ( 44 / 1000 );
CO2_mg = FA.CO2_mean .* hh;

% This is the conversion from mmol mol to g m3 for H2O
gg = ( ( 1 ./ ( R .* ( FA.t_meanK ./ FA.atm_press ) ) ) .* 18 ) ./ 1000;
% convert mmol H2O / mol dry air to g H2O / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_h2o = ( MW_h2o * R_h2o * FA.t_meanK ) / ( 1000 * FA.atm_press )
H2O_g = FA.H2O_mean .* gg;

rhoa_dry_kg = ( FA.rhoa_dry .* MWd ) ./ 1000; % from mol/m3 to kg/m3

Cp = 1004.67 + ( Tdry .^ 2 ./ 3364 );
RhoCp = FA.rhoa_dry_kg .* Cp;
NR_pos = find( FA.NR_tot > 0 );

Kair = ( 0.000067 .* FA.t_mean ) + 0.024343;

Ti_bot = (0.883.*FA.t_mean+2.17)+273.16;
Ti_bot(NR_pos) = (0.944.*FA.t_mean(NR_pos)+2.57)+273.16;
Ti_top = (1.008.*FA.t_mean-0.41)+273.16;
Ti_top(NR_pos) = (1.005.*FA.t_mean(NR_pos)+0.24)+273.16;
Ti_spar = (1.01.*FA.t_mean-0.17)+273.16;
Ti_spar(NR_pos) = (1.01.*FA.t_mean(NR_pos)+0.36)+273.16;
Si_bot = Kair.*(Ti_bot-FA.t_meank)./(0.004.*sqrt(0.065./abs(FA.u_mean))+0.004);
Si_top = ( Kair.*(Ti_top-FA.t_meank) .* ...
           (0.0225+(0.0028.*sqrt(0.045./abs(FA.u_mean)) + ...
                    0.00025./abs(FA.u_mean)+0.0045)) ./ ...
           (0.0225*(0.0028*sqrt(0.045./abs(FA.u_mean)) + ...
                    0.00025./abs(FA.u_mean)+0.0045)) );
Sip_spar = ( Kair .* (Ti_spar - FA.t_meank) ./ ...
             (0.0025 .* log((0.0025 + 0.0058 .* ...
                             sqrt(0.005./abs(FA.u_mean))) ./ 0.0025)).*0.15 );
pd = 44.6.*28.97.*FA.atm_press./101.3.*273.16./FA.t_meank;
dFc = (Si_top+Si_bot+Sip_spar) ./ RhoCp.*CO2_mg ./ FA.t_meank .* ...
      (1+1.6077.*H2O_g./pd);

if draw_plots
    h_burba_fig = figure( 'Name', 'Burba' );
    plot(dFc,'.'); ylim([-1 1]);
    title( sprintf('%s %d', get_site_name( sitecode ), year( 1 ) ) );
    ylabel('Burba cold temp correction');
    xlabel('time');
end

% Convert correct flux from mumol/m2/s to mg/m2/s
fc_mg = FA.fc_raw_massman_wpl.*0.044; 
fc_mg_corr = (FA.fc_raw_massman_wpl.*0.044)+dFc;


found = find(FA.t_mean<0);
fc_out=fc_mg;
fc_out(found)=fc_mg_corr(found);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filters for co2 and make a master flag variable (decimal_day_nan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decimal_day_nan = decimal_day;
record = 1:1:length(FA.fc_raw_massman_wpl);
conc_record = 1:1:length(FA.CO2_mean);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 1 - run and plot fluxes with the following four filters with
% all other filters commented out, then evaluate the ustar cutoff with
% figure (1).  Use the plot to decide which ustar bin on the x-axis is the
% cutoff, and then use the printed out vector on the main screen to decide
% what the ustar value is for that bin.  That's the number you enter into
% the site-specific info above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Number of co2 flux periods removed due to:');
% Original number of NaNs
nanflag = find(isnan(FA.fc_raw_massman_wpl));
removednans = length(nanflag);
decimal_day_nan(nanflag) = NaN;
record(nanflag) = NaN;
co2_conc_nanflag = find(isnan(FA.CO2_mean));
conc_record(co2_conc_nanflag) = NaN;
disp(sprintf('    original empties = %d',removednans));

% % Remove values during precipitation
precipflag = find(FA.precip > 0);
removed_precip = length(precipflag);
decimal_day_nan(precipflag) = NaN;
record(precipflag) = NaN;
conc_record(precipflag) = NaN;
disp(sprintf('    precip = %d',removed_precip));

% Remove for behind tower wind direction
windflag = find(FA.wnd_dir_compass > wind_min & FA.wnd_dir_compass < wind_max);
removed_wind = length(windflag);
decimal_day_nan(windflag) = NaN;
record(windflag) = NaN;
disp(sprintf('    wind direction = %d',removed_wind));

% Remove night-time negative fluxes
% changed NEE cutoff from 0 to -0.2 as per conversation with Marcy 29 Mar 2012
isnight = ( FA.Par_Avg < 20.0 ) | ( FA.sw_incoming < 20 );
nightnegflag = find( isnight & ( FA.fc_raw_massman_wpl < -0.2) );
removed_nightneg = length(nightnegflag);
decimal_day_nan(nightnegflag) = NaN;
record(nightnegflag) = NaN;
disp(sprintf('    night-time negs = %d',removed_nightneg));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PPINE EXTRA WIND DIRECTION REMOVAL
% ppine has super high night respiration when winds come from ~ 50 degrees, so these must be excluded also:
if sitecode == 5
    ppine_night_wind = find( ( FA.wnd_dir_compass > 30 & ...
                               FA.wnd_dir_compass < 65 ) & ...
                             ( hour <= 9 | hour > 18 ) );
    windflag = unique( [ windflag; ppine_night_wind ] );
    removed_ppine_night_wind = length(ppine_night_wind);
    decimal_day_nan(ppine_night_wind) = NaN;
    record(ppine_night_wind) = NaN;
    conc_record(ppine_night_wind) = NaN;
    disp(sprintf('    ppine night winds = %d',removed_ppine_night_wind));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gland 2007 had large fluxes for very cold temperatures early in the year.
if sitecode == 1 && year_arg == 2007
    gland_cold = find( FA.Tdry < 271 );
    removed_gland_cold = length( gland_cold );
    decimal_day_nan( gland_cold ) = NaN;
    record( gland_cold ) = NaN;
    disp( sprintf( '    gland cold = %d',removed_gland_cold ));
end

% Take out dodgy calibration period at Shrubland in 2007
if sitecode == 2 && year_arg == 2007 
    decimal_day_nan(12150:12250) = NaN;
    record(12150:12250) = NaN;
    conc_record(12600:12750) = NaN;
end

% Take out dodgy calibration period at Shrubland in 2009
if sitecode == 2 && year_arg == 2009 
    conc_record(11595:11829) = NaN;
end


% Plot out to see and determine ustar cutoff
if iteration == 1    
    u_star_2 = FA.u_star(find(~isnan(decimal_day_nan)));
    fc_raw_massman_wpl_2 = FA.fc_raw_massman_wpl(find(~isnan(decimal_day_nan)));
    hour_2 = hour(find(~isnan(decimal_day_nan)));
    
    n_bins = 30; % you can change this to have more or less categories
    ustar_bin = 1:1:n_bins;
    ustar_mean = repmat( NaN, size( ustar_bin ) );
    for i = 1:n_bins % you can change this to have more or less categories
        if i == 1
            startbin(i) = 0;
        elseif i >= 2
            startbin(i) = (i - 1)*0.01;
        end
        endbin(i) = 0.01 + startbin(i);    
        elementstouse = find( ( u_star_2 > startbin(i) & ...
                                u_star_2 < endbin(i)) & ...
                              ( hour_2 > 22 | hour_2 < 5) );
        co2mean(i) = mean(fc_raw_massman_wpl_2(elementstouse));
        ustar_mean( i ) = mean( u_star_2( elementstouse ) );
    end

    startbin;
    if draw_plots
        figure( 'Name', 'determine Ustar cutoff', 'NumberTitle', 'Off' );
        clf;
        plot( ustar_mean, FA.co2mean, '.k' );
        xlabel( 'UStar' );
        ylabel( 'co2mean' );
        title( 'determine UStar cutoff' );
        shg;
    end
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 2 - Now that you have entered a ustar cutoff in the site
% options above, run with iteration 2 to see the effect of removing those
% values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 1
    
    % Remove values with low U*
    ustarflag = find(FA.u_star < ustar_lim);
    removed_ustar = length(ustarflag);
    decimal_day_nan(ustarflag) = NaN;
    record(ustarflag) = NaN;
    
    % display pulled ustar
    disp(sprintf('    FA.u_star = %d',removed_ustar));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 3 - now that values have been filtered for ustar, decide what
% the min and max co2 flux values should be by examining figure 2 and then
% entering them in the site options above, then run program with iteration
% 3 and see the effect of removing them in figure 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if iteration > 2
    
    if ( sitecode == UNM_sites.GLand )
        FA.precip = fill_Gland_2011_precip_from_SLand(FA.precip);
    end
    
    [ FA.fc_raw_massman_wpl, FA.E_wpl_massman, FA.HL_wpl_massman, FA.HSdry, ...
      FA.HSdry_massman, FA.CO2_mean, FA.H2O_mean, FA.atm_press, FA.NR_tot, ...
      FA.sw_incoming, FA.sw_outgoing, FA.lw_incoming, FA.lw_outgoing, ...
      FA.precip, FA.rH ] = ...
        remove_specific_problem_periods( sitecode, ...
                                         year_arg, ...
                                         FA.fc_raw_massman_wpl, ...
                                         FA.E_wpl_massman, ...
                                         FA.HL_wpl_massman, ...
                                         FA.HSdry, ...
                                         FA.HSdry_massman, ...
                                         FA.CO2_mean, ...
                                         FA.H2O_mean, ...
                                         FA.atm_press, ...
                                         FA.NR_tot, ...
                                         FA.sw_incoming, ...
                                         FA.sw_outgoing, ...
                                         FA.lw_incoming, ...
                                         FA.lw_outgoing, ...
                                         FA.precip, ...
                                         FA.rH );

    [ DOY_co2_min, DOY_co2_max ] = get_daily_maxmin( month, ...
                                                     co2_min_by_month, ...
                                                     co2_max_by_month, ...
                                                     winter_co2_min );

    
    removed_maxs_mins=0;
    maxminflag = [];

    [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
        specify_siteyear_filter_exceptions( sitecode, year_arg, ...
                                            DOY_co2_min, DOY_co2_max );
    
    maxminflag = ( ( FA.fc_raw_massman_wpl > DOY_co2_max ) | ...
                   ( FA.fc_raw_massman_wpl < DOY_co2_min ) );
    
    removed_maxs_mins = numel( find( maxminflag ) );
    decimal_day_nan( maxminflag ) = NaN;
    record( maxminflag ) = NaN;
    
    % display what is pulled for maxs and mins
    disp(sprintf('    above max or below min = %d',removed_maxs_mins));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 4 - Now examine the effect of high and low co2 filters by
% running program with iteration 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if iteration > 3
    
    % Remove high CO2 concentration points
    highco2flag = find(FA.CO2_mean > 450);

    % exceptions
    co2_conc_filter_exceptions = repmat( false, size( FA.CO2_mean ) );
    co2_conc_filter_exceptions = ...
        specify_siteyear_co2_conc_filter_exceptions( ...
            sitecode, year, co2_conc_filter_exceptions );

    removed_highco2 = length(highco2flag);
    decimal_day_nan(highco2flag) = NaN;
    record(highco2flag) = NaN;
    conc_record(highco2flag) = NaN;

    % Remove low CO2 concentration points
    if sitecode == 9
        lowco2flag = find(FA.CO2_mean <250);
    elseif sitecode == 8 && year(1) ==2008
        lowco2flag = find(FA.CO2_mean <250);
    elseif sitecode == 1 && year(1) ==2007
        lowco2flag = find(FA.CO2_mean <344);
    else
        lowco2flag = find(FA.CO2_mean <350);
    end

    removed_lowco2 = length(lowco2flag);
    decimal_day_nan(lowco2flag) = NaN;
    record(lowco2flag) = NaN;
    conc_record(lowco2flag) = NaN;
    
    % display what's pulled for too high or too low co2
    disp(sprintf('    low co2 = %d',removed_lowco2));
    disp(sprintf('    high co2 = %d',removed_highco2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 5 - Now clear out the last of the outliers by running iteration
% 5, which removes values outside a running standard deviation window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 4
    % Remove values outside of a running standard deviation
    n_bins = 48;
    std_bin = zeros( 1, n_bins );
    bin_length = round( length( FA.fc_raw_massman_wpl )/ n_bins );

    % count up what's been filtered out already
    good_co2 = repmat( true, size( decimal_day ) );
    good_co2( highco2flag ) = false;
    good_co2( lowco2flag ) = false;
    good_co2( co2_conc_filter_exceptions ) = true;

    idx_NEE_good = repmat( true, size( decimal_day ) );
    idx_NEE_good( ustarflag ) = false;
    idx_NEE_good( precipflag ) = false;
    idx_NEE_good( nightnegflag ) = false;
    idx_NEE_good( windflag ) = false;
    idx_NEE_good( maxminflag ) = false;
    idx_NEE_good( nanflag ) = false;
    idx_NEE_good( ~good_co2 ) = false;
    %    idx_NEE_good( idx_std_removed ) = false;
    stdflag = repmat( false, size( idx_NEE_good ) );

    for i = 1:n_bins
        if i == 1
            startbin( i ) = 1;
        elseif i >= 2
            startbin( i ) = ( (i-1) * bin_length );
        end    
        endbin( i ) = min( bin_length + startbin( i ), numel( idx_NEE_good ) );

        % make logical indices for elements that are (1) in this bin and (2)
        % not already filtered for something else
        this_bin = repmat( false, size( idx_NEE_good ) );
        this_bin( startbin( i ):endbin( i ) ) = true;
        
        std_bin(i) = ...
            nanstd( FA.fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        mean_flux(i) = ...
            nanmean( FA.fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        bin_ceil(i) = mean_flux( i ) + ( n_SDs_filter_hi * std_bin( i ) );
        bin_floor(i) = mean_flux( i ) - ( n_SDs_filter_lo * std_bin( i ) );
        stdflag_thisbin_hi = ( this_bin & ...
                               FA.fc_raw_massman_wpl > bin_ceil( i ) );
        stdflag_thisbin_low = ( this_bin & ...
                                FA.fc_raw_massman_wpl < bin_floor( i ) );
        stdflag = stdflag | stdflag_thisbin_hi | stdflag_thisbin_low;
        stdflag( find( std_exc_flag ) ) = false;

        elementstouse_c = find( conc_record > startbin( i ) & ...
                               conc_record <= endbin( i ) & ...
                               isnan( conc_record) == 0);
        conc_std_bin( i) = std( FA.CO2_mean( elementstouse_c));
        mean_conc( i) = mean( FA.CO2_mean( elementstouse_c));
        if sitecode == 7
            conc_bin_index = find( FA.CO2_mean( elementstouse_c) < ...
                                  ( mean_conc( i)-( 2.*conc_std_bin( i)))...
                                  | FA.CO2_mean( elementstouse_c) > ...
                                  ( mean_conc( i)+( 2.*conc_std_bin( i))) & ...
                                  FA.wnd_spd( elementstouse_c) > 0.3);
        else
            conc_bin_index = find( FA.CO2_mean(elementstouse_c) < ...
                                   (mean_conc(i)-(2.*conc_std_bin(i)))  | ...
                                   FA.CO2_mean(elementstouse_c) > ...
                                   (mean_conc(i)+(2.*conc_std_bin(i))) & ...
                                   FA.wnd_spd(elementstouse_c) > 3);
        end
        conc_outofstdnan = elementstouse_c(conc_bin_index);
        conc_record(conc_outofstdnan) = NaN;
        
        CO2_to_plot = FA.CO2_mean(elementstouse_c);
        wnd_to_plot = FA.wnd_spd(elementstouse_c);
        xxo=ones(length(elementstouse_c),1);
        xaxis=linspace(1,length(elementstouse_c),length(elementstouse_c));
        
        xx((i*2)-1)=startbin( i );
        xx(i*2)=endbin( i );
        yy((i*2)-1)=mean_conc(i);
        yy(i*2)=mean_conc(i);
        yyl((i*2)-1)=(mean_conc(i)-(2.*conc_std_bin(i)));
        yyl(i*2)=(mean_conc(i)-(2.*conc_std_bin(i)));
        yyu((i*2)-1)=(mean_conc(i)+(2.*conc_std_bin(i)));
        yyu(i*2)=(mean_conc(i)+(2.*conc_std_bin(i)));
        
    end   
    idx_NEE_good( stdflag ) = false;
    decimal_day_nan(stdflag) = NaN;
    record(stdflag) = NaN;
    removed_outofstdnan = numel( find (stdflag ) );
    disp(sprintf('    above %d or below %d running standard deviations = %d', ...
                 n_SDs_filter_hi, n_SDs_filter_lo, removed_outofstdnan ) );

    if xx( end ) > length( decimal_day )
        xx(end) = length(decimal_day);
    end
    pal = cbrewer( 'qual', 'Dark2', 8 );

    if draw_plots
        h_co2_fig = figure( 'Name', '[CO2]' );
        FA.CO2_mean_clean=FA.CO2_mean;
        FA.CO2_mean_clean(find(isnan(conc_record)))=-9999;
        h_co2_all = plot( decimal_day, FA.CO2_mean, ...
                          'Marker', '.', ...
                          'Color', 'black', ...
                          'LineStyle', 'none');
        title( sprintf( '%s %d', get_site_name( sitecode ), year( 1 ) ) );
        hold on;
        h_co2_clean = plot( decimal_day, FA.CO2_mean_clean, ...
                            'Marker', 'o', ...
                            'Color', pal( 1, : ), ...
                            'LineStyle', 'none');
        h_FA.CO2_mean = plot( decimal_day(xx), yy, ...
                           'Marker', 'o', ...
                           'Color', pal( 3, : ), ...
                           'LineStyle', '-', ...
                           'LineWidth', 3);
        h_co2_std = plot( decimal_day(xx), yyl, ...
                          'Color', pal( 3, : ), ...
                          'linewidth', 3 );
        h_co2_std = plot( decimal_day(xx), yyu, ...
                          'Color', pal( 3, : ),...
                          'linewidth', 3 );
        xx=linspace(1, length(FA.CO2_mean), length(FA.CO2_mean));
        ylim([300 450]);
        xlabel('day of year');
        ylabel('[CO_2], ppm');
        legend( [ h_co2_all, h_co2_clean, h_FA.CO2_mean, h_co2_std ], ...
                'all [CO2]', 'cleaned [CO2]', 'mean [CO2]', 'st dev [CO2]', ...
                'Location', 'best' );
    end  %co2 plot
end % close if statement for iterations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the co2 flux for the whole series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restore_fname = fullfile( getenv( 'FLUXROOT' ), ...
                          'FluxOut', ...
                          'QC_files', ...
                          sprintf( '%s_%d_QC_Tim.mat', ...
                                   get_site_name( sitecode ), ...
                                   year( 2 ) ) );
save_vars = { 'sitecode', 'year', 'decimal_day', 'FA.fc_raw_massman_wpl', ...
              'idx_NEE_good', 'ustarflag', 'precipflag', 'nightnegflag', ...
              'windflag', 'maxminflag', 'lowco2flag', 'highco2flag', ...
              'nanflag', 'stdflag', 'n_bins', 'endbin', 'startbin', ...
              'bin_ceil', 'bin_floor', 'mean_flux' };
save( restore_fname, save_vars{ : } );

maxminflag = find( maxminflag );

if sitecode == UNM_sites.PPine
    FA.fc_raw_massman_wpl = ...
        normalize_PPine_NEE( FA.fc_raw_massman_wpl, idx_NEE_good );
end

if draw_plots
    [ h_fig_flux, ax_NEE, ax_flags ] = plot_NEE_with_QC_results( ...
        sitecode, ...
        year, ...
        decimal_day, ...
        FA.fc_raw_massman_wpl, ...
        idx_NEE_good, ustarflag, ...
        precipflag, nightnegflag, ...
        windflag, maxminflag, ...
        lowco2flag, highco2flag, ...
        nanflag, stdflag, n_bins, ...
        endbin, startbin, bin_ceil, ...
        bin_floor, mean_flux );
    shg;  %bring current window to front
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for sensible heat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max and mins for HSdry
HS_flag = find(FA.HSdry > HS_max | FA.HSdry < HS_min);
FA.HSdry(HS_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
FA.HSdry(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
if iteration > 1
    FA.HSdry(ustarflag) = NaN;
    removed_HS = length(find(isnan(FA.HSdry)));
end

% max and mins for HSdry_massman
HSmass_flag = find(FA.HSdry_massman > HSmass_max | ...
                   FA.HSdry_massman < HSmass_min);
FA.HSdry_massman(HSmass_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
FA.HSdry_massman(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
FA.HSdry_massman(ustarflag) = NaN;
removed_HSmass = length(find(isnan(FA.HSdry_massman)));

% clean the co2 flux variables
FA.fc_raw( not( idx_NEE_good ) ) = NaN;
FA.fc_raw_massman( not( idx_NEE_good ) ) = NaN;
FA.fc_water_term( not( idx_NEE_good ) ) = NaN;
FA.fc_heat_term_massman( not( idx_NEE_good ) ) = NaN;
FA.fc_raw_massman_wpl( not( idx_NEE_good ) ) = NaN;

% clean the h2o flux variables - remove points flagged for ustar, wind, or pcp
idx_E_good = repmat( true, size( E_raw ) );
idx_E_good( unique( [ ustarflag; windflag; precipflag ] ) ) = false;
FA.E_raw( not( idx_E_good ) ) = NaN;
FA.E_raw_massman( not( idx_E_good ) ) = NaN;
FA.E_water_term( not( idx_E_good ) ) = NaN;
FA.E_heat_term_massman( not( idx_E_good ) ) = NaN;
FA.E_wpl_massman( not( idx_E_good ) ) = NaN;

% clean the co2 concentration
FA.CO2_mean( isnan( conc_record ) ) = NaN;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for max's and min's for other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% QC for HL_raw
LH_flag = ( FA.HL_raw > LH_max ) | ( FA.HL_raw < LH_min );
removed_LH = length( find( LH_flag ) );
FA.HL_raw( LH_flag ) = NaN;

% QC for HL_wpl_massman
LH_min = -20;  %as per Jim Heilman, 28 Mar 2012

% if PAR measurement exists, use this to remove nighttime LE, otherwise
% use FA.NR_tot
LH_rad = FA.Par_Avg;
LH_rad( isnan( LH_rad ) ) = FA.NR_tot( isnan( LH_rad ) );

LH_maxmin_flag = ( FA.HL_wpl_massman > LH_max ) | ( FA.HL_wpl_massman < LH_min );
LH_night_flag = ( LH_rad < 20.0 ) & ( abs( FA.HL_wpl_massman ) > 20.0 );
LH_day_flag = ( LH_rad >= 20.0 ) & ( FA.HL_wpl_massman < 0.0 );
if draw_plots
    script_LE_diagnostic_plot;
end
removed_LH_wpl_mass = numel( find( LH_maxmin_flag | ...
                                   LH_night_flag | ...
                                   LH_day_flag ) );
FA.HL_wpl_massman( LH_maxmin_flag | LH_night_flag | LH_day_flag ) = NaN;
% QC for FA.sw_incoming

% QC for Tdry
Tdry_flag = find(FA.Tdry > Tdry_max | FA.Tdry < Tdry_min);
removed_Tdry = length(Tdry_flag);
FA.Tdry(Tdry_flag) = NaN;

% QC for Tsoil

% QC for rH
rH_flag = find(FA.rH > rH_max | FA.rH < rH_min);
removed_rH = length(rH_flag);
FA.rH(rH_flag) = NaN;

% QC for h2o mean values
h2o_flag = ( FA.H2O_mean > h2o_max ) | ( FA.H2O_mean < h2o_min );
removed_h2o = length( find ( h2o_flag ) );
FA.H2O_mean( h2o_flag ) = NaN;

% QC for atmospheric pressure
press_flag = []; %find(FA.atm_press > press_max | FA.atm_press < press_min);
removed_press = length(press_flag);
FA.atm_press(press_flag) = NaN;

% min/max QC for TX soil heat fluxes
if sitecode == 7
    if year_arg == 2005
        soil_heat_flux_open(find(soil_heat_flux_open > 100 | ...
                                 soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | ...
                                   soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | ...
                                   soil_heat_flux_juncan < -60)) = NaN;
    elseif year_arg == 2006
        soil_heat_flux_open(find(soil_heat_flux_open > 90 | ...
                                 soil_heat_flux_open < -60)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | ...
                                   soil_heat_flux_mescan < -50)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | ...
                                   soil_heat_flux_juncan < -60)) = NaN;
    elseif year_arg == 2007 
        soil_heat_flux_open(find(soil_heat_flux_open > 110 | ...
                                 soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 40 | ...
                                   soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 20 | ...
                                   soil_heat_flux_juncan < -40)) = NaN;
    end
end

% remove days 295 to 320 for GLand 2010 for several variables -- the reported
% values look weirdly bogus -- TWH 9 Apr 2012
if sitecode == 1 & year(2) == 2010
    bogus_idx = ( decimal_day >= 294 ) & ( decimal_day <= 320 );
    FA.HL_wpl_massman( bogus_idx ) = NaN;
    FA.HSdry_massman( bogus_idx ) = NaN;
    FA.E_wpl_massman( bogus_idx ) = NaN;
    FA.lw_incoming( bogus_idx ) = NaN;
    FA.lw_outgoing( bogus_idx ) = NaN;
end

if ( sitecode == 5 ) & ( year(2) == 2008 )
    bogus_idx = ( decimal_day >= 100 ) & ...
        ( decimal_day < 190 ) & ...
        ( FA.rH < 0.03 );
    FA.rH( bogus_idx ) = NaN;
end

if ( sitecode == 7 ) & ( year( 2 ) == 2008 )
    FA.u_star( FA.u_star > 200 ) = NaN;
end

if ( sitecode == 3 ) & ( year( 2 ) == 2009 )
    FA.u_star( decimal_day < 34 ) = NaN;
    FA.wnd_dir_compass( decimal_day < 34 ) = NaN;
end

% small runs of consecutive zeros in these fields are (1) almost certainly bogus
% and (2) seem to mess up the Lasslop flux partitioning.  Replace them
% here with NaN.
FA.fc_raw_massman_wpl = ...
    replace_consecutive( FA.fc_raw_massman_wpl, 1 );
FA.HL_wpl_massman = ...
    replace_consecutive( FA.HL_wpl_massman, 1 );
FA.HSdry_massman = ...
    replace_consecutive( FA.HSdry_massman, 1 );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print to screen the number of removals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(' ');
fprintf('number of co2 flux values pulled in post-process = %d', ...
             (filelength_n-sum(~isnan(record))));
fprintf('number of co2 flux values used = %d',...
             sum(~isnan(record)));
fprintf(' ');
fprintf('Values removed for other qcd variables');
fprintf('    number of latent heat values removed = %d',removed_LH);
fprintf(['    number of massman&wpl-corrected latent heat values removed = ' ...
         '%d'], removed_LH_wpl_mass);
fprintf('    number of sensible heat values removed = %d',removed_HS);
fprintf('    number of massman-corrected sensible heat values removed = %d', ...
        removed_HSmass);
fprintf('    number of temperature values removed = %d',removed_Tdry);
fprintf('    number of relative humidity values removed = %d',removed_rH);
fprintf('    number of mean water vapor values removed = %d',removed_h2o);
fprintf('    number of atm press values removed = %d',removed_press);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE FILE FOR ONLINE GAP-FILLING PROGRAM (REICHSTEIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dd_idx = isnan(decimal_day_nan);
qc = ones(datalength,1);
qc( not( idx_NEE_good ) ) = 2;
NEE = FA.fc_raw_massman_wpl;
NEE( not( idx_NEE_good ) ) = -9999;
LE = FA.HL_wpl_massman;

H_dry = FA.HSdry_massman;
Tair = FA.Tdry - 273.15;

if draw_plots
    figure('Name', 'NEE vs wind direction' );
    ax1 = subplot( 2, 1, 1 );
    idx = repmat( false, 1, size( FA.fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( FA.sw_incoming < 10 ) = false;
    idx( FA.wnd_dir_compass < 180 | FA.wnd_dir_compass > 260 ) = false;
    plot( FA.wnd_dir_compass( idx ), FA.fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (daytime )' );
    ax2 = subplot( 2, 1, 2 );
    idx = repmat( false, 1, size( FA.fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( FA.sw_incoming > 10 ) = false;
    idx( FA.wnd_dir_compass < 180 | FA.wnd_dir_compass > 260 ) = false;
    plot( FA.wnd_dir_compass( idx ), FA.fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (nighttime )' );

    idx = repmat( false, 1, size( FA.fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    %idx( FA.wnd_dir_compass < 180 | FA.wnd_dir_compass > 260 ) = false;
    
    figure('Name', 'NEE vs ustar' );
    plot( FA.u_star( idx ), FA.fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'ustar' );
    
    figure('Name', 'NEE vs wind speed' );
    plot( FA.wnd_spd( idx ), FA.fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind speed' );
    
    figure( 'Name', 'NEE and wind direction' );
    ax1 = subplot( 4, 1, 1 );
    plot( decimal_day( idx ), FA.fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'DOY' );
    ax2 = subplot( 4, 1, 2 );
    plot( decimal_day, Tair, '.' );
    ylabel( 'T' ); xlabel( 'DOY' );
    ax3 = subplot( 4, 1, 3 );
    plot( decimal_day( idx ), FA.CO2_mean( idx ), '.' );
    ylabel( '[CO_2]' ); xlabel( 'DOY' );
    ax4 = subplot( 4, 1, 4 );
    plot( decimal_day( FA.precip > 0 ), FA.precip( FA.precip > 0 ), '.' );
    ylabel( 'pcp' ); xlabel( 'DOY' );
    linkaxes( [ ax1, ax2, ax3, ax4 ], 'x' );
end

if sitecode == 1 & year == 2010
    Tair( 12993:end ) = FA.Tair_TOA5(  12993:end );
end

if draw_fingerprints
    h_fps = RBD_plot_fingerprints( sitecode, year_arg, decimal_day, ...
                                   FA.sw_incoming, FA.rH, Tair, NEE, LE, ...
                                   FA.H_dry, ...
                                   shift_t_str );
end

if write_gap_filling_out_file
    if (sitecode>7 && sitecode<10) % || 9);
        disp('writing gap-filling file...')
        header = {'day' 'month' 'year' 'hour' 'minute' ...
                  'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
                  'rH' 'FA.precip' 'Ustar'};
        %FA.sw_incoming=ones(size(qc)).*-999;
        Tsoil=ones(size(qc)).*-999;
        datamatrix = [day month year hour minute qc NEE LE H_dry FA.sw_incoming Tair Tsoil FA.rH FA.precip FA.u_star];
        for n = 1:datalength
            for k = 1:15;
                if isnan(datamatrix(n,k)) == 1;
                    datamatrix(n,k) = -9999;
                else
                end
            end
        end
        outfilename = strcat(outfolder,filename,'_for_gap_filling');
        xlswrite(outfilename, header, 'data', 'A1');
        xlswrite(outfilename, datamatrix, 'data', 'A2');
    else    
        disp('writing gap-filling file...')
        
        header = {'day' 'month' 'year' 'hour' 'minute' ...
                  'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
                  'rH' 'precip' 'Ustar'};
        if sitecode == 3
            Tsoil = ones(size(qc)).*-999;
        end
        datamatrix = [day month year hour minute qc NEE ...
                      LE H_dry FA.sw_incoming Tair Tsoil FA.rH FA.precip FA.u_star];
        [ filled_idx, datamatrix ] = ...
            UNM_gapfill_from_local_data( ...
                sitecode, ...
                year, ...
                dataset( { datamatrix, header{ : } } ) );
        datamatrix = double( datamatrix );

        for n = 1:datalength
            for k = 1:15;
                if isnan(datamatrix(n,k)) == 1;
                    datamatrix(n,k) = -9999;
                else
                end
            end
        end
    end
    outfilename_forgapfill_txt = strcat( outfolder, ...
                                         filename, ...
                                         '_for_gap_filling.txt' );

    fid = fopen( outfilename_forgapfill_txt , 'w' );
    fmt = repmat('%s\t', 1, numel( header ) - 1 );
    fmt = [ fmt, '%s\n' ];
    fprintf( fid, fmt, header{ : } );
    fclose( fid );
    dlmwrite( outfilename_forgapfill_txt, ...
              datamatrix, ...
              '-append', ...
              'delimiter', '\t' );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE COMPLETE OUT-FILE  (FLUX_all matrix with bad values removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if write_complete_out_file
    disp('writing qc file...')
    Tsoil = ones(size(qc)).*-999;
    if sitecode == 5 || sitecode == 6 
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
                   'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
                   'wnd_dir_compass', 'wnd_spd', 'CO2_mean', 'CO2_std', ...
                   'H2O_mean', 'H2O_std', 'fc_raw', 'fc_raw_massman', ...
                   'fc_water_term', 'fc_heat_term_massman', ...
                   'fc_raw_massman_wpl', 'E_raw', 'E_raw_massman', ...
                   'E_water_term', 'E_heat_term_massman', 'E_wpl_massman', ...
                   'HSdry', 'HSdry_massman', 'HL_raw', 'HL_wpl_massman', ...
                   'Tdry', 'air_temp_hmp', 'Tsoil_2cm', 'Tsoil_6cm', ...
                   'VWC_2cm', 'precip', 'atm_press', 'rH' 'Par_Avg', ...
                   'sw_incoming', 'sw_outgoing', 'lw_incoming', ...
                   'lw_outgoing', 'NR_sw', 'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
                       agc_Avg, FA.u_star, FA.wnd_dir_compass, FA.wnd_spd, ...
                       FA.CO2_mean, CO2_std, FA.H2O_mean, H2O_std, FA.fc_raw, ...
                       FA.fc_raw_massman, FA.fc_water_term, ...
                       FA.fc_heat_term_massman, FA.fc_raw_massman_wpl, ...
                       FA.E_raw, FA.E_raw_massman, FA.E_water_term, ...
                       FA.E_heat_term_massman, FA.E_wpl_massman, FA.HSdry, ...
                       FA.HSdry_massman, FA.HL_raw, FA.HL_wpl_massman, ...
                       FA.Tdry, air_temp_hmp, Tsoil_2cm, Tsoil_6cm, VWC, ...
                       FA.precip FA.atm_press, FA.rH FA.Par_Avg, ...
                       FA.sw_incoming, FA.sw_outgoing, FA.lw_incoming, ...
                       FA.lw_outgoing, FA.NR_sw, FA.NR_lw, FA.NR_tot];
        
    elseif sitecode == 7
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
                   'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
                   'wnd_dir_compass', 'wnd_spd', 'CO2_mean', ...
                   'CO2_std', 'H2O_mean', 'H2O_std', 'fc_raw', ...
                   'fc_raw_massman', 'fc_water_term', ...
                   'fc_heat_term_massman', 'fc_raw_massman_wpl', 'E_raw', ...
                   'E_raw_massman', 'E_water_term', 'E_heat_term_massman', ...
                   'E_wpl_massman', 'HSdry', 'HSdry_massman', 'HL_raw', ...
                   'HL_wpl_massman', 'Tdry', 'air_temp_hmp', 'Tsoil', ...
                   'canopy_5cm', 'canopy_10cm', 'open_5cm', 'open_10cm', ...
                   'soil_heat_flux_open', 'soil_heat_flux_mescan', ...
                   'soil_heat_flux_juncan', 'precip', 'atm_press', 'rH' ...
                   'Par_Avg', 'sw_incoming', 'sw_outgoing', ...
                   'lw_incoming', 'lw_outgoing', 'NR_sw', ...
                   'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
                       agc_Avg, FA.u_star, FA.wnd_dir_compass, FA.wnd_spd, ...
                       FA.CO2_mean, CO2_std, FA.H2O_mean, H2O_std, FA.fc_raw, ...
                       FA.fc_raw_massman, FA.fc_water_term, ...
                       FA.fc_heat_term_massman, FA.fc_raw_massman_wpl, ...
                       FA.E_raw, FA.E_raw_massman, FA.E_water_term, ...
                       FA.E_heat_term_massman, FA.E_wpl_massman, FA.HSdry, ...
                       FA.HSdry_massman, FA.HL_raw, FA.HL_wpl_massman, ...
                       FA.Tdry, air_temp_hmp, Tsoil, canopy_5cm, canopy_10cm, ...
                       open_5cm, open_10cm, soil_heat_flux_open, ...
                       soil_heat_flux_mescan, soil_heat_flux_juncan, ...
                       FA.precip, FA.atm_press, FA.rH FA.Par_Avg, ...
                       FA.sw_incoming, FA.sw_outgoing, FA.lw_incoming, ...
                       FA.lw_outgoing, FA.NR_sw, FA.NR_lw, FA.NR_tot];
        
    elseif sitecode == 8 || sitecode == 9
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
                   'second', 'jday', 'iok', 'u_star', 'wnd_dir_compass', ...
                   'wnd_spd', 'CO2_mean', 'CO2_std', 'H2O_mean', 'H2O_std', ...
                   'fc_raw', 'fc_raw_massman', 'fc_water_term', ...
                   'fc_heat_term_massman', 'fc_raw_massman_wpl', 'E_raw', ...
                   'E_raw_massman', 'E_water_term', 'E_heat_term_massman', ...
                   'E_wpl_massman', 'HSdry', 'HSdry_massman', 'HL_raw', ...
                   'HL_wpl_massman', 'Tdry', 'air_temp_hmp', 'precip', ...
                   'atm_press', 'rH', 'Par_Avg', 'sw_incoming', ...
                   'sw_outgoing', 'lw_incoming', 'lw_outgoing', 'NR_sw', ...
                   'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
                       FA.u_star, FA.wnd_dir_compass, FA.wnd_spd, ...
                       FA.CO2_mean, CO2_std, FA.H2O_mean, H2O_std, FA.fc_raw, ...
                       FA.fc_raw_massman, FA.fc_water_term, ...
                       FA.fc_heat_term_massman, FA.fc_raw_massman_wpl, ...
                       FA.E_raw, FA.E_raw_massman, FA.E_water_term, ...
                       FA.E_heat_term_massman, FA.E_wpl_massman, FA.HSdry, ...
                       FA.HSdry_massman, FA.HL_raw, FA.HL_wpl_massman, ...
                       FA.Tdry, air_temp_hmp, FA.precip, FA.atm_press, FA.rH, ...
                       FA.Par_Avg, FA.sw_incoming, FA.sw_outgoing, ...
                       FA.lw_incoming, FA.lw_outgoing, FA.NR_sw,FA.NR_lw, ...
                       FA.NR_tot];
        
    else
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
                   'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
                   'wnd_dir_compass', 'wnd_spd', 'CO2_mean', ...
                   'CO2_std', 'H2O_mean', 'H2O_std', 'fc_raw', ...
                   'fc_raw_massman', 'fc_water_term', ...
                   'fc_heat_term_massman', 'fc_raw_massman_wpl', 'E_raw', ...
                   'E_raw_massman', 'E_water_term', 'E_heat_term_massman', ...
                   'E_wpl_massman', 'HSdry', 'HSdry_massman', 'HL_raw', ...
                   'HL_wpl_massman', 'Tdry', 'air_temp_hmp', 'Tsoil', ...
                   SHF_labels{ : }, 'precip', 'atm_press', 'rH' ...
                   'Par_Avg', 'sw_incoming', 'sw_outgoing', ...
                   'lw_incoming', 'lw_outgoing', 'NR_sw', ...
                   'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
                       agc_Avg, FA.u_star, FA.wnd_dir_compass, FA.wnd_spd, ...
                       FA.CO2_mean, CO2_std,FA.H2O_mean,H2O_std, FA.fc_raw, ...
                       FA.fc_raw_massman, FA.fc_water_term, ...
                       FA.fc_heat_term_massman, FA.fc_raw_massman_wpl, ...
                       FA.E_raw,FA.E_raw_massman,FA.E_water_term, ...
                       FA.E_heat_term_massman,FA.E_wpl_massman, FA.HSdry, ...
                       FA.HSdry_massman,FA.HL_raw,FA.HL_wpl_massman, FA.Tdry, ...
                       air_temp_hmp,Tsoil, soil_heat_flux, FA.precip, ...
                       FA.atm_press, FA.rH, FA.Par_Avg, FA.sw_incoming, ...
                       FA.sw_outgoing, FA.lw_incoming, FA.lw_outgoing, ...
                       FA.NR_sw,FA.NR_lw,FA.NR_tot];
    end

    outfilename_csv = strcat( outfolder, filename, '_qc.txt' );
    out_data = dataset( { datamatrix2, header2{ 2:end } } );
    export( out_data, 'file', outfilename_csv );

end



%------------------------------------------------------------

function NEE = normalize_PPine_NEE( NEE, idx_NEE_good )
% NORMALIZE_PPINE_NEE - normalizes respiration at PPine to a maximum of 10
%   umol/m2/s.  10 was chosen by ML and TWH based on our own data from PPine as
%   well as data from the Metolius ponderosa pine sites in Oregon.

idx = ( NEE > 0 ) & idx_NEE_good;
NEE_bak = NEE;
NEE( idx ) = normalize_vector( NEE( idx ), 0, 10 );

%------------------------------------------------------------

function [ doy_min, doy_max ] = get_daily_maxmin( data_month, ...
                                                  co2_min_by_month, ...
                                                  co2_max_by_month, ...
                                                  winter_co2_min )
% GET_DAILY_MAXMIN - Expands monthly or single-value co2 max, co2 min
%   specifications to half-hourly values for specified year.  With half-hourly
%   values we can easily subsequently implement ad-hoc exceptions for specific
%   site years.

n_obs_in_siteyear = numel( data_month );

doy_max = []; %repmat( NaN, n_obs_in_siteyear, 1 );
doy_min = []; %repmat( NaN, n_obs_in_siteyear, 1 );

if numel( co2_min_by_month ) == 1
    co2_min_by_month = repmat( co2_min_by_month, 1, 12 );
end
if numel( co2_max_by_month ) == 1
    co2_max_by_month = repmat( co2_max_by_month, 1, 12 );
end

% set Jan, Feb, Dec minimum to more restrictive of co2_min_by_month,
% winter_co2_min
winter_co2_min = repmat( winter_co2_min, 1, 3 );
co2_min_by_month( [ 1, 2, 12 ] ) = max( winter_co2_min, ...
                                        co2_min_by_month( [ 1, 2, 12 ] ) );

for m = 1:12
    n_obs_this_month = numel( find( data_month == m ) );
    doy_max = [ doy_max; repmat( co2_max_by_month( m ), ...
                                 n_obs_this_month, ...
                                 1 ) ];
    doy_min = [ doy_min; repmat( co2_min_by_month( m ), ...
                                 n_obs_this_month, ...
                                 1 ) ];
end

%------------------------------------------------------------

function [ fc_raw_massman_wpl, E_wpl_massman, HL_wpl_massman, ...
           HSdry, HSdry_massman, CO2_mean, H2O_mean, atm_press, NR_tot, ...
           sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, precip, rH ] = ...
    remove_specific_problem_periods( sitecode, year, ...
                                     fc_raw_massman_wpl, ...
                                     E_wpl_massman, ...
                                     HL_wpl_massman, ...
                                     HSdry, ...
                                     HSdry_massman, ...
                                     CO2_mean, ...
                                     H2O_mean, ...
                                     atm_press, ...
                                     NR_tot, ...
                                     sw_incoming, ...
                                     sw_outgoing, ...
                                     lw_incoming, ...
                                     lw_outgoing, ...
                                     precip, rH )

% Helper function for UNM_RemoveBadData (RBD for short).  Specifies periods
% where various flux observations did not activate any of the RBD filters,
% yet are deemed biologically impossible.

% if sitecode passed as integer, convert to UNM_sites object
if not( isa( sitecode, 'UNM_sites' ) )
    sitecode = UNM_sites( sitecode );
end

% GLand 2007
switch sitecode
  case UNM_sites.GLand
    switch year
      case 2007 
        
        % IRGA problems
        idx = DOYidx( 156 ) : DOYidx( 163 );
        fc_raw_massman_wpl( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        CO2_mean( idx  ) = NaN;
        H2O_mean( idx ) = NaN;
        atm_press( idx ) = NaN;
        
        % IRGA problems here -- big jump in [CO2] and suspicious looking fluxes
        idx = DOYidx( 228.5 ) : DOYidx( 235.5 );
        fc_raw_massman_wpl( idx ) = NaN;
        H2O_mean( idx ) = NaN;
        
      case 2008
        sw_incoming( DOYidx( 7 ) : DOYidx( 9 ) ) = NaN;
        
      case 2010
        % IRGA problems
        idx = DOYidx( 102 ) : DOYidx( 119.5 );
        E_wpl_massman( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        H2O_mean( idx ) = NaN;
        
        H2O_mean( DOYidx( 85.5 ) : DOYidx( 102.5 ) ) = NaN;
        
        fc_raw_massman_wpl( DOYidx( 327 ) : DOYidx( 328 ) ) = NaN;
        
      case 2011
        
        % IRGA problems
        idx = DOYidx( 96 ) : DOYidx( 104 );
        fc_raw_massman_wpl( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        CO2_mean( idx ) = NaN;
        H2O_mean( idx ) = NaN;
        
        idx = DOYidx( 342 ) : DOYidx( 348 );
        fc_raw_massman_wpl( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        CO2_mean( idx ) = NaN;
        H2O_mean( idx ) = NaN;
        
        % [CO2] concentration calibration problem
        idx = DOYidx( 131.6 ) : DOYidx( 164.6 );
        CO2_mean( idx ) = CO2_mean( idx ) + 10.0;
    end
    
  case UNM_sites.SLand
    switch year
      case 2007
        NR_tot( DOYidx( 143 ) : DOYidx( 151 ) ) = NaN;
        sw_outgoing( DOYidx( 150 ) : DOYidx( 162 ) ) = NaN;
      case 2009
        CO2_mean( DOYidx( 139 ) : DOYidx( 142 ) ) = NaN;
        CO2_mean( DOYidx( 287.5 ) : DOYidx( 290.8 ) ) = NaN;
      case 2011
        idx = DOYidx( 342 ) : DOYidx( 348 );
        fc_raw_massman_wpl( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        CO2_mean( idx ) = NaN;
        H2O_mean( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
    end
    
  case UNM_sites.JSav
    switch year
      case 2010
        lw_outgoing( DOYidx( 130.3 ) : DOYidx( 131.5 ) ) = NaN;
        lw_outgoing( DOYidx( 331.4 ) : DOYidx( 332.7 ) ) = NaN;
        H2O_mean( DOYidx( 221 ) : DOYidx( 229 ) ) = NaN;
      case 2011
        NR_tot( NR_tot < -180 ) = NaN;

        idx = DOYidx( 65 ) : DOYidx( 120 );
        lw_fixed = lw_outgoing( idx );
        lw_fixed( lw_fixed < 280 ) = NaN;
        lw_outgoing( idx ) = lw_fixed;
        
        idx = DOYidx( 300 ) : DOYidx( 304 );
        lw_fixed = lw_outgoing( idx );
        lw_fixed( lw_fixed < 300 ) = NaN;
        lw_outgoing( idx ) = lw_fixed;
        
    end
    
  case UNM_sites.PJ_girdle
    switch year
      case 2009
        CO2_mean( DOYidx( 131.4 ) : DOYidx( 141.5 ) ) = NaN;
        CO2_mean( DOYidx( 284 ) : DOYidx( 293.65 ) ) = NaN;
    end
    
  case UNM_sites.PPine
    switch year
      case 2008
        fc_raw_massman_wpl( DOYidx( 260 ) : DOYidx( 290 ) ) = NaN;
        rH( DOYidx( 100 ) : DOYidx( 187 ) ) = NaN;  %these observation are way
                                                    %too small

        % divide by 18 to cutoff at 200 with correct units
        E_wpl_massman( E_wpl_massman > ( 200 ./ 18 ) ) = NaN;
      case 2009
        fc_raw_massman_wpl( DOYidx( 157 ) : DOYidx( 159 ) ) = NaN;
        idx = DOYidx( 157 ) : DOYidx( 183 );
        fc_raw_massman_wpl( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        % divide by 18 to cutoff at 200 with correct units
        E_wpl_massman( E_wpl_massman > ( 200 ./ 18 ) ) = NaN;
        HSdry( idx ) = NaN;
        HSdry_massman( idx ) = NaN;
      case 2011
        idx = DOYidx( 186 ) : DOYidx( 200 );
        fc_raw_massman_wpl( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        H2O_mean( idx ) = NaN;
    end
    
  case UNM_sites.MCon
    switch year
      case 2009
        sw_incoming( DOYidx( 342 ) : end ) = NaN;
      case 2010
        idx = DOYidx( 134.4 ) : DOYidx( 146.5 );
        CO2_mean( idx ) = CO2_mean( idx ) + 10;
        
        idx = DOYidx( 301.6 ) : DOYidx( 344.7 );
        CO2_mean( idx ) = CO2_mean( idx ) - 17;        
      case 2011
        idx = DOYidx( 225.4 ) : DOYidx( 237.8 );
        lw_incoming( idx ) = NaN;
        lw_outgoing( idx ) = NaN;
        E_wpl_massman( idx ) = NaN;
        HL_wpl_massman( idx ) = NaN;
        HSdry( idx ) = NaN;
        HSdry_massman( idx ) = NaN;
        % Our pcp gauge shows huge pcp on DOY 80 and 309, while the nearby
        % met station (Redondo-Redonito) shows none.  
        precip( DOYidx( 80 ):DOYidx( 81 ) ) = 0.0;
        precip( DOYidx( 309 ):DOYidx( 310 ) ) = 0.0;
    end
    
  case UNM_sites.New_GLand
    switch year
      case 2010
        sw_incoming( DOYidx( 355 ) : end ) = NaN;
    end 
end

%------------------------------------------------------------

function [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
    specify_siteyear_filter_exceptions( sitecode, year, ...
                                        DOY_co2_min, DOY_co2_max );

% SPECIFY_SITEYEAR_MAXMIN_EXCEPTIONS - % Helper function for UNM_RemoveBadData
% (RBD for short).  Adds site-year-specific DOY-based CO2 NEE max/min values to
% the DOY-based max-min arrays, and defines exceptions to the standard deviation
% filter.  This is meant to be applied to cases where measured NEE seems
% biologically reasonable despite tripping one of the RBD filters.

% initialize standard deviation filter exceptions to no exceptions
std_exc_flag = repmat( false, size( DOY_co2_max ) );

if isa( sitecode, 'double') | isa( sitecode, 'integer' )
    sitecode = UNM_sites( sitecode );
end

switch sitecode
  case UNM_sites.GLand
    switch year
      case 2007
        DOY_co2_max( 1 : DOYidx( 15 ) ) = 1.25;
      case 2008
        idx = DOYidx( 184 ) : DOYidx( 186.5 );
        DOY_co2_max( idx ) = 15;
        std_exc_flag( idx ) = true;
      case 2009
        idx = DOYidx( 245 ) : DOYidx( 255 );
        DOY_co2_max( idx ) = 1.5;
        
        DOY_co2_max( DOYidx( 178 ) : DOYidx( 267 ) ) = 0.8;
        
        % the site burned DOY 210, 2009.  Here we remove points in the period
        % following the burn that look more like noise than biologically
        % realistic carbon uptake.
        DOY_co2_min( DOYidx( 210 ) : DOYidx( 256 ) ) = -0.5;
        DOY_co2_min( DOYidx( 256 ) : DOYidx( 270 ) ) = -1.2;
      case 2010
        DOY_co2_max( DOYidx( 200 ) : DOYidx( 225 ) ) = 2.5;
        DOY_co2_max( 1 : DOYidx( 160 ) ) = 1.5;
        DOY_co2_min( 1 : DOYidx( 160 ) ) = -1.5;

        idx = DOYidx( 223 ) : DOYidx( 229 );
        DOY_co2_min( idx ) = -17;
        std_exc_flag( idx ) = true;
      case 2011
        std_exc_flag( DOYidx( 158.4 ) : DOYidx( 158.6 ) ) = true;
        std_exc_flag( DOYidx( 159.4 ) : DOYidx( 159.6 ) ) = true;
        std_exc_flag( DOYidx( 245.4 ) : DOYidx( 245.6 ) ) = true;
        %    std_exc_flag( DOYidx( 337 ) : DOYidx( 343.7 ) ) = true;
        
        DOY_co2_min( DOYidx( 310 ) : end ) = -0.5;
        DOY_co2_min( 1 : DOYidx( 210 ) ) = -0.5;

        DOY_co2_max( DOYidx( 261 ) : end ) = 2.0;
        DOY_co2_max( DOYidx( 250 ) : DOYidx( 260 ) ) = 0.8;
        DOY_co2_max( DOYidx( 280 ) : DOYidx( 285 ) ) = 1.2;
    end %GLand

  case UNM_sites.SLand
    switch year
      case 2008
        DOY_co2_min( 1 : DOYidx( 50 ) ) = -0.5;
        
        idx = DOYidx( 184 ) : DOYidx( 190 );
        DOY_co2_max( idx ) = 20;
        std_exc_flag( idx ) = true;
      case 2010
        DOY_co2_min( 1 : DOYidx( 80 ) ) = -1.4;
        DOY_co2_max( DOYidx( 204 ) : DOYidx( 220 ) ) = 2.0;
      case 2011
        idx = DOYidx( 215.5 ) : DOYidx( 216.4 );
        std_exc_flag( idx ) = true;

        idx = DOYidx( 190 ) : DOYidx( 195 );
        DOY_co2_max( idx ) = 7;
        std_exc_flag( idx ) = true;

        DOY_co2_min(  1 : DOYidx( 70.0 ) ) = -0.5;
        DOY_co2_max(  1 : DOYidx( 70.0 ) ) = 1.0;
        DOY_co2_min( DOYidx( 80  ) : DOYidx( 100 ) ) = -2.0;

        std_exc_flag( DOYidx( 20.4) : DOYidx( 20.6 ) ) = true;
        
        DOY_co2_min(  DOYidx( 185 ) : end ) = -1.5;

    end %SLand
    
  case UNM_sites.JSav
    switch year
      case 2008
        idx = DOYidx( 215 ) : DOYidx( 240 );
        DOY_co2_min( idx ) = -12.0;
        
      case 2009
        DOY_co2_max( 1 : DOYidx( 125 ) ) = 2.0;
        DOY_co2_max( DOYidx( 150 ) : DOYidx( 180 ) ) = 2.0;
        DOY_co2_max( DOYidx( 220 ) : DOYidx( 250 ) ) = 2.5;
        DOY_co2_max( DOYidx( 251 ) : DOYidx( 280 ) ) = 4.0;
        DOY_co2_max( DOYidx( 281 ) : DOYidx( 365 ) ) = 2.5;
        DOY_co2_min( 1 : DOYidx( 94 ) ) = -6.0;

      case 2010
        DOY_co2_max( 1 : DOYidx( 80 ) ) = 2.0;
        DOY_co2_max( DOYidx( 81 ) : DOYidx( 190 ) ) = 4.0;
        DOY_co2_max( DOYidx( 190 ) : DOYidx( 210 ) ) = 6.0;
        DOY_co2_max( DOYidx( 211 ) : DOYidx( 225 ) ) = 5.0;
        DOY_co2_max( DOYidx( 226 ) : end ) = 3.0;

      case 2011
        DOY_co2_min( 1 : DOYidx( 40 ) ) = -2.0;
        DOY_co2_max( DOYidx( 210 ) : DOYidx( 220 ) ) = 5.0;
        DOY_co2_max( DOYidx( 221 ) : DOYidx( 265 ) ) = 4.0;
        DOY_co2_max( DOYidx( 266 ) : end ) = 3.0;

        std_exc_flag( DOYidx( 12.5 ) : DOYidx( 12.6 ) ) = true;
        std_exc_flag( DOYidx( 17.4 ) : DOYidx( 17.6 ) ) = true;
        std_exc_flag( DOYidx( 20.4 ) : DOYidx( 20.7 ) ) = true;
        std_exc_flag( DOYidx( 58.4 ) : DOYidx( 58.6 ) ) = true;
        std_exc_flag( DOYidx( 64.3 ) : DOYidx( 64.5 ) ) = true;
        std_exc_flag( DOYidx( 73.4 ) : DOYidx( 73.5 ) ) = true;
        std_exc_flag( DOYidx( 184.5 ) : DOYidx( 186 ) ) = true;
        std_exc_flag( DOYidx( 232.0 ) : DOYidx( 232.1 ) ) = true;
        std_exc_flag( DOYidx( 313.4 ) : DOYidx( 313.6 ) ) = true;
    end  %JSav
    
  case UNM_sites.PJ
    switch year    
      case 2008
        DOY_co2_max( 1 : DOYidx( 185 ) ) = 3.0;
        DOY_co2_min( DOYidx( 260 ) : DOYidx( 290 ) ) = -18.0;
        DOY_co2_min( DOYidx( 335 ) : DOYidx( 365 ) ) = -6.5;
        
      case 2009
        DOY_co2_max( 1 : DOYidx( 180 ) ) = 3.0;
        DOY_co2_max( DOYidx( 190 ) : DOYidx( 260 ) ) = 4.0;

      case 2011
        std_exc_flag( DOYidx( 31.5 ) : DOYidx( 31.7 ) ) = true;
        std_exc_flag( DOYidx( 182.6 ) : DOYidx( 182.8 ) ) = true;
        std_exc_flag( DOYidx( 183.4 ) : DOYidx( 183.7 ) ) = true;
        std_exc_flag( DOYidx( 329.0 ) : DOYidx( 329.7 ) ) = true;
        
        DOY_co2_max( 1 : DOYidx( 155 ) ) = 2.0;
        DOY_co2_max( DOYidx( 328.0 ) : end ) = 2.5;
        DOY_co2_min( DOYidx( 350 ) : end ) = -1.0;
    end  %PJ

  case UNM_sites.PPine
    % these are *UNNORMALIZED* NEE values.  Positive (i.e., respiration)
    % values will be subsequently normalized to 10.0, so enter values
    % accordingly. 
    switch year
      case 2007
        DOY_co2_max( DOYidx( 86 ) : DOYidx( 88 ) ) = 4.0;
        % DOY_co2_max( DOYidx( 185 ) : DOYidx( 259.99 ) ) = 10.0;
        % DOY_co2_max( DOYidx( 260 ) : DOYidx( 276 ) ) = 15.0;
        % DOY_co2_max( DOYidx( 276 ) : DOYidx( 277 ) ) = 5.0;
        % DOY_co2_max( DOYidx( 277 ) : DOYidx( 279 ) ) = 10.0;
        % DOY_co2_max( DOYidx( 280 ) : end ) = 5.0;
      case 2009
        %DOY_co2_max( : ) = 10;
        DOY_co2_max( DOYidx( 64 ) : DOYidx( 67 ) ) = 4.0;
        %DOY_co2_max( DOYidx( 240 ) : DOYidx( 276 ) ) = 13.3;
        DOY_co2_max( DOYidx( 240 ) : DOYidx( 276 ) ) = 8.5;
        
        %DOY_co2_max( DOYidx( 67 ) : DOYidx( 150 ) ) = 8.0;
        %DOY_co2_max( DOYidx( 300 ) : end ) = 10.0;
      case 2010
        DOY_co2_max( 1 : DOYidx( 35 ) ) = 2.5;
      case 2011
        istd_exc_flag( DOYidx( 171 ) : DOYidx( 172 ) ) = true;
        DOY_co2_min( DOYidx( 291.4 ) : DOYidx( 291.6 ) ) = -20;
    end
    
  case UNM_sites.MCon
    switch year
      case 2007
        idx = DOYidx( 120.35 ) : DOYidx( 120.55 );
        std_exc_flag( idx ) = true;
        DOY_co2_min( idx ) = -15;
        std_exc_flag( DOYidx( 292.4 ) : DOYidx( 294.5 ) ) = true;
        std_exc_flag( DOYidx( 293.5 ) : DOYidx( 293.6 ) ) = true;
        std_exc_flag( DOYidx( 301.5 ) : DOYidx( 301.7 ) ) = true;
        
        DOY_co2_max( DOYidx( 75 ) : DOYidx( 86 ) ) = 2.0;
        DOY_co2_max( DOYidx( 176 ) : DOYidx( 206 ) ) = 3.5;
        DOY_co2_max( DOYidx( 207 ) : DOYidx( 297 ) ) = 4.0;
        DOY_co2_min( DOYidx( 327 ) : end ) = -2.0;
        
      case 2008
        std_exc_flag( DOYidx( 43.5 ) : DOYidx( 43.6 ) ) = true;
        std_exc_flag( DOYidx( 88 ) : DOYidx( 93 ) ) = true;
        std_exc_flag( DOYidx( 121 ) : DOYidx( 122 ) ) = true;
        
        DOY_co2_min( 1 : DOYidx( 106 ) ) = -2.0;
        DOY_co2_max( DOYidx( 125 ) : DOYidx( 155 ) ) = 3.0;

      case 2009
        DOY_co2_min( DOYidx( 83 ) : DOYidx( 100 ) ) = -3.0;
        DOY_co2_max( DOYidx( 83 ) : DOYidx( 100 ) ) = 4.0;
        DOY_co2_max( DOYidx( 156 ) : DOYidx( 305 ) ) = 4.0;
        DOY_co2_max( DOYidx( 311 ) : end ) = 3.0;

      case 2010
        DOY_co2_max( DOYidx( 200 ) : DOYidx( 244 ) ) = 4.0;
        DOY_co2_max( DOYidx( 246 ) : DOYidx( 300 ) ) = 3.0;

      case 2011

        DOY_co2_max( DOYidx( 95 ) : DOYidx( 166 ) ) = 4.0;
        DOY_co2_max( DOYidx( 180 ) : end ) = 4.0;
    end  % MCon

  case UNM_sites.TX
    switch year 
      case 2009
        DOY_co2_max( DOYidx( 163 ) : DOYidx( 163.5 ) ) = 9.0;
        DOY_co2_max( DOYidx( 265 ) : DOYidx( 305 ) ) = 12.0;
    end
    
  case UNM_sites.PJ_girdle
    switch year
      case 2009
        DOY_co2_max( 1 : DOYidx( 100 ) ) = 1.5;
        DOY_co2_max( DOYidx( 100 ) : DOYidx( 140 ) ) = 2.5;
        DOY_co2_max( DOYidx( 140 ) : DOYidx( 176 ) ) = 2.0;
        DOY_co2_max( DOYidx( 177 ) : DOYidx( 191 ) ) = 4.0;
        DOY_co2_max( DOYidx( 244 ) : DOYidx( 267 ) ) = 3.2;
        DOY_co2_max( DOYidx( 275 ) : DOYidx( 299 ) ) = 3.0;
        DOY_co2_max( DOYidx( 300 ) : end ) = 2.0;
      case 2011
        idx = DOYidx( 192.2 ) : DOYidx( 192.6 );
        std_exc_flag( idx ) = true;
        DOY_co2_max( idx ) = 6.5;
        
        DOY_co2_min( DOYidx( 350 ) : end ) = -1.0;
    end
    
  case UNM_sites.New_GLand
    switch year
      case 2011
        std_exc_flag( DOYidx( 39.5 ) : DOYidx( 39.7 ) ) = true;
        std_exc_flag( DOYidx( 50.5 ) : DOYidx( 50.7 ) ) = true;
        std_exc_flag( DOYidx( 58.5 ) : DOYidx( 58.7 ) ) = true;
        std_exc_flag( DOYidx( 66.6 ) : DOYidx( 66.8 ) ) = true;
        std_exc_flag( DOYidx( 72.5 ) : DOYidx( 72.6 ) ) = true;
        std_exc_flag( DOYidx( 89.55 ) : DOYidx( 89.65 ) ) = true;
        std_exc_flag( DOYidx( 104.48 ) : DOYidx( 104.52 ) ) = true;
        std_exc_flag( DOYidx( 107.52 ) : DOYidx( 107.58 ) ) = true;
        std_exc_flag( DOYidx( 129.48 ) : DOYidx( 129.56 ) ) = true;
        
        idx = DOYidx( 80.5 ) : DOYidx( 80.65 );
        std_exc_flag( idx ) = true;
        DOY_co2_max( idx ) = 6.9;
        

        idx = DOYidx( 99.45 ) : DOYidx( 99.6 );
        std_exc_flag( idx ) = true;
        DOY_co2_max( idx ) = 7.4;

        idx = DOYidx( 116.5 ) : DOYidx( 116.6 );
        std_exc_flag( idx ) = true;
        DOY_co2_max( idx ) = 7.2;
        
        DOY_co2_max( DOYidx( 194 ) : DOYidx( 195 ) ) = 2.3;
        std_exc_flag( DOYidx( 201 ) : DOYidx( 203 ) ) = true;
        std_exc_flag( DOYidx( 225.6 ) : DOYidx( 225.7 ) ) = true;
        std_exc_flag( DOYidx( 290.4 ) : DOYidx( 290.6 ) ) = true;
        std_exc_flag( DOYidx( 335.45 ) : DOYidx( 335.6 ) ) = true;
        DOY_co2_max( DOYidx( 344.5 ) : DOYidx( 344.7 ) ) = 9.0;
        DOY_co2_max( DOYidx( 345.48 ) : DOYidx( 345.56 ) ) = 9.0;
    end  % New_GLand
end

%------------------------------------------------------------

function co2_conc_filter_exceptions = ...
    specify_siteyear_co2_conc_filter_exceptions( ...
        sitecode, year, co2_conc_filter_exceptions );
% Helper function for UNM_RemoveBadData (RBD for short).  Disables the high and
% low CO2 concentration filters for specified time periods (noted in the code
% below).  There are periods of incorrect [CO2] observations from the IRGA which
% nonetheless contain reasonable CO2 NEE.  This allows us to keep those NEE
% measurements.

if ( sitecode == 1 ) & ( year(1) == 2007 )
    co2_conc_filter_exceptions( DOYidx( 214 ) : DOYidx( 218 ) ) = true;
end

% keep index 5084 to 5764 in 2010 - these CO2 obs are bogus but the
% fluxes look OK.  TWH 27 Mar 2012
if ( sitecode == 1 ) & ( year(1) == 2010 )
    % keep index 4128 to 5084, 7296-8064 (days 152:168) in 2010 -
    % these CO2 obs are bogus but the datalogger 30-min fluxes look OK.  TWH 27
    % Mar 2012
    co2_conc_filter_exceptions( 4128:5764 ) = true;
    co2_conc_filter_exceptions( 7296:8064 ) = true;
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 218 ) : DOYidx( 223 ) ) = true;
    %co2_conc_filter_exceptions( DOYidx( 271 ) : DOYidx( 278 ) ) = true;
end 
if ( sitecode == 1 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 153 ) : DOYidx( 160 ) ) = true;
end 
if ( sitecode == 2 ) & ( year == 2007 )
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 253 ) : DOYidx( 257 ) ) = true;
end 
if ( sitecode == 3 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 41.6 ) : DOYidx( 52.7 ) ) = true;
end 
if ( sitecode == 4 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 358  ) : end ) = true;
end 
if (sitecode == 5 ) & ( year == 2007 )
    % days 290:335 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 290 ) : DOYidx( 335 ) ) = true;
end
if (sitecode == 8 ) & ( year == 2009 )
    % days 1 to 40.5 -- low [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 1 ) : DOYidx( 40.5 ) ) = true;
end

%------------------------------------------------------------

function par_norm = normalize_PAR( sitecode, par, doy, draw_plots )
% NORMALIZE_PAR - normalizes PAR to a site-specific maximum.
%   

if ismember( sitecode, 5:9 )
    fprintf( 'PAR normalization not yet implemented for %s\n', ...
             char( UNM_sites( sitecode ) ) );
end

par_max = 2500;
doy = floor( doy );
norm_factor = par_max / prctile( par, 99.8 );
par_norm = par * norm_factor;

if draw_plots
    figure( 'NumberTitle', 'off', ...
            'Name', 'PAR normalization' );

    max_par = nanmax( [ par, par_norm ] );

    pal = cbrewer( 'qual', 'Dark2', 8 );
    h_par = plot( doy, par, 'ok' );
    hold on;
    h_par_norm = plot( doy, par_norm, 'x', 'Color', pal( 1, : ) );
    hold off;
    ylabel( 'PAR [W/m^2]' );
    xlabel( 'DOY' );
    legend( [ h_par, h_par_norm ], 'PAR (obs)', 'PAR (normalized)', ...
            'Location', 'best' );
end

%------------------------------------------------------------

function gland_precip = fill_Gland_2011_precip_from_SLand(gland_precip)
% FILL_GLAND_2011_PRECIP_FROM_SLAND - There is a large gap (~one month) in the
% Gland precip record around July 2011.  Fill those precip values from SLand
% 

sland11 = parse_forgapfilling_file( UNM_sites.SLand, 2011, ...
                                    'use_filled', false );

idx = DOYidx( 164 ) : DOYidx( 206 );
gland_precip( idx ) = sland11.precip( idx );

2
