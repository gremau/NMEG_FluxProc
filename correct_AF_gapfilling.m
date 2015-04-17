function data_corrected = correct_AF_gapfilling( site, yr, data_in )
% CORRECT_AF_GAPFILLING - fix or remove periods where gapfilled fluxes fail
% or are ridiculous
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

% Make a copy of data_in to correct
data_corrected = data_in;

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
        data_corrected = array2table( temp_arr, ...
            'VariableNames', data_in.Properties.VariableNames);
    end
    
  case UNM_sites.PPine
    switch yr
      case 2011
        
        % the gapfiller/partitioner diagnosed curiously low RE between days 27
        % and 48.  Raise  that spike to 6.  (as per conversation with Marcy
        % 16 Apr 2013).  The fix must be applied to NEE because GPP will be
        % recalculated as NEE - RE to ensure carbon balance.
        idx = ( data_in.NEE_HBLR > 0.0 ) & ...
              ( data_in.julday >= 27 ) & ...
              ( data_in.julday <= 48 );
        data_corrected.NEE_HBLR( idx ) = data_in.NEE_HBLR( idx ) .* ...
            ( 8 / max( data_in.NEE_HBLR( idx ) ) );
        fprintf( 'Fixing PPine 2011 GPP\n' );
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
%         data_corrected = replacedata( temp_arr, ...
%             'VariableNames', data_in.Properties.VariableNames );
      case 2011
        % the gapfiller/partitioner put in a big RE spike between days 300
        % and 335.  Dampen that spike to 2 (as per conversation with Marcy 17
        % Apr 2013)
        idx = DOYidx( 300 ) : DOYidx( 335 );
        data_corrected.Reco_HBLR( idx ) = data_in.Reco_HBLR( idx ) .* ...
            ( 2 / max( data_in.Reco_HBLR( idx ) ) );
      case 2012
        % the gapfiller/partitioner put in a big RE spike between days 120
        % and 133.  Dampen that spike to 6.
        idx = DOYidx( 120 ) : DOYidx( 133 );
        data_corrected.Reco_HBLR( idx ) = data_in.Reco_HBLR( idx ) .* ...
            ( 6 / max( data_in.Reco_HBLR( idx ) ) );
    end

  case UNM_sites.PJ_girdle
    switch yr
        case 2011
          % the gapfiller/partitioner put in large RE and GPP spike between
          % days 335 and 360 - replace the GPP with that from days 306.25 to
          % 316, recycled to the appropriate length.
          fill_idx = DOYidx( 306.25 ) : DOYidx( 316 );
          replace_idx = DOYidx( 335 ) : DOYidx( 360 );
          filler = data_in.Reco_HBLR( fill_idx );
          filler = repmat( filler, 3, 1 );
          filler = filler( 1 : numel( replace_idx ) );
          data_corrected.Reco_HBLR( replace_idx ) = filler;
    end
end