function data_out = column_inpaint_nans( data_in, method )
% COLUMN_INPAINT_NANS - Applys inpaint_nans to each column of a matrix.
%
% This is a wrapper for John D'Errico's inpaint_nans function.
%
% inpaint_nans is free and open source, and available here (as of Aug 2013):
% http://www.mathworks.com/matlabcentral/fileexchange/4551-inpaintnans
%
% USAGE
%    data_out = column_inpaint_nans( data_in, method );
%
% INPUTS
%   data_in: NxM numeric array containing data to be filled
%   method: integer, 1-6: the inpaint_nans method to use.  See inpaint_nans
%       documentation. 
%
% OUTPUT
%   data_out: the input data with inpaint_nans applied to each column
%
% SEE ALSO
%   inpaint_nans
%
% Timothy W. Hilton, UNM, Aug 2012

data_out = repmat( NaN, size( data_in ) );

for i = 1:size( data_in, 2 )
    data_out( :, i ) = inpaint_nans( data_in( :, i ), method );
end