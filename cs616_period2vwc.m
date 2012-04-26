function [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil )
% CS616_PERIOD2VWC - apply Campbell Scientific CS616 conversion equation to
% convert cs616 period (in microseconds) to volumetric water content
% (fraction).  Returns temperature-corrected and non-temperature-corrected
% VWC. 
%
% USAGE:
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc )
% INPUTS:
%    raw_swc: N by M matrix of soil water content raw data (microseconds)
%    T_soil: N by 1 matrix of soil temperature (C -- check this TWH )
% OUTPUTS:
%    vwc: N by M matrix of non-temperature-corrected SWC
%    vwc_Tc: N by M matrix of temperature-corrected SWC
%
% (c) Timothy W. Hilton, UNM, Apr 2012

swc_is_ds = isa( raw_swc, 'dataset' );
if swc_is_ds
    raw_swc_input = raw_swc;
    raw_swc = double( raw_swc );
end

% make sure T_soil is an array of doubles
T_soil = double( T_soil );

% -----
% perform the conversion and temperature correction
% -----

% non-temperature corrected: apply equation () from CS616 manual
vwc = repmat( -0.0663, ( size( raw_swc ) ) ) - ...
      0.00636 .* raw_swc + ...
      0.0007 .* ( raw_swc .* raw_swc );

raw_swc_Tc_2 = ( 0.526 - ( 0.052 .* raw_swc ) + ...
                 ( 0.00136 .* ( raw_swc .* raw_swc ) ) );

% if T_soil contains a single measurement, use it at all depths
if size( T_soil, 2 ) == 1
    T_soil = repmat( ( 20 - T_soil ), 1, size( raw_swc, 2 ) );
end

raw_swc_Tc = ( raw_swc + T_soil ) .* raw_swc_Tc_2;

vwc_Tc = repmat( -0.0663, ( size( raw_swc_Tc ) ) ) - ...
         0.00636 .* raw_swc_Tc + ...
         0.0007 .* ( raw_swc_Tc .* raw_swc_Tc );

% Remove any negative SWC values
vwc( vwc < 0 ) = nan;
vwc( vwc > 1 ) = nan;
vwc_Tc( vwc_Tc < 0 ) = nan;
vwc_Tc( vwc_Tc > 1 ) = nan;

% if inputs were datasets, keep the same variable names an replace the values
% with the VWC and T-corrected VWC
if swc_is_ds
    vwc = replacedata( raw_swc_input, vwc );
    vwc_Tc = replacedata( raw_swc_input, vwc_Tc );
end

