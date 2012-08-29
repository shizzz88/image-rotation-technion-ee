 clc
 clear all
 close all
 top_left=96;
 top_right=101;
 bottom_left=248;
 bottom_right=185;
 delta_row=121/127;
 delta_col=65/127  ;     
 I1=(1-delta_col)*top_left+delta_col*top_right;
 I2=(1-delta_col)*bottom_left+delta_col*bottom_right;
 pixel_res=(1-delta_row)*I1+delta_row*I2
 
 top_left=64;
 top_right=81;
 bottom_left=8;
 bottom_right=73;
 delta_row=121/127;
 delta_col=97/127;       
 I1=(1-delta_col)*top_left+delta_col*top_right;
 I2=(1-delta_col)*bottom_left+delta_col*bottom_right;
 pixel_res=(1-delta_row)*I1+delta_row*I2
 
 top_left=208;
 top_right=193;
 bottom_left=72;
 bottom_right=89;
 delta_row=57/127;
 delta_col=37/127;
 I1=(1-delta_col)*top_left+delta_col*top_right;
 I2=(1-delta_col)*bottom_left+delta_col*bottom_right;
 pixel_res=(1-delta_row)*I1+delta_row*I2
 
 
 top_left=208;
 top_right=81;
 bottom_left=76;
 bottom_right=1;
 delta_row=41/127;
 delta_col=101/127;
 I1=(1-delta_col)*top_left+delta_col*top_right;
 I2=(1-delta_col)*bottom_left+delta_col*bottom_right;
 pixel_res=(1-delta_row)*I1+delta_row*I2