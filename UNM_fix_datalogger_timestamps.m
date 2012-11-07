function data = UNM_fix_datalogger_timestamps( sitecode, year, data )
% UNM_FIX_DATALOGGER_TIMESTAMPS - called from UNM_RemoveBadData to correct
% shifts in the timestamps for particular periods.  This file simply contains
% the periods that need to be shifted (identified by running
% UNM_site_plot_fullyear_time_offsets and visually examining the plots it draws)
% and calls shift_data to correct them.
%   

all_10hz = 1:74;  %column indices for 10 hz ("matlab") data

switch sitecode
  case UNM_sites.GLand
    switch year
      case 2007
        data = shift_data( data, -1.0 );
        row_idx = DOYidx( 38 ) : DOYidx( 69 );
        col_idx = [ 1:144, 146:size( data, 2 ) ]; % all but incoming SW
        data( row_idx, : ) = shift_data( data( row_idx, : ), ...
                                         -1.0, ...
                                         'cols_to_shift', col_idx );
        data = shift_data( data, -0.5, ...
                           'cols_to_shift', all_10hz );
      case 2008
        data = shift_data( data, -1.0 );
        data = shift_data( data, -0.5, ...
                           'cols_to_shift', all_10hz );
      case 2009
        idx = 1 : DOYidx( 58 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
        idx = DOYidx( 82 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ),  -0.5 );

        idx = DOYidx( 295 ) : DOYidx( 330 );
        data( idx, : ) = shift_data( data( idx, : ), -2.0, ...
                                     'cols_to_shift', all_10hz );
        idx = DOYidx( 27 ) : DOYidx( 50 );
        data( idx, : ) = shift_data( data( idx, : ), -1.0, ...
                                     'cols_to_shift', all_10hz );
        
        data = shift_data( data, 0.5, ...
                           'cols_to_shift', all_10hz );
        
      case 2010
        col_idx = 1:size( data, 2 );
        data = shift_data( data, 1.0, 'cols_to_shift', col_idx );
      case 2011
        data = shift_data( data, 1.0 );
        data = shift_data( data, 0.5, 'cols_to_shift', all_10hz );
      case 2012
        data = shift_data( data, 1.0 );
    end

  case UNM_sites.SLand
    switch year
      case 2007
        idx = 1: DOYidx( 150 );
        data( idx, : ) = shift_data( data( idx, : ), 0.5, ...
                                     'cols_to_shift', all_10hz );
        data( idx, : ) = shift_data( data( idx, : ), -0.5, ...
                                     'cols_to_shift', ...
                                     [ 76:145, 147:size( data, 2 ) ] );
        idx = DOYidx( 45 ) : DOYidx( 60 );
        data( idx, : ) = shift_data( data( idx, : ), -1.0, ...
                                     'cols_to_shift', ...
                                     [ 1:144, 146:size( data, 2 ) ] );
      case 2008
        %idx = [ 1: DOYidx( 5 ), DOYidx( 20 ) : size( data, 1 ) ];
        %data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        data = shift_data( data, -1.0 );
        data = shift_data( data, -0.5, 'cols_to_shift', all_10hz );
      case 2009
        idx = 1 : DOYidx( 64 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
      case 2011
        idx = DOYidx( 137 ) : DOYidx( 165 );
        data( idx, : ) = shift_data( data( idx, : ),  -0.5 );
    end
    
  case UNM_sites.JSav
    switch year
      case 2007
        doy_col = 8;  % day of year column in JSav_FluxAll_2007.xls
        idx = find( ( data( :, doy_col ) >= 324 ) & ...
                    ( data( :, doy_col ) <= 335 ) );
        data( idx, : ) = shift_data( data( idx, : ),  1.0 );
      case 2009
        idx = 1 : DOYidx( 97.5 );
        data( idx, : ) = shift_data( data( idx, : ),  -1.0 );
    end

  case UNM_sites.PJ
    switch year
      case { 2009, 2010, 2011, 2012 }
        data = shift_data( data, 1.0 );
        data = shift_data( data, 0.5, 'cols_to_shift', all_10hz );
    end

  case UNM_sites.PPine
    switch year
      case 2007
        idx = DOYidx( 156.12 ) : DOYidx( 177.5 );
        Tdry_col = 14;  %shift temperature record
        data( idx, : ) = shift_data( data( idx, : ), -1.5, ...
                                     'cols_to_shift', Tdry_col );
      case 2009
        data = shift_data( data, 1.0 );
        idx = DOYidx( 260 ) : DOYidx( 267 );
        data( idx, : ) = shift_data( data( idx, : ), -2.0 );
        idx = DOYidx( 268 ) : DOYidx( 283 );
        data( idx, : ) = shift_data( data( idx, : ), -3.5 );
        idx = DOYidx( 283.0 ) : DOYidx( 293.5 );
        data( idx, : ) = shift_data( data( idx, : ), -4.5 );
        
      case 2012
        idx = DOYidx( 204 ) : DOYidx( 233 );
        data( idx, : ) = shift_data( data( idx, : ), -2.0 );
    end
    
  case UNM_sites.MCon
    switch year
      case 2008
        idx = DOYidx( 341.0 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        idx = 1 : DOYidx( 155 )
        data( idx, : ) = shift_data( data( idx, : ), -0.5 );
      case 2009
        idx = DOYidx( 351.5 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 1.5 );
        idx = DOYidx( 20 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 0.5, ...
                                     'cols_to_shift', all_10hz);
        data = shift_data( data, 0.5, 'cols_to_shift', all_10hz);
      case 2010
        col_idx = 1:size( data, 2 );
        data = shift_data( data, 1.0, 'cols_to_shift', col_idx );
        idx = DOYidx( 25 ) : DOYidx( 47 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0, ...
                                     'cols_to_shift', col_idx );
        idx = DOYidx( 300 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 0.5, ...
                                     'cols_to_shift', col_idx);
      case 2011
        col_idx = 1:size( data, 2 );
        idx = 1 : DOYidx( 12.0 );
        data( idx, : ) = shift_data( data( idx, : ),  1.5, ...
                                     'cols_to_shift', col_idx );
        idx = DOYidx( 12.0 ) : DOYidx( 48.0 );
        data( idx, : ) = shift_data( data( idx, : ),  2.5, ...
                                     'cols_to_shift', col_idx );
        
      case 2012
        col_idx = 1:size( data, 2 );
        idx = DOYidx( 133 ) : DOYidx( 224.0 );
        data( idx, : ) = shift_data( data( idx, : ), 4.5, ...
                                     'cols_to_shift', col_idx );

        col_idx = 1:size( data, 2 );
        Sep19 = datenum( 2012, 9, 19, 17, 0, 0 ) - datenum( 2012, 1, 0 );        
        idx = DOYidx( Sep19 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), -3.5, ...
                                     'cols_to_shift', col_idx );

        
        
        % compensate for the 11 Aug 2012 datalogger clock reset so that the clock would
        % match the Ameriflux tech's clock.  From Skyler: "I swapped the card
        % beforehand then changed the clock from Aug 11, 2012 20:54 to Aug 11,
        % 2012 17:10."
        Aug11_1710 = datenum( 2012, 8, 11, 17, 10, 0 ) - datenum( 2012, 1, 0 );
        idx = DOYidx( Aug11_1710 );
        data( idx:end, : ) = shift_data( data( idx:end, : ), 4.5, ...
                                     'cols_to_shift', col_idx );
    end

  case UNM_sites.TX
    switch year
      case 2009
        idx = DOYidx( 314 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
    end
    
  case UNM_sites.New_GLand
    switch year
      case 2010
        col_idx = 1:size( data, 2 );
        idx = DOYidx( 179 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ),  1.0, ...
                                     'cols_to_shift', col_idx );
      case 2011
        data = shift_data( data,  1.0 );
        data = shift_data( data, 0.5, 'cols_to_shift', all_10hz );
      case 2012
        idx = 1 : DOYidx( 103 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        idx = DOYidx( 104 ) : DOYidx( 220 );
        data( idx, : ) = shift_data( data( idx, : ), 2.0 );
    end

end

%==================================================
