function [ImOut] = Imrotate3(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut)
    %rotate an image with bilinear interpolation
    
   % input validation test
  if ZoomFactor<=0
      error('Aborting, ZoomFactor must be postive non-zero');
  end;
  if Xstart<=0
      error('Aborting, Xstart must be postive non-zero');
  end;
  if Ystart<=0
      error('Aborting, Ystart must be postive non-zero');
  end;
  if VerResOut<=0
      error('Aborting, VerResOut must be postive non-zero');
  end;
  if HorResOut<=0
      error('Aborting, HozResOut must be postive non-zero');
  end;
  
  %Input Image Size
  [XSizeIn,YSizeIn,p]=size(ImIn);
  
  % Test Input for  Resolution
  if Xstart+VerResOut>XSizeIn+1
      error('Aborting, Output image resolution exceeds Input image Resolution');
  end;
    if Ystart+HorResOut>YSizeIn+1
      error('Aborting, Output image resolution exceeds Input image Resolution');
  end;
  
  
%clip Image according to Xstart, Ystart
I=ImIn(Xstart:end,Ystart:end,1:end); % I is clipped image
[m,n,p]=size(I); %size of Clipped Pic


%image alocation 'for speed
 ImOut=uint8(zeros(VerResOut,HorResOut,p));

  XFactor=XSizeIn/VerResOut; % scaling factor for x axis (row) in case res out smaller than res in
  YFactor=YSizeIn/HorResOut; % scaling factor for y axis (coloumn) in case res out smaller than res in


% convert angle to Radians
teta=angle/180*pi;

% inverse zoom factor
ZoomFactor=1/ZoomFactor;

% operating zoom, rotation, resolution change. 
for t=1:VerResOut
   for s=1:HorResOut 
      i =(   XFactor*ZoomFactor*(t-VerResOut/2)*cos(teta) +  XFactor*ZoomFactor*(s-HorResOut/2)*sin(teta)+m/2);% evaluate row index in original image
      j =(  - YFactor*ZoomFactor*(t-VerResOut/2)*sin(teta) + YFactor*ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);% evaluate coloumn index in original image
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


        