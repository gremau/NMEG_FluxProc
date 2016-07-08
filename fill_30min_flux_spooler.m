function output = fill_30min_flux_spooler( data_in, sitecode, year )

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

plot_diagnostic = true;

output = data_in;

if sitecode == 1 % GLand
    if year == 2007
        output = fill_30min_flux_processor( output, 1,2007,9540,9763);
        output = fill_30min_flux_processor( output, 1,2007,10435,10457);
        output = fill_30min_flux_processor( output, 1,2007,10489,10503);
        output = fill_30min_flux_processor( output, 1,2007,10536,10552);
        output = fill_30min_flux_processor( output, 1,2007,10583,10605);
        output = fill_30min_flux_processor( output, 1,2007,10625,10650);
        output = fill_30min_flux_processor( output, 1,2007,10675,10697);
        output = fill_30min_flux_processor( output, 1,2007,10720,10756);
        output = fill_30min_flux_processor( output, 1,2007,10768,10809);
        output = fill_30min_flux_processor( output, 1,2007,10815,10857);
        output = fill_30min_flux_processor( output, 1,2007,10864,10903);
        output = fill_30min_flux_processor( output, 1,2007,10910,11259); 
    elseif year == 2008
        output = fill_30min_flux_processor( output, 1,2008,1669,1682);
        output = fill_30min_flux_processor( output, 1,2008,3532,4426);
        output = fill_30min_flux_processor( output, 1,2008,8446,8471);
        output = fill_30min_flux_processor( output, 1,2008,8486,8518);
        output = fill_30min_flux_processor( output, 1,2008,8530,8571);
        output = fill_30min_flux_processor( output, 1,2008,8579,8612);
        output = fill_30min_flux_processor( output, 1,2008,8626,9147);
        output = fill_30min_flux_processor( output, 1,2008,13343,13365);
        output = fill_30min_flux_processor( output, 1,2008,13832,13842);
    elseif year == 2009
        % IRGA clearly down in second part of this period
        output = fill_30min_flux_processor( output, 1, 2009, 1217, 2282 );
        output = fill_30min_flux_processor( output, 1,2009,9644,9778 );
        output = fill_30min_flux_processor( output, 1,2009,10600,10778 );
        output = fill_30min_flux_processor( output, 1,2009,14478,15929);%, ...
            %'write_file', true);  
    elseif year == 2010
        output = fill_30min_flux_processor( output, 1,2010,4740,4837);
        output = fill_30min_flux_processor( output, 1,2010,5081,5694);
        output = fill_30min_flux_processor( output, 1,2010,10673,10904);
        output = fill_30min_flux_processor( output, 1,2010,12990,13271);
        output = fill_30min_flux_processor( output, 1,2010,14089,15671);
    elseif year == 2011
        % output = fill_30min_flux_processor( output, 1,2011,1899,1999);
        output = fill_30min_flux_processor( output, 1,2011,9055,9957);
        % output = fill_30min_flux_processor( output, 1,2011,10587,10588);
    elseif year == 2012
        %output = fill_30min_flux_processor( output, 1,2012, DOYidx( 196 ), DOYidx( 216 ) );
        %output = fill_30min_flux_processor( output, 1,2012, DOYidx( 226 ), DOYidx( 241 ) );
    elseif year == 2015
        output = fill_30min_flux_processor( output, 1,2015, 5461, 6112 );
    end
    
elseif sitecode == 2 % SLand
    if year == 2007
        output = fill_30min_flux_processor( output,2,2007,12141,12159);
        output = fill_30min_flux_processor( output,2,2007,12224,12262);
        output = fill_30min_flux_processor( output,2,2007,12632,12643);
        output = fill_30min_flux_processor( output,2,2007,16483,16500);
        output = fill_30min_flux_processor( output,2,2007,16507,16519);

    elseif year == 2008
        output = fill_30min_flux_processor( output,2,2008,3533,5429);
        output = fill_30min_flux_processor( output,2,2008,8440,8469);
        output = fill_30min_flux_processor( output,2,2008,8482,8612);
        output = fill_30min_flux_processor( output,2,2008,8620,8776);
        output = fill_30min_flux_processor( output,2,2008,8779,9149);
        output = fill_30min_flux_processor( output,2,2008,13830,13841);
   
    elseif year == 2009
        output = fill_30min_flux_processor( output, 2,2009,7006,7317);
        
    elseif year == 2010
        output = fill_30min_flux_processor( output, 2,2010,16805,16814);     
    
    elseif year == 2012 % Leap year
        output = fill_30min_flux_processor( output, 2,2012,16680,16766);
        output = fill_30min_flux_processor( output, 2,2012,16832,16862);
        output = fill_30min_flux_processor( output, 2,2012,17238,17249);
        output = fill_30min_flux_processor( output, 2,2012,17324,17344);
    elseif year == 2013
        % For some reason 1 day/month of 10hz data is missing at this site
        output = fill_30min_flux_processor( output, 2, 2013, DOYidx(1), DOYidx(2.36));
        output = fill_30min_flux_processor( output, 2, 2013, DOYidx(10.68), DOYidx(11.07));
        output = fill_30min_flux_processor( output, 2, 2013, DOYidx(14.81), DOYidx(15.28));
        output = fill_30min_flux_processor( output, 2, 2013, DOYidx(240.48), DOYidx(241.46));
    end

elseif sitecode == 3 % JSav
    if year == 2007
        output = fill_30min_flux_processor( output, 3,2007,16489,16504);
        output = fill_30min_flux_processor( output, 3,2007,17025,17040);
    elseif year == 2008    
        output = fill_30min_flux_processor( output, 3,2008,9152,9159);
        output = fill_30min_flux_processor( output, 3,2008,9170,9178);
        output = fill_30min_flux_processor( output, 3,2008,13358,13370);
        output = fill_30min_flux_processor( output, 3,2008,13792,13803);
        output = fill_30min_flux_processor( output, 3,2008,15870,17163);
    elseif year == 2009
        % Irga data is garbage during this time
        output = fill_30min_flux_processor( output, 3,2009,987,3106);
        % IRGA ok
        output = fill_30min_flux_processor( output, 3,2009,6742,7958);
        %output = fill_30min_flux_processor( output, 3,2009,14716,16737);
    elseif year == 2010
%         output = fill_30min_flux_processor( output, 3,2010,10581,10586);
%         output = fill_30min_flux_processor( output, 3,2010,10629,10637);
%         output = fill_30min_flux_processor( output, 3,2010,10640,10642);
%         output = fill_30min_flux_processor( output, 3,2010,10644,10646);
%         output = fill_30min_flux_processor( output, 3,2010,10648,10674);
%         output = fill_30min_flux_processor( output, 3,2010,10676,10689);
%         output = fill_30min_flux_processor( output, 3,2010,10695,10702);
%         output = fill_30min_flux_processor( output, 3,2010,10723,10746);
%         output = fill_30min_flux_processor( output, 3,2010,10819,10825);
%         output = fill_30min_flux_processor( output, 3,2010,10868,10877);
        output = fill_30min_flux_processor( output, 3,2010,10064,10258);
    elseif year == 2011 % added by MF
        output = fill_30min_flux_processor( output, 3,2011,1541,1613);

    elseif year == 2012 % added by TWH
        output = fill_30min_flux_processor( output, 3,2012,5090,5120);
        output = fill_30min_flux_processor( output, 3,2012,11570,11602);
        % No data at end of year...
        output = fill_30min_flux_processor( output, 3,2012,16503,16527);
    elseif year == 2013
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(80), DOYidx(80.292));
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(80.042), DOYidx(95.458));
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(96.028), DOYidx(107.375));
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(111.313), DOYidx(111.979));
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(201.688), DOYidx(205.688));
        output = fill_30min_flux_processor( output, 3, 2013, DOYidx(326.104), DOYidx(329.354));
    end
    
elseif sitecode == 4 % PJ_control
    if year == 2008
        output = fill_30min_flux_processor( output, 4,2008,13789,13808);
        output = fill_30min_flux_processor( output, 4,2008,16472,16489);
    elseif year == 2009
        %output = fill_30min_flux_processor( output, 4,2009,10354,10372);
    elseif year == 2010
        % Many of these small filled periods seem fairly noisy. Could be
        % good to just let a gapfiller do it.
        output = fill_30min_flux_processor( output, 4,2010,1022,1032);
        output = fill_30min_flux_processor( output, 4,2010,1073,1079);
        output = fill_30min_flux_processor( output, 4,2010,1310,1320);
        output = fill_30min_flux_processor( output, 4,2010,1341,1355);
        output = fill_30min_flux_processor( output, 4,2010,1624,1633);
        output = fill_30min_flux_processor( output, 4,2010,1883,1894);
        output = fill_30min_flux_processor( output, 4,2010,1936,1942);
        output = fill_30min_flux_processor( output, 4,2010,1959,1985);
        output = fill_30min_flux_processor( output, 4,2010,2167,2181);
        output = fill_30min_flux_processor( output, 4,2010,2551,2564);
        output = fill_30min_flux_processor( output, 4,2010,2825,2854);
        output = fill_30min_flux_processor( output, 4,2010,3493,3507);
        output = fill_30min_flux_processor( output, 4,2010,3751,3763);
        output = fill_30min_flux_processor( output, 4,2010,3915,3924);
        output = fill_30min_flux_processor( output, 4,2010,5091,5109);
        output = fill_30min_flux_processor( output, 4,2010,5142,5152);
        output = fill_30min_flux_processor( output, 4,2010,6426,6439);
        output = fill_30min_flux_processor( output, 4,2010,9129,9136);
    elseif year == 2011
        output = fill_30min_flux_processor( output, 4,2011,13300,13315);
        output = fill_30min_flux_processor( output, 4,2011,13425,13446);
        output = fill_30min_flux_processor( output, 4,2011,14346,14361);
        output = fill_30min_flux_processor( output, 4,2011,16075,16083);
        output = fill_30min_flux_processor( output, 4,2011,16229,16237);
        output = fill_30min_flux_processor( output, 4,2011,16761,16777);
        output = fill_30min_flux_processor( output, 4,2011,16835,16868);
        output = fill_30min_flux_processor( output, 4,2011,16883,17062);
        output = fill_30min_flux_processor( output, 4,2011,17077,17155);
        output = fill_30min_flux_processor( output, 4,2011,17448,17520);
    elseif year == 2012
        output = fill_30min_flux_processor( output, 4,2012,1,27);
        output = fill_30min_flux_processor( output, 4,2012,313,336);
        output = fill_30min_flux_processor( output, 4,2012,12289,12357);
        output = fill_30min_flux_processor( output, 4,2012,16176,16296);
        output = fill_30min_flux_processor( output, 4,2012,16516,16546);  
    elseif year == 2013
        output = fill_30min_flux_processor( output, 4,2012,16600,16630);
    end
        
elseif sitecode == 5 % PPine
    if year == 2007
        output = fill_30min_flux_processor( output, 5,2007,1019,1044);
        output = fill_30min_flux_processor( output, 5,2007,1440,1523);
        output = fill_30min_flux_processor( output, 5,2007,1998,2008);
        output = fill_30min_flux_processor( output, 5,2007,2129,2175);
        output = fill_30min_flux_processor( output, 5,2007,2404,2431);
        output = fill_30min_flux_processor( output, 5,2007,3836,3857);
        output = fill_30min_flux_processor( output, 5,2007,3956,4007);
        output = fill_30min_flux_processor( output, 5,2007,4671,4692);
        output = fill_30min_flux_processor( output, 5,2007,4858,4874);
        output = fill_30min_flux_processor( output, 5,2007,4905,4927);
        output = fill_30min_flux_processor( output, 5,2007,5817,5838);
        output = fill_30min_flux_processor( output, 5,2007,6144,6167);
        output = fill_30min_flux_processor( output, 5,2007,11700,11722);
        output = fill_30min_flux_processor( output, 5,2007,12749,12773);
        output = fill_30min_flux_processor( output, 5,2007,15647,15688);
        output = fill_30min_flux_processor( output, 5,2007,16031,16044);
        output = fill_30min_flux_processor( output, 5,2007,16373,16431);
%         output = fill_30min_flux_processor( output, 5,2007,1491,1527);
%         output = fill_30min_flux_processor( output, 5,2007,3941,3946);
%         output = fill_30min_flux_processor( output, 5,2007,4000,4011);
%         output = fill_30min_flux_processor( output, 5,2007,15669,15692);
%         output = fill_30min_flux_processor( output, 5,2007,16422,16435);
    elseif year == 2008
        output = fill_30min_flux_processor( output, 5,2008,323,338);
        output = fill_30min_flux_processor( output, 5,2008,770,788);
        output = fill_30min_flux_processor( output, 5,2008,1651,1661);
        output = fill_30min_flux_processor( output, 5,2008,1735,1744);
        output = fill_30min_flux_processor( output, 5,2008,2539,2569);
        output = fill_30min_flux_processor( output, 5,2008,4787,4793);
        output = fill_30min_flux_processor( output, 5,2008,11699,11719);
        output = fill_30min_flux_processor( output, 5,2008,13080,13100);
        output = fill_30min_flux_processor( output, 5,2008,13332,13367);
        output = fill_30min_flux_processor( output, 5,2008,13729,13766);
        output = fill_30min_flux_processor( output, 5,2008,13796,13822);
        output = fill_30min_flux_processor( output, 5,2008,14188,14738);
        output = fill_30min_flux_processor( output, 5,2008,14812,14875);
        output = fill_30min_flux_processor( output, 5,2008,16801,16877);
%         output = fill_30min_flux_processor( output, 5,2008,774,792);
%         output = fill_30min_flux_processor( output, 5,2008,1739,1748);
%         output = fill_30min_flux_processor( output, 5,2008,10992,10999);
%         output = fill_30min_flux_processor( output, 5,2008,11713,11723);
%         output = fill_30min_flux_processor( output, 5,2008,13251,13258);
    elseif year == 2009
        output = fill_30min_flux_processor( output, 5,2009,7218,7287);
        output = fill_30min_flux_processor( output, 5,2009,7314,7336);
        output = fill_30min_flux_processor( output, 5,2009,7412,7449);
        output = fill_30min_flux_processor( output, 5,2009,7453,7598);
        output = fill_30min_flux_processor( output, 5,2009,7621,7637);
        output = fill_30min_flux_processor( output, 5,2009,7951,8059);
        output = fill_30min_flux_processor( output, 5,2009,8082,8157);
        output = fill_30min_flux_processor( output, 5,2009,14048,14065);
    elseif year == 2010
        % Commenting because data found
%         output = fill_30min_flux_processor( output, 5,2010,12437,12471);
%         output = fill_30min_flux_processor( output, 5,2010,12476,13420);
%         output = fill_30min_flux_processor( output, 5,2010,13433,14147);
%         output = fill_30min_flux_processor( output, 5,2010,14148,14331);
%         output = fill_30min_flux_processor( output, 5,2010,14427,15277);
%         output = fill_30min_flux_processor( output, 5,2010,15688,16758);
        output = fill_30min_flux_processor( output, 5,2010,16779,16790);
        output = fill_30min_flux_processor( output, 5,2010,16871,16901);
        output = fill_30min_flux_processor( output, 5,2010,16904,16928);
        output = fill_30min_flux_processor( output, 5,2010,17031,17064);
        output = fill_30min_flux_processor( output, 5,2010,17401,17467);
    elseif year == 2011
        output = fill_30min_flux_processor( output, 5,2011,1233,2243);
    elseif year == 2012
        output = fill_30min_flux_processor( output, 5,2012,9724,11164);
    elseif year == 2013
        output = fill_30min_flux_processor( output, 5,2013,1,24);
        output = fill_30min_flux_processor( output, 5,2013,1332,1376);
        output = fill_30min_flux_processor( output, 5,2013,1962,1993);
        output = fill_30min_flux_processor( output, 5,2013,12234,12266);
        output = fill_30min_flux_processor( output, 5,2013,15287, 15477);
        output = fill_30min_flux_processor( output, 5,2013,15553, 15558);
        output = fill_30min_flux_processor( output, 5,2013,15598, 15611);
        output = fill_30min_flux_processor( output, 5,2013,15823, 15861);
    end

elseif sitecode == 6 % MCon
    if year == 2007
        output = fill_30min_flux_processor( output, 6,2007,7,48);
        output = fill_30min_flux_processor( output, 6,2007,2104,2162);
        output = fill_30min_flux_processor( output, 6,2007,13132,14131);
        output = fill_30min_flux_processor( output, 6,2007,15743,15755);
        output = fill_30min_flux_processor( output, 6,2007,16447,16472);
        output = fill_30min_flux_processor( output, 6,2007,15747,15752);
        output = fill_30min_flux_processor( output, 6,2007,17036,17058);
        %output = fill_30min_flux_processor( output, 6,2007, 17523, 17524);
%         output = fill_30min_flux_processor( output, 6,2007,1233,1240);
%         output = fill_30min_flux_processor( output, 6,2007,2102,2110);
%         output = fill_30min_flux_processor( output, 6,2007,2126,2145);
%         output = fill_30min_flux_processor( output, 6,2007,11981,12004);
%         output = fill_30min_flux_processor( output, 6,2007,13137,14135);
%         output = fill_30min_flux_processor( output, 6,2007,15747,15752);
%         output = fill_30min_flux_processor( output, 6,2007,16451,16476);
%         output = fill_30min_flux_processor( output, 6,2007,16543,16553);
%         output = fill_30min_flux_processor( output, 6,2007,16597,16614);
%         output = fill_30min_flux_processor( output, 6,2007,16824,16852);
%         output = fill_30min_flux_processor( output, 6,2007,17041,17062);
%         output = fill_30min_flux_processor( output, 6,2007, 17523, 17524);
    elseif year == 2008
        output = fill_30min_flux_processor( output, 6,2008,427,451);
        output = fill_30min_flux_processor( output, 6,2008,1191,1207);
        output = fill_30min_flux_processor( output, 6,2008,1671,1681);
        output = fill_30min_flux_processor( output, 6,2008,11699,11718);
        output = fill_30min_flux_processor( output, 6,2008,13810,13816);
        output = fill_30min_flux_processor( output, 6,2008,15594,15610);
        output = fill_30min_flux_processor( output, 6,2008,16298,16320);
%         output = fill_30min_flux_processor( output, 6,2008,431,455);
%         output = fill_30min_flux_processor( output, 6,2008,768,774);
%         output = fill_30min_flux_processor( output, 6,2008,1195,1211);
%         output = fill_30min_flux_processor( output, 6,2008,1805,1828);
    elseif year == 2009
        output = fill_30min_flux_processor( output, 6,2009,3420,3489);
        output = fill_30min_flux_processor( output, 6,2009,15963,15984);
        output = fill_30min_flux_processor( output, 6,2009,17133,17162);
        output = fill_30min_flux_processor( output, 6,2009,17422,17450);
    elseif year == 2010 % added by Mike Fuller, Feb 23, 2011
        output = fill_30min_flux_processor( output, 6,2010,1087,1184);
        output = fill_30min_flux_processor( output, 6,2010,14154,14175);
        output = fill_30min_flux_processor( output, 6,2010,16748,16776);
        output = fill_30min_flux_processor( output, 6,2010,16880,16917);
        output = fill_30min_flux_processor( output, 6,2010,17473,17499);
        output = fill_30min_flux_processor( output, 6,2010,17509,17520);
    elseif year == 2011 % added by Mike Fuller
        output = fill_30min_flux_processor( output, 6, 2011, 1,25);
        output = fill_30min_flux_processor( output, 6, 2011, 1527,1606);
        % Filled data look pretty bad here
        output = fill_30min_flux_processor( output, 6, 2011, 10775, 11366);
    elseif year == 2012
        output = fill_30min_flux_processor( output, 6, 2012,768,790);
        output = fill_30min_flux_processor( output, 6, 2012,1674,1720);
        output = fill_30min_flux_processor( output, 6, 2012,3308,3379);
        output = fill_30min_flux_processor( output, 6, 2012, 5036,5063);
        output = fill_30min_flux_processor( output, 6, 2012, 16630,16656);
        output = fill_30min_flux_processor( output, 6, 2012, 16747,16772);
        output = fill_30min_flux_processor( output, 6, 2012, 17229,17259);
        output = fill_30min_flux_processor( output, 6, 2012, 17557,17568);
    elseif year == 2013 % added by Mike Fuller
        output = fill_30min_flux_processor( output, 6, 2013, DOYidx(1),DOYidx(1.52));
        output = fill_30min_flux_processor( output, 6, 2013, DOYidx(29.75),DOYidx(30.33));
        output = fill_30min_flux_processor( output, 6, 2013, DOYidx(52.917),DOYidx(53.458));
        output = fill_30min_flux_processor( output, 6, 2013, DOYidx(324.9),DOYidx(325.375));
    elseif year == 2014
        output = fill_30min_flux_processor( output, 6, 2013, 1832,2341);
    elseif year == 2015
        output = fill_30min_flux_processor( output, 6, 2015, 15739,15749);
        output = fill_30min_flux_processor( output, 6, 2015, 15757,15982);
        output = fill_30min_flux_processor( output, 6, 2015, 15993,16031);
        output = fill_30min_flux_processor( output, 6, 2015, 16045,16081);
        output = fill_30min_flux_processor( output, 6, 2015, 16088,16660);
        output = fill_30min_flux_processor( output, 6, 2015, 16700,16722);
        output = fill_30min_flux_processor( output, 6, 2015, 16787,16818);
        output = fill_30min_flux_processor( output, 6, 2015, 17069,17108);
        output = fill_30min_flux_processor( output, 6, 2015, 17113,17146);
        output = fill_30min_flux_processor( output, 6, 2015, 17213,17231);
        output = fill_30min_flux_processor( output, 6, 2015, 17415,17448);
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
    if year==2009
        output = fill_30min_flux_processor( output, 10,2009,7593,7663);
        % These don't look good
        output = fill_30min_flux_processor( output, 10,2009,10780,10825);
        output = fill_30min_flux_processor( output, 10,2009,10831,10961);
        output = fill_30min_flux_processor( output, 10,2009,10983,11112);
    elseif year == 2010
        output = fill_30min_flux_processor( output, 10,2010,1307,1318);
        output = fill_30min_flux_processor( output, 10,2010,1338,1349);
        output = fill_30min_flux_processor( output, 10,2010,1618,1631);
        output = fill_30min_flux_processor( output, 10,2010,1956,1979);
        output = fill_30min_flux_processor( output, 10,2010,2542,2561);
    elseif year == 2011
      output = fill_30min_flux_processor( output, 10,2011,1533,1604);
      output = fill_30min_flux_processor( output, 10,2011,14346,14373);
      output = fill_30min_flux_processor( output, 10,2011,16759,16776);
      output = fill_30min_flux_processor( output, 10,2011,17089,17114);
    elseif year == 2012
        output = fill_30min_flux_processor( output, 10,2012,DOYidx(220.4), DOYidx( 221));
        output = fill_30min_flux_processor( output, 10,2012,11640,11714);
        output = fill_30min_flux_processor( output, 10,2012,11914,11947);
        %output = fill_30min_flux_processor( output, 10,2012,12286,12322);
        output = fill_30min_flux_processor( output, 10,2012,12454,12519);
        output = fill_30min_flux_processor( output, 10,2012,12599,12762);
        output = fill_30min_flux_processor( output, 10,2012,12787,12853);
        output = fill_30min_flux_processor( output, 10,2012,13262,13303);
        output = fill_30min_flux_processor( output, 10,2012,13717,13769);
        output = fill_30min_flux_processor( output, 10,2012,13796,14123);
        output = fill_30min_flux_processor( output, 10,2012,14178,14485);
        output = fill_30min_flux_processor( output, 10,2012,16274,16306);
    elseif year == 2013
        output = fill_30min_flux_processor( output, 10,2013,5459,5686);
        output = fill_30min_flux_processor( output, 10,2013,10829,10841);
    elseif year == 2015
        output = fill_30min_flux_processor( output, 10,2015,16739,17202);
    end   
    
elseif sitecode == 11 % New GLand
    if year == 2010
        % enter values here
    elseif year == 2011
        %             UNM_30min_flux_processor_MFedit(11,2011,1898,2043);
        %             UNM_30min_flux_processor_MFedit(11,2011,3125,3220);
        %             UNM_30min_flux_processor_MFedit(11,2011,8148,8294);
        %             UNM_30min_flux_processor_MFedit(11,2011,8339,8356);
        %output = fill_30min_flux_processor( output, 11,2011,6303,8330);
    elseif year == 2012
        fill_30min_flux_processor( output, 11,2012,10482,10538);
    end 
    
end

if plot_diagnostic
    
    figure( 'Name', 'Fill 30min flux output', ...
        'Position', [100, 100, 1200, 800] );
    
    ch_idx = data_in.Fc_raw_massman_ourwpl ~= output.Fc_raw_massman_ourwpl;
    
    ax( 1 ) = subplot( 4, 1, 1 );
    plot( data_in.timestamp, data_in.CO2_mean, 'ok' );
    hold on;
    plot( output.timestamp, output.CO2_mean, '.b' );
    plot( output.timestamp( ch_idx ), output.CO2_mean( ch_idx ), '.r' );
    datetick( 'x', 'mmm-yy', 'keeplimits', 'keepticks' );
    ylabel( 'CO2\_mean' );
    ylim( [-60000, 50000]);
    
    ax( 2 ) = subplot( 4, 1, 2 );
    plot( data_in.timestamp, data_in.Fc_raw_massman_ourwpl, 'ok' );
    hold on;
    plot( output.timestamp, output.Fc_raw_massman_ourwpl, '.b' );
    plot( output.timestamp( ch_idx ), output.Fc_raw_massman_ourwpl( ch_idx ), '.r' );
    datetick( 'x', 'mmm-yy', 'keeplimits', 'keepticks' );
    ylabel( 'Fc\_raw\_massman\_ourwpl' );
    ylim( [-100, 100]);
    
    ax( 3 ) = subplot( 4, 1, 3 );
    plot( data_in.timestamp, data_in.LatentHeat_wpl_massman, 'ok' );
    hold on;
    plot( output.timestamp, output.LatentHeat_wpl_massman, '.b' );
    plot( output.timestamp( ch_idx ), output.LatentHeat_wpl_massman( ch_idx ), '.r' );
    datetick( 'x', 'mmm-yy', 'keeplimits', 'keepticks' );
    ylabel( 'LatentHeat\_wpl\_massman' );
    
    ax( 4 ) = subplot( 4, 1, 4 );
    plot( data_in.timestamp, data_in.HSdry_massman, 'ok' );
    hold on;
    plot( output.timestamp, output.HSdry_massman, '.b' );
    plot( output.timestamp( ch_idx ), output.HSdry_massman( ch_idx ), '.r' );
    linkaxes( ax, 'x' );
    datetick( 'x', 'mmm-yy', 'keeplimits', 'keepticks' );
    ylabel( 'HSdry\_massman' );
    
end

disp('All done')
