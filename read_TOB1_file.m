function ds = read_TOB1_file( fname )
% READ_TOB1_FILE - reads data from a Campbell Scientific table-oriented binary
% file (TOB1).
%
% returns the data in a dataset array.
%
% USAGE
%     ds = read_TOB1_file( fname );
%
% INPUTS: 
%     fname: character string; full path of TOB1 file to be read.
%
% OUTPUTS
%     ds: dataset array; the data from the TOB1 file
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, October 2011, based on code modified by Krista
%     Anderson-Teixeira in January 2008

[ ~, file_name_only, file_ext ] = fileparts( fname );

%fprintf( 1, 'reading %s%s\n', file_name_only, file_ext );
fprintf( 1, '.', file_name_only, file_ext );

fid=fopen( fname,'r','ieee-le' ); % file ID
if fid == -1
    err = MException( 'UNM_data_processor', ...
                      'cannot open file %s\n', fname );
    throw( err );
end

% ----  process TOB1 file header ----

headerlines = cell( 5,1 );
for i=1:5
    this_line = fgetl( fid );
    headerlines{ i } = strrep( this_line, '"', '' );
end

% split header lines into tokens delimited by commas
var_names = regexp( headerlines{ 2 }, ',', 'split' );
var_units = regexp( headerlines{ 3 }, ',', 'split' );
var_types = regexp( headerlines{ 5 }, ',', 'split' );

% ignore parenthesized portions of variable names
var_names = regexp( var_names, '\(', 'split' );
var_names = cellfun( @(x) x{1}, var_names, 'UniformOutput', false );
var_names = genvarname( var_names );

% ---- process TOB1 file data ----

% file pointer is now at the end of the header / beginning of the data.  record
% that position so we can return here to read each variable successively.
data_start = ftell( fid );

% Nbytes_map = struct ( 'ULONG', 4, 'IEEE4', 4, 'IEEE4L', 4, 'SecNano', 4 );
% matlab_type_map =  struct ( 'ULONG', 'uint32',...
%                           'IEEE4', 'float32',...
%                           'IEEE4L', 'float32',...
%                           'SecNano', 'uint32' );

% var_nbytes = cellfun ( @ ( x ) getfield ( Nbytes_map, x ), var_types );
% var_byte_offset = cumsum ( var_nbytes );
% var_matlab_type = cellfun ( @ ( x ) getfield ( matlab_type_map, x ), var_types );

% Calculate the number of bytes in a record and set the corresponding matlab
% precision
for i=1:length( var_names )
    if strcmp( char ( var_types ( i ) ),'ULONG' )
        var_nbytes( i ) = 4;
        var_matlab_type{ i } ='uint32';
    elseif  strcmp( char ( var_types ( i ) ),'IEEE4' )
        var_nbytes( i ) = 4;
        var_matlab_type{ i } ='float32';
    elseif strcmp( char ( var_types ( i ) ),'IEEE4L' )
        var_nbytes( i ) = 4;
        var_matlab_type{ i } = 'float32';
    elseif strcmp( char ( var_types ( i ) ),'SecNano' )
        var_nbytes( i ) = 4;
        var_matlab_type{ i } ='uint32';
    end       
end
%calculate number of bytes from the beginning of the record to the start
%of each variable
var_byte_offset = [0, cumsum( var_nbytes( 2:end ) )];

ds = dataset(  );  %dataset to contain data read from file
for this_var = 1:length( var_names )
    status = fseek( fid, data_start + var_byte_offset( this_var ), 'bof' );
    % don't want to skip an entire record - want to skip from END of this
    % record's this_var to the BEGINNING of the next record's this_var 
    bytes_to_skip = sum( var_nbytes ) - var_nbytes( this_var );
    ds.( var_names{ this_var } ) = ...
        fread( fid, inf, var_matlab_type{ this_var }, bytes_to_skip );
end

%done reading the input file now
fclose( fid );

ds.Properties.Units = var_units;
% convert centigrade to Kelvins
ds.Ts = ds.Ts + 273.15;
ds.Properties.Units{ strcmp( ds.Properties.VarNames, 'Ts' ) } = 'K';
% convert CO2 from mg/m3 to mmol / m3
ds.co2 = ds.co2 / 44.0;
ds.Properties.Units{ strcmp( ds.Properties.VarNames, 'co2' ) } = 'mmol/m^3';
% convert H2O from mg/m3 to mmol / m3
ds.h2o = ds.h2o / 0.018;
ds.Properties.Units{ strcmp( ds.Properties.VarNames, 'h2o' ) } = 'mmol/m^3';

% remove unneeded columns
keep = intersect( ds.Properties.VarNames, ...
                  { 'SECONDS', 'NANOSECONDS', 'Ux', 'Uy', 'Uz', 'co2', ...
                    'h2o', 'Ts', 'press', 'diag_csat' } );
ds = ds( :, keep );