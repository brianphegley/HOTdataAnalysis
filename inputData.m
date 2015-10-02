%% Inpute Data
file=fopen('C:\Users\Brian\Documents\Research\HOTdata\I-110 & I-10 Trip Data for 2014\I-10\I-10_201401.txt');
textdata=textscan(file,'%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s','delimiter','	');
fclose(file); clear file;
%% Interpret Data -- If this were going to the outside world, a struct would be better
TripID=[TripID;textdata{1}(2:end)];
EntryTime=[EntryTime;cell2mat(textdata{4}(2:end))];
ExitTime=[ExitTime;cell2mat(textdata{5}(2:end))];
Transponder=[Transponder;textdata{6}(2:end)];
EntryPoint=[EntryPoint;cell2mat(textdata{7}(2:end))];
ExitPoint=[ExitPoint;cell2mat(textdata{8}(2:end))];
OccupancyState=[OccupancyState;textdata{9}(2:end)];
Toll=[Toll;str2double(textdata{11}(2:end))];
Type=[Type;textdata{12}(2:end)];
clear textdata

dir='W';
TripID=TripID(EntryPoint(:,1)==dir);
EntryTime=EntryTime(EntryPoint(:,1)==dir,:);
ExitTime=ExitTime(EntryPoint(:,1)==dir,:);
Transponder=Transponder(EntryPoint(:,1)==dir);
ExitPoint=ExitPoint(EntryPoint(:,1)==dir,:);
OccupancyState=OccupancyState(EntryPoint(:,1)==dir);
Toll=Toll(EntryPoint(:,1)==dir);
Type=Type(EntryPoint(:,1)==dir);
EntryPoint=EntryPoint(EntryPoint(:,1)==dir,:);

if any(ExitPoint(:,1)~=dir)
    flag=1;
end
EntryTime=datenum(EntryTime,'dd-mmm-yy HH.MM.SS.FFF PM');
ExitTime=datenum(ExitTime,'dd-mmm-yy HH.MM.SS.FFF PM');
%% Distances
% On 10E: Alameda St to 710off: 4.48mi on expressway, 4.4mi on freeway
%       710off to Fremont Ave Gate: 1.05mi on expressway, 1.1mi on freeway
%       Fremont Ave Gate to Del Mar Ave Exit: 2.6 mi
%       Del Mar Ave Exit to Rosemead Blvd Gate: 2 mi
%       Rosemead Blvd Gate to end: 3.8 mi
%       Alameda St to EB1: 1.7 mi
%       EB1 to EB2: 4.2 mi
%       EB2 to EB3: 1.4 mi
%       EB3 to EB4: 3.4 mi
%       EB4 to End: 3.2 mi
%% Sort out Violators
violator=false(length(Type),1);
for i=1:length(Type)
    violator(i)=strcmp(Type{i},'VIOL');
end

vTripID=TripID(violator);
vEntryPoint=EntryPoint(violator,:);
vEntryTime=EntryTime(violator);
vExitTime=ExitTime(violator);
vExitPoint=ExitPoint(violator,:);
vTransponder=Transponder(violator);
vOccupancyState=OccupancyState(violator);
vToll=Toll(violator);

TripID=TripID(~violator);
EntryPoint=EntryPoint(~violator,:);
EntryTime=EntryTime(~violator);
ExitTime=ExitTime(~violator);
ExitPoint=ExitPoint(~violator,:);
Transponder=Transponder(~violator);
OccupancyState=OccupancyState(~violator);
Toll=Toll(~violator);
Type=Type(~violator);

clear violator i
%% Sort by location, time
Lengths=[4.2 1.4 3.4];daysInMonth=[31 28 31 30 31 30 31 31 30 31 30 31];
vehicleCounts=zeros(365*24*60/15,length(Lengths)+1,4);%Let's think of a way to standardize better
for i=1:length(Type)
    cType=0;
    if strcmp(OccupancyState{i},'SOV')
        cType=1;
    elseif strcmp(OccupancyState{i},'HOV-2')
        cType=2;
    elseif strcmp(OccupancyState{i},'HOV-3')
        cType=3;
    else
        disp('What type is it?');
        keyboard;
    end
    beginpoint=str2double(EntryPoint(i,end));
    endpoint=str2double(ExitPoint(i,end));
    timepoint=EntryTime(i);
    timeend=ExitTime(i);
    temp=beginpoint;totallength=0;
    while temp<endpoint
        totallength=totallength+Lengths(temp);
        temp=temp+1;
    end
    while beginpoint<=endpoint
        timeslot=sum(daysInMonth(1:(str2double(datestr(timepoint,'mm'))-1)))*24*4+(str2double(datestr(timepoint,'dd'))-1)*24*4+str2double(datestr(timepoint,'HH'))*4+...
            floor(str2double(datestr(timepoint,'MM'))/15)+1;
        vehicleCounts(timeslot,beginpoint,cType)=vehicleCounts(timeslot,beginpoint,cType)+1;
        if beginpoint~=endpoint
        timepoint=timepoint+(timeend-timepoint)*Lengths(beginpoint)/max(totallength,Lengths(beginpoint));
        totallength=totallength-Lengths(beginpoint);
        end
        beginpoint=beginpoint+1;
    end
end
for i=1:length(vToll)
    beginpoint=str2double(vEntryPoint(i,end));
    endpoint=str2double(vExitPoint(i,end));
    timepoint=vEntryTime(i);
    timeend=vExitTime(i);
    temp=beginpoint;totallength=0;
    while temp<endpoint
        totallength=totallength+Lengths(temp);
        temp=temp+1;
    end
    while beginpoint<=endpoint
        timeslot=sum(daysInMonth(1:(str2double(datestr(timepoint,'mm'))-1)))*24*12+(str2double(datestr(timepoint,'dd'))-1)*24*4+str2double(datestr(timepoint,'HH'))*4+...
            floor(str2double(datestr(timepoint,'MM'))/15)+1;
        vehicleCounts(timeslot,beginpoint,4)=vehicleCounts(timeslot,beginpoint,4)+1;
        if beginpoint~=endpoint
        timepoint=timepoint+(timeend-timepoint)*Lengths(beginpoint)/max(totallength,Lengths(beginpoint));
        totallength=totallength-Lengths(beginpoint);
        end
        beginpoint=beginpoint+1;
    end
end
%% Plot Information--Vehicle Counts
dateStart=datenum(2014,1,1);dateEnd=datenum(2014,2,1)-datenum(0,0,0,0,15,0);
timeStep=dateStart:datenum(0,0,0,0,15,0):dateEnd;
for i=1:size(vehicleCounts,2)
    figure;
    plot(timeStep,vehicleCounts(:,i,1),'b');hold on;
    plot(timeStep,vehicleCounts(:,i,1)+vehicleCounts(:,i,2),'r');
    plot(timeStep,vehicleCounts(:,i,1)+vehicleCounts(:,i,2)+vehicleCounts(:,i,3),'g');
    plot(timeStep,vehicleCounts(:,i,1)+vehicleCounts(:,i,2)+vehicleCounts(:,i,3)+vehicleCounts(:,i,4),'k');
    axis([datenum(2014,1,19) datenum(2014,1,26) 0 550]);%Need to make a varied version of this
    datetick('x','mmm dd','keeplimits');xlabel('Time');ylabel('Vehicle Counts (15 min)');
    legend('SOV','SOV+HOV-2','SOV+HOV','All');title(['ET0' num2str(i)])
end
%% Plot Information--Day of Week Average
SOVcounts=zeros(24*60/15,length(Lengths)+1,7);
HOV2counts=zeros(24*60/15,length(Lengths)+1,7);
HOV3counts=zeros(24*60/15,length(Lengths)+1,7);
Violcounts=zeros(24*60/15,length(Lengths)+1,7);
for j=1:length(Lengths)+1
for i=1:7
    h=1;
    while (i+h*7-7)*24*4<=size(vehicleCounts,1)
        SOVcounts(:,j,i)=((h-1)*SOVcounts(:,j,i)+vehicleCounts((i+h*7-8)*24*4+1:(i+h*7-7)*24*4,j,1))/h;
        HOV2counts(:,j,i)=((h-1)*HOV2counts(:,j,i)+vehicleCounts((i+h*7-8)*24*4+1:(i+h*7-7)*24*4,j,2))/h;
        HOV3counts(:,j,i)=((h-1)*HOV3counts(:,j,i)+vehicleCounts((i+h*7-8)*24*4+1:(i+h*7-7)*24*4,j,3))/h;
        Violcounts(:,j,i)=((h-1)*Violcounts(:,j,i)+vehicleCounts((i+h*7-8)*24*4+1:(i+h*7-7)*24*4,j,4))/h;
        h=h+1;
    end
end
end

tStep=datenum(0,0,0,0,0,0):datenum(0,0,0,0,15,0):datenum(0,0,1,0,0,0)-datenum(0,0,0,0,15,0);
for j=1:7
for i=1:size(vehicleCounts,2)
    figure;
    plot(tStep,SOVcounts(:,i,j),'b');hold on;
    plot(tStep,SOVcounts(:,i,j)+HOV2counts(:,i,j),'r');
    plot(tStep,SOVcounts(:,i,j)+HOV2counts(:,i,j)+HOV3counts(:,i,j),'g');
    plot(tStep,SOVcounts(:,i,j)+HOV2counts(:,i,j)+HOV3counts(:,i,j)+Violcounts(:,i,j),'k');
    datetick('x','HH:MM');xlabel('Time');ylabel('Vehicle Counts (per 15 minutes)');
    title([datestr(timeStep((j-1)*24*4+1),'dddd') ' ET0' num2str(i)]);
    legend('SOV','SOV+HOV-2','SOV+HOV','All');
end
end

%% Toll Amounts During Different Times of Day
tollAmount=NaN(4*24*31,4,6);
for i=1:length(OccupancyState)
    if strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT01')
            time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
            if strcmp(ExitPoint(i,:),'WT01')
                tollAmount(pos,1,1)=Toll(i);
            elseif strcmp(ExitPoint(i,:),'WT02')
                tollAmount(pos,1,2)=Toll(i);
            elseif strcmp(ExitPoint(i,:),'WT03')
                tollAmount(pos,1,3)=Toll(i);
            elseif strcmp(ExitPoint(i,:),'WT04')
                tollAmount(pos,1,4)=Toll(i);
            elseif strcmp(ExitPoint(i,:),'WT05')
                tollAmount(pos,1,5)=Toll(i);
            elseif strcmp(ExitPoint(i,:),'WT06')
                tollAmount(pos,1,6)=Toll(i);
            end
    elseif strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT02')
            time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'WT01')
            tollAmount(pos,2,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT02')
            tollAmount(pos,2,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT03')
            tollAmount(pos,2,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT04')
            tollAmount(pos,2,4)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT05')
            tollAmount(pos,2,5)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT06')
            tollAmount(pos,2,6)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT03')
        time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'WT01')
            tollAmount(pos,3,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT02')
            tollAmount(pos,3,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT03')
            tollAmount(pos,3,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT04')
            tollAmount(pos,3,4)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT05')
            tollAmount(pos,3,5)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT06')
            tollAmount(pos,3,6)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT04')
        time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'WT01')
            tollAmount(pos,4,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT02')
            tollAmount(pos,4,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT03')
            tollAmount(pos,4,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT04')
            tollAmount(pos,4,4)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT05')
            tollAmount(pos,4,5)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT06')
            tollAmount(pos,4,6)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT05')
        time=datestr(EntryTime(i),'ddHHMM');
        pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'WT01')
            tollAmount(pos,5,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT02')
            tollAmount(pos,5,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT03')
            tollAmount(pos,5,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT04')
            tollAmount(pos,5,4)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT05')
            tollAmount(pos,5,5)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT06')
            tollAmount(pos,5,6)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'SOV') && strcmp(EntryPoint(i,:),'WT06')
        time=datestr(EntryTime(i),'ddHHMM');
        pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'WT01')
            tollAmount(pos,6,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT02')
            tollAmount(pos,6,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT03')
            tollAmount(pos,6,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT04')
            tollAmount(pos,6,4)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT05')
            tollAmount(pos,6,5)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'WT06')
            tollAmount(pos,6,6)=Toll(i);
        end
    end
end
%% Toll per unit length
lengths=[5.5 4.6 3.8];
tollperlength=[tollAmount(:,1,1)/lengths(1) tollAmount(:,1,3)/(lengths(1)+lengths(2)) tollAmount(:,1,4)/sum(lengths)...
    tollAmount(:,2,3)/lengths(2) tollAmount(:,2,4)/(lengths(2)+lengths(3)) tollAmount(:,4,4)/lengths(3)];
hist(tollperlength,0:0.05:0.6);
%% PeMS
detectors=[737320 716028 716067 716069 716072 717059 716075 716078 765098 716081 737344 717070 ...
    716085 716087 765451 716092 717077 717075 717089 717083 717084 717093 717097 717105 717110 ... %3 to 1, 
    717114 718445 717123 717127 717131 717133 717136 716126 717146 774440 717152 717155 717156]; % 5 to 2
for i=1:length(detectors)
    sensor(i).sensor_vds=detectors(i);
end
days=datenum(2014,1,1):datenum(2014,1,31);

pems_dch2txt( ...
    'pemshourly', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed',...
    sensor,...
    '7',...
    days);

pems_txt2mat( ...
    'pemshourly', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed',...
    sensor,...
    days);
%% Plot PeMS contours
load('C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed\pemshourly_2014_01.mat');
pemsflow=[];
pemsspeed=[];
pemsdensity=[];
for i=1:length(detectors)
pemsflow=[pemsflow sum(pems.data(pems.vds==detectors(i)).flw,2)];
pemsdensity=[pemsdensity sum(pems.data(pems.vds==detectors(i)).flw./pems.data(pems.vds==detectors(i)).spd,2)];
pemsspeed=[pemsspeed pemsflow(:,end)./pemsdensity(:,end)];
end
hold on;time=0:24;detectornumber=1:38;
for i=1:31
    subplot(5,7,i+3)
    set(pcolor(time,detectornumber,[pemsspeed(i*24-23:i*24,:)', zeros(38,1)]),'Linestyle','none');
    xlabel('Time (hr)');ylabel('Detector #');
end
title('Speed Contours for month of January');
%% Consider first level relationship between Tolls and Delay Time
% Freeflow in segment 1: 64.68 mph (length 5.5 mi)
% Freeflow in segment 2: 66.81 mph (length 4.6 mi)
% Freeflow in segment 3: 67.44 mph (length 3.8 mi)
s1=5.5;s2=4.6;s3=3.8;v1=64.68;v2=66.81;v3=67.44;
delay=[];price=[];
for i=1:length(Toll)
    if strcmp(OccupancyState{i},'SOV')
        price=[price Toll(i)];
        time=datestr(EntryTime(i),'ddHHMM');
        pos=24*(str2double(time(1:2))-1)+str2double(time(3:4))+ceil(str2double(time(5:6))/60);
        if strcmp(EntryPoint(i,:),'ET01')
            if strcmp(ExitPoint(i,:),'ET01')
                delay=[delay s1*(1/mean(pemsspeed(pos,1:15))-1/v1)];
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                delay=[delay s1*(1/mean(pemsspeed(pos,1:15))-1/v1)+s2*(1/mean(pemsspeed(pos,16:30))-1/v2)];
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s1*(1/mean(pemsspeed(pos,1:15))-1/v1)+s2*(1/mean(pemsspeed(pos,16:30))-1/v2)+s3*(1/mean(pemsspeed(pos,31:end))-1/v3)];
            end
        elseif strcmp(EntryPoint(i,:),'ET02')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                delay=[delay s2*(1/mean(pemsspeed(pos,16:30))-1/v2)];
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s2*(1/mean(pemsspeed(pos,16:30))-1/v2)+s3*(1/mean(pemsspeed(pos,31:end))-1/v3)];
            end
        elseif strcmp(EntryPoint(i,:),'ET03')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET04')
                price=price(1:end-1);
            end
        elseif strcmp(EntryPoint(i,:),'ET04')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s3*(1/mean(pemsspeed(pos,31:end))-1/v3)];
            end
        end
    end
end
%% Redefine Lengths to make one standard
lengths(1)=min(tollAmount(:,1,1))/0.25;
lengths(2)=min(tollAmount(:,2,3))/0.25;
lengths(3)=min(tollAmount(:,4,4))/0.25;
%% Separate Toll Amount Via route
tollAmount(tollAmount>7)=NaN;
subplot(2,3,1)
hist(tollAmount(:,1,1)/lengths(1));
title('Vehicles through Booth 1 to Booth 1');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,2)
hist(tollAmount(:,1,3)/(lengths(1)+lengths(2)));
title('Vehicles through Booth 1 to Booth 3');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,3)
hist(tollAmount(:,1,4)/sum(lengths));
title('Vehicles through Booth 1 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,4)
hist(tollAmount(:,2,3)/lengths(2));
title('Vehicles through Booth 2 to Booth 3');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,5)
hist(tollAmount(:,2,4)/(lengths(2)+lengths(3)));
title('Vehicles through Booth 2 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,6)
hist(tollAmount(:,4,4)/lengths(3));
title('Vehicles through Booth 4 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
%% Toll Amounts During Different Times of Day
tollAmount2=NaN(4*24*31,4,4);
for i=1:length(OccupancyState)
    if strcmp(OccupancyState{i},'HOV-2') && strcmp(EntryPoint(i,:),'ET01')
            time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'ET01')
            tollAmount2(pos,1,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET02')
            tollAmount2(pos,1,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET03')
            tollAmount2(pos,1,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET04')
            tollAmount2(pos,1,4)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'HOV-2') && strcmp(EntryPoint(i,:),'ET02')
            time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'ET01')
            tollAmount2(pos,2,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET02')
            tollAmount2(pos,2,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET03')
            tollAmount2(pos,2,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET04')
            tollAmount2(pos,2,4)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'HOV-2') && strcmp(EntryPoint(i,:),'ET03')
        time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'ET01')
            tollAmount2(pos,3,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET02')
            tollAmount2(pos,3,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET03')
            tollAmount2(pos,3,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET04')
            tollAmount2(pos,3,4)=Toll(i);
        end
    elseif strcmp(OccupancyState{i},'HOV-2') && strcmp(EntryPoint(i,:),'ET04')
        time=datestr(EntryTime(i),'ddHHMM');
            pos=(str2double(time(1:2))-1)*4*24+str2double(time(3:4))*4+ceil(str2double(time(5:6))/15);
        if strcmp(ExitPoint(i,:),'ET01')
            tollAmount2(pos,4,1)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET02')
            tollAmount2(pos,4,2)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET03')
            tollAmount2(pos,4,3)=Toll(i);
        elseif strcmp(ExitPoint(i,:),'ET04')
            tollAmount2(pos,4,4)=Toll(i);
        end
    end
end
%% Separate Toll Amount Via route--HOV-2
%tollAmount2(tollAmount2>7)=NaN;
subplot(2,3,1)
hist(tollAmount2(:,1,1)/lengths(1));
title('Vehicles through Booth 1 to Booth 1');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,2)
hist(tollAmount2(:,1,3)/(lengths(1)+lengths(2)));
title('Vehicles through Booth 1 to Booth 3');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,3)
hist(tollAmount2(:,1,4)/sum(lengths));
title('Vehicles through Booth 1 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,4)
hist(tollAmount2(:,2,3)/lengths(2));
title('Vehicles through Booth 2 to Booth 3');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,5)
hist(tollAmount2(:,2,4)/(lengths(2)+lengths(3)));
title('Vehicles through Booth 2 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
subplot(2,3,6)
hist(tollAmount2(:,4,4)/lengths(3));
title('Vehicles through Booth 4 to Booth 4');xlabel('Toll Value ($/mile)');ylabel('Count');
%% Plot by time of day--Toll Amounts
time=datenum(2014,1,1):datenum(0,0,0,0,15,0):datenum(2014,2,1);
time=time(1:end-1);segment=24*4*11:24*4*18;
plot(time(segment),tollAmount(segment,4,4));
datetick;xlabel('Time');ylabel('Toll Price');
%% PeMS 5-minute data
detectors=[737320 716028 716067 716069 716072 717059 716075 716078 765098 716081 737344 717070 ...
    716085 716087 765451 716092 717077 717075 717089 717083 717084 717093 717097 717105 717110 ... %3 to 1, 
    717114 718445 717123 717127 717131 717133 717136 716126 717146 774440 717152 717155 717156 ... % 5 to 2
    762404 762408 762438 762410 762422 765508 774562 762435 762447 762449 762451 762453 762492 ... % HOV to 717084
    762455 762457 762459 762461 762463 762467 768426 717140 774442 768743 717158]; %HOV to end
% I-10W
%detectors=[717157 767329 717154 717150 774441 717142 717139 717135 717134 717129 717125 717121...
%   717119 717116 717112 717108 717101 717095 716101 717091 717087 717081 717079 716091 717073...
%   716088 717071 768972 716084 737345 717065 718332 718020 716076 717060 717055 717052 717049...
%   737329 717047 764941...
%    718331 768753 768746 768741 774443 768738 762470 762504 762468 762502 762500 762498 762496...%HOV
%   762494 762491 762488 768724 762486 762484 762482 762480 762476 762436 762474 762432 762423...%HOV
%   762413 717056 762409 762472 762405]; %HOV
for i=1:length(detectors)
    sensor(i).sensor_vds=detectors(i);
end
days=datenum(2014,1,1):datenum(2014,1,31);

pems_dch2txt( ...
    'pems5min', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed',...
    sensor,...
    '7',...
    days);

pems_txt2mat( ...
    'pems5min', ...
    'C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed',...
    sensor,...
    days);
%% Plot PeMS HOT
load('C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed\pems5min_2014_01_17.mat')
pemsflow=[];
pemsspeed=[];
pemsdensity=[];
for i=39:62
pemsflow=[pemsflow sum(pems.data(pems.vds==detectors(i)).flw,2)];
pemsdensity=[pemsdensity sum(pems.data(pems.vds==detectors(i)).flw./pems.data(pems.vds==detectors(i)).spd,2)];
pemsspeed=[pemsspeed pemsflow(:,end)./pemsdensity(:,end)];
end
hold on;time=0:(1/12):24;detectornumber=1:24;
set(pcolor(time,detectornumber,[pemsspeed', zeros(24,1)]),'Linestyle','none');
xlabel('Time (hr)');ylabel('Detector #');
title('HOT Speed Contour for January 17');
%% Process 5-minute data content
pemsflow=zeros(288,31,38);pemsdensity=zeros(288,31,38);
for days=1:31
    load(['C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed\pems5min_2014_01_' num2str(days,'%02d') '.mat']);
    for j=1:38
        pemsflow(:,days,j)=sum(pems.data(pems.vds==detectors(j)).flw,2);
        pemsdensity(:,days,j)=sum(pems.data(pems.vds==detectors(j)).flw./pems.data(pems.vds==detectors(j)).spd,2);
    end
end
pemsspeed=pemsflow./pemsdensity;
%% Delay with 5-minute data used
% Freeflow in segment 1: 64.68 mph (length 5.5 mi)
% Freeflow in segment 2: 66.81 mph (length 4.6 mi)
% Freeflow in segment 3: 67.44 mph (length 3.8 mi)
s1=5.5;s2=4.6;s3=3.8;v1=64.68;v2=66.81;v3=67.44;
delay=[];price=[];
for i=1:length(Toll)
    if strcmp(OccupancyState{i},'SOV')
        price=[price Toll(i)];
        time=datestr(EntryTime(i),'ddHHMM');
        day=str2double(time(1:2));
        pos=str2double(time(3:4))*12+floor(str2double(time(5:6))/5)+1;
        if strcmp(EntryPoint(i,:),'ET01')
            if strcmp(ExitPoint(i,:),'ET01')
                delay=[delay s1*(1/mean(pemsspeed(pos,day,1:15))-1/v1)];
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                delay=[delay s1*(1/mean(pemsspeed(pos,day,1:15))-1/v1)+s2*(1/mean(pemsspeed(pos,day,16:30))-1/v2)];
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s1*(1/mean(pemsspeed(pos,day,1:15))-1/v1)+s2*(1/mean(pemsspeed(pos,day,16:30))-1/v2)+s3*(1/mean(pemsspeed(pos,day,31:end))-1/v3)];
            end
        elseif strcmp(EntryPoint(i,:),'ET02')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                delay=[delay s2*(1/mean(pemsspeed(pos,day,16:30))-1/v2)];
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s2*(1/mean(pemsspeed(pos,day,16:30))-1/v2)+s3*(1/mean(pemsspeed(pos,day,31:end))-1/v3)];
            end
        elseif strcmp(EntryPoint(i,:),'ET03')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET04')
                price=price(1:end-1);
            end
        elseif strcmp(EntryPoint(i,:),'ET04')
            if strcmp(ExitPoint(i,:),'ET01')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET02')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET03')
                price=price(1:end-1);
            elseif strcmp(ExitPoint(i,:),'ET04')
                delay=[delay s3*(1/mean(pemsspeed(pos,day,31:end))-1/v3)];
            end
        end
    end
end
%% Plotting comparison of vehicle counts and toll rates
time=datenum(2014,1,1):datenum(0,0,0,0,15,0):datenum(2014,2,1);
time=time(1:end-1);segment=24*4*11:24*4*18;
plot(time(segment),vehicleCounts(segment,2,1),'b');hold on;
plot(time(segment),vehicleCounts(segment,2,1)+vehicleCounts(segment,2,2),'r');
plot(time(segment),vehicleCounts(segment,2,1)+vehicleCounts(segment,2,2)+vehicleCounts(segment,2,3),'g');
plot(time(segment),vehicleCounts(segment,2,1)+vehicleCounts(segment,2,2)+vehicleCounts(segment,2,3)+vehicleCounts(segment,2,4),'k');
plot(time(segment),300*tollAmount(segment,2,3),'m');
datetick;xlabel('Time');ylabel('Vehicle Count');legend('SOV','SOV+HOV-2','SOV+HOV','All');
%% Plotting comparison of mainline flow and toll rates
detectorloc=[716067 717077 717136];flow=[];%segment=segment(2:end);
for i=10:31
    load(['C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed\pems5min_2014_01_' num2str(i) '.mat'])
    flow=[flow; sum(pems.data(pems.vds==detectorloc(2)).flw,2)];
end
i=1;
while i<length(flow)
    flow(i+1:i+2)=[];
    i=i+1;
end
plot(time(segment),flow);hold on;
plot(time(segment),5500*tollAmount(segment,4,4),'m');
datetick;xlabel('Time');ylabel('Flow (veh/hr)');
%% Plotting delay to price
price(price>9)=NaN;
plot(price,delay,'.')
%% Finding max and min of counts by day of week
maxFlow1=zeros(24*4,4);minFlow1=maxFlow1;minFlow2=minFlow1;maxFlow2=maxFlow1;
maxFlow3=maxFlow1;minFlow3=minFlow1;maxFlow4=maxFlow1;minFlow4=maxFlow1;
for i=1:size(vehicleCounts,2)
    start=24*4*6+1;
    maxFlow1(:,i)=vehicleCounts(start:start+24*4-1,i,1);
    minFlow1(:,i)=vehicleCounts(start:start+24*4-1,i,1);
    maxFlow2(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2);
    minFlow2(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2);
    maxFlow3(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3);
    minFlow3(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3);
    maxFlow4(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3)+vehicleCounts(start:start+24*4-1,i,4);
    minFlow4(:,i)=vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3)+vehicleCounts(start:start+24*4-1,i,4);
    start=start+24*4*7;
    while start<size(vehicleCounts,1)
        maxFlow1(:,i)=max(maxFlow1(:,i),vehicleCounts(start:start+24*4-1,i,1));
        minFlow1(:,i)=min(minFlow1(:,i),vehicleCounts(start:start+24*4-1,i,1));
        maxFlow2(:,i)=max(maxFlow2(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2));
        minFlow2(:,i)=min(minFlow2(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2));
        maxFlow3(:,i)=max(maxFlow3(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3));
        minFlow3(:,i)=min(minFlow3(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3));
        maxFlow4(:,i)=max(maxFlow4(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3)+vehicleCounts(start:start+24*4-1,i,4));
        minFlow4(:,i)=min(minFlow4(:,i),vehicleCounts(start:start+24*4-1,i,1)+vehicleCounts(start:start+24*4-1,i,2)+vehicleCounts(start:start+24*4-1,i,3)+vehicleCounts(start:start+24*4-1,i,4));
        start=start+24*4*7;
    end
end
%% Determine Bounded Toll Values
start=24*4*6+1;maxToll1=tollAmount(start:start+24*4-1,1,1);minToll1=tollAmount(start:start+24*4-1,1,1);
maxToll2=tollAmount(start:start+24*4-1,2,3);minToll2=tollAmount(start:start+24*4-1,2,3);
maxToll3=tollAmount(start:start+24*4-1,4,4);minToll3=tollAmount(start:start+24*4-1,4,4);
start=start+24*4*7;
while start<size(tollAmount,1)
    maxToll1=max(maxToll1,tollAmount(start:start+24*4-1,1,1));
    minToll1=min(minToll1,tollAmount(start:start+24*4-1,1,1));
    maxToll2=max(maxToll2,tollAmount(start:start+24*4-1,2,3));
    minToll2=min(minToll2,tollAmount(start:start+24*4-1,2,3));
    maxToll3=max(maxToll3,tollAmount(start:start+24*4-1,4,4));
    minToll3=min(minToll3,tollAmount(start:start+24*4-1,4,4));
    start=start+24*4*7;
end
%% Plot Boundary Values
figure;
subplot(1,2,1);
plot(tStep,maxFlow1(:,1),'b');hold on;plot(tStep,minFlow1(:,1),'b');
plot(tStep,maxFlow2(:,1),'r');plot(tStep,minFlow2(:,1),'r');
plot(tStep,maxFlow3(:,1),'g');plot(tStep,minFlow3(:,1),'g');
plot(tStep,maxFlow4(:,1),'k');plot(tStep,minFlow4(:,1),'k');
xlabel('Time');ylabel('Vehicle Count');
subplot(1,2,2);
plot(tStep,maxToll1,'k');hold on;plot(tStep,minToll1,'r');
xlabel('Time');ylabel('Toll');
figure;
subplot(1,2,1);
plot(tStep,maxFlow1(:,2),'b');hold on;plot(tStep,minFlow1(:,2),'b');
plot(tStep,maxFlow2(:,2),'r');plot(tStep,minFlow2(:,2),'r');
plot(tStep,maxFlow3(:,2),'g');plot(tStep,minFlow3(:,2),'g');
plot(tStep,maxFlow4(:,2),'k');plot(tStep,minFlow4(:,2),'k');
xlabel('Time');ylabel('Vehicle Count');
subplot(1,2,2);
plot(tStep,maxToll2,'k');hold on;plot(tStep,minToll2,'r');
xlabel('Time');ylabel('Toll');
figure;
subplot(1,2,1);
plot(tStep,maxFlow1(:,3),'b');hold on;plot(tStep,minFlow1(:,3),'b');
plot(tStep,maxFlow2(:,3),'r');plot(tStep,minFlow2(:,3),'r');
plot(tStep,maxFlow3(:,3),'g');plot(tStep,minFlow3(:,3),'g');
plot(tStep,maxFlow4(:,3),'k');plot(tStep,minFlow4(:,3),'k');
xlabel('Time');ylabel('Vehicle Count');
subplot(1,2,2);
plot(tStep,maxToll2,'k');hold on;plot(tStep,minToll2,'r');
xlabel('Time');ylabel('Toll');
figure;
subplot(1,2,1);
plot(tStep,maxFlow1(:,4),'b');hold on;plot(tStep,minFlow1(:,4),'b');
plot(tStep,maxFlow2(:,4),'r');plot(tStep,minFlow2(:,4),'r');
plot(tStep,maxFlow3(:,4),'g');plot(tStep,minFlow3(:,4),'g');
plot(tStep,maxFlow4(:,4),'k');plot(tStep,minFlow4(:,4),'k');
xlabel('Time');ylabel('Vehicle Count');
subplot(1,2,2);
plot(tStep,maxToll3,'k');hold on;plot(tStep,minToll3,'r');
xlabel('Time');ylabel('Toll');
%% Calculating total Toll
TotalToll=zeros(1,31);
for i=1:length(Toll)
    day=EntryTime(i);
    day=str2double(datestr(day,'dd'));
    TotalToll(day)=TotalToll(day)+Toll(i);
end
%% Determining the percent of total in the HOT lane
totalHOTflow=sum(vehicleCounts,3)*4;timeSpaces=1:3:288;
percentIn4=totalHOTflow(:,4)./flow;
plot(timeStep,percentIn4);
%% Linear relationship of mainline flow, HOT flow, toll price
tollComplete=tollAmount(:,1,1);tollComplete(isnan(tollComplete))=0;
variables=[totalHOTflow(:,1,4),flow,tollComplete];
SOVHOTflow=vehicleCounts(:,1,4)*4;
proportion=(variables'*variables)^-1*variables'*SOVHOTflow;

congestionPeriods=[21:36 65:76];timeTrack=[];
for i=0:30
    timeTrack=[timeTrack congestionPeriods+i*96];
end

variables=[totalHOTflow(timeTrack,1,4),flow(timeTrack),tollComplete(timeTrack)];
SOVHOTflow=vehicleCounts(timeTrack,1,4)*4;
proportion=(variables'*variables)^-1*variables'*SOVHOTflow;
%% Plot toll rate
plot(tollComplete(timeTrack),totalHOTflow(timeTrack,1,1),'.')
%% Plot toll rate at points of change
tollComplete=tollAmount(:,2,3);tollComplete(isnan(tollComplete))=0;
currPrice=tollComplete(timeTrack(1));
place=timeTrack(1);
for i=2:length(timeTrack)
    if tollComplete(timeTrack(i))~=currPrice
        currPrice=tollComplete(timeTrack(i));
        place=[place;timeTrack(i)];
    end
end
plot(tollComplete(timeTrack),totalHOTflow(timeTrack,3),'.-')
%% Flow on PeMS vs Fastrak
detectorlocHOV=[762404 762492 717140];flow=[];%segment=segment(2:end);
for i=10:31
    load(['C:\Users\Brian\Documents\Research\HOTdata\PeMS\processed\pems5min_2014_01_' num2str(i) '.mat'])
    flow=[flow; sum(pems.data(pems.vds==detectorlocHOV(3)).flw,2)];
end
i=1;
while i<length(flow)
    flow(i+1:i+2)=[];
    i=i+1;
end
plot(timeStep,flow);hold on;
plot(timeStep,totalHOTflow(:,4),'r');