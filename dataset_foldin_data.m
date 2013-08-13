function ds_out = dataset_foldin_data( ds_in1, ds_in2 )
% DATASET_FOLDIN_DATA - "folds in" data from a second dataset array into a
% first, by timestamp.  
%
% The resulting merged dataset contains all variables that are present in either
% input.  Where a variable is NaN in ds_in1 but has valid data in ds_in2, the
% non-NaN value is kept.  Where a variable is non-NaN in both, the value from
% ds_in1 is kept.  Both datasets must contain a 'timestamp' variable of matlab
% serial datenumbers.  Timestamps within two minutes of each other are
% considered equal.  This function was created for (and tested on) 30-minute
% data, but should in concept work for timeseries data with any observation
% interval greater than two minutes.
%
% USAGE
%
% ds_out = dataset_foldin_data( ds_in1, ds_in2 )
%
% INPUTS:
%   ds_in1, ds_in2: matlab dataset arrays
%
% OUTPUTS:
%   dataset array containing all data from ds_in1 and ds_in2 as described above.
%
% SEE ALSO
%   dataset, datenum
%
% author: Timothy W. Hilton, UNM, Dec 2012

% -----
% make sure the two datasets have identical timestamps:
% align 30-minute timestamps and fill in missing timestamps
two_mins_tolerance = 2; % for purposes of joining data, treat timestamps
                        % within two mins of each other as equal
all_t = [ reshape( ds_in1.timestamp, [], 1 ); ...
          reshape( ds_in2.timestamp, [], 1 ) ];
[ ds_in1, ds_in2 ] = ...
    merge_datasets_by_datenum( ds_in1, ...
                               ds_in2, ...
                               'timestamp', ...
                               'timestamp', ...
                               two_mins_tolerance, ...
                               min( all_t ), ...
                               max( all_t ) );

% -----
% for variables that exist in both datasets, replace NaNs in ds_in1 with
% values from ds_in2.  For variables that exist only in ds_in2, copy to ds_out.
ds_out = ds_in1;
for i = 1:numel( ds_in2.Properties.VarNames )
    this_var = ds_in2.Properties.VarNames{ i };
    if ismember( this_var, ds_out.Properties.VarNames );
        data1 = ds_in1.( this_var );
        data2 = ds_in2.( this_var );
        idx = isnan( data1 ) & not( isnan( data2 ) );
        data1( idx ) = data2( idx );
        ds_out.( this_var ) = data1;
    else
        ds_out.( this_var ) = ds_in2.( this_var );
    end
end



