function cleaned = clean_data_by_hand( data_in )
% CLEAN_DATA_BY_HAND - opens a figure window to allow a user to select
% individual data points to remove from each column of a matrix or variable of
% a dataset array.  
%
% Given an input data_in, the first column/variable of data_in is displayed in a
% figure window.  Matlab waits for the user to close the window; when this
% occurs the second column/variable is displayed in a new window.  Matlab
% proceeds like this through every column.
%
% To remove data points: 
% When a plot opens, select "brush" from the "tools" menu.  Clicking on a data
%   point will hilight the point in red.  You may click a drag a box to select
%   multiple data points.  Holding shift while clicking or click-dragging adds
%   the new selection to the previous selection.  When a point or points to
%   remove are selected, right click a selected point and choose "replace with
%   ---> NaNs".  The selected points disappear.  When finished selecting and
%   removing points, drag a box around all the data.  Right click a point and
%   select "Create variable".  Name the variable "this_cleaned" and click OK.
%   Then close the figure window.  Matlab will now replace that column or
%   variable of data_in with this_cleaned, and move on to the next
%   column/variable.  After the last column or variable is selected, Matlab
%   clean_data_by_hand returns the amended data in cleaned.
%
% USAGE
%    cleaned = clean_data_by_hand( data_in );
% 
% INPUTS
%    data_in: numeric matrix or dataset array; the data to be cleaned.  If
%        data_in is a numeric array, each column represents on variable. 
%
% OUTPUTS
%    cleaned: numeric matrix or dataset array (according to what data_in is):
%        data_in with user-selected data points removed.
%
% SEE ALSO
%    brush, dataset
%
% (c) Timothy W. Hilton, UNM, Nov 2012

input_is_dataset = isa( data_in, 'dataset' );
if input_is_dataset
    ds_in = data_in;
    data_in = double( data_in );
end

cleaned = repmat( NaN, size( data_in ) );
n_cols = size( data_in, 2 );

for this_col = 1:n_cols
    this_cleaned = data_in( :, this_col );
    hfig = figure();
    h = plot( data_in( :, this_col ), '.' );
    waitfor( hfig );
    
    if size( this_cleaned, 2 ) == 2
        cleaned( this_cleaned( :, 1 ), this_col ) = this_cleaned( :, 2 );
    else
        cleaned( :, this_col ) = this_cleaned;
    end
end
    
if input_is_dataset
    cleaned = replacedata( ds_in, cleaned );
end

