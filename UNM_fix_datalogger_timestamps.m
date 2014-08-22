function data = UNM_fix_datalogger_timestamps( sitecode, year, ...
                                               data, headertext,...
                                               timestamp, ...
                                               varargin )
% UNM_FIX_DATALOGGER_TIMESTAMPS - corrects shifts in the timestamps for
% particular periods.
%
% called from UNM_RemoveBadData to correct
% shifts in the timestamps for particular periods.  This file simply contains
% the periods that need to be shifted (identified by running
% UNM_site_plot_fullyear_time_offsets and visually examining the plots it draws)
% and calls shift_data to correct them.
% 
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%    data: NxM numeric: the data to be fixed
%    headertext: cell array of strings; variable names for the columns in
%        data
%    timestamp: 1xN array of Matlab serial datenumbers: timestamps for the
%        observations in data
% PARAMETER-VALUE PAIRS
%    debug: {true}|false; if true, a several before & after correction plots
%        are drawn to the screen
%    save_figs: {true}|false; if true, the debug plots are saved to
%        $PLOTS/Rad_Fingerprints/SITE_YEAR_Rg_fingerprints.eps.
%        $PLOTS/Rad_Fingerprints is created if it does not exist.
%
% SEE ALSO
%    UNM_sites, dataset, UNM_site_plot_fullyear_time_offsets, shift_data
%
% author: Timothy W. Hilton, UNM, June 2012


[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ...
                         ) );
args.addRequired( 'data', @isnumeric );
args.addRequired( 'headertext', @(x) iscell( x ) && all( cellfun( @ischar, x ) ) );
args.addRequired( 'timestamp', @isnumeric );
args.addParamValue( 'debug', true, @islogical );
args.addParamValue( 'save_figs', true, @islogical );

% parse optional inputs
args.parse( sitecode, year, data, headertext, timestamp, varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
data = args.Results.data;
headertext = args.Results.headertext;
timestamp = args.Results.timestamp;
debug = args.Results.debug;
save_figs = args.Results.save_figs;

%-----

all_10hz = 1:74;  %column indices for 10 hz ("matlab") data

if debug
    
    % -----
    % identify Rg and PAR columns from data
    Rg_col = find( strcmp('Rad_short_Up_Avg', headertext) );
    if isempty( Rg_col )
        Rg_col = find( strcmp('pyrr_incoming_Avg', headertext) );
    end
    if isempty( Rg_col )
        error( 'could not find incoming shortwave column' );
    end
    
    nrows = size( data, 1 );
    dtime = timestamp - datenum( year, 1, 0 );
    [ y, ~, ~, ~, ~, ~ ] = datevec (timestamp );
    this_year = y == year;

    h_fig = figure( 'Name', 'datalogger timestamp correction results');
    h_ax = subplot( 2, 1, 1 );

    % set figure location and size
    pos = get( h_fig, 'Position' );
    % make the figure twice as tall as the default, so it can contain both
    % before and after plots at the default size
    pos( 4 ) = pos( 4 ) * 2;  
    % place the figure at the bottom of the screen so it still fits
    pos( 2 ) = 0;
    set( h_fig, 'Position', pos );
    
    t_str = sprintf( '%s %d Rg before timing fixed', ...
                     char( sitecode ), year );
    t_str = strrep( t_str, '_', '\_' );
    plot_fingerprint( dtime( this_year ), ...
                      data( this_year, Rg_col ), ...
                      t_str, ...
                      'clim', [ 0, 20 ], ...
                      'fig_visible', true, ...
                      'h_fig', h_fig, ...
                      'h_ax', h_ax );
    
end

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
        Dec07_1255 = datenum( 2012, 12, 7, 12, 55, 0 ) - datenum( 2012, 1, 0 );
        idx = 1 : DOYidx( Dec07_1255  );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        
    end

  case UNM_sites.SLand
    switch year
      case 2007
        % idx = 1: DOYidx( 150 );
        % data( idx, : ) = shift_data( data( idx, : ), 0.5, ...
        %                              'cols_to_shift', all_10hz );
        % data( idx, : ) = shift_data( data( idx, : ), -0.5, ...
        %                              'cols_to_shift', ...
        %                              [ 76:145, 147:size( data, 2 ) ] );
        % idx = DOYidx( 45 ) : DOYidx( 60 );
        % data( idx, : ) = shift_data( data( idx, : ), -1.0, ...
        %                              'cols_to_shift', ...
        %                              [ 1:144, 146:size( data, 2 ) ] );
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

    switch year
      case 2012
        idx = DOYidx( 343 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), -1.0 );
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
        idx = DOYidx( 261 ) : DOYidx( 267 );
        data( idx, : ) = shift_data( data( idx, : ), -2.5 );
        idx = DOYidx( 267 ) : ( DOYidx( 268 ) - 1 );
        data( idx, : ) = shift_data( data( idx, : ), -3.0 );
        idx = DOYidx( 268 ) : DOYidx( 283 );
        data( idx, : ) = shift_data( data( idx, : ), -3.5 );
        idx = DOYidx( 283.0 ) : DOYidx( 293.5 );
        data( idx, : ) = shift_data( data( idx, : ), -4.5 );

      case 2010
        data = shift_data( data, 1.0 );

      case 2011
        idx = DOYidx( 12 ) : DOYidx( 30 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        idx = DOYidx( 30 ) : DOYidx( 56 );
        data( idx, : ) = shift_data( data( idx, : ), 0.5 );
      
      case 2012
        idx = DOYidx( 204 ) : DOYidx( 233 );
        data( idx, : ) = shift_data( data( idx, : ), -2.0 );

%      case 2013   %RJL added this section on 11/11/13
%         idx = DOYidx( 129 ) : DOYidx( 151 );
%         data( idx, : ) = shift_data( data( idx, : ), 1.5 );
%         idx = DOYidx( 221 ) : DOYidx( 309 );
%         data( idx, : ) = shift_data( data( idx, : ), 1.5 );
    end
    
  case UNM_sites.MCon
    switch year
      case 2008
        idx = DOYidx( 341.0 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
        idx = 1 : DOYidx( 155 );
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
        
        Aug11_1710 = datenum( 2012, 8, 11, 17, 10, 0 ) - datenum( 2012, 1, 0 );
        Nov14_1200 = datenum( 2012, 11, 14, 12, 0, 0 ) - datenum( 2012, 1, 0 );
        Aug11_1710 = DOYidx( Aug11_1710 );
        Nov14_1200 = DOYidx( Nov14_1200 );
        Sep19_1700 = DOYidx( datenum( 2012, 9, 19, 17, 0, 0 ) - ...
                        datenum( 2012, 1, 0 ) );

        % data( Aug11_1710:Sep19_1700, : ) = ...
        %     shift_data( data( Aug11_1710:Sep19_1700, : ), 3.5, ...
        %                 'cols_to_shift', col_idx );
        data( Sep19_1700:Nov14_1200, : ) = ...
            shift_data( data( Sep19_1700:Nov14_1200, : ), -3.5, ...
                        'cols_to_shift', col_idx );

        
        
        % compensate for the 11 Aug 2012 datalogger clock reset so that the clock would
        % match the Ameriflux tech's clock.  From Skyler: "I swapped the card
        % beforehand then changed the clock from Aug 11, 2012 20:54 to Aug 11,
        % 2012 17:10."
        data( Aug11_1710:Nov14_1200, : ) = ...
            shift_data( data( Aug11_1710:Nov14_1200, : ), 4.5, ...
        'cols_to_shift', col_idx );
        
      case 2013
         idx = 1 : DOYidx( 72 );
         data( idx , : ) = shift_data( data( idx, : ), 1.0 );
         idx = DOYidx( 72.01 ) : DOYidx( 337 );
         data( idx , : ) = shift_data( data( idx, : ), 1.5 );
         idx = DOYidx( 337.01 ) : DOYidx( 342 );
         data( idx , : ) = shift_data( data( idx, : ), 1.0 );
         idx = DOYidx( 342.01 ) : DOYidx( 365.98 );
         data( idx , : ) = shift_data( data( idx, : ), 2.0 );
    end

  case UNM_sites.TX
    switch year
      case { 2007, 2008, 2010, 2011, 2012 }
        data = shift_data( data, 1.0 );
      case 2009
        data = shift_data( data, 1.0 );
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
        idx = DOYidx( 104 ) : size( data, 1 );
        data( idx, : ) = shift_data( data( idx, : ), 2.0 );
        
        Dec07_1355 = datenum( 2012, 12, 7, 13, 55, 0 ) - datenum( 2012, 1, 0 );
        idx = 1 : DOYidx( Dec07_1355  );
        data( idx, : ) = shift_data( data( idx, : ), 1.0 );
    end

end

if debug
    h_ax = subplot( 2, 1, 2 );

    t_str = strrep( t_str, 'before', 'after' );
    plot_fingerprint( dtime( this_year ), ...
                      data( this_year, Rg_col ), ...
                      t_str, ...
                      'clim', [ 0, 20 ], ...
                      'fig_visible', true, ...
                      'h_fig', h_fig, ...
                      'h_ax', h_ax );
    
    if save_figs
        save_dir = fullfile( getenv( 'PLOTS' ), 'Rad_Fingerprints' );
        is_folder = 7; % exist returns 7 if argument is a directory
        if exist( save_dir ) ~= is_folder
            mkdir( getenv( 'PLOTS' ), 'Rad_Fingerprints' );
        end

        fname = fullfile( save_dir, ...
                          sprintf( '%s_%d_Rg_fingerprints.eps', ...
                                   char( sitecode ), year ) );
        
        fprintf( 'saving %s\n', fname );
        figure_2_eps( h_fig, fname );
                      

    end

end


%==================================================
