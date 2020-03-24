function [hfs,has] = plotta_smith();

%% Smith Chart
theta = 0:pi/100:2*pi;
imma = -50:0.1:50;
rea = 0:0.1:50;
gammainf = exp(j.*theta);

r1 = [1+j.*imma];
r1d2 = [0.5+j.*imma];
r1d4 = [0.25+j.*imma];
r2 = [2+j.*imma];
r4 = [4+j.*imma];

i1 = [rea + j.*1];
i1d2 = [rea+j.*0.5];
i1d4 = [rea+j.*0.25];
i2 = [rea+j.*2];
i4 = [rea+j.*4];

gammar1 = (r1-1)./(r1+1);
gammar2 = (r2-1)./(r2+1);
gammar1d2 = (r1d2-1)./(r1d2+1);
gammar4 = (r4-1)./(r4+1);
gammar1d4 = (r1d4-1)./(r1d4+1);

gammai1 = (i1-1)./(i1+1);
gammai2 = (i2-1)./(i2+1);
gammai1d2 = (i1d2-1)./(i1d2+1);
gammai4 = (i4-1)./(i4+1);
gammai1d4 = (i1d4-1)./(i1d4+1);

hfs=figure;
has=axes;
hold on
plot([-1 1],[0 0],'k')
plot(real(gammainf),imag(gammainf),'k')
plot(real(gammar1),imag(gammar1),'k')
plot(real(gammar2),imag(gammar2),'k')
plot(real(gammar1d2),imag(gammar1d2),'k')
plot(real(gammar4),imag(gammar4),'k')
plot(real(gammar1d4),imag(gammar1d4),'k')
plot(real(gammai1),imag(gammai1),'k')
plot(real(gammai2),imag(gammai2),'k')
plot(real(gammai1d2),imag(gammai1d2),'k')
plot(real(gammai4),imag(gammai4),'k')
plot(real(gammai1d4),imag(gammai1d4),'k')
plot(real(gammai1),-imag(gammai1),'k')
plot(real(gammai2),-imag(gammai2),'k')
plot(real(gammai1d2),-imag(gammai1d2),'k')
plot(real(gammai4),-imag(gammai4),'k')
plot(real(gammai1d4),-imag(gammai1d4),'k')

end