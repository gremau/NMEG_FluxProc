function fluxall = UNM_assign_soil_data_labels( sitecode, year, fluxall )
% UNM_ASSIGN_SOIL_DATA_LABELS - assign labels to soil measurements.
%
%   Labels are of the format soilT_cover_index_depth_*, where cover, index, and
%   depth are character strings.  e.g. "soilT_O_2_12.5_avg" denotes cover type
%   open, index (pit) 2, and depth of 12.5 cm.  Depth is followed by an
%   underscore, and then optional arbitrary text.
%
% USAGE:
%   fluxall = UNM_assign_soil_data_labels( sitecode, year, fluxall )
%
% INPUTS
%   sitecode: integer or UNM_sites object; site to consider
%   year: integer; year to consider
%   fluxall: matlab dataset object; parsed fluxall.xls or fluxall.txt data
%
% OUTPUTS
%   fluxall: matlab dataset object; fluxall.xls data with relabeled soil data
%       columns
%
% SEE ALSO
%    dataset, UNM_parse_fluxall_txt_file, UNM_parse_fluxall_xls_file
%
% author: Timothy W. Hilton, UNM, May-July 2012

if ~isa( sitecode, 'UNM_sites' )
    sitecode = UNM_sites( sitecode );
end

% The actual work is performed by two helper functions:
fluxall = format_soilT_and_SWC_labels( sitecode, year, fluxall );
fluxall = format_SHF_labels( sitecode, year, fluxall );

%============================================================
% helper functions for UNM_assign_soil_data_labels
%============================================================

function fluxall =  format_SHF_labels( sitecode, year, fluxall )
%  SHF_COLUMNS - identifies soil heat flux (SHF) columns and assigns descriptive
%   labels.
% regular expression to identify strings containing 'shf' or 'hfp',
% case-insensitive
re_SHF = '.*([Ss][Hh][Ff]).*|.*([Hh][Ff][Pp]).*';
[ ~, idx_SHF ] = regexp_header_vars( fluxall, re_SHF );
SHF_vars = fluxall.Properties.VarNames( idx_SHF );

switch sitecode
  case UNM_sites.GLand
    if year < 2012
        % 2007-2011 GLand should have two SHF observations (grass and open)
        if numel( idx_SHF ) < 2
            error( sprintf( [ 'unable to locate 2 SHF measurements for ', ...
                              'GLand %d' ], year ) );
        end
        switch year
          case 2007
            fluxall.Properties.VarNames( idx_SHF ) = ...
                { 'SHF_grass_1', 'SHF_open_1' }';
            
          case 2008
            fluxall.Properties.VarNames( idx_SHF ) = ...
                { 'SHF_open_1', 'SHF_grass_1' }';
            
          case { 2009, 2010, 2011 }
            % these SHF variables are labeled "hfp01_COVER_Avg" -- reformat these to
            % SHF_COVER_1       
            SHF_vars = regexprep( SHF_vars, 'hfp(01)?', 'SHF' );
            SHF_vars = regexprep( SHF_vars, '([0-9])_Avg', '$1' );
            SHF_vars = regexprep( SHF_vars, '_Avg', '_1' );
            fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
        end
    else
        SHF_vars = regexprep( SHF_vars, 'hfp', 'SHF' );
        SHF_vars = regexprep( SHF_vars, '_Avg', '' );
        fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    end
    
  case UNM_sites.SLand
    if ismember( year, [ 2007, 2008 ] )
        SHF_vars = replace_hex_chars( SHF_vars );
        SHF_vars = regexprep( SHF_vars, ...
                              { 'shf_Avg\(1\)', 'shf_Avg\(2\)' }, ...
                              { 'SHF_shrub_1', 'SHF_open_1' }, ...
                              'once' );
    elseif ismember( year, [ 2009, 2010 ] )
        old_vars = { 'hfp01_1_Avg', 'hfp01_2_Avg', 'hfp01_3_Avg', ...
                     'hfp01_4_Avg', 'hfp01_5_Avg', 'hfp01_6_Avg' };
        new_vars = { 'SHF_shrub_1', 'SHF_shrub_2', 'SHF_grass_1', ...
                     'SHF_grass_2', 'SHF_open_1', 'SHF_open_2' };
        SHF_vars = regexprep( SHF_vars, old_vars, new_vars, 'once' );
    elseif year >= 2011
        old_vars = { 'shf_sh_1_Avg', 'shf_sh_2_Avg', 'shf_gr_1_Avg', ...
                     'shf_gr_2_Avg', 'shf_op_1_Avg', 'shf_op_2_Avg' };
        new_vars = { 'SHF_shrub_1', 'SHF_shrub_2', 'SHF_grass_1', ...
                     'SHF_grass_2', 'SHF_open_1', 'SHF_open_2' };
        SHF_vars = regexprep( SHF_vars, old_vars, new_vars, 'once' );
    end
    fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    
  case UNM_sites.JSav
    SHF_vars = replace_hex_chars( SHF_vars );
    SHF_vars = regexprep( SHF_vars, ...
                          { 'shf_Avg.*1.*', 'shf_Avg.*2.*', ...
                        'shf_Avg.*3.*', 'shf_Avg.*4.*' }, ...
                          { 'SHF_open_1', 'SHF_open_2', ...
                        'SHF_edge_1', 'SHF_juniper_1'  }, ...
                          'once' );
    fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    
  case UNM_sites.PJ | UNM_sites.TestSite
    % capitalize "shf" and remove trailing "_Avg" 
    SHF_vars = regexprep( SHF_vars, { 'shf', '_Avg' },  { 'SHF', '' } );
    
  case UNM_sites.PPine
    SHF_vars = replace_hex_chars( SHF_vars );
    SHF_vars = regexprep( SHF_vars, ...
                          { 'shf_Avg.*1.*', 'shf_Avg.*2.*', ...
                        'shf_Avg.*3.*' }, ...
                          { 'SHF_ponderosa_1', 'SHF_ponderosa_2', ...
                        'SHF_ponderosa_3' }, ...
                          'once' );
    fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    
  case UNM_sites.MCon
    SHF_vars = replace_hex_chars( SHF_vars );
    SHF_vars = regexprep( SHF_vars, ...
                          { 'shf_Avg.*1.*', 'shf_Avg.*2.*', ...
                        'shf_Avg.*3.*' }, ...
                          { 'SHF_mcon_1', 'SHF_mcon_2', ...
                        'SHF_mcon_3' }, ...
                          'once' );
    fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    
  case UNM_sites.New_GLand
    vars = fluxall.Properties.VarNames; 
    vars = regexprep( vars, ...
                      { 'grass_1_Avg', 'grass_2_Avg', ...
                        'open_1_Avg', 'open_2_Avg' }, ...
                      { 'SHF_open_1', 'SHF_open_2', ...
                        'SHF_grass_1', 'SHF_grass_2'  }, ...
                      'once' );
    fluxall.Properties.VarNames = vars;
    
end
        
        
%============================================================

function fluxall = format_soilT_and_SWC_labels( sitecode, year, fluxall )
% SOILT_AND_SWC_COLUMNS - identifies soil temperature (soilT) and soil water
%   content (SWC) columns and assigns descriptive labels.


placeholder = 0;
labels_template = struct( 'labels', { 'placeholder' }, ...
                          'columns', [ placeholder ] );
echo_SWC_labels = labels_template;
cs616_SWC_labels = labels_template;
soilT_labels = labels_template;
TCAV_labels = labels_template;

%place holders
% cs616_SWC_labels.columns = [];
% cs616_SWC_labels.labels = {};

% echo_SWC_labels.columns = [];
% echo_SWC_labels.labels = {};

% soilT_labels.columns = [];
% soilT_labels.labels = {};

switch sitecode
    
    % --------------------------------------------------
  case UNM_sites.GLand

    descriptive_soilT_labels = { 'soilT_open_1_2p5', ...
                        'soilT_open_1_12p5', ...
                        'soilT_open_1_22p5', ...
                        'soilT_grass_1_2p5', ...
                        'soilT_grass_1_12p5', ...
                        'soilT_grass_1_22p5', ...
                        'soilT_open_2_2p5', ...
                        'soilT_open_2_12p5', ...
                        'soilT_open_2_22p5', ...
                        'soilT_grass_2_2p5', ...
                        'soilT_grass_2_12p5', ...
                        'soilT_grass_2_22p5', ...
                        'soilT_open_3_2p5', ...
                        'soilT_open_3_12p5', ...
                        'soilT_open_3_22p5', ...
                        'soilT_open_3_37p5', ... 
                        'soilT_grass_3_2p5', ...
                        'soilT_grass_3_12p5', ...
                        'soilT_grass_3_22p5', ...
                        'soilT_grass_3_37p5' }; 

    descriptive_cs616_labels = { 'cs616SWC_open_1_2p5', ...
                        'cs616SWC_open_1_12p5', ...
                        'cs616SWC_open_1_22p5', ...
                        'cs616SWC_grass_1_2p5', ...
                        'cs616SWC_grass_1_12p5', ...
                        'cs616SWC_grass_1_22p5', ...
                        'cs616SWC_open_2_2p5', ...
                        'cs616SWC_open_2_12p5', ...
                        'cs616SWC_open_2_22p5', ...
                        'cs616SWC_grass_2_2p5', ...
                        'cs616SWC_grass_2_12p5', ...
                        'cs616SWC_grass_2_22p5', ...
                        'cs616SWC_open_3_2p5', ...
                        'cs616SWC_open_3_12p5', ...
                        'cs616SWC_open_3_22p5', ...
                        'cs616SWC_open_3_37p5', ...
                        'cs616SWC_grass_3_2p5', ...
                        'cs616SWC_grass_3_12p5', ...
                        'cs616SWC_grass_3_22p5', ...
                        'cs616SWC_grass_3_37p5' };
    
    switch year
        
      case { 2007, 2008 }
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616' );

        % the two 52.5 cm observations to not actually exist (conversation
        % with Marcy, 26 Apr 2012) --TWH
        idx_to_remove = idx_cs616( [ 17, 22, 23 ] );
        idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        fluxall( :, idx_to_remove ) = [];
      
      case { 2009, 2010 }
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616' );

        % the two 52.5 cm observations to not actually exist (conversation
        % with Marcy, 26 Apr 2012) --TWH
        idx_to_remove = idx_cs616( [ 17, 22 ] );
        idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        
        fluxall( :, idx_to_remove ) = [];

        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'mux25t' );
        fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;

        [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV|tcav' );
        fluxall.Properties.VarNames( idx_TCAV ) = ...
            { 'TCAV_open_Avg', 'TCAV_cover_Avg' };

      case { 2011, 2012 }
        % this year cs616 SWC are labeled open1_12.5, grass2_2.5, etc.  They
        % are in columns 203 to 222
        re = '(^(open|grass)[12]_[0-9]{1,2}p5cm|swc.*)';  % regular expression to
                                                  % identify cs616 labels
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, re );
        % prepend 'cs616SWC_' to labels and separate cover type from pit number
        % (e.g. grass1... -> cs616_grass_1...
        fluxall.Properties.VarNames( idx_cs616 ) = ...
            strcat( 'cs616SWC_', fluxall.Properties.VarNames( idx_cs616 ) );
        fluxall.Properties.VarNames( idx_cs616 ) = ...
            regexprep( fluxall.Properties.VarNames( idx_cs616 ), ...
                       '(grass|open)', '$1_');

        % % the two 52.5 cm observations to not actually exist (conversation
        % % with Marcy, 26 Apr 2012) --TWH
        % idx_to_remove = idx_cs616( [ 17, 22 ] );
        % idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, '(mux25t|soilT)' );
        fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        
        % some files in late 2012 are labeled "soilt..." not "soilT..."
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'soilt' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            regexprep( fluxall.Properties.VarNames( idx_Tsoil ), ...
                       'soilt', ...
                       'soilT' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            regexprep( fluxall.Properties.VarNames( idx_Tsoil ), ...
                       '_Avg', ...
                       '' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            format_probe_strings( fluxall.Properties.VarNames( idx_Tsoil ) ); 
        
    end   %switch GLand year

    % --------------------------------------------------
  case UNM_sites.SLand
    
    descriptive_cs616_labels = { 'cs616SWC_open_1_2p5', ...
                        'cs616SWC_open_1_12p5', ...
                        'cs616SWC_open_1_22p5', ...
                        'cs616SWC_open_1_37p5', ...
                        'cs616SWC_open_1_52p5', ...
                        'cs616SWC_cover_1_2p5', ...
                        'cs616SWC_cover_1_12p5', ...
                        'cs616SWC_cover_1_22p5', ...
                        'cs616SWC_cover_1_37p5', ...
                        'cs616SWC_cover_1_52p5', ...
                        'cs616SWC_open_2_2p5', ...
                        'cs616SWC_open_2_12p5', ...
                        'cs616SWC_open_2_22p5', ...
                        'cs616SWC_open_2_37p5', ...
                        'cs616SWC_open_2_52p5', ...
                        'cs616SWC_cover_2_2p5', ...
                        'cs616SWC_cover_2_12p5', ...
                        'cs616SWC_cover_2_22p5', ...
                        'cs616SWC_cover_2_37p5', ...
                        'cs616SWC_cover_2_52p5' };
    
    descriptive_soilT_labels = { 'soilT_open_1_2p5', 'soilT_open_1_12p5', ...
                        'soilT_open_1_22p5', 'soilT_open_1_37p5', ...
                        'soilT_open_1_52p5', 'soilT_cover_1_2p5', ...
                        'soilT_cover_1_12p5', 'soilT_cover_1_22p5', ...
                        'soilT_cover_1_37p5', 'soilT_cover_1_52p5', ...
                        'soilT_open_2_2p5', 'soilT_open_2_12p5', ...
                        'soilT_open_2_22p5', 'soilT_open_2_37p5', ...
                        'soilT_open_2_52p5', 'soilT_cover_2_2p5', ...
                        'soilT_cover_2_12p5', 'soilT_cover_2_22p5', ...
                        'soilT_cover_2_37p5', 'soilT_cover_2_52p5' };
    
    switch year
      case { 2007, 2008, 2009, 2010 }
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616_wcr.*' );
        fluxall.Properties.VarNames( idx_cs616( 1:20 ) ) = ...
            descriptive_cs616_labels;
        fluxall( :, idx_cs616( 21:end ) )  = [];
        
        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'mux25t' );
        if ~isempty( idx_Tsoil )
            fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        end

      case { 2011, 2012 }
        % change soil_h2o... labels to descriptive SWC labels
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, '(soil_h2o_.*_Avg|cs616SWC)' );
        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        
        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'mux25t' );
        if ~isempty( idx_Tsoil )
            fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        end
        
        % some files in late 2012 are labeled "soilt..._Avg" not "soilT..."
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'soilt' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            regexprep( fluxall.Properties.VarNames( idx_Tsoil ), ...
                       'soilt', ...
                       'soilT' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            regexprep( fluxall.Properties.VarNames( idx_Tsoil ), ...
                       '_Avg', ...
                       '' );
        fluxall.Properties.VarNames( idx_Tsoil ) = ...
            format_probe_strings( fluxall.Properties.VarNames( idx_Tsoil ) );
        
    end    % switch SLand year
    
    % --------------------------------------------------
  case UNM_sites.JSav
    
    soilT_descriptive_labels_2008 = { 'soilT_open_1_5', 'soilT_open_1_10', ...
                        'soilT_open_1_20', 'soilT_open_1_40', ...
                        'soilT_open_1_62', 'soilT_open_2_5', ...
                        'soilT_open_2_10', 'soilT_open_2_20', ...
                        'soilT_open_2_40', 'soilT_open_2_62', ...
                        'soilT_edge_1_5', 'soilT_edge_1_10', ...
                        'soilT_edge_1_20', 'soilT_edge_1_40', ...
                        'soilT_edge_1_62', 'soilT_canopy_1_5', ...
                        'soilT_canopy_1_10', 'soilT_canopy_1_20', ...
                        'soilT_canopy_1_40', 'soilT_canopy_1_62' };
    
    cs616_descriptive_labels_preJul09 = { 'cs616SWC_open_1_5', ...
                            'cs616SWC_open_1_10', 'cs616SWC_open_1_20', ...
                            'cs616SWC_open_1_40', 'cs616SWC_open_2_5', ...
                            'cs616SWC_open_2_10', 'cs616SWC_open_2_20', ...
                            'cs616SWC_open_2_40', 'cs616SWC_edge_1_5', ...
                            'cs616SWC_edge_1_10', 'cs616SWC_edge_1_20', ...
                            'cs616SWC_edge_1_40', 'cs616SWC_canopy_1_5', ...
                            'cs616SWC_canopy_1_10', 'cs616SWC_canopy_1_20', ...
                            'cs616SWC_canopy_1_40' };
    
    cs616_descriptive_labels_postJul09 = { 'cs616SWC_juniper_1_2p5', ...
                        'cs616SWC_juniper_1_12p5', ...
                        'cs616SWC_juniper_1_32p5', 'cs616SWC_juniper_2_2p5', ...
                        'cs616SWC_juniper_2_12p5', ...
                        'cs616SWC_juniper_2_32p5', 'cs616SWC_juniper_3_2p5', ...
                        'cs616SWC_juniper_3_12p5', ...
                        'cs616SWC_juniper_3_32p5', 'cs616SWC_open_1_2p5', ...
                        'cs616SWC_open_1_12p5', 'cs616SWC_open_1_32p5', ...
                        'cs616SWC_open_2_2p5', 'cs616SWC_open_2_12p5', ...
                        'cs616SWC_open_2_32p5', 'cs616SWC_open_3_2p5', ...
                        'cs616SWC_open_3_12p5', 'cs616SWC_open_3_32p5' };
    
    switch year
      case 2007
        % It doesn't appear from the TOA5 files that there were any
        % soil measurements at the site prior to 8/31/2007. Between this 
        % date and 2/25/2008 there were 28 Tsoil sensors, which was then
        % reduced to 20 Tsoil sensors. 16 VWC sensors were installed on
        % 8/31/2007, and these were renamed (but not changed)
        % on 2/25/2008. -- GEM
        vars = fluxall.Properties.VarNames;
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'VWC.*' );
        if ~isempty(idx_cs616)
            vars( idx_cs616 ) = cs616_descriptive_labels_preJul09;
        end
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, '[sS]oilT_' );
        % Ensure that the mid-2007 change is ok, but these may be
        % the wrong labels for pre-2/25/2007 sensors entirely. --GEM
        if length(idx_Tsoil) > length(soilT_descriptive_labels_2008)
            idx_Tsoil = idx_Tsoil(1:length(soilT_descriptive_labels_2008));
        end
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = soilT_descriptive_labels_2008;
        end
        
        
        warning( 'temperature data not yet labeled for JSav 2007' );
        
      case 2008 
        vars = fluxall.Properties.VarNames;
        
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_preJul09;

        %soil T
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = soilT_descriptive_labels_2008;
        end

        %TCAV
        [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = format_probe_strings( vars( idx_TCAV ) );
        end

        fluxall.Properties.VarNames = vars;


      case 2009
        % there was a major SWC instrument changeover on 9 Jul 2009.  In the
        % 2009 Fluxall file, some columns appear to have data from one
        % instrument prior to 9 July, and from another after 9 July.  These
        % columns appear to have two headers at the top, one for each
        % instrument.  --TWH 

        vars = fluxall.Properties.VarNames;
        
        %CS616 SWC probes
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616.*' );
        if not( isempty( idx_cs616 ) )
            vars( idx_cs616 ) = regexprep( vars( idx_cs616 ), ...
                                           'cs616_', 'cs616SWC_' );
            vars( idx_cs616 ) = replace_hex_chars( vars( idx_cs616 ) );
            vars( idx_cs616 ) = format_probe_strings( vars( idx_cs616 ) );
        end
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), ...
                                           '[sS]oilT', 'soilT' );
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), '_Avg$', '' );
            vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
            vars( idx_Tsoil ) = format_probe_strings( vars( idx_Tsoil ) );
        end
        
        %TCAV
        [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = format_probe_strings( vars( idx_TCAV ) );
        end
        
        fluxall.Properties.VarNames = genvarname( vars );
      
      case { 2010, 2011, 2012, 2013 } %RJL added 2013 02/04/2014
        % echo SWC probes
        vars = fluxall.Properties.VarNames;
        [ ~, idx_echo ] = regexp_header_vars( fluxall, 'SWC.*' );
        vars( idx_echo ) = strrep( vars( idx_echo ), 'SWC', 'echoSWC' );
        vars( idx_echo ) = replace_hex_chars( vars( idx_echo ) );
        vars( idx_echo ) = format_probe_strings( vars( idx_echo ) );
        
        %CS616 SWC probes
        [ ~, idx_cs616 ] = regexp_header_vars( fluxall, 'cs616.*' );
        if not( isempty( idx_cs616 ) )
            vars( idx_cs616 ) = cs616_descriptive_labels_postJul09;
            vars( idx_cs616 ) = replace_hex_chars( vars( idx_cs616 ) );
            vars( idx_cs616 ) = format_probe_strings( vars( idx_cs616 ) );
        end
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_header_vars( fluxall, 'SoilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), ...
                                           'SoilT', 'soilT' );
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), '_Avg', '' );
            vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
            vars( idx_Tsoil ) = format_probe_strings( vars( idx_Tsoil ) );
        end
                    
        %TCAV
        [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = format_probe_strings( vars( idx_TCAV ) );
        end
        
        % soil heat flux
        [ ~, idx_shf ] = regexp_header_vars( fluxall, 'shf' );
        if ~isempty( idx_shf )
            vars( idx_shf ) = replace_hex_chars( vars( idx_shf ) );
            vars( idx_shf ) = format_probe_strings( vars( idx_shf ) );
        end
        
        fluxall.Properties.VarNames = vars;
        
    end   % switch JSav year
    
    % --------------------------------------------------
  case UNM_sites.PJ
    % note that PJ and PJ girdle do not report soil moisture or soil T in
    % their FluxAll files (except for 2008 ), so their soil data are parsed separately.
    switch year
      case 2008
        
        [ ~, idx_echo ] = regexp_header_vars( fluxall, 'echo.*' );
        swc_vars = arrayfun( @(x) { sprintf( 'echoSWC_%d', x ) }, ...
                             1:numel( idx_echo ) );
        fluxall.Properties.VarNames( idx_echo ) = swc_vars;
        fluxall.Properties.VarNames( idx_echo ) = ...
            strrep( fluxall.Properties.VarNames( idx_echo ), ...
                    'SWC', 'echoSWC' );
    end
    TCAV_labels.labels = { 'TCAV_pinon_1_Avg', 'TCAV_juniper_1_Avg' };

    % --------------------------------------------------

  case UNM_sites.PPine

    % PPine soil water content is in another file, parsed separately from
    % UNM_Ameriflux_prepare_soil_met.m
    switch year
        case { 2009, 2010, 2011 }
            [ ~, idx_soilT ] = regexp_header_vars( fluxall, 'T107.*' );
            if isempty( idx_soilT )
                [ ~, idx_soilT ] = regexp_header_vars( fluxall, 'soilT.*' );
                if isempty( idx_soilT )
                    error( ['no soil temperature found (expecting ' ...
                        'soilT_ponderosa_X_Y'] );
                end
            else
                fluxall.Properties.VarNames( idx_soilT ) = ...
                    { 'soilT_ponderosa_1_5', ...
                    'soilT_ponderosa_2_5', ...
                    'soilT_ponderosa_3_5', ...
                    'soilT_ponderosa_4_5', ...
                    'soilT_ponderosa_5_5', ...
                    'soilT_ponderosa_6_5', ...
                    'soilT_ponderosa_7_5', ...
                    'soilT_ponderosa_8_5', ...
                    'soilT_ponderosa_9_5', ...
                    'soilT_ponderosa_10_5', ...
                    'soilT_ponderosa_11_5', ...
                    'soilT_ponderosa_12_5' };
            end
            
            [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV.*' );
            if ~isempty( idx_TCAV )
                fluxall.Properties.VarNames{ idx_TCAV } = 'TCAV_ponderosa_1';
            end
            
    end
    
  case UNM_sites.MCon
    
    % MCon soil water content is in another file, parsed separately from
    % UNM_Ameriflux_prepare_soil_met.m
    [ ~, idx_soilT ] = regexp_header_vars( fluxall, 'T107.*' );
    if not( isempty( idx_soilT ) )
        fluxall.Properties.VarNames( idx_soilT ) = ...
            { 'soilT_mcon_1_5', ...
              'soilT_mcon_2_5', ...
              'soilT_mcon_3_5', ... 
              'soilT_mcon_4_5' };
    end
    
    [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV.*' );
    if ~isempty( idx_TCAV )
        fluxall.Properties.VarNames{ idx_TCAV } = 'TCAV_mcon_1';
    end
    
  case UNM_sites.New_GLand  % unburned grass
    
    [ ~, idx_cs616 ] = regexp_header_vars( fluxall, '(Soilwcr.*|cs616.*)' );
    swc_vars = fluxall.Properties.VarNames( idx_cs616 );
    swc_vars = strrep( swc_vars, 'Soilwcr', 'cs616SWC' );
    swc_vars = replace_hex_chars( swc_vars );
    swc_vars = format_probe_strings( swc_vars );
    fluxall.Properties.VarNames( idx_cs616 ) = swc_vars;
    
    [ ~, idx_soilT ] = regexp_header_vars( fluxall, 'SoilT.*' );
    T_vars = fluxall.Properties.VarNames( idx_soilT );
    T_vars = regexprep( T_vars, 'SoilT', 'soilT' );
    T_vars = regexprep( T_vars, '_Avg$', '' );
    T_vars = replace_hex_chars( T_vars );
    T_vars = format_probe_strings( T_vars );
    fluxall.Properties.VarNames( idx_soilT ) = T_vars;
    
    vars = fluxall.Properties.VarNames;
    [ ~, idx_TCAV ] = regexp_header_vars( fluxall, 'TCAV' );
    vars( idx_TCAV ) = regexprep( vars( idx_TCAV ), '_Avg', '_1' );
    fluxall.Properties.VarNames = vars;

end
    

%==================================================
