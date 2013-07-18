function cleaned = clean_data_by_hand( data_in )
% CLEAN_DATA_BY_HAND - 
%   

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

