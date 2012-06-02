clc
clear all
close all
%% notation
%row=vertical=t,x
%col=horizontal=s,y

%% input data
teta=0/180*pi;
HorResOut=800;
VerResOut=600;
XSizeIn=96;
YSizeIn=128;
Xstart=30;
Ystart=29;
m=XSizeIn+1-Xstart;%m=67
n=YSizeIn+1-Ystart;%n=100
ZoomFactor=0.25;

%% run loop and print output to file
%create a file named input.txt in current dir, with write permission
fid = fopen('out_test.txt', 'w');  
fprintf(fid,'#inFloorJ\t#inFloorI\t#inCeilingJ\t#inCeilingI\t#inCeilingI\t#deltaJ\t#deltaI\t#out_of_range\r\n');
for t=1:1:VerResOut
    for s=1:1:HorResOut
         i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*sin(teta)+m/2);
         j =(  -ZoomFactor*(t-VerResOut/2)*sin(teta) +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);
         if i>1 && j>1 && i<=m-1 && j<=n-1%check if i,j are out of range
              %i,j are in range
              out_of_range=0;
              i=i+Xstart ;
              j=j+Ystart;
              inFloorJ=floor(j);
              inFloorI=floor(i);
              inCeilingJ=ceil(j);
              inCeilingI=ceil(i);
              deltaJ=j-inFloorJ;
              deltaI=i-inFloorI; 
              %print to file
              fprintf(fid,'%d\t',inFloorJ);
              fprintf(fid,'%d\t',inFloorI);
              fprintf(fid,'%d\t',inCeilingJ);
              fprintf(fid,'%d\t',inCeilingI);
              fprintf(fid,'%1.2f\t',deltaJ);
              fprintf(fid,'%1.2f\t',deltaI);
              fprintf(fid,'%d\t\r\n',out_of_range);
         else
              %i,j are out of range 
              out_of_range=1;
              fprintf(fid,'%d\t\r\n',out_of_range);
%               i=0;
%               j=0;
%               inFloorJ=floor(j);
%               inFloorI=floor(i);
%               inCeilingJ=ceil(j);
%               inCeilingI=ceil(i);
%               deltaJ=j-inFloorJ;
%               deltaI=i-inFloorI;
         end
    end   
end
         fclose (fid);

