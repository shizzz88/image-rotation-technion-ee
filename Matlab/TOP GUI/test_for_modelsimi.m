clc
clear all
%teta=0*60/180*pi;
teta=60/180*pi;
%s=304;%col indx
t=301;%row indx
s=301;
HorResOut=800;
VerResOut=600;
n=100;
m=67;
Xstart=30;
Ystart=29;
ZoomFactor=0.25;
result=zeros(30,3);
for index=1:1:30

result(index,1)=s;
i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*sin(teta)+m/2);
j =(  -ZoomFactor*(t-VerResOut/2)*sin(teta) +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);

i=i+Xstart ;
j=j+Ystart;
result(index,2)=i;
result(index,3)=j;
s=s+1;
end
