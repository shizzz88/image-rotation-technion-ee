function [img] = decompress_img (varargin)
%%
% decompress_img (InArg)
%
% Input parameters:
%       InArg - Compressed variable to be decompressed
%
% Output parameters:
%       ImageName - Decompressed image (matlab format)
%
% Description:
% The function decompress an image, into a matlab matrix
%
% Usage example:
%       dec_img = decompress_img(cmp_img, [640 480]);
%  - cmp_img is the matrix compressed by 'compress_img.m'.
    
    %% Validate input arguments 
    if nargin ~= 2
        error('Please enter a compressed variable name, and its size');
    end
    
    %% Extract data from compressed image
    cmpImg = varargin{1};
    cmpImgSize = numel(cmpImg(:,1)); %% Number of data rows
    
    %% Decompress image
    img = zeros(varargin{2}(2), varargin{2}(1),'uint8');
    pos = 1;
    
    for cnt = 1:cmpImgSize
        %Decompress image
        img(pos:(pos+cmpImg(cnt,2))) = repmat(cmpImg(cnt,1), cmpImg(cnt,2)+1,1); % Decompress image R
       
        %Position increment
        pos = pos + cmpImg(cnt,2)+1;
    end
end