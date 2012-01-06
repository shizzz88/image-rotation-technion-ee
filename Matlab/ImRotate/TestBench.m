clc
clear all
close all
 ImIn=imread('Lena.jpg'); %-------------DELETE
     
 figure
  imshow(ImIn);
Xstart=1;Ystart=1; %-------------DELETE
VerResOut=512+1-Xstart;
HorResOut=512+1-Ystart;   
angle=20; %-------------DELETE
    ZoomFactor=1;
    ImOut = Imrotate3(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);
 figure
    imshow(ImOut);
    title('bilinear interpolation with sine using  taylor expansion');
%revision test
    

    