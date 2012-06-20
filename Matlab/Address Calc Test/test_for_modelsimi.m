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

%% run loop and print output to file
%create a file named input.txt in current dir, with write permission
fid = fopen('..\..\test_matlab.txt', 'w');  
fprintf(fid,'#tl\t#tr\t#bl\t#br\t#d_row\t#d_col\t#out_of_range\r\n');
for t=1:1:600
    for s=1:1:800

%for t=1:1:VerResOut
   % for s=1:1:HorResOut
         i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*111/128+m/2);
         j =(  -ZoomFactor*(t-VerResOut/2)*111/128 +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);
         if i>=1 && j>=1 && i<=m-1 && j<=n-1%check if i,j are out of range
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
              tl=(inFloorI-1)*YSizeIn+inFloorJ;
              tr=(inFloorI-1)*YSizeIn+inCeilingJ;
              bl=(inCeilingI-1)*YSizeIn+inFloorJ;
              br=(inCeilingI-1)*YSizeIn+inCeilingJ;
              
              
              %print to file
              fprintf(fid,'%d ',s);
              fprintf(fid,'%d ',t);
              fprintf(fid,'%d ',tl);
              fprintf(fid,'%d ',tr);
              fprintf(fid,'%d ',bl);
              fprintf(fid,'%d ',br);
              fprintf(fid,'%2.0f ',deltaI*128);
              fprintf(fid,'%2.0f ',deltaJ*128);

              fprintf(fid,'%d\t\r\n',out_of_range);
         else
              %i,j are out of range 
              out_of_range=1;
              fprintf(fid,'%d ',s);
              fprintf(fid,'%d ',t);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d ',0);
              fprintf(fid,'%d\t\r\n',out_of_range);
         end
    end   
end
         fclose (fid);

