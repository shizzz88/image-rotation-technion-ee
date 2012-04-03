function [ImOut] = Imrotate5(ImIn,angle,ZoomFactor,Xstart,Ystart,VerResOut,HorResOut)
    %rotate an image with bilinear interpolation
    %new modified crop compatible to hardware 
    
   % input validation test
  if ZoomFactor<=0
      msgbox('Aborting, ZoomFactor must be postive non-zero');
      error('Aborting, ZoomFactor must be postive non-zero');
  end;
  if Xstart<=0
      msgbox('Aborting, Xstart must be postive non-zero');      
      error('Aborting, Xstart must be postive non-zero');
  end;
  if Ystart<=0
      msgbox('Aborting, Ystart must be postive non-zero');
      error('Aborting, Ystart must be postive non-zero');
  end;
  if VerResOut<=0
      msgbox('Aborting, VerResOut must be postive non-zero');
      error('Aborting, VerResOut must be postive non-zero');
  end;
  if HorResOut<=0
       msgbox('Aborting, HozResOut must be postive non-zero');
      error('Aborting, HozResOut must be postive non-zero');
  end;
  
  %Input Image Size
  [XSizeIn,YSizeIn,p]=size(ImIn);
  
  % Test Input for  Resolution
%   if Xstart+VerResOut>XSizeIn+1
%       error('Aborting, Output image resolution exceeds Input image Resolution');
%   end;
%     if Ystart+HorResOut>YSizeIn+1
%       error('Aborting, Output image resolution exceeds Input image Resolution');
%   end;
  
  
% %clip Image according to Xstart, Ystart
%   I=ImIn(Xstart:end,Ystart:end,1:end); % I is clipped image
% [m,n,p]=size(I); %size of Clipped Pic

%evaluate output image size after crop
m=XSizeIn+1-Xstart;
n=YSizeIn+1-Ystart;

%image alocation 'for speed
 ImOut=uint8(zeros(VerResOut,HorResOut,p));

%   XFactor=XSizeIn/VerResOut; % scaling factor for x axis (row) in case res out smaller than res in
%   YFactor=YSizeIn/HorResOut; % scaling factor for y axis (coloumn) in case res out smaller than res in


% convert angle to Radians
teta=angle/180*pi;

% inverse zoom factor
ZoomFactor=1/ZoomFactor;

% operating zoom, rotation, resolution change. 
for t=1:VerResOut
   for s=1:HorResOut 
      i =(  ZoomFactor*(t-VerResOut/2)*cos(teta) +  ZoomFactor*(s-HorResOut/2)*sin(teta)+m/2);% evaluate row index in original image
      j =(  -ZoomFactor*(t-VerResOut/2)*sin(teta) +ZoomFactor* (s-HorResOut/2)*cos(teta)+n/2);% evaluate coloumn index in original image
      if i>1 && j>1 && i<=m-1 && j<=n-1           %check if evaluated [i,j] index exits outside of image else Imout=0 as previously defined
%crop image
          % after [i,j] indexes are evaluated as if ROI  was relocated to left corner (as if top of ROI indexes is [1,1],
           % then  we move [i,j] to ROI by [Xstart,Ystat].
            i=i+Xstart; %move row index
            j=j+Ystart; %move coloumn index
          
 % Bilinear Interpolation Algorithm
 %
% round the values of i,j         
        inFloorJ=floor(j);
        inFloorI=floor(i);
        inCeilingJ=ceil(j);
        inCeilingI=ceil(i);
        
       
           deltaJ=j-inFloorJ;
           deltaI=i-inFloorI;

        
        I1=(1-deltaJ)*ImIn(inFloorI,inFloorJ,:)+deltaJ*ImIn(inFloorI,inCeilingJ,:);%weighted avarage between two bottom pixels
        I2=(1-deltaJ)*ImIn(inCeilingI,inFloorJ,:)+deltaJ*ImIn(inCeilingI,inCeilingJ,:);%weighted avarage between two top pixels
        ImOut(t,s,:)=(1-deltaI)*I1+deltaI*I2;%weighted avarage between two values  avaraged values
%         if I(t,s,:)<0 I(t,s,:)=0; end;
%         if I(t,s,:)>255 I(t,s,:)=255; end;
      end
   end
end
end

% imshow(ImOut)


        