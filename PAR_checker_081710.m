close all
clear all

load PPine_PAR.mat

x(x==-9999)=nan;

b = regress(x(:,3),x(:,2));
fit = b.*(x(:,2));
figure; 
plot(x(:,2),x(:,3),'bo'); hold on; 


bb = regress(x(:,6),x(:,5));
fit2 = bb.*(x(:,5));

plot(x(:,5),x(:,6),'go')
plot(x(:,5),fit2,'m','linewidth',3)
plot(x(:,2),fit,'r','linewidth',3)

c=bb-b;

add=c.*x(:,2);

plot(x(:,2),(x(:,3)+add),'k.')


figure;
plot(x(:,1),(x(:,3)+add),'k.'); hold on
plot(x(:,1),x(:,3),'b.'); hold on
plot(x(:,4),x(:,6),'g.'); hold on