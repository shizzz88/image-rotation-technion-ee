clc
clear all
close all
 ImIn=imread('Lena8bit.bmp'); %-------------DELETE
     
 figure
  imshow(ImIn);
Xstart=29;Ystart=30; %-------------DELETE
% VerResOut=600+1-Xstart;
% HorResOut=800+1-Ystart;  
 VerResOut=600;
 HorResOut=800;   

angle=60; %-------------DELETE
    ZoomFactor=4;
    ImOut = Imrotate5(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);
 figure
    imshow(ImOut);
    title('bilinear interpolation with sine using  taylor expansion');
%revision test
    

    