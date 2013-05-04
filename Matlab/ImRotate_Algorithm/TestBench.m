clc
clear all
close all
 ImIn=imread('../../General/Test Images/lena96_input for uart.jpg'); %-------------DELETE
     
 figure
  imshow(ImIn);
Xstart=1;Ystart=1; %-------------DELETE
% VerResOut=600+1-Xstart;
% HorResOut=800+1-Ystart;  
 VerResOut=600;
 HorResOut=800;   

angle=60; %-------------DELETE
    ZoomFactor=1;
    [ImOut,imOut_addresses] = Imrotate6(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);
%     [ImOut] = Imrotate5(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut);

 figure
    imshow(ImOut);
    title('bilinear interpolation with sine using  taylor expansion');
%revision test
    

    