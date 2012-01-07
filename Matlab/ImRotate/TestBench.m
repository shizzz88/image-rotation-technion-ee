clc
clear all
close all
 ImIn=imread('Lena.jpg'); %-------------DELETE
     
 figure
  imshow(ImIn);
Xstart=0;Ystart=1; %-------------DELETE
% VerResOut=600+1-Xstart;
% HorResOut=800+1-Ystart;  
 VerResOut=600;
 HorResOut=800;   

angle=20; %-------------DELETE
    ZoomFactor=1;
    ImOut = Imrotate5(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);
 figure
    imshow(ImOut);
    title('bilinear interpolation with sine using  taylor expansion');
%revision test
    

    