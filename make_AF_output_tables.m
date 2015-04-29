function [amflux_gaps, amflux_gf] = make_AF_output_tables( sitecode, nrow)
% MAKE_AF_OUTPUT_TABLES - define variable name and units for
% Ameriflux files and create dummy table array to be populated externally.
% 
% FIXME - This is deprecated. It is being superseded by
% prepare_AF_output_data.m
%
% Helper function for UNM_Ameriflux_prepare_output_data.  Creates a table with
% specified variables, units, and number of rows populated entirely with NaN.
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site
%    nrow: integer; specifies the number of rows in the table
%
% OUTPUTS
%    amflux_gaps: table array; table array with variable and units for
%         with-gaps Ameriflux files, populated with NaNs
%    amflux_gf; table array; table array with variable and units for
%         gapfilled Ameriflux files, populated with NaNs
%
% SEE ALSO
%    table, UNM_sites
%
% author: Timothy W. Hilton, UNM, January 2012

warning( 'This function (make_AF_output_tables) is deprecated!' );

ts_depth(1)={'TS_2p5cm'};
ts_depth(2)={'TS_2p5cm'};
ts_depth(3)={'TS_5cm'};
ts_depth(4)={'TS_5cm'};
ts_depth(5)={'TS_5cm'};
ts_depth(6)={'TS_5cm'};
ts_depth(7)={'TS_2cm'};
ts_depth(8)={'TS_2cm'};
ts_depth(9)={'TS_2cm'};
ts_depth(10)={'TS_5cm'};
ts_depth(11)={'TS_2cm'};

sw_depth(1)={'SWC_2p5cm'};
sw_depth(2)={'SWC_2p5cm'};
sw_depth(3)={'SWC_5cm'};
sw_depth(4)={'SWC_5cm'};
sw_depth(5)={'SWC_5cm'};
sw_depth(6)={'SWC_5cm'};
sw_depth(7)={'SWC_2cm'};
sw_depth(8)={'SWC_2cm'};
sw_depth(9)={'SWC_2cm'};
sw_depth(10)={'SWC_5cm'};
sw_depth(11)={'SWC_2cm'};

header_gaps = {'YEAR','DOY','HRMIN','DTIME','UST','TA','WD','WS','NEE','FC' ...
               'SFC','H','SSA','LE','SLE','G1',char(ts_depth(sitecode)),...
               'PRECIP','RH', 'PA','CO2' ...
               'VPD',char(sw_depth(sitecode)),'RNET','PAR','PAR_DIFF',...
               'PAR_out','Rg','Rg_DIFF','Rg_out',...
               'Rlong_in','Rlong_out','FH2O','H20','RE','GPP','APAR'};

units_gaps = {'-','-','-','-','m/s','deg C','deg','m/s','mumol/m2/s',...
              'mumol/m2/s',...
              'mumol/m2/s','W/m2','W/m2','W/m2','W/m2','W/m2','deg C','mm',...
              '%', 'kPA','mumol/mol',...
              'kPA','m3/m3','W/m2','mumol/m2/s','mumol/m2/s','mumol/m2/s',...
              'W/m2','W/m2','W/m2',...
              'W/m2','W/m2','mg/m2/s','mmol/mol','mumol/m2/s','mumol/m2/s',...
              'mumol/m2/s'};

header_GF = {'YEAR','DOY','HRMIN','DTIME','UST','TA','TA_flag','WD','WS',...
             'NEE','FC','FC_flag',...
             'SFC','H','H_flag','SSA','LE','LE_flag','SLE','G1',...
             char(ts_depth(sitecode)),'PRECIP','RH', 'RH_flag', 'PA','CO2',...
             'VPD','VPD_flag',char(sw_depth(sitecode)),'RNET','PAR',...
             'PAR_DIFF','PAR_out','Rg','Rg_flag','Rg_DIFF','Rg_out',...
             'Rlong_in','Rlong_out','FH2O','H20','RE','RE_flag','GPP','GPP_flag',...
             'APAR','SWC_2','SWC_3'};

units_GF = {'-','-','-','-','m/s','deg C','-','deg','m/s','mumol/m2/s',...
            'mumol/m2/s','-',...
            'mumol/m2/s','W/m2','-','W/m2','W/m2','-','W/m2','W/m2','deg C',...
            'mm','%', '-', 'kPA','mumol/mol',...
            'kPA','-','m3/m3','W/m2','mumol/m2/s','mumol/m2/s','mumol/m2/s',...
            'W/m2','-','W/m2','W/m2',...
            'W/m2','W/m2','mg/m2/s','mmol/mol','mumol/m2/s','-','mumol/m2/s',...
            '-','mumol/m2/s','m3/m3','m3/m3'};


% Ameriflux output tables
dummy_data = repmat( NaN, nrow, numel( header_gaps ) );
amflux_gaps = array2table( dummy_data, 'VariableNames', header_gaps );
amflux_gaps.Properties.VariableUnits = units_gaps;

dummy_data = repmat( NaN, nrow, numel( header_GF ) );
amflux_gf = array2table( dummy_data, 'VariableNames', header_GF );
amflux_gf.Properties.VariableUnits = units_GF;


