function ds_out = UNM_assign_soil_data_labels_JSav09( ds_in )
% UNM_ASSIGN_SWC_DATA_LABELS_JSAV09 - assigns labels to JSav 2009 fluxall
% file soil variables.
%   
% The datalogger labels for JSav's soil probes changed substantially in July
% 2009.  This assigns descriptive labels to the soil variables on either side
% of the change.
%
% Labels are of the format soilT_cover_index_depth_*, where cover, index, and
% depth are character strings.  e.g. "soilT_O_2_12.5_avg" denotes cover type
% open, index (pit) 2, and depth of 12.5 cm.  Depth is followed by an
% underscore, and then optional arbitrary text.
%
% USAGE:  
%    ds_out = UNM_assign_soil_data_labels_JSav09( ds_in )
%
% INPUTS:
%    ds_in: dataset array; parsed FLUXALL data (probably output of
%        UNM_parse_fluxall_txt_file or UNM_parse_fluxall_xls_file 
%
% OUTPUTS
%    ds_out: dataset array; ds_in with soil variable labels updated.
%
% SEE ALSO
%    dataset, UNM_parse_fluxall_txt_file, UNM_parse_fluxall_xls_file
%
% author: Timothy W. Hilton, UNM, December 2012


soilT_descriptive_labels_preJul09 = { 'soilT_open_1_5', 'soilT_open_1_10', ...
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
                    'cs616SWC_juniper_1_12p5', 'cs616SWC_juniper_1_32p5', ...
                    'cs616SWC_juniper_2_2p5', 'cs616SWC_juniper_2_12p5', ...
                    'cs616SWC_juniper_2_32p5', 'cs616SWC_juniper_3_2p5', ...
                    'cs616SWC_juniper_3_12p5', 'cs616SWC_juniper_3_32p5', ...
                    'cs616SWC_open_1_2p5', 'cs616SWC_open_1_12p5', ...
                    'cs616SWC_open_1_32p5', 'cs616SWC_open_2_2p5', ...
                    'cs616SWC_open_2_12p5', 'cs616SWC_open_2_32p5', ...
                    'cs616SWC_open_3_2p5', 'cs616SWC_open_3_12p5', ...
                    'cs616SWC_open_3_32p5' };

vars = ds_in.Properties.VarNames;

% assign descriptive labels based on the number of cs616 probes detected.
[ cs616_vars, idx_cs616 ] = regexp_header_vars( ds_in, 'cs616.*' );
if numel( cs616_vars ) == 16
    vars( idx_cs616 ) = cs616_descriptive_labels_preJul09( : ); 
elseif numel( cs616_vars ) == 18
    vars( idx_cs616 ) = cs616_descriptive_labels_postJul09( : ); 
else
    err_msg = sprintf( [ 'JSav 2009 should have 16 cs616 probes prior to 9 ' ...
                        'Jul 2009 and 18 cs616 probes beginning 9 Jul 2009.  ' ...
                        '%d cs616 probes were detected' ], ...
                       numel( idx_cs616 ) );
    error( err_msg );
end

% assign descriptive labels to soil T for first half of 2009
[ ~, idx_Tsoil_preJul09 ] = regexp_header_vars( ds_in, '[sS]oilT_Avg' );
if ~isempty( idx_Tsoil_preJul09 )
    vars( idx_Tsoil_preJul09 ) = soilT_descriptive_labels_preJul09( : );
end
% format all probe names into strings describing cover, depth, etc.
[ ~, idx_Tsoil ] = regexp_header_vars( ds_in, '[sS]oilT' );
if not( isempty( idx_Tsoil ) )
    vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), '[sS]oilT', 'soilT' );
    vars( idx_Tsoil ) = regexprep( vars( idx_Tsoil ), '_Avg$', '' );
    vars( idx_Tsoil ) = replace_hex_chars( vars( idx_Tsoil ) );
    vars( idx_Tsoil ) = format_probe_strings( vars( idx_Tsoil ) );
end


ds_in.Properties.VarNames = vars;

ds_out = ds_in;
    
