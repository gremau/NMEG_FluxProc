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
%     load_binary: optional, logical (default true); if true, load binary
%          (.mat) versions of fluxall data.  If false, parse Excel version (this
%          is much slower).
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
% (c) Timothy W. Hilton, UNM, May 2012


function [] = UNM_RemoveBadData_pre2012( sitecode, year, varargin )


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
args.addParamValue( 'load_binary', true, @islogical );
args.addParamValue( 'write_QC', true, @islogical );
args.addParamValue( 'write_GF', true, @islogical );
args.addParamValue( 'draw_plots', true, @islogical );
args.addParamValue( 'draw_fingerprints', true, @islogical );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

% place user arguments into variables
sitecode = args.Results.sitecode;

% sitecode = 10;
% year = 2011;
iteration = int8( args.Results.iteration );

data_for_analyses = 0; %1 to output file with data sorted for specific
                       %analyses 
ET_gap_filler = 0; %run ET gap-filler program

winter_co2_min = -100;  %initialization -- will be set for specific sites later
obs_per_day = 48;  % half-hourly observations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify some details about sites and years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.sitecode==1; % grassland
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

elseif args.Results.sitecode==2; % shrubland
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
    
elseif args.Results.sitecode==3; % Juniper savanna
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
    
elseif args.Results.sitecode == 4; % Pinyon Juniper
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
    
elseif args.Results.sitecode==5; % Ponderosa Pine
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
    
elseif args.Results.sitecode==6; % Mixed conifer
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
    
elseif args.Results.sitecode == 7;
    site = 'TX'
    if year == 2005
        filelength_n = 17522;
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2006
        filelength_n = 17524;
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FZ';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2008;
        filelength_n = 17452;
        lastcolumn='GP';
        ustar_lim = 0.11;  % (changed from 0.11 10 Apr 2012 -- TWH )
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ] ;
    elseif year == 2009;
        filelength_n = 17282;
        lastcolumn='GP';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ] ;
    elseif year == 2010
        filelength_n = 17524;
        lastcolumn='GQ';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2011;
        filelength_n = 7282;
        lastcolumn='GQ';
        ustar_lim = 0.11;
        co2_min_by_month = -26; 
        co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
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

elseif args.Results.sitecode == 8;
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
    co2_min_by_month = -26; co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif args.Results.sitecode == 9;
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
    co2_min_by_month = -26;
    co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                        12, 12, 9, 6, 6, 4.9 ];
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 35; h2o_min = 0;
    press_min = 70; press_max = 130;

elseif args.Results.sitecode == 10; % Pinyon Juniper girdle
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

elseif args.Results.sitecode == 11; % new Grassland
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
% parse fluxall data into matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
                       sprintf( '%s_%d_FA_Convert.mat', ...
                                char( args.Results.sitecode ), year(1) ) );
if not( args.Results.load_binary )
    if args.Results.year <= 2012
        drive='c:';
        row1=5;  %first row of data to process - rows 1 - 4 are header
        filename = strcat(site,'_flux_all_',num2str(year))
        %filename = strcat(site,'_new_radiation_flux_all_',num2str(year))
        filelength = num2str(filelength_n);
        %datalength = filelength_n - row1 + 1; 
        filein = strcat(drive,'\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\',filename)
        range = strcat('B',num2str(row1),':',lastcolumn,filelength);
        headerrange = strcat('B2:',lastcolumn,'2');
        time_stamp_range = strcat('A5:A',filelength);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open file and parse out dates and times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('reading data...')
        [num xls_text] = xlsread(filein,headerrange);
        headertext = xls_text;
        [num xls_text] = xlsread(filein,range);  %does not read in first column because it's text!!!!!!!!
        data = num;
        ncol = size(data,2)+1;
        datalength = size(data,1);
        [num xls_text] = xlsread(filein,time_stamp_range);
        timestamp = xls_text;
        [year month day hour minute second] = datevec(timestamp);
        datenumber = datenum(timestamp);
        disp('file read');

        save( save_fname );
        fprintf( 'saved %s\n', save_fname );
    else
        fluxall_data = UNM_parse_fluxall_txt_file( args.Results.sitecode, args.Results.year );
        headertext = fluxall_data.Properties.VarNames;
        [year month day hour minute second] = datevec( fluxall_data.timestamp );
        fluxall_data.timestamp = [];
        data = double( fluxall_data );
    end
else
    this_args = args;  %preserve arguments from local function call
    load( save_fname );
    args = this_args;
    fprintf( 'loaded %s\n', save_fname );
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some siteyears have periods where the observed radition does not line
% up with sunrise.  Fix this here so that the matched time/radiation
% propagates through the rest of the calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = UNM_fix_datalogger_timestamps( args.Results.sitecode, ...
                                      args.Results.year, ...
                                      data, ...
                                      headertext( 2:end ), ...
                                      datenumber, ...
                                      'debug', args.Results.draw_plots );
if ( args.Results.sitecode == UNM_sites.MCon ) & ( args.Results.year <= 2008 )
    data = revise_MCon_duplicated_Rg( data, headertext, datenumber );
end 

shift_t_str = 'shifted';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Matlab processed ts data (these are in the same columns for all
% sites, so they can be just hard-wired in by column number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( args.Results.sitecode == 7 ) & ( year == 2008 )

    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,28);
    CO2_mean=data(:,32);
    CO2_std=data(:,33);
    H2O_mean=data(:,37);
    H2O_std=data(:,38);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,39);
    fc_raw_massman = data(:,40);
    fc_water_term = data(:,41);
    fc_heat_term_massman = data(:,42);
    fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,44);
    E_raw_massman = data(:,45);
    E_water_term = data(:,46);
    E_heat_term_massman = data(:,47);
    E_wpl_massman = data(:,48); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

    HSdry = data(:,50);
    HSdry_massman = data(:,53);

    HL_raw = data(:,54);
    HL_wpl_massman = data(:,56);
    HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available
    %HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,57);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );
    
    for i=1:ncol;
        if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
            rH = data(:,i-1);
        end
    end


elseif args.Results.year < 2009 && args.Results.sitecode ~= 3 
    if args.Results.sitecode == 7 && args.Results.year == 2008 % This is set up for 2009 output
        disp('TX 2008 is set up as 2009 output');
        %stop
    end
    
    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,27);
    CO2_mean=data(:,31);
    CO2_std=data(:,32);
    H2O_mean=data(:,36);
    H2O_std=data(:,37);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,40);
    fc_raw_massman = data(:,44);
    fc_water_term = data(:,42);
    fc_heat_term_massman = data(:,45);
    fc_raw_massman_wpl = data(:,46); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,49);
    E_raw_massman = data(:,53);
    E_water_term = data(:,51);
    E_heat_term_massman = data(:,54);
    E_wpl_massman = data(:,55); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

    HSdry = data(:,56);
    HSdry_massman = data(:,59);

    HL_raw = data(:,61);
    HL_wpl_massman = data(:,64);
    HL_wpl_massman_un = data(:,63);
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available
    HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,65);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );
    
    for i=1:ncol;
        if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
            rH = data(:,i-1);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else  %JSav pre-2009
    
    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,28);
    CO2_mean=data(:,32);
    CO2_std=data(:,33);
    H2O_mean=data(:,37);
    H2O_std=data(:,38);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,39);
    fc_raw_massman = data(:,40);
    fc_water_term = data(:,41);
    fc_heat_term_massman = data(:,42);
    fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,44);
    E_raw_massman = data(:,45);
    E_water_term = data(:,46);
    E_heat_term_massman = data(:,47);
    E_wpl_massman = data(:,48);

    HSdry = data(:,50);
    HSdry_massman = data(:,53);

    HL_raw = data(:,54);
    HL_wpl_massman = data(:,56);
    HL_wpl_massman_un = data(:,55);
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available as very similar values
    HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,57);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );

end

%initialize RH to NaN
rH = repmat( NaN, size( data, 1), 1 );

% filter out absurd u_star values
u_star( u_star > 50 ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not  
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('agc_Avg',headertext(i)) == 1
        agc_Avg = data(:,i-1);
    elseif strcmp( 'h2o_hmp_Avg', headertext( i ) )
        h2o_hmp = data( :, i-1 );
    elseif strcmp('RH',headertext(i)) == 1 || ...
            strcmp('rh_hmp', headertext(i)) == 1 || ...
            strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
            strcmp('RH_Avg', headertext(i)) == 1
        rH = data(:,i-1) / 100.0;
    elseif strcmp( 'Ts_mean', headertext( i ) )
        Tair_TOA5 = data(:,i-1);
    elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
            strcmp('rain_Tot', headertext(i)) == 1 || ...
            strcmp('precip', headertext(i)) == 1 || ...
            strcmp('precip(in)', headertext(i)) == 1 || ...
            strcmp('ppt', headertext(i)) == 1 || ...
            strcmp('Precipitation', headertext(i)) == 1
        precip = data(:,i-1);
    elseif strcmp('press_mean', headertext(i)) == 1 || ...
            strcmp('press_Avg', headertext(i)) == 1 || ...
            strcmp('press_a', headertext(i)) == 1 || ...
            strcmp('press_mean', headertext(i)) == 1
        atm_press = data(:,i-1);
    elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
            strcmp('par_Avg(1)', headertext(i)) == 1 || ...
            strcmp('par_Avg_1', headertext(i)) == 1 || ...
            strcmp('par_Avg', headertext(i)) == 1 || ...
            strcmp('par_up_Avg', headertext(i)) == 1 || ...        
            strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
            strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
            strcmp('par_lite_Avg', headertext(i)) == 1
        Par_Avg = data(:,i-1);
    elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
            strcmp('AirTC_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
            strcmp('pnl_tmp_a', headertext(i))==1 || ...
            strcmp('t_hmp_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_top_Avg', headertext(i))==1
        air_temp_hmp = data(:,i-1);
    elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
            (args.Results.year == 2009 || ...
             args.Results.year ==2010) && args.Results.sitecode == 6
        air_temp_hmp = data(:,i-1);
    elseif strcmp('Tsoil',headertext(i)) == 1 || ...
            strcmp('Tsoil_avg',headertext(i)) == 1 || ...
            strcmp('soilT_Avg(1)',headertext(i)) == 1
        Tsoil = data(:,i-1);
    elseif strcmp('Rn_correct_Avg',headertext(i))==1 || ...
            strcmp('NR_surf_AVG', headertext(i))==1 || ...
            strcmp('NetTot_Avg_corrected', headertext(i))==1 || ...
            strcmp('NetTot_Avg', headertext(i))==1 || ...
            strcmp('Rn_Avg',headertext(i))==1 || ...
            strcmp('Rn_total_Avg',headertext(i))==1
        NR_tot = data(:,i-1);
    elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
            strcmp('pyrr_incoming_Avg', headertext(i))
        sw_incoming = data(:,i-1);
    elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
            strcmp('pyrr_outgoing_Avg', headertext(i))==1
        sw_outgoing = data(:,i-1);
    elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
            strcmp('Rad_long_Up__Avg', headertext(i)) == 1
        lw_incoming = data(:,i-1);
    elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
            strcmp('Rad_long_Dn__Avg', headertext(i))==1
        lw_outgoing = data(:,i-1);
    elseif strcmp('CNR1TC_Avg', headertext(i)) == 1 || ...
            strcmp('Temp_C_Avg', headertext(i)) == 1
        CNR1TK = data(:,i-1) + 273.15;
    elseif strcmp('VW_Avg', headertext(i))==1
        VWC = data(:,i-1);
    elseif strcmp('shf_Avg(1)', headertext(i))==1 || ...
            strcmp('shf_pinon_1_Avg', headertext(i))==1
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND shf_pinon_1_Avg');       
    elseif any( strcmp( headertext(i), ...
                        { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND hfp_grass_1_Avg');       
    elseif any( strcmp( headertext( i ), ...
                        { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
        soil_heat_flux_2 = data(:,i-1);
        disp('FOUND hfp_grass_2_Avg');       
    elseif strcmp('shf_Avg(2)', headertext(i))==1 || ...
            strcmp('shf_jun_1_Avg', headertext(i))==1
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_open = data(:,i-1);
    elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_mescan = data(:,i-1);
    elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_juncan = data(:,i-1);
        %Shurbland flux plates 2009 onwards
    elseif strcmp('hfp01_1_Avg', headertext(i))==1 
        soil_heat_flux_1 = data(:,i-1);
    elseif strcmp('hfp01_2_Avg', headertext(i))==1 
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfp01_3_Avg', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('hfp01_4_Avg', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
    elseif strcmp('hfp01_5_Avg', headertext(i))==1 
        soil_heat_flux_5 = data(:,i-1);
    elseif strcmp('hfp01_6_Avg', headertext(i))==1 
        soil_heat_flux_6 = data(:,i-1);
    elseif strcmp('shf_Avg(3)', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('shf_Avg(4)', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
        
    end
end

% remove absurd precipitation measurements
precip( precip > 1000 ) = NaN;

if ismember( args.Results.sitecode, [ 1, 2 ] ) & args.Results.year == 2009
    Par_Avg = combine_PARavg_PARlite( headertext, data );
end

if ismember( args.Results.sitecode, [ 3, 4 ] )
    % use "RH" at JSav, PJ
    rh_col = find( strcmp( 'RH', headertext ) ) - 1;
    fprintf( 'found RH\n' );
    rH = data( :, rh_col ) / 100.0;
elseif ismember( args.Results.sitecode, [ 5, 6 ] )
    % use "RH_2" at PPine, MCon
    rh_col = find( strcmp( 'RH_2', headertext ) | ...
                   strcmp( 'RH_2_Avg', headertext ) ) - 1;
    if ~isempty( rh_col )
        fprintf( 'found RH_2\n' );
    else
        error( 'could not locate RH_2' );
    end
    rH = data( :, rh_col ) / 100.0;
elseif args.Results.sitecode == 10
    % at PJ girdle, calculate relative humidity from hmp obs using helper
    % function
    rH = thmp_and_h2ohmp_2_rhhmp( air_temp_hmp, h2o_hmp ) / 100.0;
end

save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
                       sprintf( '%s_%d_before_radiation.mat', ...
                                char( args.Results.sitecode ), year(1) ) );
save( save_fname );
fprintf( 'saved %s\n', save_fname );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correction for incorrectly-calculated latent heat flux pointed out by Jim
% Heilman 8 Mar 2012.  E_heat_term_massman should have been added to the
% latent heat flux.  To do the job right, this fix should happen in
% UNM_flux_DATE.m.  Doing the correction here is a temporary fix in order to
% get Ameriflux files created soon.
% -TWH 9 Mar 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lv = ( repmat( 2.501, size( E_raw_massman ) ) - ...
       0.00237 * ( Tdry - 273.15 ) )  * 10^3;
HL_wpl_massman = ( 18.016 / 1000 * Lv ) .* ...
    ( E_raw_massman + E_heat_term_massman );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site-specific steps for soil temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if args.Results.sitecode == 1 %GLand   added TWH, 27 Oct 2011
    for i=1:ncol;
        if strcmp('TCAV_grass_Avg',headertext(i)) == 1
            Tsoil = data(:,i-1);
        end
    end

    % find soil heat flux plate measurements
    SHF_idx = find( cellfun( @(x) ~isempty(x), ...
                             regexp( headertext, 'hfp.*[Aa]vg' ) ) );
    if numel( SHF_idx ) ~= 2 
        %error( 'could not find two soil heat flux observations' );
    end
    soil_heat_flux = data( :, SHF_idx );
    SHF_labels = headertext( SHF_idx );
    SHF_labels = regexprep( SHF_labels, 'hfp01_(.*)', 'SHF_$1');

elseif args.Results.sitecode == 2 %SLand   added TWH, 4 Nov 2011
    for i=1:ncol;
        if strcmp( 'shf_sh_1_Avg', headertext( i ) ) == 1
            soil_heat_flux_1 = data(:,i-1);
        end    
        if strcmp( 'shf_sh_2_Avg', headertext( i ) ) == 1
            soil_heat_flux_2 = data(:,i-1);
        end
    end
    SHF_labels = { 'shf_sh_1_Avg', 'shf_sh_2_Avg' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_1 ];

elseif args.Results.sitecode == 3 %JSav   added TWH, 7 May 2012
    SHF_cols = find( ~cellfun( @isempty, regexp( headertext, 'shf_Avg.*' ) ) );
    soil_heat_flux = data( :, SHF_cols - 1 );
    if isempty( soil_heat_flux ) 
        soil_heat_flux = repmat( NaN, size( data, 1 ), 4 );
        soil_heat_flux_1 = soil_heat_flux( :, 1 );
        soil_heat_flux_2 = soil_heat_flux( :, 2 );
        soil_heat_flux_3 = soil_heat_flux( :, 3 );
        soil_heat_flux_4 = soil_heat_flux( :, 4 );
    end
    SHF_labels = { 'SHF_1', 'SHF_2', 'SHF_3', 'SHF_4' };

elseif args.Results.sitecode == 4 %PJ
    for i=1:ncol;
        if strcmp('tcav_pinon_1_Avg',headertext(i)) == 1
            Tsoil1 = data(:,i-1);
        elseif strcmp('tcav_jun_1_Avg',headertext(i)) == 1
            Tsoil2 = data(:,i-1);
        end
    end
    if exist( 'Tsoil1' ) == 1 & exist( 'Tsoil2' ) == 1
        Tsoil = (Tsoil1 + Tsoil2)/2;
    else
        Tsoil = repmat( NaN, size( data, 1 ), 1 );
    end
    soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
    soil_heat_flux_2 = repmat( NaN, size( data, 1 ), 1 );
    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];

    % related lines 678-682: corrections for site 4 (PJ) soil_heat_flux_1 and soil_heat_flux_2
    Tsoil=sw_incoming.*NaN;  %MF: note, this converts all values in Tsoil to NaN. Not sure if this was intended.
    
elseif args.Results.sitecode == 5 || args.Results.sitecode == 6 % Ponderosa pine or Mixed conifer

    soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
    soil_heat_flux_2 = soil_heat_flux_1;
    soil_heat_flux_3 = soil_heat_flux_1;

    for i=1:ncol;
        if strcmp('T107_C_Avg(1)',headertext(i)) == 1
            Tsoil_2cm_1 = data(:,i-1);
        elseif strcmp('T107_C_Avg(2)',headertext(i)) == 1
            Tsoil_2cm_2 = data(:,i-1);
        elseif strcmp('T107_C_Avg(3)',headertext(i)) == 1
            Tsoil_6cm_1 = data(:,i-1);
        elseif strcmp('T107_C_Avg(4)',headertext(i)) == 1
            Tsoil_6cm_2 = data(:,i-1);
        elseif strcmp('shf_Avg(1)',headertext(i)) == 1
            soil_heat_flux_1 = data(:,i-1);
        elseif strcmp('shf_Avg(2)',headertext(i)) == 1
            soil_heat_flux_2 = data(:,i-1);
        elseif strcmp('shf_Avg(3)',headertext(i)) == 1
            soil_heat_flux_3 = data(:,i-1);
        end
    end
    Tsoil_2cm = (Tsoil_2cm_1 + Tsoil_2cm_2)/2;
    Tsoil_6cm = (Tsoil_6cm_1 + Tsoil_6cm_2)/2;
    Tsoil = Tsoil_2cm;

    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2', 'soil_heat_flux_3' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2, soil_heat_flux_3 ];
    
elseif args.Results.sitecode == 7 % Texas Freeman
    for i=1:ncol;
        if strcmp('Tsoil_Avg(2)',headertext(i)) == 1
            open_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(3)',headertext(i)) == 1
            open_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(5)',headertext(i)) == 1
            Mesquite_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(6)',headertext(i)) == 1
            Mesquite_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(8)',headertext(i)) == 1
            Juniper_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(9)',headertext(i)) == 1
            Juniper_10cm = data(:,i-1);
        end
    end
    if args.Results.year == 2005 % juniper probes on-line after 5/19/05
                        % before 5/19
        canopy_5cm = Mesquite_5cm(find(decimal_day < 139.61));
        canopy_10cm = Mesquite_10cm(find(decimal_day < 139.61));
        % after 5/19
        canopy_5cm(find(decimal_day >= 139.61)) = (Mesquite_5cm(find(decimal_day >= 139.61)) + Juniper_5cm(find(decimal_day >= 139.61)))/2;
        canopy_10cm(find(decimal_day >= 139.61)) = (Mesquite_10cm(find(decimal_day >= 139.61)) + Juniper_10cm(find(decimal_day >= 139.61)))/2;
        % clean strange 0 values
        canopy_5cm(find(canopy_5cm == 0)) = NaN;
        canopy_10cm(find(canopy_10cm == 0)) = NaN;
        Tsoil = (open_5cm + canopy_5cm)./2;
    else
        canopy_5cm = (Mesquite_5cm + Juniper_5cm)/2;
        canopy_10cm = (Mesquite_10cm + Juniper_10cm)/2;
        Tsoil = (open_5cm + canopy_5cm)/2;
    end
    
elseif args.Results.sitecode == 10 || args.Results.sitecode == 11
    Tsoil=sw_incoming.*NaN;
    soil_heat_flux_1 =sw_incoming.*NaN;
    soil_heat_flux_2 =sw_incoming.*NaN;
    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];
end


% Juniper S heat flux plates need multiplying by calibration factors
if args.Results.sitecode == 3
    soil_heat_flux_1 = soil_heat_flux_1.*32.27;
    soil_heat_flux_2 = soil_heat_flux_2.*33.00;
    soil_heat_flux_3 = soil_heat_flux_3.*31.60;
    soil_heat_flux_4 = soil_heat_flux_4.*32.20;
end

% Pinon Juniper heat flux plates need multiplying by calibration factors
if args.Results.sitecode == 4 
    
    soil_heat_flux_1 = soil_heat_flux_1.*35.2;
    soil_heat_flux_2 = soil_heat_flux_2.*32.1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Radiation corrections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if not( exist( 'lw_incoming' ) )
    lw_incoming = repmat( NaN, size( data, 1 ), 1 );
end
if not( exist( 'lw_outgoing' ) )
    lw_outgoing = repmat( NaN, size( data, 1 ), 1 );
end
if not( exist( 'CNR1TK' ) )
    CNR1TK = repmat( NaN, size( data, 1 ), 1 );
end

[ sw_incoming, sw_outgoing, Par_Avg ] = ...
    UNM_RBD_apply_radiation_calibration_factors( args.Results.sitecode, ...
                                                 args.Results.year, ...
                                                 decimal_day, ...
                                                 sw_incoming, ...
                                                 sw_outgoing, ...
                                                 lw_incoming, ...
                                                 lw_outgoing, ...
                                                 Par_Avg, ...
                                                 NR_tot, ...
                                                 wnd_spd, ...
                                                 CNR1TK );

[ NR_sw, NR_lw, NR_tot ] = ...
    UNM_RBD_calculate_net_radiation( args.Results.sitecode, ...
                                     args.Results.year, ...
                                     sw_incoming, ...
                                     sw_outgoing, ...
                                     lw_incoming, ...
                                     lw_outgoing, ...
                                     NR_tot, ...
                                     wnd_spd, ...
                                     decimal_day );

% normalize PAR to account for calibration problems at some sites
Par_Avg = normalize_PAR_wrapper( args.Results.sitecode, ...
                                 args.Results.year, ...
                                 decimal_day, ...
                                 Par_Avg,...
                                 args.Results.draw_plots );


save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
                       sprintf( '%s_%d_after_radiation.mat', ...
                                char( args.Results.sitecode ), year(1) ) );
save( save_fname );
fprintf( 'saved %s\n', save_fname );

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
hh = (1 ./ ( R .* ( t_meanK ./ atm_press ) .* 1000 ) ) .* 44;
% convert umol CO2 / mol dry air to mg CO2 / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_co2 = ( ( MWd * Rd * t_meanK ) / ( 1000 * atm_press ) ) * ( 44 / 1000 );
CO2_mg = CO2_mean .* hh;

% This is the conversion from mmol mol to g m3 for H2O
gg = ( ( 1 ./ ...
         ( R .* ( t_meanK ./ atm_press ) ) ) .* 18 ) ...
     ./ 1000;
% convert mmol H2O / mol dry air to g H2O / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_h2o = ( MW_h2o * R_h2o * t_meanK ) / ( 1000 * atm_press )
H2O_g = H2O_mean .* gg;

rhoa_dry_kg = ( rhoa_dry .* MWd ) ./ 1000; % from mol/m3 to kg/m3

Cp = 1004.67 + ( Tdry .^ 2 ./ 3364 );
RhoCp = rhoa_dry_kg .* Cp;
NR_pos = find( NR_tot > 0 );

Kair = ( 0.000067 .* t_mean ) + 0.024343;

Ti_bot = (0.883.*t_mean+2.17)+273.16;
Ti_bot(NR_pos) = (0.944.*t_mean(NR_pos)+2.57)+273.16;
Ti_top = (1.008.*t_mean-0.41)+273.16;
Ti_top(NR_pos) = (1.005.*t_mean(NR_pos)+0.24)+273.16;
Ti_spar = (1.01.*t_mean-0.17)+273.16;
Ti_spar(NR_pos) = (1.01.*t_mean(NR_pos)+0.36)+273.16;
Si_bot = Kair.*(Ti_bot-t_meanK)./(0.004.*sqrt(0.065./abs(u_mean))+0.004);
Si_top = ( Kair.*(Ti_top-t_meanK) .* ...
           (0.0225+(0.0028.*sqrt(0.045./abs(u_mean)) + ...
                    0.00025./abs(u_mean)+0.0045)) ./ ...
           (0.0225*(0.0028*sqrt(0.045./abs(u_mean)) + ...
                    0.00025./abs(u_mean)+0.0045)) );
Sip_spar = ( Kair .* (Ti_spar - t_meanK) ./ ...
             (0.0025 .* log((0.0025 + 0.0058.*sqrt(0.005./abs(u_mean))) ./ ...
                            0.0025)).*0.15 );
pd = 44.6.*28.97.*atm_press./101.3.*273.16./t_meanK;
dFc = (Si_top+Si_bot+Sip_spar) ./ RhoCp.*CO2_mg ./ t_meanK .* ...
      (1+1.6077.*H2O_g./pd);

if args.Results.draw_plots
    h_burba_fig = figure( 'Name', 'Burba' );
    plot(dFc,'.'); ylim([-1 1]);
    title( sprintf('%s %d', get_site_name( args.Results.sitecode ), year( 1 ) ) );
    ylabel('Burba cold temp correction');
    xlabel('time');
end

fc_mg = fc_raw_massman_wpl.*0.044; % Convert correct flux from mumol/m2/s to
                                   % mg/m2/s
fc_mg_corr = (fc_raw_massman_wpl.*0.044)+dFc;


found = find(t_mean<0);
fc_out=fc_mg;
fc_out(found)=fc_mg_corr(found);
% not sure what this next line is plotting -- TWH 23 Mar 2012
%figure; plot(fc_mg.*22.7273,'-'); hold on; plot(fc_out.*22.7273,'r-'); ylim([-20 20]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filters for co2 and make a master flag variable (decimal_day_nan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decimal_day_nan = decimal_day;
record = 1:1:length(fc_raw_massman_wpl);
conc_record = 1:1:length(CO2_mean);

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
nanflag = find(isnan(fc_raw_massman_wpl));
removednans = length(nanflag);
decimal_day_nan(nanflag) = NaN;
record(nanflag) = NaN;
co2_conc_nanflag = find(isnan(CO2_mean));
conc_record(co2_conc_nanflag) = NaN;
disp(sprintf('    original empties = %d',removednans));

% % Remove values during precipitation
precipflag = find(precip > 0);
removed_precip = length(precipflag);
decimal_day_nan(precipflag) = NaN;
record(precipflag) = NaN;
conc_record(precipflag) = NaN;
disp(sprintf('    precip = %d',removed_precip));

% Remove for behind tower wind direction
windflag = find(wnd_dir_compass > wind_min & wnd_dir_compass < wind_max);
removed_wind = length(windflag);
decimal_day_nan(windflag) = NaN;
record(windflag) = NaN;
disp(sprintf('    wind direction = %d',removed_wind));

% Remove night-time negative fluxes
% changed NEE cutoff from 0 to -0.2 as per conversation with Marcy 29 Mar 2012
isnight = ( Par_Avg < 20.0 ) | ( sw_incoming < 20 );
nightnegflag = find( isnight & ( fc_raw_massman_wpl < -0.2) );
removed_nightneg = length(nightnegflag);
decimal_day_nan(nightnegflag) = NaN;
record(nightnegflag) = NaN;
disp(sprintf('    night-time negs = %d',removed_nightneg));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PPINE EXTRA WIND DIRECTION REMOVAL
% ppine has super high night respiration when winds come from ~ 50 degrees, so these must be excluded also:
if args.Results.sitecode == 5
    ppine_night_wind = find( ( wnd_dir_compass > 30 & ...
                               wnd_dir_compass < 65 ) & ...
                             ( hour <= 9 | hour > 18 ) );
    % ppine_night_wind = find( ( wnd_dir_compass > 30 & ...
    %                            wnd_dir_compass < 65 ) );
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
if args.Results.sitecode == 1 && args.Results.year == 2007
    gland_cold = find(Tdry < 271);
    removed_gland_cold = length(gland_cold);
    decimal_day_nan(gland_cold) = NaN;
    record(gland_cold) = NaN;
    disp(sprintf('    gland cold = %d',removed_gland_cold));
end

% Take out dodgy calibration period at Shrubland in 2007
if args.Results.sitecode == 2 && args.Results.year == 2007 
    decimal_day_nan(12150:12250) = NaN;
    record(12150:12250) = NaN;
    conc_record(12600:12750) = NaN;
end

% Take out dodgy calibration period at Shrubland in 2009
if args.Results.sitecode == 2 && args.Results.year == 2009 
    conc_record(11595:11829) = NaN;
end


% Plot out to see and determine ustar cutoff
if iteration == 1    
    u_star_2 = u_star(find(~isnan(decimal_day_nan)));
    fc_raw_massman_wpl_2 = fc_raw_massman_wpl(find(~isnan(decimal_day_nan)));
    hour_2 = hour(find(~isnan(decimal_day_nan)));

    ustar_bin = 1:1:30; % you can change this to have more or less categories
    ustar_mean = repmat( NaN, size( ustar_bin ) );
    for i = 1:30 % you can change this to have more or less categories
        if i == 1
            startbin(i) = 0;
        elseif i >= 2
            startbin(i) = (i - 1)*0.01;
        end
        endbin(i) = 0.01 + startbin(i);    
        elementstouse = find((u_star_2 > startbin(i) & u_star_2 < endbin(i)) & (hour_2 > 22 | hour_2 < 5));
        co2mean(i) = mean(fc_raw_massman_wpl_2(elementstouse));
        ustar_mean( i ) = mean( u_star_2( elementstouse ) );
    end

    startbin;
    if args.Results.draw_plots
        figure( 'Name', 'determine Ustar cutoff', 'NumberTitle', 'Off' );
        clf;
        plot( ustar_mean, co2mean, '.k' );
        xlabel( 'UStar' );
        ylabel( 'co2mean' );
        title( 'UStar' );
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
    ustarflag = find(u_star < ustar_lim);
    removed_ustar = length(ustarflag);
    decimal_day_nan(ustarflag) = NaN;
    record(ustarflag) = NaN;
    
    % display pulled ustar
    disp(sprintf('    u_star = %d',removed_ustar));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 3 - now that values have been filtered for ustar, decide what
% the min and max co2 flux values should be by examining figure 2 and then
% entering them in the site options above, then run program with iteration
% 3 and see the effect of removing them in figure 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if iteration > 2
    
    if ( args.Results.sitecode == UNM_sites.GLand ) & ( args.Results.year == 2011 )
        precip = fill_Gland_2011_precip_from_SLand(precip);
    end
    
    [ fc_raw_massman_wpl, E_wpl_massman, HL_wpl_massman, ...
      HSdry, HSdry_massman, CO2_mean, H2O_mean, atm_press, NR_tot, ...
      sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, precip, rH ] = ...
        remove_specific_problem_periods( args.Results.sitecode, args.Results.year, ...
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
                                         precip, ...
                                         rH );

    [ DOY_co2_min, DOY_co2_max ] = get_daily_maxmin( month, ...
                                                     co2_min_by_month, ...
                                                     co2_max_by_month, ...
                                                     winter_co2_min );

    
    removed_maxs_mins=0;
    maxminflag = [];

    [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
        specify_siteyear_filter_exceptions( args.Results.sitecode, args.Results.year, ...
                                            DOY_co2_min, DOY_co2_max );
    
    maxminflag = ( ( fc_raw_massman_wpl > DOY_co2_max ) | ...
                   ( fc_raw_massman_wpl < DOY_co2_min ) );
    
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
    highco2flag = find(CO2_mean > 450);

    % exceptions
    co2_conc_filter_exceptions = repmat( false, size( CO2_mean ) );
    co2_conc_filter_exceptions = ...
        specify_siteyear_co2_conc_filter_exceptions( ...
            args.Results.sitecode, year, co2_conc_filter_exceptions );

    removed_highco2 = length(highco2flag);
    decimal_day_nan(highco2flag) = NaN;
    record(highco2flag) = NaN;
    conc_record(highco2flag) = NaN;

    % Remove low CO2 concentration points
    if args.Results.sitecode == 9
        lowco2flag = find(CO2_mean <250);
    elseif args.Results.sitecode == 8 && year(1) ==2008
        lowco2flag = find(CO2_mean <250);
    elseif args.Results.sitecode == 1 && year(1) ==2007
        lowco2flag = find(CO2_mean <344);
    else
        lowco2flag = find(CO2_mean <350);
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
    %     figure;
    %     element = gcf;
    % Remove values outside of a running standard deviation
    n_bins = 48;
    std_bin = zeros( 1, n_bins );
    bin_length = round(length(fc_raw_massman_wpl)/ n_bins);

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

    % if args.Results.sitecode == UNM_sites.PPine
    %     % for PPine, normalize NEE to a defined range...
    %     idx_norm = idx_NEE_good & maxminflag;
    %     fc_raw_massman_wpl = normalize_PPine_NEE( fc_raw_massman_wpl, ...
    %                                               idx_norm );
    %     % ...and reset max/min flags according to normalized NEE
    %     [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
    %         specify_siteyear_filter_exceptions( args.Results.sitecode, args.Results.year, ...
    %                                             DOY_co2_min, DOY_co2_max );
    %     maxminflag = ( ( fc_raw_massman_wpl > DOY_co2_max ) | ...
    %                    ( fc_raw_massman_wpl < DOY_co2_min ) );
    %     idx_NEE_good( maxminflag ) = false;
    % end


    for i = 1:n_bins
        if i == 1
            startbin( i ) = 1;
        elseif i >= 2
            startbin( i ) = ((i-1) * bin_length);
        end    
        endbin( i ) = min( bin_length + startbin( i ), numel( idx_NEE_good) );

        % make logical indices for elements that are (1) in this bin and (2)
        % not already filtered for something else
        this_bin = repmat( false, size( idx_NEE_good ) );
        this_bin( startbin( i ):endbin( i ) ) = true;
        
        std_bin(i) = nanstd( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        mean_flux(i) = nanmean( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        bin_ceil(i) = mean_flux( i ) + ( n_SDs_filter_hi * std_bin( i ) );
        bin_floor(i) = mean_flux( i ) - ( n_SDs_filter_lo * std_bin( i ) );
        stdflag_thisbin_hi = ( this_bin & ...
                               fc_raw_massman_wpl > bin_ceil( i ) );
        stdflag_thisbin_low = ( this_bin & ...
                                fc_raw_massman_wpl < bin_floor( i ) );
        stdflag = stdflag | stdflag_thisbin_hi | stdflag_thisbin_low;
        stdflag( find( std_exc_flag ) ) = false;

        % %plot each SD window and its mean and SD
        % figure()
        % h_all = plot( decimal_day( this_bin ),...
        %               fc_raw_massman_wpl( this_bin ), 'ok' );
        % hold on
        % if any( stdflag_thisbin_low | stdflag_thisbin_hi )
        %     h_out = plot( decimal_day( stdflag_thisbin_low | ...
        %                                stdflag_thisbin_hi ), ...
        %                   fc_raw_massman_wpl( stdflag_thisbin_low | ...
        %                                       stdflag_thisbin_hi ), ...
        %                   'r.' );
        %     refline( 0, bin_ceil( i ) );
        %     refline( 0, bin_floor( i ) );
        %     legend( [ h_all, h_out ], 'all NEE', 'filtered for SD' );
        % end
        % title( sprintf( 'SD filter, window %d/%d', i, n_bins ) );

        elementstouse_c = find(conc_record > startbin( i ) & conc_record <= endbin( i ) & isnan(conc_record) == 0);
        conc_std_bin(i) = std(CO2_mean(elementstouse_c));
        mean_conc(i) = mean(CO2_mean(elementstouse_c));
        if args.Results.sitecode == 7
            conc_bin_index = find(CO2_mean(elementstouse_c) < ...
                                  (mean_conc(i)-(2.*conc_std_bin(i)))...
                                  | CO2_mean(elementstouse_c) > ...
                                  (mean_conc(i)+(2.*conc_std_bin(i))) & ...
                                  wnd_spd(elementstouse_c) > 0.3);  ...
            %u_star(elementstouse_c) > ustar_lim);
        else
            conc_bin_index = find(CO2_mean(elementstouse_c) < (mean_conc(i)-(2.*conc_std_bin(i)))...
                                  | CO2_mean(elementstouse_c) > (mean_conc(i)+(2.*conc_std_bin(i))) & wnd_spd(elementstouse_c) > 3);  %u_star(elementstouse_c) > ustar_lim);           
        end
        conc_outofstdnan = elementstouse_c(conc_bin_index);
        conc_record(conc_outofstdnan) = NaN;
        
        CO2_to_plot = CO2_mean(elementstouse_c);
        wnd_to_plot = wnd_spd(elementstouse_c);
        xxo=ones(length(elementstouse_c),1);
        xaxis=linspace(1,length(elementstouse_c),length(elementstouse_c));
        %         
        %         figure(element); 
        %         plot(elementstouse_c,CO2_to_plot,'o'); hold on
        %         plot(elementstouse_c,xxo.*mean_conc(i),'r'); hold on
        %         plot(elementstouse_c,xxo.*(mean_conc(i)-(2.*conc_std_bin(i))),'g'); hold on
        %         plot(elementstouse_c,xxo.*(mean_conc(i)+(2.*conc_std_bin(i))),'g'); hold on
        %         plot(elementstouse_c(conc_bin_index),CO2_to_plot(conc_bin_index),'k*')
        %         plot(elementstouse_c,wnd_to_plot+mean_conc(i),'c'); hold on
        %         plot(elementstouse_c,1+mean_conc(i),'m'); hold on
        %         plot(elementstouse_c,10+mean_conc(i),'m'); hold on
        
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
    pal = brewer_palettes( 'Dark2' );

    if args.Results.draw_plots
        h_co2_fig = figure( 'Name', '[CO2]' );
        CO2_mean_clean=CO2_mean;
        CO2_mean_clean(find(isnan(conc_record)))=-9999;
        h_co2_all = plot( decimal_day, CO2_mean, ...
                          'Marker', '.', ...
                          'Color', 'black', ...
                          'LineStyle', 'none');
        title( sprintf( '%s %d', get_site_name( args.Results.sitecode ), year( 1 ) ) );
        hold on;
        h_co2_clean = plot( decimal_day, CO2_mean_clean, ...
                            'Marker', 'o', ...
                            'Color', pal( 1, : ), ...
                            'LineStyle', 'none');
        h_co2_mean = plot( decimal_day(xx), yy, ...
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
        xx=linspace(1, length(CO2_mean), length(CO2_mean));
        ylim([300 450]);
        xlabel('day of year');
        ylabel('[CO_2], ppm');
        legend( [ h_co2_all, h_co2_clean, h_co2_mean, h_co2_std ], ...
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
                                   get_site_name( args.Results.sitecode ), ...
                                   year( 2 ) ) );
save_vars = { 'sitecode', 'year', 'decimal_day', 'fc_raw_massman_wpl', ...
              'idx_NEE_good', 'ustarflag', 'precipflag', 'nightnegflag', ...
              'windflag', 'maxminflag', 'lowco2flag', 'highco2flag', ...
              'nanflag', 'stdflag', 'n_bins', 'endbin', 'startbin', ...
              'bin_ceil', 'bin_floor', 'mean_flux' };
save( restore_fname, save_vars{ : } );

maxminflag = find( maxminflag );

if args.Results.sitecode == UNM_sites.PPine
    fc_raw_massman_wpl = normalize_PPine_NEE( fc_raw_massman_wpl, ...
                                              idx_NEE_good );
end

if args.Results.draw_plots
    [ h_fig_flux, ax_NEE, ax_flags ] = plot_NEE_with_QC_results( ...
        args.Results.sitecode, ...
        year, ...
        decimal_day, ...
        fc_raw_massman_wpl, ...
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
HS_flag = find(HSdry > HS_max | HSdry < HS_min);
HSdry(HS_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
if iteration > 1
    HSdry(ustarflag) = NaN;
    removed_HS = length(find(isnan(HSdry)));
end

% max and mins for HSdry_massman
HSmass_flag = find(HSdry_massman > HSmass_max | HSdry_massman < HSmass_min);
HSdry_massman(HSmass_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry_massman(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
HSdry_massman(ustarflag) = NaN;
removed_HSmass = length(find(isnan(HSdry_massman)));

% clean the co2 flux variables
fc_raw( not( idx_NEE_good ) ) = NaN;
fc_raw_massman( not( idx_NEE_good ) ) = NaN;
fc_water_term( not( idx_NEE_good ) ) = NaN;
fc_heat_term_massman( not( idx_NEE_good ) ) = NaN;
fc_raw_massman_wpl( not( idx_NEE_good ) ) = NaN;

% clean the h2o flux variables - remove points flagged for ustar, wind, or pcp
idx_E_good = repmat( true, size( E_raw ) );
idx_E_good( unique( [ ustarflag; windflag; precipflag ] ) ) = false;
E_raw( not( idx_E_good ) ) = NaN;
E_raw_massman( not( idx_E_good ) ) = NaN;
E_water_term( not( idx_E_good ) ) = NaN;
E_heat_term_massman( not( idx_E_good ) ) = NaN;
E_wpl_massman( not( idx_E_good ) ) = NaN;
% cap water flux at 200 (divide by 18 to get correct units)
E_wpl_massman( E_wpl_massman > ( 200 ./ 18 ) ) = NaN;

% clean the co2 concentration
CO2_mean( isnan( conc_record ) ) = NaN;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for max's and min's for other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% QC for HL_raw
LH_flag = ( HL_raw > LH_max ) | ( HL_raw < LH_min );
removed_LH = length( find( LH_flag ) );
HL_raw( LH_flag ) = NaN;

% QC for HL_wpl_massman
LH_min = -20;  %as per Jim Heilman, 28 Mar 2012
               % if PAR measurement exists, use this to remove nighttime LE, otherwise
               % use NR_tot
LH_rad = Par_Avg;
LH_rad( isnan( LH_rad ) ) = NR_tot( isnan( LH_rad ) );

LH_maxmin_flag = ( HL_wpl_massman > LH_max ) | ( HL_wpl_massman < LH_min );
LH_night_flag = ( LH_rad < 20.0 ) & ( abs( HL_wpl_massman ) > 20.0 );
LH_day_flag = ( LH_rad >= 20.0 ) & ( HL_wpl_massman < 0.0 );
if args.Results.draw_plots
    script_LE_diagnostic_plot;
end
removed_LH_wpl_mass = numel( find( LH_maxmin_flag | ...
                                   LH_night_flag | ...
                                   LH_day_flag ) );
HL_wpl_massman( LH_maxmin_flag | LH_night_flag | LH_day_flag ) = NaN;
% QC for sw_incoming

% QC for Tdry
Tdry_flag = find(Tdry > Tdry_max | Tdry < Tdry_min);
removed_Tdry = length(Tdry_flag);
Tdry(Tdry_flag) = NaN;

% QC for Tsoil

% QC for rH
rH_flag = find(rH > rH_max | rH < rH_min);
removed_rH = length(rH_flag);
rH(rH_flag) = NaN;

% QC for h2o mean values
h2o_flag = ( H2O_mean > h2o_max ) | ( H2O_mean < h2o_min );
removed_h2o = length( find ( h2o_flag ) );
H2O_mean( h2o_flag ) = NaN;

% QC for atmospheric pressure
press_flag = []; %find(atm_press > press_max | atm_press < press_min);
removed_press = length(press_flag);
atm_press(press_flag) = NaN;

% min/max QC for TX soil heat fluxes
if args.Results.sitecode == 7
    if args.Results.year == 2005
        soil_heat_flux_open(find(soil_heat_flux_open > 100 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;
    elseif args.Results.year == 2006
        soil_heat_flux_open(find(soil_heat_flux_open > 90 | soil_heat_flux_open < -60)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -50)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;
    elseif args.Results.year == 2007 
        soil_heat_flux_open(find(soil_heat_flux_open > 110 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 40 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 20 | soil_heat_flux_juncan < -40)) = NaN;
    end
end

% remove days 295 to 320 for GLand 2010 for several variables -- the reported
% values look weirdly bogus -- TWH 9 Apr 2012
if args.Results.sitecode == 1 & args.Results.year == 2010
    bogus_idx = ( decimal_day >= 294 ) & ( decimal_day <= 320 );
    HL_wpl_massman( bogus_idx ) = NaN;
    HSdry_massman( bogus_idx ) = NaN;
    E_wpl_massman( bogus_idx ) = NaN;
    lw_incoming( bogus_idx ) = NaN;
    lw_outgoing( bogus_idx ) = NaN;
end

if ( args.Results.sitecode == 5 ) & ( args.Results.year == 2008 )
    bogus_idx = ( decimal_day >= 100 ) & ( decimal_day < 190 ) & ( rH < 0.03 );
    rH( bogus_idx ) = NaN;
end

if ( args.Results.sitecode == 7 ) & ( year( 2 ) == 2008 )
    u_star( u_star > 200 ) = NaN;
end

if ( args.Results.sitecode == 3 ) & ( year( 2 ) == 2009 )
    u_star( decimal_day < 34 ) = NaN;
    wnd_dir_compass( decimal_day < 34 ) = NaN;
end

% small runs of consecutive zeros in these fields are (1) almost certainly bogus
% and (2) seem to mess up the Lasslop flux partitioning.  Replace them
% here with NaN.
fc_raw_massman_wpl = ...
    replace_consecutive( fc_raw_massman_wpl, 1 );
HL_wpl_massman = ...
    replace_consecutive( HL_wpl_massman, 1 );
HSdry_massman = ...
    replace_consecutive( HSdry_massman, 1 );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print to screen the number of removals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(' ');
disp(sprintf('number of co2 flux values pulled in post-process = %d',(filelength_n-sum(~isnan(record)))));
disp(sprintf('number of co2 flux values used = %d',sum(~isnan(record))));
disp(' ');
disp('Values removed for other qcd variables');
disp(sprintf('    number of latent heat values removed = %d',removed_LH));
disp(sprintf('    number of massman&wpl-corrected latent heat values removed = %d',removed_LH_wpl_mass));
disp(sprintf('    number of sensible heat values removed = %d',removed_HS));
disp(sprintf('    number of massman-corrected sensible heat values removed = %d',removed_HSmass));
disp(sprintf('    number of temperature values removed = %d',removed_Tdry));
disp(sprintf('    number of relative humidity values removed = %d',removed_rH));
disp(sprintf('    number of mean water vapor values removed = %d',removed_h2o));
disp(sprintf('    number of atm press values removed = %d',removed_press));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE FILE FOR ONLINE GAP-FILLING PROGRAM (REICHSTEIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dd_idx = isnan(decimal_day_nan);
qc = ones(datalength,1);
%qc(dd_idx) = 2;
qc( not( idx_NEE_good ) ) = 2;
NEE = fc_raw_massman_wpl;
NEE( not( idx_NEE_good ) ) = -9999;
LE = HL_wpl_massman;
%LE(dd_idx) = -9999;

H_dry = HSdry_massman;
%H_dry(dd_idx) = -9999;
Tair = Tdry - 273.15;

if args.Results.draw_plots
    figure('Name', 'NEE vs wind direction' );
    ax1 = subplot( 2, 1, 1 );
    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( sw_incoming < 10 ) = false;
    idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    plot( wnd_dir_compass( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (daytime )' );
    ax2 = subplot( 2, 1, 2 );
    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( sw_incoming > 10 ) = false;
    idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    plot( wnd_dir_compass( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (nighttime )' );

    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    %idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    
    figure('Name', 'NEE vs ustar' );
    plot( u_star( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'ustar' );
    
    figure('Name', 'NEE vs wind speed' );
    plot( wnd_spd( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind speed' );
    
    figure( 'Name', 'NEE and wind direction' );
    ax1 = subplot( 4, 1, 1 );
    plot( decimal_day( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'DOY' );
    ax2 = subplot( 4, 1, 2 );
    plot( decimal_day, Tair, '.' );
    ylabel( 'T' ); xlabel( 'DOY' );
    ax3 = subplot( 4, 1, 3 );
    plot( decimal_day( idx ), CO2_mean( idx ), '.' );
    ylabel( '[CO_2]' ); xlabel( 'DOY' );
    ax4 = subplot( 4, 1, 4 );
    plot( decimal_day( precip > 0 ), precip( precip > 0 ), '.' );
    ylabel( 'pcp' ); xlabel( 'DOY' );
    linkaxes( [ ax1, ax2, ax3, ax4 ], 'x' );
end

if args.Results.sitecode == 1 & year == 2010
    Tair( 12993:end ) = Tair_TOA5(  12993:end );
end

if args.Results.draw_fingerprints
    h_fps = RBD_plot_fingerprints( args.Results.sitecode, args.Results.year, decimal_day, ...
                                   sw_incoming, rH, Tair, NEE, LE, ...
                                   H_dry, ...
                                   shift_t_str );
end

if (args.Results.sitecode>7 && args.Results.sitecode<10) % || 9);
    disp('writing gap-filling file...')
    header = {'day' 'month' 'year' 'hour' 'minute' ...
              'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
              'rH' 'precip' 'Ustar'};
    %sw_incoming=ones(size(qc)).*-999;
    Tsoil=ones(size(qc)).*-999;
    datamatrix = [day month year hour minute qc NEE LE H_dry ...
                  sw_incoming Tair Tsoil rH precip u_star];

else    
    disp('preparing gap-filling file...')
    
    fgf_headers = {'day' 'month' 'year' 'hour' 'minute' ...
                   'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
                   'rH' 'precip' 'Ustar'};
    if args.Results.sitecode == 3
        Tsoil = ones(size(qc)).*-999;
    end
    
    fgf = dataset( { [day month year hour minute qc NEE ...
                      LE H_dry sw_incoming Tair Tsoil rH precip u_star], ...
                     fgf_headers{ : } } );
    [ filled_idx, fgf ] = ...
        UNM_gapfill_from_local_data( ...
            args.Results.sitecode, ...
            args.Results.year, ...
            fgf );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE COMPLETE OUT-FILE  (FLUX_all matrix with bad values removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Tsoil = ones(size(qc)).*-999;
if args.Results.sitecode == 5 || args.Results.sitecode == 6 
    qc_headers = {'year', 'month', 'day', 'hour', 'minute', ...
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
    qc_data = [year, month, day, hour, minute, second, jday, iok, ...
               agc_Avg, u_star, wnd_dir_compass, wnd_spd, CO2_mean, ...
               CO2_std, H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
               fc_water_term, fc_heat_term_massman, ...
               fc_raw_massman_wpl, E_raw, E_raw_massman, ...
               E_water_term, E_heat_term_massman, E_wpl_massman, ...
               HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
               air_temp_hmp, Tsoil_2cm, Tsoil_6cm, VWC, precip ...
               atm_press, rH Par_Avg, sw_incoming, sw_outgoing, ...
               lw_incoming, lw_outgoing, NR_sw, NR_lw, NR_tot];
    
elseif args.Results.sitecode == 7
    qc_headers = {'year', 'month', 'day', 'hour', 'minute', ...
                  'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
                  'wnd_dir_compass', 'wnd_spd', 'CO2_mean', 'CO2_std', ...
                  'H2O_mean', 'H2O_std', 'fc_raw', 'fc_raw_massman', ...
                  'fc_water_term', 'fc_heat_term_massman', ...
                  'fc_raw_massman_wpl', 'E_raw', 'E_raw_massman', ...
                  'E_water_term', 'E_heat_term_massman', 'E_wpl_massman', ...
                  'HSdry', 'HSdry_massman', 'HL_raw', 'HL_wpl_massman', ...
                  'Tdry', 'air_temp_hmp', 'Tsoil', 'canopy_5cm', ...
                  'canopy_10cm', 'open_5cm', 'open_10cm', ...
                  'soil_heat_flux_open', 'soil_heat_flux_mescan', ...
                  'soil_heat_flux_juncan', 'precip', 'atm_press', 'rH' ...
                  'Par_Avg', 'sw_incoming', 'sw_outgoing', 'lw_incoming', ...
                  'lw_outgoing', 'NR_sw', 'NR_lw', 'NR_tot'};
    qc_data = [year, month, day, hour, minute, second, jday, iok, ...
               agc_Avg, u_star, wnd_dir_compass, wnd_spd, CO2_mean, ...
               CO2_std, H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
               fc_water_term, fc_heat_term_massman, ...
               fc_raw_massman_wpl, E_raw, E_raw_massman, ...
               E_water_term, E_heat_term_massman, E_wpl_massman, ...
               HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
               air_temp_hmp, Tsoil, canopy_5cm, canopy_10cm, ...
               open_5cm, open_10cm, soil_heat_flux_open, ...
               soil_heat_flux_mescan, soil_heat_flux_juncan, precip, ...
               atm_press, rH Par_Avg, sw_incoming, sw_outgoing, ...
               lw_incoming, lw_outgoing, NR_sw, NR_lw, NR_tot];
    
elseif args.Results.sitecode == 8 || args.Results.sitecode == 9
    qc_headers = {'year', 'month', 'day', 'hour', 'minute', ...
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
    %atm_press=ones(size(precip)).*-999;
    %air_temp_hmp=ones(size(precip)).*-999;
    qc_data = [year, month, day, hour, minute, second, jday, iok, ...
               u_star, wnd_dir_compass, wnd_spd, CO2_mean, CO2_std, ...
               H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
               fc_water_term, fc_heat_term_massman, ...
               fc_raw_massman_wpl, E_raw, E_raw_massman, ...
               E_water_term, E_heat_term_massman, E_wpl_massman, ...
               HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
               air_temp_hmp, precip, atm_press, rH, Par_Avg, ...
               sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, ...
               NR_sw,NR_lw,NR_tot];
    
else
    qc_headers = {'year', 'month', 'day', 'hour', ...
                  'minute', 'second', 'jday', 'iok', 'agc_Avg', ...
                  'u_star', 'wnd_dir_compass', 'wnd_spd', 'CO2_mean', ...
                  'CO2_std', 'H2O_mean', 'H2O_std', 'fc_raw', ...
                  'fc_raw_massman', 'fc_water_term', ...
                  'fc_heat_term_massman', 'fc_raw_massman_wpl', ...
                  'E_raw', 'E_raw_massman', 'E_water_term', ...
                  'E_heat_term_massman', 'E_wpl_massman', 'HSdry', ...
                  'HSdry_massman', 'HL_raw', 'HL_wpl_massman', 'Tdry', ...
                  'air_temp_hmp', 'Tsoil', SHF_labels{ : }, 'precip', ...
                  'atm_press', 'rH' 'Par_Avg', 'sw_incoming', ...
                  'sw_outgoing', 'lw_incoming', 'lw_outgoing', 'NR_sw', ...
                  'NR_lw', 'NR_tot'};
    qc_data = [year, month, day, hour, minute, second, jday, iok, ...
               agc_Avg, u_star, wnd_dir_compass, wnd_spd,CO2_mean, ...
               CO2_std,H2O_mean,H2O_std, fc_raw, fc_raw_massman, ...
               fc_water_term, fc_heat_term_massman, ...
               fc_raw_massman_wpl, E_raw,E_raw_massman,E_water_term, ...
               E_heat_term_massman,E_wpl_massman, HSdry, ...
               HSdry_massman,HL_raw,HL_wpl_massman, Tdry, ...
               air_temp_hmp,Tsoil, soil_heat_flux, precip, atm_press, ...
               rH, Par_Avg, sw_incoming, sw_outgoing, lw_incoming, ...
               lw_outgoing,NR_sw,NR_lw,NR_tot];
end

if iteration > 4
    
    if args.Results.sitecode == 8 || args.Results.sitecode == 9
        numbers_removed = [removednans removed_precip ...
                           removed_wind removed_nightneg ...
                           removed_ustar removed_maxs_mins ...
                           removed_lowco2 removed_highco2 ...
                           removed_outofstdnan NaN ...
                           (filelength_n-sum(~isnan(record))) ...
                           sum(~isnan(record)) removed_LH ...
                           removed_LH_wpl_mass removed_HS ...
                           removed_HSmass removed_Tdry ...
                           removed_rH removed_h2o];
        removals_header = {'Original nans', ...
                           'Precip periods', ...
                           'Bad wind direction', ...
                           'Night-time negs', ...
                           'Low ustar', ...
                           'Over max or min', ...
                           'Low co2', ...
                           'High co2', ...
                           'Outside running std', ...
                           '', ...
                           'Total co2 pulled', ...
                           'Total retained', ...
                           'LH values removed', ...
                           'LH with WPL/Massman removed', ...
                           'HS removed', ...
                           'HS with massman removed', ...
                           'Temp removed', ...
                           'Rel humidity removed', ...
                           'Water removed'};
    else
        numbers_removed = [removednans removed_precip ...
                           removed_wind removed_nightneg ...
                           removed_ustar removed_maxs_mins ...
                           removed_lowco2 removed_highco2 ...
                           removed_outofstdnan NaN ...
                           (filelength_n-sum(~isnan(record))) ...
                           sum(~isnan(record)) removed_LH ...
                           removed_LH_wpl_mass removed_HS ...
                           removed_HSmass removed_Tdry ...
                           removed_rH removed_h2o removed_press];
        removals_header = {'Original nans', ...
                           'Precip periods', ...
                           'Bad wind direction', ...
                           'Night-time negs', ...
                           'Low ustar',...
                           'Over max or min', ...
                           'Low co2', ...
                           'High co2', ...
                           'Outside running std', ...
                           '',...
                           'Total co2 pulled', ...
                           'Total retained',...
                           'LH values removed', ...
                           'LH with WPL/Massman removed', ...
                           'HS removed', ...
                           'HS with massman removed',...
                           'Temp removed', ...
                           'Rel humidity removed', ...
                           'Water removed', ...
                           'Pressure removed'};
        % xlswrite(outfilename,numbers_removed','numbers removed','B1');
        % xlswrite (outfilename, removals_header', 'numbers removed', 'A1');
    end
end

if args.Results.write_GF
    %write for gapfilling file
    outfolder = fullfile( get_site_directory( args.Results.sitecode ), ...
                          'processed_flux' );
    outfilename_forgapfill_txt = fullfile( outfolder, ...
                                           strcat( filename, ...
                                                   '_for_gap_filling.txt' ) );
    fprintf('writing gap-filling file: %s\n', outfilename_forgapfill_txt );
    export_dataset_tim(  outfilename_forgapfill_txt, ...
                         fgf, ...
                         'replace_NaNs', -9999 );
    % fid = fopen( outfilename_forgapfill_txt , 'w' );
    % fmt = repmat('%s\t', 1, numel( fgf_headers ) - 1 );
    % fmt = [ fmt, '%s\n' ];
    % fprintf( fid, fmt, fgf_headers{ : } );
    % fclose( fid );
    % dlmwrite( outfilename_forgapfill_txt, ...
    %           double( fgf ), ...
    %           '-append', ...
    %           'delimiter', '\t' );
end

if args.Results.write_QC
    % write QC file
    outfolder = fullfile( get_site_directory( args.Results.sitecode ), ...
                          'processed_flux' );
    outfilename_csv = fullfile( outfolder, strcat( filename, '_qc.txt' ) );
    fprintf( 'writing qc file: %s\n', outfilename_csv );
    out_data = dataset( { qc_data, qc_headers{ : } } );
    export_dataset_tim(  outfilename_csv, out_data, ...
                         'replace_NaNs', -9999 );
end
%------------------------------------------------------------
%------------------------------------------------------------
%           HELPER FUNCTIONS
%------------------------------------------------------------
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
        sw_incoming( DOYidx( 7 ) : DOYidx( 8 ) ) = NaN;
        
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
    
  case UNM_sites.TX
    switch year
      case 2009
        sw_incoming( DOYidx( 313.5 ) : DOYidx( 313.8 ) ) = NaN;
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

if ( sitecode == UNM_sites.GLand ) & ( year(1) == 2007 )
    co2_conc_filter_exceptions( DOYidx( 214 ) : DOYidx( 218 ) ) = true;
end

% keep index 5084 to 5764 in 2010 - these CO2 obs are bogus but the
% fluxes look OK.  TWH 27 Mar 2012
if ( sitecode == UNM_sites.GLand ) & ( year(1) == 2010 )
    % keep index 4128 to 5084, 7296-8064 (days 152:168) in 2010 -
    % these CO2 obs are bogus but the datalogger 30-min fluxes look OK.  TWH 27
    % Mar 2012
    co2_conc_filter_exceptions( 4128:5764 ) = true;
    co2_conc_filter_exceptions( 7296:8064 ) = true;
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 218 ) : DOYidx( 223 ) ) = true;
    %co2_conc_filter_exceptions( DOYidx( 271 ) : DOYidx( 278 ) ) = true;
end 
if ( sitecode == UNM_sites.GLand ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 153 ) : DOYidx( 160 ) ) = true;
end 
if ( sitecode == UNM_sites.SLand ) & ( year == 2007 )
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 253 ) : DOYidx( 257 ) ) = true;
end 
if ( sitecode == UNM_sites.JSav ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 41.6 ) : DOYidx( 52.7 ) ) = true;
end 
if ( sitecode == UNM_sites.PJ ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 358  ) : end ) = true;
end 
if (sitecode == UNM_sites.PPine ) & ( year == 2007 )
    % days 290:335 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 290 ) : DOYidx( 335 ) ) = true;
end
if (sitecode == UNM_sites.TX ) & ( year == 2008 )
    % low [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 154 ) : DOYidx( 179 ) ) = true;
end
if (sitecode == UNM_sites.TX_forest ) & ( year == 2009 )
    % days 1 to 40.5 -- low [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 1 ) : DOYidx( 40.5 ) ) = true;
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

%-----------------------------------------------------------------

