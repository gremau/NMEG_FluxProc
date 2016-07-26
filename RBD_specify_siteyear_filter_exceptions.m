function [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
    RBD_specify_siteyear_filter_exceptions( sitecode, year, ...
    DOY_co2_min, DOY_co2_max )

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
                % Things were somewhat noisy this year, especially before
                % the site revamp in June
                idx = 1 : DOYidx( 35 );
                DOY_co2_max( idx ) = 1.8;
                DOY_co2_min( idx ) = -0.8;
                idx2 = ( DOYidx( 262 ) : size( DOY_co2_max, 1) );
                %DOY_co2_max( idx2 ) = 1.9;
                %DOY_co2_min( idx2 ) = -0.8;
            case 2008
                % There is a big respiration spike here. Not sure of the
                % explanation, but it is also visible at Shrub
                idx = DOYidx( 184 ) : DOYidx( 186.5 );
                DOY_co2_max( idx ) = 15;
                std_exc_flag( idx ) = true;
            case 2009
                % Too restrictive - GEM
                idx = DOYidx( 245 ) : DOYidx( 255 );
                %DOY_co2_max( idx ) = 2.25;
                % Too restrictive - GEM
                % DOY_co2_max( DOYidx( 178 ) : DOYidx( 267 ) ) = 0.8;
                
                % the site burned DOY 210, 2009.  Here we remove points in the period
                % following the burn that look more like noise than biologically
                % realistic carbon uptake.
                %DOY_co2_min( DOYidx( 210 ) : DOYidx( 256 ) ) = -0.5;
                %DOY_co2_min( DOYidx( 256 ) : DOYidx( 270 ) ) = -1.2;
            case 2010
                %DOY_co2_max( DOYidx( 200 ) : DOYidx( 225 ) ) = 3.25;
                %DOY_co2_max( 1 : DOYidx( 160 ) ) = 2.0;
                % Too restrictive (changed from 2.5-3.75)?  - GEM
               DOY_co2_min( 100 : DOYidx( 160 ) ) = -3.75;
                % Don't understand why next 3 lines are needed - GEM
%                 idx = DOYidx( 223 ) : DOYidx( 229 );
%                 DOY_co2_min( idx ) = -17;
%                 std_exc_flag( idx ) = true;
            case 2011
                % Not clear why these are here - GEM
%                 std_exc_flag( DOYidx( 158.4 ) : DOYidx( 158.6 ) ) = true;
%                 std_exc_flag( DOYidx( 159.4 ) : DOYidx( 159.6 ) ) = true;
%                 std_exc_flag( DOYidx( 245.4 ) : DOYidx( 245.6 ) ) = true;
                %    std_exc_flag( DOYidx( 337 ) : DOYidx( 343.7 ) ) = true;
                % Too restrictive ( -0.5 to -1 )- GEM            
               % DOY_co2_min( DOYidx( 309 ) : end ) = -1.0;
               % DOY_co2_min( 1 : DOYidx( 210 ) ) = -1.0;               
                DOY_co2_max( DOYidx( 270 ) : DOYidx( 280 ) ) = 2.5;                          
                % Too restrictive - GEM
                %DOY_co2_max( DOYidx( 250 ) : DOYidx( 260 ) ) = 0.8;
                DOY_co2_max( DOYidx( 280 ) : DOYidx( 285 ) ) = 1.2;
            case 2012
                % Most of these are a bit too restrictive - GEM
               % DOY_co2_max( DOYidx( 112 ) : DOYidx( 137 ) ) = 1.25;
               % DOY_co2_max( DOYidx( 300 ) : DOYidx( 317 ) ) = 2;
%                 DOY_co2_max( DOYidx( 325 ) : DOYidx( 343 ) ) = 1.4;
%                 DOY_co2_max( DOYidx( 343 ) : DOYidx( 347 ) ) = 1.2;
%                 DOY_co2_max( DOYidx( 348 ) : end ) = 0.75;
                %std_exc_flag( DOYidx( 174 ) : DOYidx( 175 ) ) = true;
            case 2013
                % There is a small period where variance in fluxes is
                % especially high - not sure it is real
              %  DOY_co2_max( DOYidx( 160 ) : DOYidx( 169 ) ) = 3;
                DOY_co2_min( DOYidx( 160 ) : DOYidx( 169 ) ) = -1.75;
            case 2014
                % There is a small period where variance in fluxes is
                % especially high - not sure it is real
              %  DOY_co2_max( DOYidx( 190 ) : DOYidx( 199 ) ) = 4;
              %  DOY_co2_min( DOYidx( 190 ) : DOYidx( 199 ) ) = -2;
        end %GLand
        
    case UNM_sites.SLand
        switch year
            case 2007
                % Things were somewhat noisy this year, especially before
                % the site revamp in late May
                idx = 1 : DOYidx( 110 );
                DOY_co2_max( idx ) = 1.25;
                idx = DOYidx( 110 ) : DOYidx( 185 );
                DOY_co2_max( idx ) = 2;
                idx = 1 : DOYidx( 86 );
                DOY_co2_min( idx ) = -0.95;
            case 2008
                % There is a big respiration spike here. Not sure of the
                % explanation, but it is also visible at GLand
                idx = DOYidx( 184 ) : DOYidx( 190 );
                DOY_co2_max( idx ) = 20;
                std_exc_flag( idx ) = true;
            case 2010
                DOY_co2_min( 1 : DOYidx( 80 ) ) = -1.4;
                DOY_co2_max( DOYidx( 204 ) : DOYidx( 220 ) ) = 3.0;
            case 2011
                % Not sure why these resp pulses are protected - GEM
                idx = DOYidx( 215.5 ) : DOYidx( 216.4 );
                std_exc_flag( idx ) = true;

                idx = DOYidx( 190 ) : DOYidx( 195 );
                DOY_co2_max( idx ) = 7;
                std_exc_flag( idx ) = true;
%                 % Too restrictive, sd filter works fine - GEM
%                 DOY_co2_min(  1 : DOYidx( 70.0 ) ) = -0.5;
%                 DOY_co2_max(  1 : DOYidx( 70.0 ) ) = 1.0;
%                 DOY_co2_min( DOYidx( 80  ) : DOYidx( 100 ) ) = -2.0;
%                 
%                 std_exc_flag( DOYidx( 20.4) : DOYidx( 20.6 ) ) = true;
                
                DOY_co2_min(  DOYidx( 185 ) : end ) = -2.0;
            case 2012
                DOY_co2_max(  DOYidx( 310 ) : DOYidx( 320 ) ) = 1.5;
%                 DOY_co2_max(  DOYidx( 323.2 ) : DOYidx( 323.8 ) ) = 2.5;
                std_exc_flag( DOYidx( 323.2 ) : DOYidx( 323.8 ) ) = true;
%                 DOY_co2_max(  DOYidx( 328 ) : end ) = 0.5;
            case 2013
%                 DOY_co2_max(  DOYidx( 21 ) : DOYidx( 27 ) ) = 0.5;
%                 DOY_co2_max(  DOYidx( 28 ) : DOYidx( 30 ) ) = 2.0;
                DOY_co2_max(  DOYidx( 208 ) : DOYidx( 270 ) ) = 3.5;
%                 DOY_co2_max(  DOYidx( 216 ) : DOYidx( 225 ) ) = 2.7;
                DOY_co2_min(  DOYidx( 133 ) : DOYidx( 134 ) ) = -1.0;
%                 DOY_co2_min(  DOYidx( 155 ) : DOYidx( 170 ) ) = -1.0;
%                 DOY_co2_min(  DOYidx( 208 ) : DOYidx( 216 ) ) = -5.0;
%                 DOY_co2_min(  DOYidx( 224 ) : DOYidx( 225 ) ) = -5.0;
            case 2014
                DOY_co2_max(  DOYidx( 215 ) : DOYidx( 280 ) ) = 2.5;
                DOY_co2_min(  DOYidx( 267 ) : DOYidx( 268 ) ) = -4.0;
                DOY_co2_min(  DOYidx( 280 ) : DOYidx( 345 ) ) = -3.0;

        end %SLand
        
    case UNM_sites.JSav
        switch year
            case 2008
                % Too restrictive - GEM
%                 idx = DOYidx( 215 ) : DOYidx( 240 );
%                 DOY_co2_min( idx ) = -12.0;
                
            case 2009
                %DOY_co2_max( 1 : DOYidx( 125 ) ) = 2.25;
                %DOY_co2_max( DOYidx( 150 ) : DOYidx( 280 ) ) = 4.0;
                % Too restrictive - GEM
                %DOY_co2_max( DOYidx( 150 ) : DOYidx( 180 ) ) = 2.0;
                %DOY_co2_max( DOYidx( 220 ) : DOYidx( 250 ) ) = 2.5;
                %DOY_co2_max( DOYidx( 281 ) : DOYidx( 365 ) ) = 2.5;
                %DOY_co2_min( 1 : DOYidx( 94 ) ) = -6.0;
                
            case 2010
%                 DOY_co2_max( 1 : DOYidx( 80 ) ) = 2.0;
%                 DOY_co2_max( DOYidx( 81 ) : DOYidx( 190 ) ) = 4.0;
%                 DOY_co2_max( DOYidx( 190 ) : DOYidx( 210 ) ) = 6.0;
                %DOY_co2_max( DOYidx( 190 ) : DOYidx( 210 ) ) = 5.5;
                %DOY_co2_max( DOYidx( 265 ) : DOYidx( 295 ) ) = 4.0;
%                 DOY_co2_max( DOYidx( 226 ) : end ) = 3.0;
                
            case 2011
                %DOY_co2_max( DOYidx( 221 ) : DOYidx( 265 ) ) = 4.5;
                %DOY_co2_max( DOYidx( 266 ) : end ) = 3.5;
                % Exceptions - some removed by GEM
                %std_exc_flag( DOYidx( 17.4 ) : DOYidx( 17.6 ) ) = true;
                %std_exc_flag( DOYidx( 58.4 ) : DOYidx( 58.6 ) ) = true;
                %std_exc_flag( DOYidx( 64.3 ) : DOYidx( 64.5 ) ) = true;
                %std_exc_flag( DOYidx( 73.4 ) : DOYidx( 73.5 ) ) = true;

                
            case 2012
                % Some of these are too restrictive - GEM
%                 DOY_co2_max( DOYidx( 137 ) : DOYidx( 148 ) ) = 5.0;
                %DOY_co2_max( DOYidx( 185 ) : DOYidx( 220 ) ) = 5.0;
                %DOY_co2_max( DOYidx( 245 ) : DOYidx( 285 ) ) = 4.7;
%                 DOY_co2_max( DOYidx( 314 ) : DOYidx( 316 ) ) = 1.2;
%                 DOY_co2_max( DOYidx( 325 ) : DOYidx( 326 ) ) = 1.0;
%                 DOY_co2_min( DOYidx( 325 ) : DOYidx( 329 ) ) = -1.5;
%                 DOY_co2_min( DOYidx( 330 ) : end ) = -0.75;
                
        end  %JSav
        
    case UNM_sites.PJ
        switch year
            case 2008
                DOY_co2_max( 1 : DOYidx( 185 ) ) = 3.0;
                % SD filter takes care of these now - GEM
%                 DOY_co2_min( DOYidx( 260 ) : DOYidx( 290 ) ) = -18.0;
%                 DOY_co2_min( DOYidx( 335 ) : DOYidx( 365 ) ) = -6.5;
                
%             case 2009
%                 % Commented by GEM March 2015
%                 DOY_co2_max( 1 : DOYidx( 180 ) ) = 3.0;
%                 DOY_co2_max( DOYidx( 190 ) : DOYidx( 260 ) ) = 4.0;
                
            case 2011
                std_exc_flag( DOYidx( 31.5 ) : DOYidx( 31.8 ) ) = true;
                std_exc_flag( DOYidx( 182.6 ) : DOYidx( 182.8 ) ) = true;
                std_exc_flag( DOYidx( 183.4 ) : DOYidx( 183.7 ) ) = true;
                DOY_co2_min( DOYidx( 350 ) : end ) = -2.0;
                
            case 2012
                DOY_co2_max( DOYidx( 307 ) : end ) = 2.0;
                
            case 2013
                DOY_co2_max( DOYidx( 210 ) : DOYidx( 219 ) ) = 4.0;
                DOY_co2_max( DOYidx( 345 ) : DOYidx( 365 ) ) = 2.5;
        end  %PJ
        
    case UNM_sites.PPine
        switch year
            case 2007
                %DOY_co2_max( DOYidx( 185 ) : DOYidx( 259.99 ) ) = 10.0;
                %DOY_co2_max( DOYidx( 240 ) : DOYidx( 276 ) ) = 5.5;
                %DOY_co2_max( DOYidx( 276 ) : DOYidx( 277 ) ) = 5.0;
                %DOY_co2_max( DOYidx( 277 ) : DOYidx( 279 ) ) = 10.0;
                %DOY_co2_max( DOYidx( 280 ) : end ) = 5.0;
                
%            case 2009
%                 DOY_co2_max( : ) = 10;
%                 DOY_co2_max( DOYidx( 64 ) : DOYidx( 67 ) ) = 15.0;
%                 DOY_co2_max( DOYidx( 67 ) : DOYidx( 150 ) ) = 8.0;
%                 DOY_co2_max( DOYidx( 300 ) : end ) = 10.0;
                
            case 2011
                std_exc_flag( DOYidx( 171 ) : DOYidx( 172 ) ) = true;
                %DOY_co2_min( DOYidx( 291.4 ) : DOYidx( 291.6 ) ) = -20.0;
                DOY_co2_min( DOYidx( 90 ) : DOYidx( 310 ) ) = -15.5;
                
%             case 2012
%                 DOY_co2_min( DOYidx( 90 ) : DOYidx( 140 ) ) = -20.0;
%                 DOY_co2_max( DOYidx( 353 ) : DOYidx( 355 ) ) = 4.0;
                
            case 2013 %Added by RJL based on Marcy request 11/22/2013
                DOY_co2_min( DOYidx( 330 ) : end ) = -18.0;
                DOY_co2_min( DOYidx( 20 ) : DOYidx( 150 ) ) = -15.0;
                
            case 2014
                DOY_co2_min( DOYidx( 100 ) : DOYidx( 310 ) ) = -17.0;
        end
        
    case UNM_sites.MCon
        switch year
            case 2007
                % Get rid of some noisy looking data
                DOY_co2_max( DOYidx( 75 ) : DOYidx( 86 ) ) = 2.0;
                DOY_co2_max( DOYidx( 175 ) : DOYidx( 297 ) ) = 4.0;
                DOY_co2_min( DOYidx( 327 ) : DOYidx( 345 ) ) = -2.0;
                
            case 2008
                DOY_co2_min( DOYidx( 70 ) : DOYidx( 106 ) ) = -2.0;
                DOY_co2_max( DOYidx( 125 ) : DOYidx( 155 ) ) = 3.0;
                
%             case 2009
%                 DOY_co2_min( DOYidx( 83 ) : DOYidx( 100 ) ) = -3.0;
%                 DOY_co2_max( DOYidx( 83 ) : DOYidx( 100 ) ) = 4.0;
%                 DOY_co2_max( DOYidx( 156 ) : DOYidx( 305 ) ) = 4.0;
%                 DOY_co2_max( DOYidx( 311 ) : end ) = 3.0;
                
            case 2010
                DOY_co2_max( DOYidx( 200 ) : DOYidx( 244 ) ) = 5.0;
                DOY_co2_max( DOYidx( 246 ) : DOYidx( 300 ) ) = 3.0;
                
            case 2011
%                 DOY_co2_max( DOYidx( 95 ) : DOYidx( 166 ) ) = 4.0;
                DOY_co2_max( DOYidx( 300 ) : end ) = 4.0;
                
            case 2012
                DOY_co2_max( DOYidx( 344 ) : end ) = 2.0;
                
            case 2013
                DOY_co2_max( 1 : DOYidx( 18 ) ) = 1.4;
                DOY_co2_max( DOYidx( 27 ) : DOYidx( 31 ) ) = 1.5;
                DOY_co2_min( DOYidx( 27 ) : DOYidx( 31 ) ) = -1.5;
                DOY_co2_max( DOYidx( 67.5 ) : DOYidx( 69.55 ) ) = 1.0;
                DOY_co2_min( DOYidx( 67.5 ) : DOYidx( 69.55 ) ) = -2.0;
                DOY_co2_max( DOYidx( 76 ) : DOYidx( 76.6 ) ) = 1.0;
                DOY_co2_min( DOYidx( 76 ) : DOYidx( 76.6 ) ) = -2.0;
        end  % MCon
        
    case UNM_sites.TX
        switch year
            case 2009
                DOY_co2_max( DOYidx( 163 ) : DOYidx( 163.5 ) ) = 9.0;
                DOY_co2_max( DOYidx( 265 ) : DOYidx( 305 ) ) = 12.0;
                
            case 2011
                DOY_co2_max( 1 : DOYidx( 31 ) ) = 3.0;
                DOY_co2_max( DOYidx( 33 ) : DOYidx( 45 ) ) = 3.0;
                DOY_co2_max( DOYidx( 33 ) : DOYidx( 45 ) ) = 3.0;
                
            case 2012
                DOY_co2_max( 1 : DOYidx( 30 ) ) = 3.0;
                DOY_co2_max( DOYidx( 152 ) : DOYidx( 160 ) ) = 5.0;
                DOY_co2_max( DOYidx( 318 ) : DOYidx( 326 ) ) = 4.0;
                DOY_co2_max( DOYidx( 345 ) : end ) = 2.1;
        end % TX
        
    case UNM_sites.PJ_girdle
        switch year
            case 2009
                % 5 lines commented out by GEM, March 2015
%                 DOY_co2_max( 1 : DOYidx( 100 ) ) = 1.5;
%                 DOY_co2_max( DOYidx( 100 ) : DOYidx( 140 ) ) = 2.5;
%                 DOY_co2_max( DOYidx( 140 ) : DOYidx( 176 ) ) = 2.0;
%                 DOY_co2_max( DOYidx( 177 ) : DOYidx( 191 ) ) = 4.0;
%                 DOY_co2_max( DOYidx( 244 ) : DOYidx( 267 ) ) = 3.2;
                DOY_co2_max( DOYidx( 275 ) : DOYidx( 299 ) ) = 3.0;
                DOY_co2_max( DOYidx( 300 ) : end ) = 2.0;
                
            case 2010
                % Strange Fc drop - don't see any IRGA problems
                DOY_co2_min( DOYidx( 312) : DOYidx( 322 ) ) = -5.0;
                
            case 2011
                % Not sure who likes this respiration spike... could be
                % rain related - GEM
                idx = DOYidx( 192.2 ) : DOYidx( 192.6 );
                std_exc_flag( idx ) = true;
                DOY_co2_max( idx ) = 6.5;
                DOY_co2_min( DOYidx( 350 ) : end ) = -2.5;
                
%             case 2012
%                 DOY_co2_max( DOYidx( 260 ) : DOYidx( 280 ) ) = 2.0;
%                 DOY_co2_max( DOYidx( 285 ) : DOYidx( 290 ) ) = 1.5;
                
            case 2013
                DOY_co2_max( DOYidx( 222 ) : DOYidx( 226  ) ) = 4.0;
        end
        
    case UNM_sites.New_GLand
        switch year
            case 2010
                % IRGA acting funny between these 2 periods - removing only
                % outliers because most of data ([CO2] and Fc) looks
                % reasonable
                idx = DOYidx( 18.5 ) : DOYidx( 42.3 );
                DOY_co2_max( idx ) = 1.5;
                DOY_co2_min( idx ) = -2.0;
                % Big pulses - seemingly tied to precip events.
                % Removing some because I don't believe the magnitude.
                idx = DOYidx( 74 ) : DOYidx( 100 );
                DOY_co2_max( idx ) = 2.6;
                idx = DOYidx( 74 ) : DOYidx( 80 );
                DOY_co2_min( idx ) = -2.2;
                idx = DOYidx( 100 ) : DOYidx( 300 );
                DOY_co2_max( idx ) = 3.7;
                DOY_co2_min( idx ) = -7.0;
            case 2011
                % FIXME - Explanation for all these? I don't think they are
                % needed - GEM
%                 std_exc_flag( DOYidx( 39.5 ) : DOYidx( 39.7 ) ) = true;
%                 std_exc_flag( DOYidx( 50.5 ) : DOYidx( 50.7 ) ) = true;
%                 std_exc_flag( DOYidx( 58.5 ) : DOYidx( 58.7 ) ) = true;
%                 std_exc_flag( DOYidx( 66.6 ) : DOYidx( 66.8 ) ) = true;
%                 std_exc_flag( DOYidx( 72.5 ) : DOYidx( 72.6 ) ) = true;
%                 std_exc_flag( DOYidx( 89.55 ) : DOYidx( 89.65 ) ) = true;
%                 std_exc_flag( DOYidx( 104.48 ) : DOYidx( 104.52 ) ) = true;
%                 std_exc_flag( DOYidx( 107.52 ) : DOYidx( 107.58 ) ) = true;
%                 std_exc_flag( DOYidx( 129.48 ) : DOYidx( 129.56 ) ) = true;
%                 
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
%                 std_exc_flag( DOYidx( 201 ) : DOYidx( 203 ) ) = true;
%                 std_exc_flag( DOYidx( 225.6 ) : DOYidx( 225.7 ) ) = true;
%                 std_exc_flag( DOYidx( 290.4 ) : DOYidx( 290.6 ) ) = true;
%                 std_exc_flag( DOYidx( 335.45 ) : DOYidx( 335.6 ) ) = true;
                DOY_co2_max( DOYidx( 344.5 ) : DOYidx( 345.56 ) ) = 9.0;
                
            case 2012
                DOY_co2_max( DOYidx( 185 ) : DOYidx( 285 ) ) = 3.0;
                DOY_co2_max( DOYidx( 312 ) : end ) = 2.5;
                
            case 2013 %Added by RJL based on Marcy request 11/22/2013
                DOY_co2_min( DOYidx( 173 ) : DOYidx( 193 ) ) = -3.0;
                % Too restrictive - GEM
%                 DOY_co2_min( DOYidx( 190 ) : DOYidx( 200 ) ) = -4.0;
%                 DOY_co2_min( DOYidx( 200 ) : DOYidx( 208 ) ) = -9.0;
%                 DOY_co2_min( DOYidx( 208 ) : DOYidx( 210 ) ) = -10.0;
%                 DOY_co2_min( DOYidx( 210 ) : DOYidx( 233 ) ) = -15.0;
%                 DOY_co2_min( DOYidx( 233 ) : DOYidx( 238 ) ) = -8.0;
%                 DOY_co2_min( DOYidx( 238 ) : DOYidx( 255 ) ) = -4.0;
%                 DOY_co2_min( DOYidx( 255 ) : DOYidx( 264 ) ) = -6.0;
%                 DOY_co2_min( DOYidx( 264 ) : DOYidx( 272 ) ) = -7.0;
%                 DOY_co2_min( DOYidx( 292 ) : end ) = -6.0;
            case 2014 %Added by RJL based on Marcy request 11/22/2013
                DOY_co2_max( DOYidx( 335 ) : end ) = 2.0;
        end  % New_GLand
end