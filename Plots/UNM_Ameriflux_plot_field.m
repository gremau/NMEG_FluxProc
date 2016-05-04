function h = UNM_Ameriflux_plot_field( tbl_in, field, year )
% UNM_AMERIFLUX_PLOT_FIELD - create a new figure window; plot one field of an
% ameriflux dataset against day of year.
%   
% h = UNM_Ameriflux_plot_field( tbl_in, field );
%
% INPUTS
%   tbl_in: matlab dataset; the Ameriflux data
%   field: character string; the field to be plotted (from among
%       tbl_in.Properties.VarNames) 
%   year: the year (for plot labels)
%
% OUTPUTS
%   h: handle to the figure window created
%
% SEE ALSO
%   table
%
% author: Timothy W. Hilton, UNM, January 2012
    
    h = figure( 'Visible', 'off' );
    var_idx = find( strcmp( tbl_in.Properties.VariableNames, field ) );
    
    % draw the Greek character mu where 'mu' appears in the units
    this_units = tbl_in.Properties.VariableUnits{ var_idx };
    this_units = strrep( this_units, 'mu', '\mu' );
    this_units = strrep( this_units, 'm2', 'm^2' );
    field_label = regexprep( field , '([0-9])p([0-9])', '$1\.$2');
    field_label = strrep( field_label, '_', '\_' );
    
    plot( tbl_in.DTIME, tbl_in.( field ), '.k' );
    xlim( [ 1, 367 ] );
    xlabel( sprintf( '%d day of year', year ) );
    ylabel( sprintf( '%s, [ %s ]', field_label, this_units ) );
    