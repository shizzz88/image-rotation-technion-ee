clc
clear all
close all
%% notation
%row=vertical=t,x
%col=horizontal=s,y

%% input data
teta=60/180*pi;
HorResOut=800;
VerResOut=600;
XSizeIn=96;
YSizeIn=128;
Xstart=30;
Ystart=29;
m=XSizeIn+1-Xstart;%m=67
n=YSizeIn+1-Ystart;%n=100
ZoomFactor=0.25;

[t,s]=meshgrid(1:1:600,1:1:800);

i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*111/128+m/2);
j =(  -ZoomFactor*(t-VerResOut/2)*111/128 +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);

x=(i>=1);
%tbc