function [ fgf, spike_idx ] = ...
    despike_for_gapfilling_NEE( aflx_gf, fgf, DOY0, DOY1, new_max )
% DESPIKE_FOR_GAPFILLING_NEE - normalizes the Re component of NEE to a new
%   maximum.  Useful for dampening RE spikes introduced by the
%   gapfiller/partitioner.  
%
% (c) Timothy W. Hilton, UNM, Apr 2013

spike_idx = find( aflx_gf.FC_flag & ...
                  ( aflx_gf.DTIME >= DOY0 ) & ...
                  ( aflx_gf.DTIME <= DOY1 ) &...
                  ( aflx_gf.FC > 0 ) );

x = aflx_gf.FC( spike_idx );
x_adj = x * ( new_max / max( x ) );
fgf.NEE( spike_idx ) = x_adj;
% set QC to "good" so that gapfiller does not  overwrite
fgf.qcNEE( spike_idx ) = 1;  


