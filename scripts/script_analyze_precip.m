%script_analyze_precip

%sitelist = {UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ_girdle,...
%    UNM_sites.GLand,UNM_sites.New_GLand, UNM_sites.MCon, UNM_sites.PJ,...
%    UNM_sites.PPine};
sitelist = {UNM_sites.JSav};
yearlist = 2010;% 2009:2013;
count = 1;

% Assemble the file names and paths
prism_path = fullfile(getenv('FLUXROOT'), 'AncillaryData', 'MetData',...
    'PRISM_daily_2007');
bil_file = fullfile(prism_path, 'PRISM_ppt_stable_4kmD1_20070101_bil.bil');
hdr_file = fullfile(prism_path, 'PRISM_ppt_stable_4kmD1_20070101_bil.hdr');

% Open the header file and put file configuration data in a struct
fid = fopen(hdr_file);
A = textscan(fid, '%s%s');
fclose(fid);
fields = A{1};
vals = A{2};
% Convert numeric values
numvals = find(ismember(fields, {'NCOLS', 'NROWS', 'NBANDS', 'NBITS',...
    'BANDROWBYTES', 'TOTALROWBYTES', 'NODATA', 'ULXMAP','ULYMAP',...
    'XDIM', 'YDIM'}));
for i = 1:length(numvals)
    ind = numvals(i);
    vals{ind} = str2num(vals{ind});
end
conf = cell2struct(vals, fields);

% Read in the band interleaved dataset
B = multibandread(bil_file, [conf.NROWS conf.NCOLS conf.NBANDS],...
    'float', 0, 'bil', 'ieee-le');


for i = 1:length(sitelist);
    for j = 1:length(yearlist)
        sitecode = sitelist{i};
        year = yearlist(j);
        data = UNM_parse_fluxall_txt_file(sitecode, year);
        
        precip_fig = figure( 'Name', 'Precip filling',...
            'Units', 'centimeters', 'Position', [5, 6, 16, 22] );
        ax(1) = subplot(411);
        plot(data.timestamp, data.rain_Tot, '.b');
        %hold on;
        %plot(data.timestamp, data.agc_Avg ,'.', 'color', [0.7 0.7 0.7]);
        %ylim([-0.05 0.15]);
        %legend('delta Fc in mg/m2/s', 'delta Fc - angled' ); datetick('x', 'mmm-yyyy');
        ylabel('rain\_Tot (mm)');
        title( sprintf('%s %d', get_site_name( sitecode ), year( 1 ) ) );
        ax(2) = subplot(412);
        plot(data.timestamp, data.agc_Avg ,'.', 'color', [0.7 0.7 0.7]);
        %hold on;
        %plot(timestamp, fc_out, '.k');
        ylabel('AGC (%)');
        %legend('uncorrected', 'corrected'); datetick('x', 'mmm-yyyy');
        ax(3) = subplot(413);
        plot(data.timestamp, data.SWC_J1_2p5, '.g');
        ylabel('SWC %');
        %hold on;
        %plot(timestamp, cumsum(fc_nonan2), '.k');
        %legend('uncorrected', 'corrected'); datetick('x', 'mmm-yyyy');
        %ax(4) = subplot(414);
        %plot(timestamp, t_mean, '.r');
        %hold on;
        %plot(get(gca,'xlim'), [0 0], ':k');
        %ylabel('T_{mean} (C)'); xlabel('Date'); datetick('x', 'mm-yyyy');
        linkaxes(ax, 'x');
        
        figname = fullfile(getenv('FLUXROOT'), 'ustar_analysis',...
            sprintf('ustar_cutoff_%s_%d.png', get_site_name(sitecode), year(1)));
        print(ufig, '-dpng', figname );
        
        
    end
end