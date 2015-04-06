% script_check_corrections

sitecode = UNM_sites.MCon;
year_arg = 2012;

data = UNM_parse_fluxall_txt_file( sitecode, year_arg );

headertext = data.Properties.VarNames;
timestamp = data.timestamp;
[year,month,day,hour,minute,second] = datevec( data.timestamp );
ncol = size( data, 2 );
filelength_n = size( data, 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some siteyears have periods where the observed radition does not line
% up with sunrise.  Fix this here so that the matched time/radiation
% propagates through the rest of the calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = ...
    replacedata( data, ...
    UNM_fix_datalogger_timestamps( sitecode, ...
    year_arg, ...
    double( data ),...
    headertext, ...
    timestamp, ...
    'debug', ...
    false ) );

fc_raw = data.Fc_raw ;
fc_raw_massman = data.Fc_raw_massman ;
fc_water_term = data.Fc_water_term ;
fc_heat_term_massman = data.Fc_heat_term_massman ;

E_raw = data.E_raw ;
E_raw_massman = data.E_raw_massman ;
E_water_term = data.E_water_term;
E_heat_term_massman = data.E_heat_term_massman;
E_wpl_massman = data.E_wpl_massman;

agc = data.agc_Avg;
rad = data.Rad_short_Up_Avg;
windSp = data.wnd_spd;
tair = data.AirTC_Avg;

data = double( data );

for i=1:numel( headertext );
    if strcmp('Fc_raw_massman_ourwpl', headertext{i}) == 1 | ...
            strcmp('Fc_raw_massman_wpl', headertext{i}) == 1
        fc_raw_massman_wpl = data( :, i );
    elseif strcmp('SensibleHeat_dry', headertext{i}) == 1 | ...
            strcmp('HSdry_WM2', headertext{i}) == 1
        HSdry = data( :, i );
    elseif strcmp('HSdry_massman', headertext{i}) == 1 | ...
            strcmp('HSdry_massman_WM2', headertext{i}) == 1
        HSdry_massman = data( :, i );
    elseif strcmp('LatentHeat_raw', headertext{i}) == 1 | ...
            strcmp('HL_raw_WM2', headertext{i}) == 1
        HL_raw = data( :, i );
    elseif strcmp('LatentHeat_raw_massman', headertext{i}) == 1 | ...
            strcmp('HL_raw_massman_WM2', headertext{i}) == 1
        HL_wpl_massman = data( :, i );% Is this correct? Its raw, not wpl
        
        HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
        % Half hourly data filler only produces uncorrected HL_wpl_massman,
        % but use these where available as very similar values
        HL_wpl_massman( isnan( HL_wpl_massman ) & ...
            ~isnan( HL_wpl_massman_un ) ) = ...
            HL_wpl_massman_un( isnan( HL_wpl_massman ) & ...
            ~isnan( HL_wpl_massman_un ) );
    end
end

figure('Units', 'centimeters', 'Position', [5, 2, 27, 27], 'Name', ...
    sprintf('Flux corrections, %s %d', get_site_name(sitecode), year_arg));
ax(1) = subplot(411);
plot(timestamp, fc_raw, '+', 'color', [0.6 0.6 0.6]);
hold on;
plot(timestamp, fc_raw_massman, 'o', 'color', [0.8 0.8 0.8]);
plot(timestamp, fc_raw_massman_wpl, '.k');
plot(timestamp, windSp, '--g');
plot(timestamp, tair, '--r');
plot(timestamp, rad/100, '--m');
%plot(timestamp, fc_raw_massman_wpl - fc_raw_massman, ':g');
%plot(timestamp,agc - nanmin(agc), ':m');
legend('Fc raw', 'Fc raw + massman', 'Fc raw + massman + wpl', 'AGC (minus min)');
title('Carbon flux corrections'); ylim([-50, 100]);
datetick('x','mmm','keepticks');
ax(2) = subplot(412);
plot(timestamp, E_raw, '+', 'color', [0.6 0.6 0.6]);
hold on;
plot(timestamp, E_raw_massman, 'o', 'color', [0.8 0.8 0.8]);
plot(timestamp, E_wpl_massman, '.k');
legend('E raw', 'E raw + massman', 'E raw + massman + wpl');
title('ET flux corrections'); ylim([-50, 50]);
datetick('x','mmm','keepticks');
ax(3) = subplot(413);
plot(timestamp, HL_raw, '+', 'color', [0.6 0.6 0.6]);
hold on;
%plot(timestamp, fc_raw_massman, '.b');
plot(timestamp, fc_raw_massman_wpl, '.k');
legend('HL raw', 'HL raw + massman + wpl');
title('Latent heat flux corrections'); ylim([-1500, 1500]);
datetick('x','mmm','keepticks');
ax(4) = subplot(414);
plot(timestamp, HSdry, '+', 'color', [0.6 0.6 0.6]);
hold on;
%plot(timestamp, fc_raw_massman, '.b');
plot(timestamp, HSdry_massman, '.k');
legend('HSdry raw', 'HSdry raw + massman');
title('Sensible heat flux corrections'); ylim([-1500, 1500]);
datetick('x','mmm','keepticks');
linkaxes(ax, 'x');
