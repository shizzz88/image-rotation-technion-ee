function [ImOut] = Imrotate4(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut)
    %rotate an image with bilinear interpolation, with taylor sine
% input parameters : angle-output image rotation angle, ZoomFactor - output image zoom ratio around the center of the image, 
%Xstart,Ystart - output image starting crop coordinate; 0,0 is top left corner    
%VerResOut,HorResOut - dimension of required output image, must be smaller than input image     
    
    
   % input validation test
  if ZoomFactor<=0 % zoom factor must be positive
      error('Aborting, ZoomFactor must be postive non-zero');
  end;
  if Xstart<=0 %x start - must be positive
      error('Aborting, Xstart must be postive non-zero');
  end;
  if Ystart<=0%y start - must be positive
      error('Aborting, Ystart must be postive non-zero');
  end;
  if VerResOut<=0 %Vertical Resolution - must be positive
      error('Aborting, VerResOut must be postive non-zero');
  end;
  if HorResOut<=0%Horizontal Resolution - must be positive
      error('Aborting, HozResOut must be postive non-zero');
  end;
  
  %Input Image Size, calculates input image size for testing
  [XSizeIn,YSizeIn,p]=size(ImIn);
  
  % Test Input for  Resolution
  if Xstart+VerResOut>XSizeIn+1 % test for correct image size in vertical axis
      error('Aborting, Output image resolution exceeds Input image Resolution');
  end;
    if Ystart+HorResOut>YSizeIn+1 % test for correct image size in horizontal axis
      error('Aborting, Output image resolution exceeds Input image Resolution');
  end;
  
  
%clip Image according to Xstart, Ystart
I=ImIn(Xstart:end,Ystart:end,1:end); % I is clipped image
[m,n,p]=size(I); %size of Clipped Pic


%blank image alocation 'for speed
 ImOut=uint8(zeros(VerResOut,HorResOut,p));

 %--------------------------------------------------------------------------
 %  SCALE factor - used to scale big image to small from and viseversa
 %XFactor=XSizeIn/VerResOut;% scaling factor for x axis (row) in case res out smaller than res in
  %YFactor=YSizeIn/HorResOut; % scaling factor for y axis (coloumn) in case res out smaller than res in
%--------------------------------------------------------------------------


% convert angle to Radians
teta=angle/180*pi;

% inverse zoom factor
ZoomFactor=1/ZoomFactor;

% operating zoom, rotation, resolution change. 
cos_teta=1-teta*teta/2+(teta^4)/24;%taylor series of cosine function
sin_teta=teta-teta*teta*teta/6+(teta^5)/120;%taylor series of sine function

for t=1:VerResOut
   for s=1:HorResOut 
       i =(   ZoomFactor*(t-VerResOut/2)*cos_teta + ZoomFactor*(s-HorResOut/2)*sin_teta+m/2);% evaluate row index in original image
      j =(  - ZoomFactor*(t-VerResOut/2)*sin_teta + ZoomFactor* (s-HorResOut/2)*cos_teta+n/2);% evaluate coloumn index in original image

 % ----------- use this version if you want auto image SCALING--------------
%        i =(   XFactor*ZoomFactor*(t-VerResOut/2)*cos_teta +  XFactor*ZoomFactor*(s-HorResOut/2)*sin_teta+m/2);% evaluate row index in original image
%       j =(  - YFactor*ZoomFactor*(t-VerResOut/2)*sin_teta + YFactor*ZoomFactor* (s-HorResOut/2)*cos_teta+n/2);% evaluate coloumn index in original image
%------------------------------------------------------------------------------------------------------------- 

if i>1 && j>1 && i<=m-1 && j<=n-1           
            
 % Bilinear Interpolation Algorithm
 %
% round the values of i,j         
        inFloorJ=floor(j);
        inFloorI=floor(i);
        inCeilingJ=ceil(j);
        inCeilingI=ceil(i);
        
       
           deltaJ=j-inFloorJ;
           deltaI=i-inFloorI;

        
        I1=(1-deltaJ)*I(inFloorI,inFloorJ,:)+deltaJ*I(inFloorI,inCeilingJ,:);
        I2=(1-deltaJ)*I(inCeilingI,inFloorJ,:)+deltaJ*I(inCeilingI,inCeilingJ,:);
        ImOut(t,s,:)=(1-deltaI)*I1+deltaI*I2;
%         if I(t,s,:)<0 I(t,s,:)=0; end;
%         if I(t,s,:)>255 I(t,s,:)=255; end;
      end
   end
end
end

% imshow(ImOut)


        