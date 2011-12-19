close all

x(x>1)=1;
x(x<-0.0099)=-0.0099;

a = 1;
nobs = 20;
b = [ones(nobs,1)/nobs];
y = x;
y2= y(nobs/2:length(y),:);
i = 0;

colour(1,:)=[1.0 0.0 0.0];
colour(2,:)=[0.0 1.0 0.0];
colour(3,:)=[0.0 0.0 1.0];

for k = 1:9
    figure
for j = 1:3
    i = i+1;
    data=(x(:,i+3));
    y(:,i+3) = filter(b,a,data);
    y2(:,i+3)=y(nobs/2:length(y),i+3);
    
%     subplot(2,1,1)
%     plot(x(:,i+3),'color',colour(j,:));hold on
%     ylim([0 0.5])
%     subplot(2,1,2)
%     plot(y(nobs/2:length(y),i+3),'color',colour(j,:)); hold on
%     ylim([0 0.5])

    subplot(3,1,j)
    plot(x(:,i+3),'b');hold on
    plot(y(nobs/2:length(y),i+3),'r'); hold on
    ylim([0 0.5])
end
end

shallow =[4 7 10 13 16 19 22 25 28];
medium = [5 8 11 14 17 20 23 26 29];
deep =   [6 9 12 15 18 21 24 27 30];

figure;
subplot(2,1,1)
plot(y2(:,shallow)); hold on
subplot(2,1,2)
plot(mean(y2(:,shallow)'),'k','linewidth',2)

figure;
subplot(2,1,1)
plot(y2(:,medium)); hold on
subplot(2,1,2)
plot(mean(y2(:,medium)'),'k','linewidth',2)

figure;
subplot(2,1,1)
plot(y2(:,deep)); hold on
subplot(2,1,2)
plot(mean(y2(:,deep)'),'k','linewidth',2)
