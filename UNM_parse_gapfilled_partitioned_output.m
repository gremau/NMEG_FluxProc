function [ pt_in ] = UNM_parse_gapfilled_partitioned_output( sitecode, year )
    % PARSE_GAPFILLED_PARTITIONED_OUTPUT - 
    %   
    % [gf_in, pt_in] = parse_gapfilled_partitioned_output(sitecode, year)

    % %% parse the gapfilled file
    % gf_file = fullfile( get_site_directory( sitecode ), ...
    %                     'processed flux', ...
    %                     sprintf( 'DataSetafterGapfill_%d.txt', year ) );
    % % exception handling added by MF, modified by TWH
    % try
    %     %gf_in=dlmread(gf_file,'',1,0);
    %     gf_in = parse_jena_output( gf_file );
    % catch err
    %     %error('Did you remember to delete first row and col of gap-filled files?');
    %     error(sprintf('error parsing %s', gf_file));
    % end
    % %% add timestamps to gf_in
    % gf_in.timestamp = datenum( gf_in.Year, gf_in.Month, gf_in.Day, ...
    %                            gf_in.Hour, gf_in.Minute, 0 );

    %% parse the partitioned file
    pt_file = fullfile( get_site_directory( sitecode ), ...
                        'processed flux', ...
                        sprintf( 'DataSetafterFluxpartGL2010_%d.txt', year ) );
    % exception handling added by MF, modified by TWH
    try
        %pt_in=dlmread(pt_file,'',1,0);
        pt_in = parse_jena_output( pt_file );
    catch err
        error(sprintf('error parsing %s', gf_file));
    end
    pt_in.timestamp = datenum( pt_in.Year, pt_in.Month, pt_in.Day, ...
                               pt_in.Hour, pt_in.Minute, 0 );

