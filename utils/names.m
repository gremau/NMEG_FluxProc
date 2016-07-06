function result = names( ds )
% NAMES - compactly prints the variable names in a dataset array
%   
% USAGE
%    result = names( ds );
%
% INPUTS
%    ds: Matlab dataset array
%
% OUTPUTS
%    result: 0 for success, -1 for failure
%
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, July 2012


result = -1;

if not( isa( ds, 'dataset' ) )
    error( 'argument ds must be a dataset object' );
    return
end

for i = 1:size( ds, 2 )
    fprintf( '%d\t%s\t%s\n', i, ...
             ds.Properties.VarNames{ i }, ...
             replace_hex_chars( ds.Properties.VarNames{ i } ) );
end

result = 0;
