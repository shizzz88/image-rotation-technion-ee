clc
clear all
teta=0;
s=301;
t=301;
HorResOut=800;
VerResOut=600;
n=100;
m=67;
Xstart=30;
Ystart=29;
ZoomFactor=0.25;
i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*sin(teta)+m/2);
j =(  -ZoomFactor*(t-VerResOut/2)*sin(teta) +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);

i=i+Xstart 
j=j+Ystart