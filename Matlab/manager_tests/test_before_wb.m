 clc
 clear all
 close all
%% notation
%row=vertical=t,x
%col=horizontal=s,y
%                        MATH Functionality- EXPLAINED
% 
% 						- - - - Col,y - - - - 
% 				 		---------------------
% 				 |		|                   | 
% 				 |		|                   | 
% 				 |		|                   | 
% 			Row,x		|     	Image       | 
% 				 |		|                   | 
% 				 |		|                   | 
% 				 |		|                   | 
% --				 		---------------------
%% IMPORTFILE(FILETOREAD1)
%  Imports data from the specified file
%  FILETOREAD1:  file to read

%  Auto-generated by MATLAB on 19-Jun-2012 11:37:02

% Import the file

row=1;
col=1;


filename='..\..\img_mang_toRAM_test.txt';

%# read the whole file to a temporary cell array
fid = fopen(filename,'rt');
tmp = textscan(fid,'%s','Delimiter','\n');
fclose(fid);

%# remove the lines starting with headerline
tmp = tmp{1};

HorResOut=256;
VerResOut=256;


%new loop - row build
ImOut=uint8(zeros(VerResOut,HorResOut));
for row=1:VerResOut%:-1:1
    for col=1:HorResOut %:-1:1
       if ((row-1)*HorResOut +col) > size(tmp) 
           break;
       end
%         if strcmp(tmp((row-1)*HorResOut+col),'XXXXXXXX')
%              ImOut(row,col)=0;
%        else
           ImOut(row,col)=bin2dec(tmp((row-1)*HorResOut+col));
%        end

   end
end


figure(1)
imshow(ImOut,[])%
title('to RAM');

%% to SDRAM img
row=1;
col=1;


filename='..\..\img_mang_toSDRAM_test.txt';

%# read the whole file to a temporary cell array
fid = fopen(filename,'rt');
tmp = textscan(fid,'%s','Delimiter','\n');
fclose(fid);

%# remove the lines starting with headerline
tmp = tmp{1};




%new loop - row build
ImOut=uint8(zeros(VerResOut,HorResOut));
for row=1:VerResOut%:-1:1
    for col=1:HorResOut %:-1:1
       if ((row-1)*HorResOut +col) > size(tmp) 
           break;
       end
        if strcmp(tmp((row-1)*HorResOut+col),'UUUUUUUU')
             ImOut(row,col)=0;
       else
           ImOut(row,col)=bin2dec(tmp((row-1)*HorResOut+col));
        end

   end
end


figure(2)
imshow(ImOut,[])%
title('to SDRAM');
