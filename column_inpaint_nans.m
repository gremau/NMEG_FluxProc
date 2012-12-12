function data_out = column_inpaint_nans( data_in, method )
% COLUMN_INPAINT_NANS - Wrapper for John D'Errico's inpaint_nans function.
% Applys inpaint_nans to each column of a matrix.
%   
% INPUTS
%   data_in: NxM numeric array containing data to be filled
%   method: integer, 1-6: the inpaint_nans method to use.  See inpaint_nans
%       documentation. 
%
% OUTPUT
%   data_out: the input data with inpaint_nans applied to each column
%
% Timothy W. Hilton, UNM, Aug 2012

data_out = repmat( NaN, size( data_in ) );

for i = 1:size( data_in, 2 )
    data_out( :, i ) = inpaint_nans( data_in( :, i ), method );
end