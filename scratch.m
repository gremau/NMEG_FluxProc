filename = '/Volumes/Untitled/home/tim/Data/DataSandbox/TX/ts_data/TOB1_TX_2011_03_30_0000.DAT';

CR=13;
LF=10;
COMMA=44;

fid=fopen(filename,'r','ieee-le'); % file ID
if fid == -1
    err = MException('UNM_data_processor', ...
                     'cannot open file %s\n', filename);
    throw(err);
end
d=fread(fid,864000,'uchar');

% find Line Feeds and Carriage Returns
icr = find(d==CR);
ilf = find(d==LF);

% find the end of the header
EOH = ilf(5);

% read last line of header to get the file structure
HLine2 = d(ilf(1)+1:ilf(2)-1)';
HLine5 = d(ilf(4)+1:ilf(5)-1)';

begfields = [1 find(HLine5==COMMA)+1];
endfields = [find(HLine5==COMMA)-1 length(HLine5)-1];

begfields2 = [1 find(HLine2==COMMA)+1];
endfields2 = [find(HLine2==COMMA)-1 length(HLine2)-1];

Nfields = length(begfields);

% don't read the quotes at beginning and end of each field
for i=1:Nfields
    FieldName{i} = char(HLine2(begfields2(i)+1:endfields2(i)-1));
    Field{i} = char(HLine5(begfields(i)+1: endfields(i)-1));
end

% Calculate the number of bytes in a record and get the
% corresponding matlab precision
for i=1:size(Field,2)
    if strcmp(char(Field(i)),'ULONG')
        NBytes(i) = 4;
        MatlabPrec{i}='uint32';
    elseif  strcmp(char(Field(i)),'IEEE4')
        NBytes(i) = 4;
        MatlabPrec{i}='float32';
    elseif strcmp(char(Field(i)),'IEEE4L')
        NBytes(i) = 4;
        MatlabPrec{i}='float32';
    elseif strcmp(char(Field(i)),'SecNano')
        NBytes(i) = 4;
        MatlabPrec{i}='uint32';
    end       
end

%%% Start reading the channels
fprintf(1, 'reading data: %s\n', datestr(date, 'dd mmm YYYY'));
% first position pointer at the end of the header
fseek(fid,EOH,'bof');   %fseek repositions file position indicator (doc
                        %fseek). 'bof' = beginning of file
ftell(fid);  %position = ftell(fid) returns the location of the file position
             %indicator for the file specified by fid

BytesPerRecord=sum(NBytes)*ones(size(NBytes)) - NBytes ;
BytesCumulative = [0 cumsum(NBytes(1:length(NBytes)-1))];

% read each column into data matrix:
for i=1:Nfields
    % fseek repositions file position indicator (doc fseek). problem here
    fseek(fid,EOH+BytesCumulative(i),'bof');
    % reads data into matrix (data, col i)
    data(:,i)= fread(fid,24*3600*10,char(MatlabPrec(i)),BytesPerRecord);
    keyboard()
end

% assign variable names to columns of data:
if (Nfields==14) % TX_forest & TX_grassland
    time1=(data(:,1));
    uin=(data(:,7));
    vin=(data(:,8));
    win=(data(:,9));
    Tin=(data(:,10)+273.15);
    co2in=(data(:,11))/44;
    h2oin=(data(:,12))/.018;
    Pin=(data(:,13));
    diagcsat=(data(:,14));
    diagsonin = zeros(length(diagcsat),1);
elseif (Nfields==11); % JSAV, PPINE, TX_savanna ....
    time1=(data(:,1)); % seconds since 1990(?)
    time2=(data(:,2)); % nanoseconds
    uin=(data(:,3));
    vin=(data(:,4));
    win=(data(:,5));
    co2in=(data(:,6))/44;
    h2oin=(data(:,7));
    %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
    h2oin=h2oin/.018;
    Tin=(data(:,8)+273.15);
    Pin=(data(:,9));
    diagsonin=(data(:,10));
elseif (Nfields==12 & (sitecode==1 | sitecode==2 | sitecode==10));  
    %GLand, SLand. %Sev sites have their columns mixed up. There is no irga
    %diagnositc!
    time1=(data(:,1)); % seconds since 
    time2=(data(:,2)); % nanoseconds 
    uin=(data(:,3));
    vin=(data(:,4));
    win=(data(:,5));
    co2in=(data(:,6))/44;
    h2oin=(data(:,7));
    %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
    h2oin=h2oin/.018;
end