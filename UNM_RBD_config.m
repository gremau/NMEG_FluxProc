function RBDrc = UNM_RBD_config( sitecode, year, varargin )
% UNM_RBDRC - setup configuration details (file lengths, ustar thresholds, CO2
% flux max/min, etc.) for a specified site year
%
% USAGE
%     RBDrc = UNM_RBDrc( sitecode, year, varargin )
%
% INPUTS
%     sitecode: UNM_sites object or integer; specifies site to process
%     year: integer; year to process
%
% (c) Timothy W. Hilton, UNM, 2013

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ...
                         ( x <= this_year ) ) );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );
% -----

RBDrc = struct;

%initialization -- will be set for specific sites later
RBDrc.winter_co2_min = -100;  


switch args.Results.sitecode
  case UNM_sites.GLand
    if year == 2006
        RBDrc.filelength_n = 11594;
    elseif year == 2007
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn='HC';
        RBDrc.ustar_lim = 0.06;
        RBDrc.co2_min = -7;
        RBDrc.co2_max = 6;
        RBDrc.co2_max_by_month = [2.5 2.5 2.5 2.5 3.5 3.5 3.5 3.5 3.5 2.5 2.5 2.5];
        RBDrc.co2_min_by_month = [-0.5 -0.5 -1 -3 -3 -4 -4 -4 -4 -1 -0.5 -0.5];
    elseif year == 2008;
        RBDrc.filelength_n = 17571;
        RBDrc.lastcolumn = 'HD';
        RBDrc.ustar_lim = 0.06;
        RBDrc.co2_min_by_month = [ -0.4, -0.4, repmat( -10, 1, 9 ), -0.4 ];
        RBDrc.co2_max_by_month = 6;
    elseif year == 2009;
        RBDrc.filelength_n = 17520;
        RBDrc.lastcolumn = 'IC';
        RBDrc.ustar_lim = 0.06;
        RBDrc.winter_co2_min = -0.5;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = [2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5 2.5];
    elseif year == 2010;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IL';
        RBDrc.ustar_lim = 0.06;
        RBDrc.winter_co2_min = -0.5;
        RBDrc.co2_min_by_month = [ -0.5, -0.5, repmat( -10, 1, 9 ), -0.5 ];;
        RBDrc.co2_max_by_month = 6;
    elseif year == 2011;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IL';
        RBDrc.ustar_lim = 0.06;
        RBDrc.co2_min_by_month = -0.8;
        RBDrc.co2_max_by_month = 6;
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 330;
    RBDrc.wind_max = 30; % these are given a sonic_orient = 180;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 320;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 450;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 450;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;

  case UNM_sites.SLand % shrubland
    if year == 2006
    elseif year == 2007
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'HA';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = [-0.7, -0.7, repmat( -4, 1, 9 ), -0.7 ];
        RBDrc.co2_max_by_month = [ repmat( 1.5, 1, 6 ), repmat( 3.5, 1, 6 ) ];
    elseif year == 2008
        RBDrc.filelength_n = 17572;
        RBDrc.lastcolumn = 'GZ';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = repmat( 6, 1, 12 );
        co2_max_by_month( [ 7, 8 ] ) = 2.5; %remove some funny looking pts
                                            %in Jul and Aug
    elseif year == 2009
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IL';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -4;
        RBDrc.co2_max_by_month = 4;
    elseif year == 2010
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IE';
        RBDrc.ustar_lim = 0.08;
        RBDrc.winter_co2_min_by_month = -1;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 6;
    elseif year == 2011
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IQ';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 6;
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 320;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 450;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 450;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    

  case UNM_sites.JSav
    if year == 2007
        RBDrc.filelength_n = 11596;
        RBDrc.lastcolumn = 'HR';
        RBDrc.ustar_lim = 0.09;
        RBDrc.co2_min_by_month = -11;
        RBDrc.co2_max_by_month = repmat( 7, 1, 12 );
        RBDrc.co2_max_by_month( 7 ) = 5; %remove some funny pts in July
    elseif year == 2008
        RBDrc.filelength_n = 17572;
        RBDrc.lastcolumn = 'HJ';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = repmat( 10, 1, 12 );
        RBDrc.co2_max_by_month( 9 ) = 5; %remove some funny pts in Sep
    elseif year == 2009
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IN';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 10;
    elseif year == 2010
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IE';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 10;
    elseif year == 2011
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'IE';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 10;
    elseif year == 2012
        RBDrc.filelength_n = 7749;
        RBDrc.lastcolumn = 'FE';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = [ repmat( 2, 1, 6 ), repmat( 10, 1, 6 ) ];
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 320;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 550;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 550;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;
    
  case UNM_sites.PJ
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 15;
    RBDrc.wind_max = 75; % these are given a sonic_orient = 225;
    RBDrc.co2_min_by_month = -10;
    RBDrc.co2_max_by_month = 6;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 310;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 640;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 640;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;
    if year == 2007
        RBDrc.lastcolumn = 'HO';
        RBDrc.filelength_n = 2514;
        RBDrc.ustar_lim = 0.16;
        RBDrc.co2_min_by_month = -5;
        RBDrc.co2_max_by_month = 2.5;
    elseif year == 2008
        RBDrc.lastcolumn = 'HO';
        RBDrc.filelength_n = 17571;
        RBDrc.ustar_lim = 0.16;
        RBDrc.co2_max_by_month = [ 1.5, 1.5, 1.4, repmat( 6, 1, 6 ), 3, 3, 3 ];
    elseif year == 2009
        RBDrc.lastcolumn = 'HJ';
        RBDrc.filelength_n = 17523;
        RBDrc.ustar_lim = 0.16;
    elseif year == 2010
        RBDrc.lastcolumn = 'HA';
        RBDrc.filelength_n = 17523;
        RBDrc.ustar_lim = 0.16;
    elseif year == 2011  % added this block Mar 21, 2011
        RBDrc.lastcolumn = 'EZ';
        RBDrc.filelength_n = 17523;
        RBDrc.ustar_lim = 0.16;
    elseif year == 2012  % added this block 15 Oct, 2012
        RBDrc.lastcolumn = 'EZ';
        RBDrc.co2_max_by_month = [ 2, 2, 2, 2.5, 3, 3, 3, repmat( 6, 1, 5 ) ];
        RBDrc.filelength_n = 11893;
        RBDrc.ustar_lim = 0.16;
    end    
    

  case UNM_sites.PPine
    % site default values
    RBDrc.co2_min_by_month = [-6 -6 -15 -15 -15 -15 -15 -15 -15 -15 -15 -5];
    if year == 2006
        RBDrc.filelength_n = 11594;
        RBDrc.lastcolumn = 'FT';
        RBDrc.ustar_lim = 0.08;
    elseif year == 2007
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'FV';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = [-6 -6 -15 -20 -20 -20 -20 -20 -20 -20 -15 -10];
    elseif year == 2008;
        RBDrc.filelength_n = 17571;
        RBDrc.lastcolumn = 'FU';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = -18; %[-6 -6 -15 -15 -15 -15 -20 -20 -25 -25 -15 -10];
    elseif year == 2009;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'FY';
        RBDrc.ustar_lim = 0.15;
        RBDrc.co2_min_by_month = [ -4, -10, -15, -20, -20, -20, ...
                            -20, -20, -20, -20, -15, -10 ];
        RBDrc.co2_max_by_month = 20;
        %co2_max_by_month = [ 8, 8, 8, repmat( 10, 1, 8 ), 4 ];
        
    elseif year == 2010;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'FW';
        RBDrc.ustar_lim = 0.08;
        RBDrc.co2_min_by_month = [ -15, -15, -15, -20, -20, -20, ...
                            -20, -20, -20, -20, -15, -4 ];
        
    elseif year == 2011;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'FY';
        RBDrc.ustar_lim = 0.08;
    elseif year == 2012  % added this block 15 Oct, 2012
        RBDrc.ustar_lim = 0.08;
    end
    RBDrc.co2_max_by_month = 30;
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 119;
    RBDrc.wind_max = 179; % these are given a sonic_orient = 329;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 310;
    RBDrc.HS_min = -200;
    RBDrc.HS_max = 800;
    RBDrc.HSmass_min = -200;
    RBDrc.HSmass_max = 800;
    RBDrc.LH_min = -50;
    RBDrc.LH_max = 550;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    

  case UNM_sites.MCon
    RBDrc.co2_min_by_month = [ -1.5, -1.5, repmat( -12, 1, 9 ), -1.5 ];
    RBDrc.co2_max_by_month = 6;
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 153;
    RBDrc.wind_max = 213; % these are given a sonic_orient = 333;
    RBDrc.Tdry_min = 250;
    RBDrc.Tdry_max = 300;
    RBDrc.HS_min = -200;
    RBDrc.HS_max = 800;
    RBDrc.HSmass_min = -200;
    RBDrc.HSmass_max = 800;
    RBDrc.LH_min = -50;
    RBDrc.LH_max = 550;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    if year == 2006
        RBDrc.filelength_n = 4420;
        RBDrc.lastcolumn = 'GA';
        RBDrc.ustar_lim = 0.12;
    elseif year == 2007
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'GB';
        RBDrc.ustar_lim = 0.12;
        RBDrc.co2_max_by_month = repmat( 6, 1, 12 );
        co2_max_by_month( [ 4, 5 ] )  = 2;
    elseif year == 2008;
        RBDrc.filelength_n = 17419;
        RBDrc.lastcolumn = 'GB';
        RBDrc.ustar_lim = 0.11;
        RBDrc.n_SDs_filter_hi = 3.5; % how many std devs above the mean NEE to allow
    elseif year == 2009;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'GF';
        RBDrc.ustar_lim = 0.11;
    elseif year == 2010;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'GI';
        RBDrc.ustar_lim = 0.11;
    elseif year == 2011;
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'GI';
        RBDrc.ustar_lim = 0.11;
    end
    

  case UNM_sites.TX
    if year == 2005
        RBDrc.filelength_n = 17522;
        RBDrc.lastcolumn = 'GF';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2006
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'GF';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2007
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'FZ';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2008;
        RBDrc.filelength_n = 17452;
        RBDrc.lastcolumn = 'GP';
        RBDrc.ustar_lim = 0.11;  % (changed from 0.11 10 Apr 2012 -- TWH )
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ] ;
    elseif year == 2009;
        RBDrc.filelength_n = 17282;
        RBDrc.lastcolumn = 'GP';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ] ;
    elseif year == 2010
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'GQ';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    elseif year == 2011;
        RBDrc.filelength_n = 7282;
        RBDrc.lastcolumn = 'GQ';
        RBDrc.ustar_lim = 0.11;
        RBDrc.co2_min_by_month = -26;
        RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                            12, 12, 9, 6, 6, 4.9 ];
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 296;
    RBDrc.wind_max = 356; % these are given a sonic_orient = 146;
    RBDrc.Tdry_min = 265;
    RBDrc.Tdry_max = 315;
    RBDrc.HS_min = -200;
    RBDrc.HS_max = 800;
    RBDrc.HSmass_min = -200;
    RBDrc.HSmass_max = 800;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 550;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;


  case UNM_sites.TX_forest
    if year == 2005
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'DO';
        RBDrc.ustar_lim = 0.12;
    elseif year == 2006
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'DO';
        RBDrc.ustar_lim = 0.12;
    elseif year == 2007
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'DO';
        RBDrc.ustar_lim = 0.12;
    elseif year == 2008;
        RBDrc.filelength_n = 17571;
        RBDrc.lastcolumn = 'ET';
        RBDrc.ustar_lim = 0.12;
    elseif year == 2009;
        RBDrc.filelength_n = 17180;
        RBDrc.lastcolumn = 'EU';
        RBDrc.ustar_lim = 0.11;
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.co2_min_by_month = -26;
    RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                        12, 12, 9, 6, 6, 4.9 ];
    RBDrc.wind_min = 300;
    RBDrc.wind_max = 360; % these are given a sonic_orient = ;
    RBDrc.Tdry_min = 265;
    RBDrc.Tdry_max = 315;
    RBDrc.HS_min = -200;
    RBDrc.HS_max = 800;
    RBDrc.HSmass_min = -200;
    RBDrc.HSmass_max = 800;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 550;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;
    

  case UNM_sites.TX_grass
    if year == 2005
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'DT';
        RBDrc.ustar_lim = 0.06;
    elseif year == 2006
        RBDrc.filelength_n = 17523;
        RBDrc.lastcolumn = 'DO';
        RBDrc.ustar_lim = 0.06;
    elseif year == 2007
        RBDrc.filelength_n = 17524;
        RBDrc.lastcolumn = 'DO';
        RBDrc.ustar_lim = 0.07;
    elseif year == 2008;
        RBDrc.filelength_n = 17571;
        RBDrc.lastcolumn = 'ET';
        RBDrc.ustar_lim = 0.11;
    elseif year == 2009;
        RBDrc.filelength_n = 17180;
        RBDrc.lastcolumn = 'ET';
        RBDrc.ustar_lim = 0.11;
    end
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.co2_min_by_month = -26;
    RBDrc.co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                        12, 12, 9, 6, 6, 4.9 ];
    RBDrc.wind_min = 300;
    RBDrc.wind_max = 360; % these are given a sonic_orient = ;
    RBDrc.Tdry_min = 265;
    RBDrc.Tdry_max = 315;
    RBDrc.HS_min = -200;
    RBDrc.HS_max = 800;
    RBDrc.HSmass_min = -200;
    RBDrc.HSmass_max = 800;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 550;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 35;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;


  case UNM_sites.PJ_girdle
    RBDrc.lastcolumn = 'FE';
    RBDrc.ustar_lim = 0.16;
    RBDrc.n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.wind_min = 15;
    RBDrc.wind_max = 75; % these are given a sonic_orient = 225;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 310;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 640;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 640;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    RBDrc.press_min = 70;
    RBDrc.press_max = 130;
    if year == 2009
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 6;
        RBDrc.filelength_n = 17523;
    elseif year == 2010
        RBDrc.co2_min_by_month = -7;
        RBDrc.co2_max_by_month = 6;
        RBDrc.filelength_n = 17523;
    elseif year == 2011
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = 6;
        RBDrc.filelength_n = 17523;
    elseif year == 2012
        RBDrc.co2_min_by_month = -10;
        RBDrc.co2_max_by_month = [ 1, 1.5, 2, 2, 2, 2, 2, repmat( 6, 1, 5 ) ];
        RBDrc.filelength_n = 7752;
    end      


  case UNM_sites.New_GLand
    RBDrc.ustar_lim = 0.06;
    if year == 2010
        RBDrc.lastcolumn = 'HF';
        RBDrc.filelength_n = 17523;
    elseif year == 2011
        RBDrc.lastcolumn = 'HS';
        RBDrc.filelength_n = 17523; % updated 10 Nov, 2011
        
    end  
    RBDrc.n_SDs_filter_hi = 4.5; % how many std devs above the mean NEE to allow
    RBDrc.n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    RBDrc.co2_min_by_month = -7;
    RBDrc.co2_max_by_month = 6;
    RBDrc.wind_min = 330;
    RBDrc.wind_max = 30; % these are given a sonic_orient = 180;
    RBDrc.Tdry_min = 240;
    RBDrc.Tdry_max = 320;
    RBDrc.HS_min = -100;
    RBDrc.HS_max = 450;
    RBDrc.HSmass_min = -100;
    RBDrc.HSmass_max = 450;
    RBDrc.LH_min = -150;
    RBDrc.LH_max = 450;
    RBDrc.rH_min = 0;
    RBDrc.rH_max = 1;
    RBDrc.h2o_max = 30;
    RBDrc.h2o_min = 0;
    
end %switch arg.Results.sitecode
