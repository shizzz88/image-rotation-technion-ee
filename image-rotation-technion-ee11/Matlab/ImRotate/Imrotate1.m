function [ImOut] = Imrotate1(ImIn,angle,ZoomFactor,Xstart,Ystart)
    %rotate an image without bilinear interpolation

   
    
    %Add input validation test
%     GoodInput=1;
%     if GoodInput then
  
  %clip Image according to Xstart, Ystart
I=ImIn(Xstart:end,Ystart:end,1:end); % I is clipped image

%enclosing rectanle size using Pythagoras
[m,n,p]=size(I);
Nrect=ceil(sqrt(m*m+n*n))+1;

%image alocation 'for speed
 ImOut=uint8(zeros(Nrect,Nrect,p));



%angle to Radians
teta=angle/180*pi;
%inverse zoom factor
ZoomFactor=1/ZoomFactor;

for t=1:Nrect
   for s=1:Nrect 
      i =uint16(   ZoomFactor*(t-Nrect/2)*cos(teta) + ZoomFactor*(s-Nrect/2)*sin(teta)+m/2);% evaluate row index in original image
      j =uint16(  -ZoomFactor*(t-Nrect/2)*sin(teta) +ZoomFactor* (s-Nrect/2)*cos(teta)+n/2);% evaluate coloumn index in original image
      if i>0 && j>0 && i<=m && j<=n           
         ImOut(t,s,:)=I(i,j,:);
      end
   end
end
end

% imshow(ImOut)

        