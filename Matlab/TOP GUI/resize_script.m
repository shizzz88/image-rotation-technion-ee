clear all
close all
clc
%read image and requested resolution from user
%write new image in jpeg format
[FileName,PathName,FilterIndex] =uigetfile({'*.jpg;*.bmp','All Image Files';'*.*','All Files' },'Please Choose Image');
path_and_name=strcat(PathName,FileName);
[a,amap]=imread(path_and_name);
ainfo=imfinfo(path_and_name);


  
if ainfo.Format=='bmp'
        %change color map to gray scale
		amap=rgb2gray(amap);
		%get new resolution and file name from user
		prompt = {'Enter number of rows:','Enter number of coloums:','Enter Name for new fie'};
		dlg_title = 'Input required resolution';
		num_lines = 1;
		answer = inputdlg(prompt,dlg_title,num_lines);
		newres=[str2num(answer{1}),str2num(answer{2})];
		%resize image and colormap
		[b,bmap]=imresize(a,amap,newres);
		%imshow(b,bmap)
		filename=strcat(answer{3},'.bmp');
		%write new image to file
		imwrite(b,bmap,filename,'bmp');
else %input file is jpeg
    a=rgb2gray(a);
    prompt = {'Enter number of rows:','Enter number of coloums:','Enter Name for new fie'};
    dlg_title = 'Input required resolution';
    num_lines = 1;
    answer = inputdlg(prompt,dlg_title,num_lines);
    newres=[str2num(answer{1}),str2num(answer{2})];
    %resize image and colormap
    [b]=imresize(a,newres);
    %imshow(b,bmap)
    filename=strcat(answer{3},'.jpg');
    %write new image to file
    imwrite(b,filename,'jpg');
end