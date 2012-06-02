clc
clear all
close all
%% notation
%row=vertical=t,x
%col=horizontal=s,y
tic;%start measure time
%% input data
teta=60/180*pi;
ColResOut=800;
RowResOut=600;
XSizeIn=96;
YSizeIn=128;
Xstart=30;
Ystart=29;
m=XSizeIn+1-Xstart;%m=67
n=YSizeIn+1-Ystart;%n=100
ZoomFactor=0.25;

%turn numbers to binary and multiply by 128
trig_frac_size=7;
fix_factor=2^trig_frac_size;

zoom_factor=dec2bin(uint8(ZoomFactor*fix_factor),trig_frac_size+1); %8 bits
sin_teta=dec2bin(uint8(sin(teta)*fix_factor),trig_frac_size+1);     %8 bits
cos_teta=dec2bin(uint8(cos(teta)*fix_factor),trig_frac_size+1);     %8 bits
ram_start_add_in=dec2bin(0,22);                                     %22 bits
x_crop_start=dec2bin(Xstart,10);
y_crop_start=dec2bin(Ystart,10);
fid = fopen('input_test.txt', 'w');  
fprintf(fid,'#zoom_factor\t#sin_teta\t#cos_teta\t#x_crop_start\t#y_crop_start\t#ram_start_add_in\r\n');
fprintf(fid,'%s\t',zoom_factor);
fprintf(fid,'%s\t',sin_teta);
fprintf(fid,'%s\t',cos_teta);
fprintf(fid,'%s\t',x_crop_start);
fprintf(fid,'%s\t',y_crop_start);
fprintf(fid,'%s\t\r\n',ram_start_add_in);

fprintf(fid,'#col_idx_in\t#row_idx_in\r\n');
for row_idx_in=1:1:RowResOut
    for col_idx_in=1:1:ColResOut
        fprintf(fid,'%s\t',dec2bin(col_idx_in,10));                     %10 bits
        fprintf(fid,'%s\t\r\n',dec2bin(row_idx_in,10));                     %10 bits
    end   
end

fclose (fid);
toc%stop measure time - 140 seconds
