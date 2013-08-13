function [] = UNM_30_min_spooler(sitecode,year)

%This is a little spooling program to run all the 30-min processing chunks
%for a given site and year at the same time.  
%
% All it does is call UNM_30min_flux_processor over and over.  You can add more
% sets of rows to run if you need to.  It runs as a function, just call it with
% the sitecode and the year.

%the sitecodes are
% 1 = grassland
% 2 = shrubland
% 3 = juniper savanna
% 4 = pinyon juniper (original site)
% 5 = ponderosa pine
% 6 = mixed conifer
% 7 = TX freeman
% 8 = TX forest
% 9 = TX grassland
% 10 = PJ_girdle, PJG_test
% 11 = new grassland


if sitecode == 1 % GLand
    if year == 2006
    elseif year == 2007
        UNM_30min_flux_processor(1,2007,8213,8260);
        UNM_30min_flux_processor(1,2007,8549,8596);
        UNM_30min_flux_processor(1,2007,8885,8932);
        UNM_30min_flux_processor(1,2007,9892,9940);
        UNM_30min_flux_processor(1,2007,11135,11154);
        UNM_30min_flux_processor(1,2007,11157,11188);
        UNM_30min_flux_processor(1,2007,11237,11284);
    elseif year == 2008
        UNM_30min_flux_processor(1,2008,330,357);
        UNM_30min_flux_processor(1,2008,624,628);
        UNM_30min_flux_processor(1,2008,1673,1686);
        UNM_30min_flux_processor(1,2008,3536,4428);
        UNM_30min_flux_processor(1,2008,8428,9148);
        UNM_30min_flux_processor(1,2008,13345,13358);
    elseif year == 2009
        UNM_30min_flux_processor_071610(1,2009,1221,2282);
        UNM_30min_flux_processor_071610(1,2009,2443,2439);
        UNM_30min_flux_processor_071610(1,2009,4297,4321);
        UNM_30min_flux_processor_071610(1,2009,6002,6079);
        UNM_30min_flux_processor_071610(1,2009,9627,9779);
        UNM_30min_flux_processor_071610(1,2009,10601,10780);
        UNM_30min_flux_processor_071610(1,2009,14478,15929);  
    elseif year == 2010
        UNM_30min_flux_processor_071610(1,2010,4743,4840);
        UNM_30min_flux_processor_071610(1,2010,5084,5697);
        UNM_30min_flux_processor_071610(1,2010,10676,10907);
        UNM_30min_flux_processor_071610(1,2010,12993,17524);
    elseif year == 2011
%        UNM_30min_flux_processor_071610(1,2011,1899,1999);
        UNM_30min_flux_processor_071610(1,2011,10587,10588);
    elseif year == 2012
        UNM_30min_flux_processor_Tim(1,2012, DOYidx( 196 ), DOYidx( 216 ) );
        UNM_30min_flux_processor_Tim(1,2012, DOYidx( 226 ), DOYidx( 241 ) );
    end
    
elseif sitecode == 2 % SLand
    if year == 2006
    elseif year == 2007
        UNM_30min_flux_processor(2,2008,5,6820);%% – fix this
        UNM_30min_flux_processor(2,2007,7181,7228);
        UNM_30min_flux_processor(2,2007,7517,7564);
        UNM_30min_flux_processor(2,2007, 7853,7900);
        UNM_30min_flux_processor(2,2007,8189,8236);
        UNM_30min_flux_processor(2,2007,8525,8572);
        UNM_30min_flux_processor(2,2007,10903,10924);
        UNM_30min_flux_processor(2,2007,11785,11803);
        UNM_30min_flux_processor(2,2007,16157,16163);

    elseif year == 2008
        UNM_30min_flux_processor(2,2008,3537,5433);
        UNM_30min_flux_processor(2,2008,8444,8473);
        UNM_30min_flux_processor(2,2008,8486,8616);
        UNM_30min_flux_processor(2,2008,8624,8780);
        UNM_30min_flux_processor(2,2008,8783,9153);
   
    elseif year == 2009
        UNM_30min_flux_processor_071610(2,2009,4386,4420);
        UNM_30min_flux_processor_071610(2,2009,6076,7758);
        
    elseif year == 2010
        UNM_30min_flux_processor_071610(2,2010,16805,16814);     
        
    elseif year == 2011
        UNM_30min_flux_processor_071610(2,2011,1901,2002);    
        UNM_30min_flux_processor_071610(2,2011,8669,8759); 
    
    elseif year == 2012
        UNM_30min_flux_processor_071610(2,2012,16704,17568);    
    end

elseif sitecode == 3 % JSav
    if year == 2007
        UNM_30min_flux_processor(3,2007,963,988);
        UNM_30min_flux_processor(3,2007,7244,7261);
        UNM_30min_flux_processor(3,2007,7582,7615);
        UNM_30min_flux_processor(3,2007,11099,11114);
    elseif year == 2008    
        UNM_30min_flux_processor(3,2008,9176,9182);
        UNM_30min_flux_processor(3,2008,9863,9892);
        UNM_30min_flux_processor(3,2008,10207,10228);
        UNM_30min_flux_processor(3,2008,10923,10948);
    elseif year == 2009
        UNM_30min_flux_processor_071610(3,2009,987,3106);
        UNM_30min_flux_processor_071610(3,2009,6746,7962);
        UNM_30min_flux_processor_071610(3,2009,14716,16737);
    elseif year == 2010
        UNM_30min_flux_processor_071610(3,2010,10581,10586);
        UNM_30min_flux_processor_071610(3,2010,10629,10637);
        UNM_30min_flux_processor_071610(3,2010,10640,10642);
        UNM_30min_flux_processor_071610(3,2010,10644,10646);
        UNM_30min_flux_processor_071610(3,2010,10648,10674);
        UNM_30min_flux_processor_071610(3,2010,10676,10689);
        UNM_30min_flux_processor_071610(3,2010,10695,10702);
        UNM_30min_flux_processor_071610(3,2010,10723,10746);
        UNM_30min_flux_processor_071610(3,2010,10819,10825);
        UNM_30min_flux_processor_071610(3,2010,10868,10877);
        UNM_30min_flux_processor_071610(3,2010,10967,10969);
    elseif year == 2011 % added by MF
        UNM_30min_flux_processor_071610(3,2011,1541,1613);

    elseif year == 2012 % added by TWH
        UNM_30min_flux_processor_Tim(3,2012,4211,5119);
        UNM_30min_flux_processor_Tim(3,2012,10540,12691);
        UNM_30min_flux_processor_Tim(3,2012,16512,17567);
    end    
elseif sitecode == 4 % PJ_control
    if year == 2009
        UNM_30min_flux_processor_062909(4,2009,10354,10372);
    elseif year == 2010
        UNM_30min_flux_processor_071610(4,2010,1025,1035);
        UNM_30min_flux_processor_071610(4,2010,1076,1082);
        UNM_30min_flux_processor_071610(4,2010,1313,1323);
        UNM_30min_flux_processor_071610(4,2010,1344,1358);
        UNM_30min_flux_processor_071610(4,2010,1627,1636);
        UNM_30min_flux_processor_071610(4,2010,1886,1897);
        UNM_30min_flux_processor_071610(4,2010,1939,1945);
        UNM_30min_flux_processor_071610(4,2010,1962,1988);
        UNM_30min_flux_processor_071610(4,2010,2170,2184);
        UNM_30min_flux_processor_071610(4,2010,2554,2567);
        UNM_30min_flux_processor_071610(4,2010,2828,2857);
        UNM_30min_flux_processor_071610(4,2010,3496,3510);
        UNM_30min_flux_processor_071610(4,2010,3754,3766);
        UNM_30min_flux_processor_071610(4,2010,3918,3927);
        UNM_30min_flux_processor_071610(4,2010,5094,5110);
        UNM_30min_flux_processor_071610(4,2010,5145,5155);
        UNM_30min_flux_processor_071610(4,2010,6429,6442);
        UNM_30min_flux_processor_071610(4,2010,9132,9139);
    elseif year == 2011
        UNM_30min_flux_processor_071610(4,2011,2819,2907);
        UNM_30min_flux_processor_071610(4,2011,9976,11031);
        
    end
        
elseif sitecode == 5 % PPine
    if year == 2007
        UNM_30min_flux_processor(5,2007,1491,1527);
        UNM_30min_flux_processor(5,2007,3941,3946);
        UNM_30min_flux_processor(5,2007,4000,4011);
        UNM_30min_flux_processor(5,2007,15669,15692);
        UNM_30min_flux_processor(5,2007,16422,16435);
    elseif year == 2008
        UNM_30min_flux_processor(5,2008,774,792);
        UNM_30min_flux_processor(5,2008,1739,1748);
        UNM_30min_flux_processor(5,2008,10992,10999);
        UNM_30min_flux_processor(5,2008,11713,11723);
        UNM_30min_flux_processor(5,2008,13251,13258);
    elseif year == 2009
        UNM_30min_flux_processor_071610(5,2009,7491,7599);
        UNM_30min_flux_processor_071610(5,2009,7971,8060);
        UNM_30min_flux_processor_071610(5,2009,8115,8158);
    elseif year == 2010
        %UNM_30min_flux_processor_071610(5,2010,12437,12471);
        %UNM_30min_flux_processor_071610(5,2010,12476,13420);
        %UNM_30min_flux_processor_071610(5,2010,13433,14147);
        %UNM_30min_flux_processor_071610(5,2010,14148,14331);
        UNM_30min_flux_processor_071610(5,2010,14427,15277);
        UNM_30min_flux_processor_071610(5,2010,15688,16758);
        UNM_30min_flux_processor_071610(5,2010,16858,16873);
        UNM_30min_flux_processor_071610(5,2010,16878,16885);
        UNM_30min_flux_processor_071610(5,2010,16930,17044);
        UNM_30min_flux_processor_071610(5,2010,17063,17524);
    elseif year == 2011
        UNM_30min_flux_processor_071610(5,2011,1236,2246);
    end

elseif sitecode == 6 % MCon
    if year == 2007
        UNM_30min_flux_processor(6,2007,1233,1240);
        UNM_30min_flux_processor(6,2007,2102,2110);
        UNM_30min_flux_processor(6,2007,2126,2145);
        UNM_30min_flux_processor(6,2007,11981,12004);
        UNM_30min_flux_processor(6,2007,13137,14135);
        UNM_30min_flux_processor(6,2007,15747,15752);
        UNM_30min_flux_processor(6,2007,16451,16476);
        UNM_30min_flux_processor(6,2007,16543,16553);
        UNM_30min_flux_processor(6,2007,16597,16614);
        UNM_30min_flux_processor(6,2007,16824,16852);
        UNM_30min_flux_processor(6,2007,17041,17062);
        UNM_30min_flux_processor(6,2007, 17523, 17524);
    elseif year == 2008
        UNM_30min_flux_processor(6,2008,431,455);
        UNM_30min_flux_processor(6,2008,768,774);
        UNM_30min_flux_processor(6,2008,1195,1211);
        UNM_30min_flux_processor(6,2008,1805,1828);
    elseif year == 2009
        UNM_30min_flux_processor_071610(6,2009,1968,1995);
        UNM_30min_flux_processor_071610(6,2009,3435,3493);
        UNM_30min_flux_processor_071610(6,2009,6801,6864);
        UNM_30min_flux_processor_071610(6,2009,15971,15995);
        UNM_30min_flux_processor_071610(6,2009,17137,17165);
        UNM_30min_flux_processor_071610(6,2009,17426,17453);
    elseif year == 2010 % added by Mike Fuller, Feb 23, 2011
        UNM_30min_flux_processor_071610(6,2010,1090,1176);
        UNM_30min_flux_processor_071610(6,2010,1177,2238);
        UNM_30min_flux_processor_071610(6,2010,12420,12717);
        UNM_30min_flux_processor_071610(6,2010,12722,14066);
        UNM_30min_flux_processor_071610(6,2010,14068,14081);
        UNM_30min_flux_processor_071610(6,2010,14087,14130);
        UNM_30min_flux_processor_071610(6,2010,14146,14178);
        UNM_30min_flux_processor_071610(6,2010,14192,14335);
        UNM_30min_flux_processor_071610(6,2010,14435,16498);
        UNM_30min_flux_processor_071610(6,2010,16503,16862);
        UNM_30min_flux_processor_071610(6,2010,16963,17524);
    elseif year == 2011 % added by Mike Fuller
        UNM_30min_flux_processor_071610(6, 2011, 1530,1609);
        UNM_30min_flux_processor_071610(6, 2011, 1781,2236);
        UNM_30min_flux_processor_071610(6, 2011, 10778, 11369);
    end

elseif sitecode == 7 % TX_savanna
    if year == 2005
        UNM_30min_flux_processor_071610(7,2005,338,346);
        UNM_30min_flux_processor_071610(7,2005,4919,5028);
        UNM_30min_flux_processor_071610(7,2005,12533,12580);
        UNM_30min_flux_processor_071610(7,2005,16361,16364);
    elseif year == 2006
        UNM_30min_flux_processor_071610(7,2006,2355,2362);
        UNM_30min_flux_processor_071610(7,2006,2379,2383);
        UNM_30min_flux_processor_071610(7,2006,12965,13033);
        UNM_30min_flux_processor_071610(7,2006,14584,14841);
        UNM_30min_flux_processor_071610(7,2006,15529,15577);
    elseif year == 2007
        UNM_30min_flux_processor_071610(7,2007,4740,4756);
        UNM_30min_flux_processor_071610(7,2007,9220,9268);
        UNM_30min_flux_processor_071610(7,2007,10272,10287);
        UNM_30min_flux_processor_071610(7,2007,10492,10616);
        UNM_30min_flux_processor_071610(7,2007,10825,10852);
        UNM_30min_flux_processor_071610(7,2007,13252,13300);
        UNM_30min_flux_processor_071610(7,2007,16828,16852);
        UNM_30min_flux_processor_071610(7,2007,16870,16996);
    elseif year == 2008
        UNM_30min_flux_processor_071610(7,2008,506,580);
%         UNM_30min_flux_processor_071610(7,2008,2152,2187);
%         UNM_30min_flux_processor_071610(7,2008,4021,6426);
%         UNM_30min_flux_processor_071610(7,2008,7364,8538);
%         UNM_30min_flux_processor_071610(7,2008,9212,9882);
%         UNM_30min_flux_processor_071610(7,2008,10106,10132);
%         UNM_30min_flux_processor_071610(7,2008, 12801, 14572);
    elseif year == 2009
      %  UNM_30min_flux_processor_071610(7,2009,5,6704);
        UNM_30min_flux_processor_071610(7,2009,6705,17282);
    elseif year == 2011
        UNM_30min_flux_processor_071610(7,2011,6131,6148);
    end 
    
elseif sitecode == 8 % TX_forest    
    if year == 2008
        UNM_30min_flux_processor_071610(8,2008,5,17571);
    elseif year == 2009        
        UNM_30min_flux_processor_071610(8,2009,5,17523);
    end
    
elseif sitecode == 9 % TX_grassland
    if year == 2005
        UNM_30min_flux_processor(9,2005,506,532);
        UNM_30min_flux_processor(9,2005,976,1204);
        UNM_30min_flux_processor(9,2005,1553,1953);
        UNM_30min_flux_processor(9,2005,2021,2596);
        UNM_30min_flux_processor(9,2005,2837,2850);
        UNM_30min_flux_processor(9,2005,2858,3245);
        UNM_30min_flux_processor(9,2005,5449,5600);
        UNM_30min_flux_processor(9,2005,6794,6938);
        UNM_30min_flux_processor(9,2005,16363,16398);
    elseif year == 2006
    elseif year == 2007
    elseif year == 2008
        UNM_30min_flux_processor_071610(9,2008,5,17571);
    elseif year == 2009    
        %UNM_30min_flux_processor_071610(9,2009,5,13033);
        UNM_30min_flux_processor_071610(9,2009,13033,16894);
    end
    
elseif sitecode == 10 % PJ_girdle
    if year == 2010
        UNM_30min_flux_processor_071610(10,2010,1309,1322);
        UNM_30min_flux_processor_071610(10,2010,1340,1353);
        UNM_30min_flux_processor_071610(10,2010,1620,1635);
        UNM_30min_flux_processor_071610(10,2010,1958,1983);
        UNM_30min_flux_processor_071610(10,2010,2544,2565);
    elseif year == 2011
      %UNM_30min_flux_processor_071610(10,2011,1537,1607);
      %UNM_30min_flux_processor_071610(10,2011,2814,2906);
      UNM_30min_flux_processor_Tim(10,2011,10660,11026);
    elseif year == 2012
        UNM_30min_flux_processor_Tim(10,2012,DOYidx(220.4), DOYidx( 242.5));
    end   
    
elseif sitecode == 11 % New GLand
    if year == 2010
        % enter values here
    elseif year == 2011
        %             UNM_30min_flux_processor_MFedit(11,2011,1898,2043);
        %             UNM_30min_flux_processor_MFedit(11,2011,3125,3220);
        %             UNM_30min_flux_processor_MFedit(11,2011,8148,8294);
        %             UNM_30min_flux_processor_MFedit(11,2011,8339,8356);
        UNM_30min_flux_processor_Tim(11,2011,6303,8330);
    end 
    
end


disp('All done')
