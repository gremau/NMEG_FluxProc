function fluxall = UNM_assign_soil_data_labels( sitecode, year, fluxall )

% UNM_ASSIGN_SOIL_DATA_LABELS - assign labels to soil measurements.
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
%   fluxall: matlab dataset object; parsed fluxall.xls data
%
% OUTPUTS
%   fluxall: matlab dataset object; fluxall.xls data with relabeled soil data
%       columns
%
% (c) Timothy W. Hilton, UNM, May-July 2012

if ~isa( sitecode, 'UNM_sites' )
    sitecode = UNM_sites( sitecode );
end

placeholder = 0;
labels_template = struct( 'labels', { 'placeholder' }, ...
                          'columns', [ placeholder ] );
echo_SWC_labels = labels_template;
cs616_SWC_labels = labels_template;
soilT_labels = labels_template;
TCAV_labels = labels_template;

% regular expression to identify strings containing 'shf' or 'hfp',
% case-insensitive
re_SHF = '.*([Ss][Hh][Ff]).*|.*([Hh][Ff][Pp]).*';

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
                        'soilT_cover_1_2p5', ...
                        'soilT_cover_1_12p5', ...
                        'soilT_cover_1_22p5', ...
                        'soilT_open_2_2p5', ...
                        'soilT_open_2_12p5', ...
                        'soilT_open_2_22p5', ...
                        'soilT_cover_2_2p5', ...
                        'soilT_cover_2_12p5', ...
                        'soilT_cover_2_22p5', ...
                        'soilT_open_3_2p5', ...
                        'soilT_open_3_12p5', ...
                        'soilT_open_3_22p5', ...
                        'soilT_open_3_37p5', ... 
                        'soilT_cover_3_2p5', ...
                        'soilT_cover_3_12p5', ...
                        'soilT_cover_3_22p5', ...
                        'soilT_cover_3_37p5' }; 

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

    % make sure there are two SHF measurements
    [ ~, idx_SHF ] = regexp_ds_vars( fluxall, re_SHF );
    if numel( idx_SHF ) ~= 2
        error( 'unable to locate 2 SHF measurements, GLand 2007' );
    else
    
    switch year
        
      case { 2007, 2008 }
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616' );

        % the two 52.5 cm observations to not actually exist (conversation
        % with Marcy, 26 Apr 2012) --TWH
        idx_to_remove = idx_cs616( [ 17, 22, 23 ] );
        idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        fluxall( :, idx_to_remove ) = [];
        

        fluxall.Properties.VarNames( idx_SHF ) = { 'SHF_grass', 'SHF_open' }';
        warning( [ 'check to make sure that GLand 2008 SHF vars are in ' ...
                  'correct order' ] );
      
      case { 2009, 2010 }
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616' );

        % the two 52.5 cm observations to not actually exist (conversation
        % with Marcy, 26 Apr 2012) --TWH
        idx_to_remove = idx_cs616( [ 17, 22 ] );
        idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        
        fluxall( :, idx_to_remove ) = [];

        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'mux25t' );
        fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;

        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV|tcav' );
        TCAV_labels.labels = { 'TCAV_open_Avg', 'TCAV_cover_Avg' };
        
        fluxall.Properties.VarNames( idx_SHF ) = ...
            regexprep( fluxall.Properties.VarNames( idx_SHF ), ...
                       { 'hfp01', '_Avg' }, { 'SHF_', '' } );

      case 2011
        % this year cs616 SWC are labeled open1_12.5, grass2_2.5, etc.  They
        % are in columns 203 to 222
        re = '^(open|grass)[12]_[0-9]{1,2}p5cm';  % regular expression to
                                                  % identify cs616 labels
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, re );
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
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'mux25t' );
        fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        
        fluxall.Properties.VarNames( idx_SHF ) = ...
            regexprep( fluxall.Properties.VarNames( idx_SHF ), ...
                       { 'hfp01', '_Avg' }, { 'SHF_', '' } );
        
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
    
    descriptive_soilT_labels = { 'soilT_bare_1_2p5', 'soilT_bare_1_12p5', ...
                        'soilT_bare_1_22p5', 'soilT_bare_1_37p5', ...
                        'soilT_bare_1_52p5', 'soilT_cover_1_2p5', ...
                        'soilT_cover_1_12p5', 'soilT_cover_1_22p5', ...
                        'soilT_cover_1_37p5', 'soilT_cover_1_52p5', ...
                        'soilT_bare_2_2p5', 'soilT_bare_2_12p5', ...
                        'soilT_bare_2_22p5', 'soilT_bare_2_37p5', ...
                        'soilT_bare_2_52p5', 'soilT_cover_2_2p5', ...
                        'soilT_cover_2_12p5', 'soilT_cover_2_22p5', ...
                        'soilT_cover_2_37p5', 'soilT_cover_2_52p5' };
    
    switch year
      case { 2007, 2008, 2009, 2010 }
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616_wcr.*' );
        fluxall.Properties.VarNames( idx_cs616( 1:20 ) ) = ...
            descriptive_cs616_labels;
        fluxall( :, idx_cs616( 21:end ) )  = [];
        
        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'mux25t' );
        if ~isempty( idx_Tsoil )
            fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        end

      case 2011
        % change soil_h2o... labels to descriptive SWC labels
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'soil_h2o_.*_Avg' );
        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        
        % change mux25t... labels to descriptive soilT labels
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'mux25t' );
        if ~isempty( idx_Tsoil )
            fluxall.Properties.VarNames( idx_Tsoil ) = descriptive_soilT_labels;
        end
        
    end    % switch SLand year
    
    % --------------------------------------------------
  case UNM_sites.JSav
    
    cs616_descriptive_labels_preJul09 = { 'cs616SWC_open_1_5', ...
                            'cs616SWC_open_1_10', 'cs616SWC_open_1_20', ...
                            'cs616SWC_open_1_40', 'cs616SWC_open_2_5', ...
                            'cs616SWC_open_2_10', 'cs616SWC_open_2_20', ...
                            'cs616SWC_open_2_40', 'cs616SWC_edge_1_5', ...
                            'cs616SWC_edge_1_10', 'cs616SWC_edge_1_20', ...
                            'cs616SWC_edge_1_40', 'cs616SWC_canopy_1_5', ...
                            'cs616SWC_canopy_1_10', 'cs616SWC_canopy_1_20', ...
                            'cs616SWC_canopy_1_40' };
    
    cs616_descriptive_labels_postJul09 = { 'cs616SWC_J_1_2p5', ...
                        'cs616SWC_J_1_12p5', 'cs616SWC_J_1_22p5', ...
                        'cs616SWC_J_2_2p5', 'cs616SWC_J_2_12p5', ...
                        'cs616SWC_J_2_22p5', 'cs616SWC_J_3_2p5', ...
                        'cs616SWC_J_3_12p5', 'cs616SWC_J_3_22p5', ...
                        'cs616SWC_O_1_2p5', 'cs616SWC_O_1_12p5', ...
                        'cs616SWC_O_1_22p5', 'cs616SWC_O_2_2p5', ...
                        'cs616SWC_O_2_12p5', 'cs616SWC_O_2_22p5', ...
                        'cs616SWC_O_3_2p5', 'cs616SWC_O_3_12p5', ...
                        'cs616SWC_O_3_22p5' };
    
    switch year
      case 2007
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'VWC.*' );
        fluxall.Properties.VarNames( idx_cs616 ) = ...
            cs616_descriptive_labels_preJul09;
      case 2008
        vars = fluxall.Properties.VarNames;
        
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_preJul09;

        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), ...
                                           '[sS]oilT_Avg', 'soilT' );
            vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
            vars( idx_Tsoil ) = JSav_format_probe_strings( vars( idx_Tsoil ) );
        end

        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = JSav_format_probe_strings( vars( idx_TCAV ) );
        end

        fluxall.Properties.VarNames = vars;


      case 2009
        % there was a major SWC instrument changeover on 9 Jul 2009.  In the
        % 2009 Fluxall file, some columns appear to have data from one
        % instrument prior to 9 July, and from another after 9 July.  These
        % columns appear to have two headers at the top, one for each
        % instrument.  --TWH 
        jul09 = datenum( 2009, 7, 9 ) - datenum( 2009, 1, 0 );
        
        % pull out pre-July 9 SWC data        
        preJul09 = double( fluxall( :, [ 171:173, 174:176, ...
                            162:164, 177:179 ] ) );
        preJul09 ( DOYidx( jul09 ):end, : ) = NaN;
        
        preJul09 = dataset( { preJul09, ...
                            cs616_descriptive_labels_preJul09{ [1:3, 5:7, ...
                            9:11, 13:15] } } );

        % pull out post-July 9 SWC data
        postJul09 = double( fluxall( :, 162:179 ) );
        postJul09( 1:DOYidx( jul09 ), : ) = NaN;
        postJul09 = dataset( { postJul09, ...
                             cs616_descriptive_labels_postJul09{ : } } );
        
        echo_SWC_labels.columns = 180:197;
        echo_SWC_labels.labels = strrep( cs616_descriptive_labels_postJul09, ...
                                         'cs616SWC', 'echoSWC' );

        vars = fluxall.Properties.VarNames;
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars = regexprep( vars, '[sS]oilT_Avg', 'soilT' );
            vars = replace_hex_chars( vars );
            vars = JSav_format_probe_strings( vars );
        end

        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = JSav_format_probe_strings( vars( idx_TCAV ) );
        end

        fluxall.Properties.VarNames = vars;
        
        % remove fluxall SWC variables and replace with properly-labeled
        % variables defined above, with one probe's measurement in each column.
        fluxall( :, 162:197 ) = [];
        fluxall = [ fluxall, preJul09, postJul09 ];
        
      case { 2010, 2011 }
        % echo SWC probes
        vars = fluxall.Properties.VarNames;
        [ ~, idx_echo ] = regexp_ds_vars( fluxall, 'SWC.*' );
        vars( idx_echo ) = strrep( vars( idx_echo ), 'SWC', 'echoSWC' );
        vars( idx_echo ) = replace_hex_chars( vars( idx_echo ) );
        vars( idx_echo ) = JSav_format_probe_strings( vars( idx_echo ) );
        
        %CS616 SWC probes
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_postJul09;
        vars( idx_cs616 ) = replace_hex_chars( vars( idx_cs616 ) );
        vars( idx_cs616 ) = JSav_format_probe_strings( vars( idx_cs616 ) );
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'SoilT_' );
        if ~isempty( idx_Tsoil )
            vars = regexprep( vars, 'SoilT', 'soilT' );
            vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
            vars( idx_Tsoil ) = JSav_format_probe_strings( vars( idx_Tsoil ) );
        end
                    
        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = JSav_format_probe_strings( vars( idx_TCAV ) );
        end
        
        % soil heat flux
        [ ~, idx_shf ] = regexp_ds_vars( fluxall, 'shf' );
        if ~isempty( idx_shf )
            vars( idx_shf ) = replace_hex_chars( vars( idx_shf ) );
            vars( idx_shf ) = JSav_format_probe_strings( vars( idx_shf ) );
        end
        
        fluxall.Properties.VarNames = vars;
        
    end   % switch JSav year
    
    % --------------------------------------------------
  case UNM_sites.PJ
    % note that PJ and PJ girdle do not report soil moisture or soil T in
    % their FluxAll files (except for 2008 ), so their soil data are parsed separately.
    switch year
      case 2008
        
        [ ~, idx_echo ] = regexp_ds_vars( fluxall, 'echo.*' );
        swc_vars = arrayfun( @(x) { sprintf( 'echoSWC_%d', x ) }, ...
                             1:numel( idx_echo ) );
        fluxall.Properties.VarNames( idx_echo ) = swc_vars;
        fluxall.Properties.VarNames( idx_echo ) = ...
            strrep( fluxall.Properties.VarNames( idx_echo ), ...
                    'SWC', 'echoSWC' );
    end
    TCAV_labels.labels = { 'TCAV_pinon_1_Avg', 'TCAV_juniper_1_Avg' };

    % --------------------------------------------------
    
  case UNM_sites.New_GLand  % unburned grass
    
    [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'Soilwcr.*' );
    swc_vars = fluxall.Properties.VarNames( idx_cs616 );
    swc_vars = strrep( swc_vars, 'Soilwcr', 'cs616SWC' );
    % replace the 'g' in _g1 or _g2 with "grass_"
    swc_vars = regexprep( swc_vars, '_g([12])', '_grass_$1' );
    % replace the 'o, O, or 0' in e.g. _o1 or _02 with "open_"
    swc_vars = regexprep( swc_vars, '_[oO0]([12])', '_open_$1' );
    %swc_vars = repexprep
    fluxall.Properties.VarNames( idx_cs616 ) = swc_vars;
    
    echo_SWC_labels.columns = []; 
    echo_SWC_labels.labels = {}; 
    
    soilT_labels.columns = [];
    soilT_labels.labels = {};
    
    TCAV_labels.columns = [];
    TCAV_labels.labels = {};

end
    

%==================================================
function str_out = JSav_format_probe_strings( str_in )
% JSAV_FORMAT_PROBE_STRINGS - format "J3", "O2", etc. desinations to "J_3",
% "O_2", etc.

% open pits are usually designated with "O", but sometimes 'o' or '0'
str_out = regexprep( str_in, '_[Oo0]([0-9])_', '_O_$1_' );
% add separating underscore to J1, etc. probe designations
str_out = regexprep( str_out, '_([JO])([0-9])_', '_$1_$2_' );