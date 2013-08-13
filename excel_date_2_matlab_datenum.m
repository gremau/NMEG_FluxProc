function dn = excel_date_2_matlab_datenum(esd)
% EXCEL_DATE_2_MATLAB_DATENUM - convert Microsoft Excel serial date to a Matlab
% serial datenumber.
%
% See
% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s.
%
% dn = excel_date_2_matlab_datenum(esd)
%
% INPUTS
%    esd: MxN array of Excel serial dates
% OUTPUTS
%    dn: MxN array of Matlab datenums
%
% SEE ALSO
%    datenum
%
% Timothy W. Hilton, UNM, January 2012
    
    
% convert the serial date as per
% http://www.mathworks.com/help/techdoc/import_export/f5-100860.html#br0xp1s
    dn = esd + datenum( '30-Dec-1899' );
