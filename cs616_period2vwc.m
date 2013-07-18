function [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil, varargin )
% CS616_PERIOD2VWC - apply Campbell Scientific CS616 conversion equation to
% convert cs616 period (in microseconds) to volumetric water content
% (fraction).  Returns temperature-corrected and non-temperature-corrected
% VWC. 
%
% USAGE:
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil )
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil, draw_plots, 'true' )
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil, ...
%                                        draw_plots, 'true', ...
%                                        'save_plots', true, ...
%                                        'sitecode', sitecode, ...
%                                        'year', year )
% INPUTS:
%    raw_swc: N by M matrix of soil water content raw data (microseconds)
%    T_soil: N by 1 matrix of soil temperature (C -- check this TWH )
% OUTPUTS:
%    vwc: N by M matrix of non-temperature-corrected SWC
%    vwc_Tc: N by M matrix of temperature-corrected SWC
%
% (c) Timothy W. Hilton, UNM, Apr 2012


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'raw_swc', @(x) isnumeric(x) | isa( x, 'dataset' ) );
args.addRequired( 'T_soil',  @(x) isnumeric(x) | isa( x, 'dataset' ) );
args.addParamValue( 'sitecode', ...
                    @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addParamValue( 'year', ...
                    @(x) ( isintval( x ) & ( x >= 2006 ) ) );
args.addParamValue( 'draw_plots', true, @islogical );
args.addParamValue( 'save_plots', false, @islogical );

% parse optional inputs
args.parse( raw_swc, T_soil, varargin{ : } );
raw_swc = args.Results.raw_swc;
T_soil = args.Results.T_soil;

% -----
% convert arguments to double arrays if they were provided as dataset objects
% -----
swc_is_ds = isa( raw_swc, 'dataset' );
if swc_is_ds
    raw_swc_input = raw_swc;
    swc_depths = extract_Tsoil_depths( raw_swc.Properties.VarNames );
    shallow = repmat( false, size( raw_swc ) );
    shallow( :, swc_depths < 10.0 ) = true;
    raw_swc = double( raw_swc );
end

% make sure T_soil is an array of doubles
if isa( T_soil, 'dataset' )
    T_soil = double( T_soil );
end

% -----
% perform the cs616 period conversion and temperature correction
% -----

% some fluxall files have echo SWC (already VWC) and cs616 SWC (cs616 period, in
% microseconds) in the same column.  Valid cs616 periods are larger than about
% 15 microseconds (see cs616 manual figure 4).  This is an approximate filter
% so that we don't apply the cs616 calibration to echo data.
is_cs616 = ( raw_swc > 14.0 );

% non-temperature corrected: apply quadratic form of calibration equation
% (section 6.3, p. 29, CS616 manual)
pd2vwc = @( pd ) repmat( -0.0663, size( pd ) ) - ...
         ( 0.0063 .* pd ) + ...
         ( 0.0007 .* ( pd .* pd ) );

vwc = raw_swc;
vwc( is_cs616 ) = pd2vwc( raw_swc( is_cs616 ) );

% perform temperature correction described in cs616 manual section 6.6 (p 33 )
cs616_period_Tcorrect = @( pd, T )  pd +  ( ( 20 - T ) .* ...
                                            ( 0.526 - ( 0.052 .* pd ) + ...
                                              ( 0.00136 .* pd .* pd ) ) );

vwc_Tc = raw_swc;
n_soil_T = size( T_soil, 2 ); %how many soil T observations?
n_swc = size( raw_swc, 2 );   %how many soil water observations?
if ( n_soil_T == n_swc )
    % if there is a soil T observation for each SWC observation, use each
    % soil T to correct its associated SWC
    vwc_Tc( is_cs616 ) = cs616_period_Tcorrect( raw_swc( is_cs616 ), ...
                                                T_soil( is_cs616 ) );
else
    % if there is only one soil T observation, it is shallow.  In this case
    % only perform T correction for the shallow SWC observations.
    if n_soil_T > 1
        error( sprintf( [ 'Number of soil T observations (%d) ', ...
                          'is greater than one but not equal to the ', ...
                          'number of soil water content obserations (%d)' ], ...
                        n_soil_T, n_swc ) );
    else
        T_soil = repmat( T_soil, 1, n_swc );
        vwc_Tc( is_cs616 & shallow ) = ...
            cs616_period_Tcorrect( raw_swc( is_cs616 & shallow ), ...
                                   T_soil( is_cs616 & shallow ) );
    end
end
vwc_Tc( is_cs616 ) = pd2vwc( vwc_Tc( is_cs616 ) );

% Remove any negative SWC values
vwc( vwc < 0 ) = nan;
vwc( vwc > 1 ) = nan;
vwc_Tc( vwc_Tc < 0 ) = nan;
vwc_Tc( vwc_Tc > 1 ) = nan;


% if inputs were datasets, keep the same variable names and replace the values
% with the VWC and T-corrected VWC
if swc_is_ds
    vwc = replacedata( raw_swc_input, vwc );
    vwc_Tc = replacedata( raw_swc_input, vwc_Tc );
end

if args.Results.draw_plots
    nrow = size( raw_swc, 1 );
    doy = ( 0:nrow-1 ) / 48;
    n_locations = size( raw_swc, 2 );  %how many measurment locations?

    if args.Results.save_plots
        file_name_list = cell( n_locations, 1 );
    end
    
    for  i = 1:n_locations
        h = figure( 'Name', 'SWC T corrections', ...
                    'Units', 'Inches', ...
                    'Position', [ 0, 0, 8.5, 11 ] );
        ax1 = subplot( 4, 1, 1 );
        h_vwc = plot( doy, vwc( :, i ), '.b' );
        hold on
        h_vwc_tc = plot( doy, vwc_Tc( :, i ), 'ok' );
        cov_num_depth = regexp( raw_swc_input.Properties.VarNames{ i }, ...
                                '_', 'split' );
        cov_num_depth = sprintf( 'VWC\\_%s\\_%s\\_%s', ...
                                 cov_num_depth{ 2 }, ...
                                 cov_num_depth{ 3 }, ...
                                 cov_num_depth{ 4 } );
        ylabel( 'VWC' );
        legend( [ h_vwc, h_vwc_tc ], 'not corrected', 'T-corrected', ...
                'Location', 'best' );
        title( regexprep( cov_num_depth, '([0-9])p([0-9])', '$1.$2' ) );
        % % if all is well, all VWC values should be in range [0, 1].  Make the
        % % y-limits of the plot at least this big
        % y_lim = get( ax, 'YLim' );
        % if ( y_lim( 1 ) > 0 )
        %     y_lim( 1 )  = 0;
        % end
        % if ( y_lim( 2 ) < 1.0 )
        %     y_lim( 2 ) = 1.0;
        % end
        % set( ax, 'YLim', y_lim );
        
        subplot( 4, 1, 2 );
        d_vwc = double( vwc( :, i ) ) - double( vwc_Tc( :, i ) );
        d_vwc_percent = d_vwc ./ double( vwc( :, i ) );
        [ ax2, h_d_vwc, h_vwc_pct ] = plotyy( doy, d_vwc, ...
                                              doy, d_vwc_percent );        
        set( h_d_vwc, 'LineStyle', 'none', ...
                      'Marker', '.', 'MarkerEdgeColor', 'k' );
        set( h_vwc_pct, 'LineStyle', 'none', ...
                    'Marker', 'o', 'MarkerFaceColor', 'none', ...
                        'MarkerEdgeColor', 'b');
        align_axes_zeros( ax2( 1 ), ax2( 2 ) );
        ylabel( ax2( 1 ), '\Delta VWC [VWC]' );
        ylabel( ax2( 2 ), '% change VWC' );
        legend( [ h_d_vwc, h_vwc_pct ], ...
                'VWC - VWC\_Tc', ...
                '% change, VWC to VWC\_Tc', ...
                'Location', 'best' );
        uistack( ax2( 1 ), 'top' ); % bring the delta VWC ax2is ax2(1) to the
                                   % front
        set( ax2( 1 ), 'Color', 'none', 'YColor', 'black' );
        set( ax2( 2 ), 'Color', 'white', 'YColor', 'blue' );
        
        ax3 = subplot( 4, 1, 3 );
        plot( doy, T_soil( :, i ), '.' );
        ylabel( 'Tsoil' );

        ax4 = subplot( 4, 1, 4 );
        plot( doy, raw_swc( :, i ), '.' );
        ylabel( 'raw SWC' );
        xlabel( 'day of year' )
        
        if ( args.Results.save_plots )
            % save plots as PNG images in temporary file, then combine to
            % multi-page PDF outside of this loop
            fdir = fullfile( tempdir(), ...
                             'SWC_Plots' );
            if not( exist( fdir ) )
                mkdir( fdir );
            end
            fname = tempname( fdir );
            set( h, 'PaperPositionMode', 'auto' );
            print( h, '-dpng', fname );
            %figure_2_eps( h, fname );
            file_name_list{ i } = fname;
            close( h );
        else
            linkaxes( [ ax1, ax2( 1 ), ax2( 2 ), ax3, ax4 ], 'x' );
            waitfor( h );
            
        end
        
    end
    if args.Results.save_plots
        combined_dir = fullfile( getenv( 'PLOTS' ), 'SWC_Plots' );
        if not( exist( combined_dir ) )
            mkdir( combined_dir );
        end
        combined_fname = fullfile( combined_dir, ...
                                   sprintf( '%s_%d_VWC.pdf', ...
                                            char( UNM_sites(args.Results.sitecode)), ...
                                            args.Results.year ) );
        cmd = sprintf( [ 'gs -q -dNOPAUSE -dBATCH ', ...
                         '-sDEVICE=pdfwrite -sOutputFile=%s ' ], ...
                       combined_fname );
        for i = 1:numel( file_name_list )
            % convert png output to pdf so that ghostscript can combine to
            % single-file multi-page pdf
            convert_cmd = sprintf( 'convert %s.png %s.pdf', ...
                             file_name_list{ i },...
                             file_name_list{ i } );
            %fprintf( '%s\n',  convert_cmd );
            system( convert_cmd );
            cmd = sprintf( '%s %s.pdf', cmd, file_name_list{ i } );
        end
        % combine individual probe pdfs into single file
        system( cmd );
    end
        
end


%=================================================================

function depths = extract_Tsoil_depths( var_names)
% EXTRACT_TSOIL_DEPTHS - extracts depths from Tsoil variable names in the format
%   VAR_COVER_NUMBER_DEPTH.  Helper function for cs616_period2vwc

grp_vars = regexp( var_names, '_', 'split' ); % split on '_'
grp_vars = vertcat( grp_vars{ : } ); 
%depth is 4th '_'-delimited field
if size( grp_vars, 2 ) >= 4
    depths = grp_vars( :, 4 );
    depths = regexprep( depths, '([0-9])p([0-9])', '$1.$2' );
    depths = replace_hex_chars( depths );
    depths = regexprep( depths, '[Cc][Mm]', '' ); %get rid of "cm"
    depths = cellfun( @str2num, depths );
else
    depths = NaN;
end
