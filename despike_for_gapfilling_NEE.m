function [ fgf, spike_idx ] = ...
    despike_for_gapfilling_NEE( aflx_gf, fgf, DOY0, DOY1, new_max )
% DESPIKE_FOR_GAPFILLING_NEE - normalizes NEE to a new maximum within a
%   specified period of time.  Useful for dampening RE spikes introduced by the
%   gapfiller/partitioner.
%
% USAGE
%   [ fgf, spike_idx ] = despike_for_gapfilling_NEE( aflx_gf, fgf, ...
%                                                    DOY0, DOY1, new_max );
%
% INPUTS
%    aflx_gf: dataset array; gap-filled Ameriflux data.  Would typically be
%        the output of parse_ameriflux_file().
%    fgf: dataset array; the existing for-gapfill datset.   Would typically be
%        the output of parse_forgapfilling_file().
%    DOY0: datenum; the first timestamp to normalize
%    DOY1: datenum; the last timestamp to normalize
%    new_max: numeric; the new maximum RE value.
%
% OUTPUTS
%    fgf: dataset array; new for-gapfilling dataset with NEE normalized and
%       the corresponding NEE QC flags set to "1".
%
% SEE ALSO
%    dataset, datenum, parse_ameriflux_file, parse_forgapfilling_file
%    spike_idx: the indices of observations and QC flags that were normalized
%
% author: Timothy W. Hilton, UNM, Apr 2013

spike_idx = find( aflx_gf.FC_flag & ...
                  ( aflx_gf.DTIME >= DOY0 ) & ...
                  ( aflx_gf.DTIME <= DOY1 ) &...
                  ( aflx_gf.FC > 0 ) );

x = aflx_gf.FC( spike_idx );
x_adj = x * ( new_max / max( x ) );
fgf.NEE( spike_idx ) = x_adj;
% set QC to "good" so that gapfiller does not  overwrite
fgf.qcNEE( spike_idx ) = 1;  


