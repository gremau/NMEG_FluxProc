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
[ ~, idx_SHF ] = regexp_ds_vars( fluxall, re_SHF );
SHF_vars = fluxall.Properties.VarNames( idx_SHF );

switch sitecode
  case UNM_sites.GLand
    % all GLand years should have two SHF observations (grass and open)    
    if numel( idx_SHF ) ~= 2
        error( 'unable to locate 2 SHF measurements, GLand 2007' );
    end
    switch year
      case 2007
            fluxall.Properties.VarNames( idx_SHF ) = ...
                { 'SHF_grass_1', 'SHF_open_1' }';
        
      case 2008
        fluxall.Properties.VarNames( idx_SHF ) = ...
            { 'SHF_open_1', 'SHF_grass_1' }';
        
      case { 2009, 2010, 2011, 2012 }
        % these SHF variables are labeled "hfp01_COVER_Avg" -- reformat these to
        % SHF_COVER_1       
        SHF_vars = regexprep( SHF_vars, 'hfp01', 'SHF' );
        SHF_vars = regexprep( SHF_vars, '_Avg', '_1' );
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
    SHF_vars = regexprep( SHF_vars, ...
                          { 'shf_Avg.*1.*', 'shf_Avg.*2.*', ...
                        'shf_Avg.*3.*', 'shf_Avg.*4.*' }, ...
                          { 'SHF_open_1', 'SHF_open_2', ...
                        'SHF_edge_1', 'SHF_juniper_1'  }, ...
                          'once' );
    fluxall.Properties.VarNames( idx_SHF ) = SHF_vars;
    
  case UNM_sites.PJ
    % capitalize "shf" and remove trailing "_Avg" 
    SHF_vars = regexprep( SHF_vars, { 'shf', '_Avg' },  { 'SHF', '' } );

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
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616' );

        % the two 52.5 cm observations to not actually exist (conversation
        % with Marcy, 26 Apr 2012) --TWH
        idx_to_remove = idx_cs616( [ 17, 22, 23 ] );
        idx_cs616 = idx_cs616( [ 1:16, 18:21 ] );

        fluxall.Properties.VarNames( idx_cs616 ) = descriptive_cs616_labels;
        fluxall( :, idx_to_remove ) = [];
      
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
        fluxall.Properties.VarNames( idx_TCAV ) = ...
            { 'TCAV_open_Avg', 'TCAV_cover_Avg' };

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
                        'cs616SWC_juniper_1_22p5', 'cs616SWC_juniper_2_2p5', ...
                        'cs616SWC_juniper_2_12p5', ...
                        'cs616SWC_juniper_2_22p5', 'cs616SWC_juniper_3_2p5', ...
                        'cs616SWC_juniper_3_12p5', ...
                        'cs616SWC_juniper_3_22p5', 'cs616SWC_open_1_2p5', ...
                        'cs616SWC_open_1_12p5', 'cs616SWC_open_1_22p5', ...
                        'cs616SWC_open_2_2p5', 'cs616SWC_open_2_12p5', ...
                        'cs616SWC_open_2_22p5', 'cs616SWC_open_3_2p5', ...
                        'cs616SWC_open_3_12p5', 'cs616SWC_open_3_22p5' };
    
    switch year
      case 2007
        vars = fluxall.Properties.VarNames;
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'VWC.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_preJul09;
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = soilT_descriptive_labels_2008;
        end
        
        
        warning( 'temperature data not yet labeled for JSav 2007' );
        
      case 2008 
        vars = fluxall.Properties.VarNames;
        
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_preJul09;

        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, '[sS]oilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = soilT_descriptive_labels_2008;
        end

        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
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
            vars = format_probe_strings( vars );
        end

        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = format_probe_strings( vars( idx_TCAV ) );
        end

        fluxall.Properties.VarNames = genvarname( vars );
        
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
        vars( idx_echo ) = format_probe_strings( vars( idx_echo ) );
        
        %CS616 SWC probes
        [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'cs616.*' );
        vars( idx_cs616 ) = cs616_descriptive_labels_postJul09;
        vars( idx_cs616 ) = replace_hex_chars( vars( idx_cs616 ) );
        vars( idx_cs616 ) = format_probe_strings( vars( idx_cs616 ) );
        
        %soil T
        [ ~, idx_Tsoil ] = regexp_ds_vars( fluxall, 'SoilT_' );
        if ~isempty( idx_Tsoil )
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), ...
                                           'SoilT', 'soilT' );
            vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), '_Avg', '' );
            vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
            vars( idx_Tsoil ) = format_probe_strings( vars( idx_Tsoil ) );
        end
                    
        %TCAV
        [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
        if ~isempty( idx_TCAV )
            vars( idx_TCAV ) = replace_hex_chars( vars( idx_TCAV ) );
            vars( idx_TCAV ) = format_probe_strings( vars( idx_TCAV ) );
        end
        
        % soil heat flux
        [ ~, idx_shf ] = regexp_ds_vars( fluxall, 'shf' );
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

  case UNM_sites.MCon
    
    % MCon soil water content is in another file, parsed separately from
    % UNM_Ameriflux_prepare_soil_met.m
    [ ~, idx_soilT ] = regexp_ds_vars( fluxall, 'T107.*' );
    fluxall.Properties.VarNames( idx_soilT ) = ...
        { 'soilT_mcon_1_5', ...
          'soilT_mcon_2_5', ...
          'soilT_mcon_3_5', ... 
          'soilT_mcon_4_5' };
    
    [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV.*' );

    fluxall.Properties.VarNames{ idx_TCAV } = 'TCAV_mcon_1';
    
  case UNM_sites.New_GLand  % unburned grass
    
    [ ~, idx_cs616 ] = regexp_ds_vars( fluxall, 'Soilwcr.*' );
    swc_vars = fluxall.Properties.VarNames( idx_cs616 );
    swc_vars = strrep( swc_vars, 'Soilwcr', 'cs616SWC' );
    swc_vars = replace_hex_chars( swc_vars );
    swc_vars = format_probe_strings( swc_vars );
    fluxall.Properties.VarNames( idx_cs616 ) = swc_vars;
    
    [ ~, idx_soilT ] = regexp_ds_vars( fluxall, 'SoilT.*' );
    T_vars = fluxall.Properties.VarNames( idx_soilT );
    T_vars = regexprep( T_vars, 'SoilT', 'soilT' );
    T_vars = regexprep( T_vars, '_Avg$', '' );
    T_vars = replace_hex_chars( T_vars );
    T_vars = format_probe_strings( T_vars );
    fluxall.Properties.VarNames( idx_soilT ) = T_vars;
    
    vars = fluxall.Properties.VarNames;
    [ ~, idx_TCAV ] = regexp_ds_vars( fluxall, 'TCAV' );
    vars( idx_TCAV ) = regexprep( vars( idx_TCAV ), '_Avg', '_1' );
    fluxall.Properties.VarNames = vars;

end
    

%==================================================
function str_out = format_probe_strings( str_in )
% FORMAT_PROBE_STRINGS - format "J3", "O2", etc. desinations to "J_3",
% "O_2", etc.

% open pits are usually designated with "O", but sometimes 'o' or '0'
str_out = regexprep( str_in, '_[Oo0]([0-9])_', '_O_$1_' );
% grass pits are usually designated with "g"
str_out = regexprep( str_out, '_g([0-9])_', '_G_$1_' );
% add separating underscore to J1, etc. probe designations
str_out = regexprep( str_out, '_([GJO])([0-9])_', '_$1_$2_' );
% remove any parens that made it this far
str_out = regexprep( str_out, '[\(\)]', '_' );
% remove trailing underscores
str_out = regexprep( str_out, '_$', '' );
% change decimal points to "p" (for legal Matlab variable names)
str_out = regexprep( str_out, '([0-9])\.([0-9])', '$1p$2' );
% change _O_ to _open_, _J_ to _juniper_, _G_ to _grass_
str_out = regexprep( str_out, '_O_', '_open_' );
str_out = regexprep( str_out, '_J_', '_juniper_' );
str_out = regexprep( str_out, '_G_', '_grass_' );