clc
clear all
close all
 ImIn=imread('lena.jpg'); %-------------DELETE
% ImIn=uint8(zeros(200,200));
%     ImIn(1:10:200,:)=256;
     figure
  imshow(ImIn);
Xstart=1;Ystart=1; %-------------DELETE
VerResOut=200;HorResOut=400;   
angle=0; %-------------DELETE
    ZoomFactor=1;
    ImOut = Imrotate3(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);
 figure
    imshow(ImOut);
    title('bilinear interpolation');
%revision test
    

    