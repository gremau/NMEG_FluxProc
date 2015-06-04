function data_amended = amend_gapfilling_and_partitioning( site, yr, data_in )
% AMEND_GAPFILLING_AND_PARTITIONING - fix or remove periods where 
% gapfilled and partitioned fluxes fail or are ridiculous
%
% FIXME: documentation
%
% Called from Ameriflux File Maker
%  
% INPUTS
%    site: UNM_sites object; which site?
%    yr: the year.  Either single value or N-element vector if data span
%        more than one year.
%    data in: Data with gapfilled and partitioned fluxes output from
%            multiple sources
%
% OUTPUTS
%    tbl_correct: MATLAB table; contains corrected gapfilling values
%
% SEE ALSO
%    UNM_sites
%
% Gregory E. Maurer

[ this_year, ~, ~ ] = datevec( now );

% -----
% define inputs, with defaults and type checking
% -----

args = inputParser;
args.addRequired( 'site', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'yr', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ...
    ) );
args.addRequired( 'data_in', @istable );

% parse optional inputs
args.parse( site, yr, data_in );

site = args.Results.site;
yr = args.Results.yr;
data_in = args.Results.data_in;

% Make a copy of data_in to correct and add an "amended" respiration col
data_amended = data_in;
data_amended.Reco_HBLR_amended = data_amended.Reco_HBLR;

switch site
  case UNM_sites.JSav
    if  yr == 2007 
        % the gapfiller does some filling before the JSav tower was
        % operational (4 May 2007 15:30), but the filled data do not look
        % good (they are time-shifted).  Remove those data here.
        row_idx = 1:DOYidx( 145 );
        non_data_vars = { 'Day', 'Month', 'Year', 'Hour', ...
                          'Minute', 'julday', 'Hr', 'timestamp' };
        
        data_cols = find( not( ismember( data_in.Properties.VariableNames, ...
                                         non_data_vars ) ) );
        temp_arr = table2array( data_in );
        temp_arr( row_idx, data_cols ) = NaN;
        data_amended = array2table( temp_arr, ...
            'VariableNames', data_in.Properties.VariableNames);
    end
    
  case UNM_sites.PPine
    % Several periods with abnormally high respiration at PPine. Amend
    % as per Marcy's request
    switch yr
      case 2009
        idx = DOYidx( 15.25 ) : DOYidx( 26.75 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 3.85 );
        idx2 = DOYidx( 45.05 ) : DOYidx( 49 );
        data_amended.Reco_HBLR_amended( idx2 ) = ...
            norm( data_in.Reco_HBLR( idx2 ), 2.15 );
        idx3 = DOYidx( 243 ) : DOYidx( 249 );
        data_amended.Reco_HBLR_amended( idx3 ) = ...
            norm( data_in.Reco_HBLR( idx3 ), 5 );
        idx4 = DOYidx( 317 ) : DOYidx( 320.85 );
        data_amended.Reco_HBLR_amended( idx4 ) = ...
            norm( data_in.Reco_HBLR( idx4 ), 5 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
      case 2010
        idx = DOYidx( 219.3 ) : DOYidx( 222.8 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 6 ); 
        idx2 = DOYidx( 350 ) : DOYidx( 366 );
        data_amended.Reco_HBLR_amended( idx2 ) = ...
            norm( data_in.Reco_HBLR( idx2 ), 4.3 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
      case 2011
        idx = DOYidx( 27.25 ) : DOYidx( 59 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 3.5 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
      case 2012
        idx = DOYidx( 321.1 ) : DOYidx( 328 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 5 );
        idx2 = DOYidx( 345.35 ) : DOYidx( 350.9 );
        data_amended.Reco_HBLR_amended( idx2 ) = ...
            norm( data_in.Reco_HBLR( idx2 ), 3.5 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
      case 2013
        idx = DOYidx( 325.3 ) : DOYidx( 350.75 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 3.2 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
      case 2014
        idx = DOYidx( 235.2 ) : DOYidx( 240.75 );
        data_amended.Reco_HBLR_amended( idx ) = ...
            norm( data_in.Reco_HBLR( idx ), 6.2 );
        dfig = plot_amended( data_in, data_amended, ...
            'Reco_HBLR', site, yr );
    end
        
  case UNM_sites.MCon
    switch yr
      case 2009
        % This seems to shift flux variables for the first 20 days of 2009
        % at MCon (which are all gapfilled) forward 1 hour. This is surely
        % Related to the radiation gapfilling issue. I'm not sure 
        % we should do this though and I am commenting it out - GEM
%         NEE_vars = cellfun( @(x) not(isempty(x)), ...
%                             regexp( pt_GL_tbl.Properties.VariableNames, '.*NEE.*' ) );
%         GPP_vars = cellfun( @(x) not(isempty(x)), ...
%                             regexp( pt_GL_tbl.Properties.VariableNames, '.*GPP.*' ) );
%         RE_vars = cellfun( @(x) not(isempty(x)), ...
%                            regexp( pt_GL_tbl.Properties.VariableNames, '.*RE.*' ) );
%         LE_vars = cellfun( @(x) not(isempty(x)), ...
%                            regexp( pt_GL_tbl.Properties.VariableNames, '.*LE.*' ) );
%         H_vars = cellfun( @(x) not(isempty(x)), ...
%                           regexp( pt_GL_tbl.Properties.VariableNames, '.*H_.*' ) );
%         shift_vars = find( NEE_vars | GPP_vars | RE_vars | H_vars );
%         idx = 1:DOYidx( 20 );
%         temp_arr = table2array( data_in );
%         temp_arr( idx, : ) = shift_data( temp_arr( idx, : ), -1.0, ...
%                                          'cols_to_shift', shift_vars );
%         data_amended = replacedata( temp_arr, ...
%             'VariableNames', data_in.Properties.VariableNames );
      case 2011
        % the gapfiller/partitioner put in a big RE spike between days 300
        % and 335.  Dampen that spike to 2 (as per conversation with Marcy 17
        % Apr 2013)
          % Commenting this because the gapfiller no longer does this, so
          % this code actually creates a spike now. GEM 5/13/2015
%         idx = DOYidx( 300 ) : DOYidx( 335 );
%         data_amended.Reco_HBLR( idx ) = data_in.Reco_HBLR( idx ) .* ...
%             ( 2 / max( data_in.Reco_HBLR( idx ) ) );
      case 2012
          % the gapfiller/partitioner put in a big RE spike between days
          % 120 and 133.  Dampen that spike to 6.
          % Commenting this because the gapfiller no longer does this, so
          % this code actually creates a spike now. GEM 5/13/2015
%         idx = DOYidx( 120 ) : DOYidx( 133 );
%         data_amended.Reco_HBLR( idx ) = data_in.Reco_HBLR( idx ) .* ...
%             ( 6 / max( data_in.Reco_HBLR( idx ) ) );
    end
  case UNM_sites.GLand
    switch yr
        case 2012
            % 1 period with abnormally high respiration this year. Amend
            % as per Marcy's request
            idx = DOYidx( 192.5 ) : DOYidx( 217.4 );
            data_amended.Reco_HBLR_amended( idx ) = ...
                norm( data_in.Reco_HBLR( idx ), 1.55 );
            dfig = plot_amended( data_in, data_amended, ...
                'Reco_HBLR', site, yr );
    end
            
  case UNM_sites.PJ_girdle
    switch yr
        case 2009
            % 2 periods with abnormally high respiration this year. Amend
            % as per Marcy's request
            idx = DOYidx( 194.5 ) : DOYidx( 202.75 );
            data_amended.Reco_HBLR_amended( idx ) = ...
                norm( data_in.Reco_HBLR( idx ), 3 );
            idx2 = DOYidx( 224.25 ) : DOYidx( 228.8 );
            data_amended.Reco_HBLR_amended( idx2 ) = ...
                norm( data_in.Reco_HBLR( idx2 ), 2 );
            dfig = plot_amended( data_in, data_amended, ...
                'Reco_HBLR', site, yr );
        case 2010
            % 1 period with abnormally high respiration this year. Amend
            % as per Marcy's request
            idx = DOYidx( 184.25 ) : DOYidx( 188.7 );
            data_amended.Reco_HBLR_amended( idx ) = ...
                norm( data_in.Reco_HBLR( idx ), 2.5 );
            dfig = plot_amended( data_in, data_amended, ...
                'Reco_HBLR', site, yr );
        case 2012
            % 1 period with abnormally high respiration this year. Amend
            % as per Marcy's request
            idx = DOYidx( 263.55 ) : DOYidx( 299.9 );
            data_amended.Reco_HBLR_amended( idx ) = ...
                norm( data_in.Reco_HBLR( idx ), 2.6 );
            dfig = plot_amended( data_in, data_amended, ...
                'Reco_HBLR', site, yr );
        case 2011
          % the gapfiller/partitioner put in large RE and GPP spike between
          % days 335 and 360 - replace the GPP with that from days 306.25 to
          % 316, recycled to the appropriate length.
          % Commenting this because the gapfiller no longer does this, so
          % this code actually reduces what may be a valuable spike now. 
          % GEM 5/13/2015
%           fill_idx = DOYidx( 306.25 ) : DOYidx( 316 );
%           replace_idx = DOYidx( 335 ) : DOYidx( 360 );
%           filler = data_in.Reco_HBLR( fill_idx );
%           filler = repmat( filler, 3, 1 );
%           filler = filler( 1 : numel( replace_idx ) );
%           data_amended.Reco_HBLR( replace_idx ) = filler;
      end
    
  case UNM_sites.PJ
    switch yr
        case 2009
          % 1 period with abnormally high respiration this year. Amend
          % as per Marcy's request
          idx = DOYidx( 178.25 ) : DOYidx( 182 );
          data_amended.Reco_HBLR_amended( idx ) = ...
              norm( data_in.Reco_HBLR( idx ), 2.75 );
          dfig = plot_amended( data_in, data_amended, ...
              'Reco_HBLR', site, yr );
        case 2011
          % 2 periods with abnormally high respiration this year. Amend
          % as per Marcy's request
          idx = DOYidx( 241.25 ) : DOYidx( 246.8 );
          data_amended.Reco_HBLR_amended( idx ) = ...
              norm( data_in.Reco_HBLR( idx ), 3.5 );
          idx2 = DOYidx( 349 ) : DOYidx( 356.75 );
          data_amended.Reco_HBLR_amended( idx2 ) = ...
              norm( data_in.Reco_HBLR( idx2 ), 3 );
          dfig = plot_amended( data_in, data_amended, ...
              'Reco_HBLR', site, yr );
      end
end

function data_norm = norm( in, norm_to_max )
    minval = min( in );
    maxval = norm_to_max;
    data_norm = normalize_vector(in, minval, maxval );
    

function fig = plot_amended( in, amended, varname, site, yr )
    fig = figure( 'Name', ...
        sprintf( '%s %d Amendments to gapfill/partitioning', ...
        get_site_name( site ), yr ));
    varname_amended = [ varname '_amended' ];
    doy = in.timestamp - datenum( yr, 1, 0);
    plot( doy, in.NEE_f, ':', 'Color', [0.7, 0.7, 0.7]);
    hold on;
    plot( doy, in.( varname ), '.r');
    plot( doy, amended.( varname_amended ), '.b');
    varname = strrep( varname, '_', '\_' );
    legend( 'NEE_f', varname, [ 'Amended ' varname ]);

