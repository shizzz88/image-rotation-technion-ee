function [Varname] = compress_img (varargin)
%%
% Function compress_img (FileName)
% Input Arguments:
%       FileName - image file to load
%
% Output Arguments:
%        Varname  - Returned variable, which holds the image's data
%
% Description:
% The function compresses an image, and returns the compressed matrix
%
% Usage example:
%       cmp_img = compress_img('image.bmp', 256)

    %% Checks if file exists, and validate input
    if nargin ~= 2 %Only one input is allowed
        error ('Use: compress_img("FileName.bmp", MAX_NUM_OF_ELEMENTS'); %Exiting
    end
    
    if ~exist(varargin{1}, 'file') %Check if file exist in computer
        error('ErrorTests:convertTest', 'No such file name: %s', varargin{1});
    end

    %% Load image
    % varagin{1} - File name. i.e: 'image.bmp'
    % varagin{2} - Maximum identical pixel to compress in the same data
    
    MAX_CMP_SIZE = varargin{2}; %Maximum identical pixels to compress
    img = imread(varargin{1}); %Read image from file
    img = img';
    
    imSize  = size(img,1) * size(img,2);
    
    cmp = zeros(imSize,2); % Compresses matrix

    cPosCmp = 1; % Position in compressed matrix
    cPos = 1; % Position in original matrix

    %% Compress image
    %TODO: Writing to file is TEMPORARY. REMOVE text writing after VHDL
    %design
       
    %fid = fopen('exp.txt', 'w');  % open the file with write permission
    %fprintf(fid, '#Color\tRepetition\r\n'); %%Write color value into text file
    while (cPos <= imSize)
        numFound = find( img(cPos:min([cPos+MAX_CMP_SIZE imSize])) ~= img(cPos),1) - 1; %Number of repetitions for a color
        cmp(cPosCmp,1) = img(cPos); % Color value
        %fprintf(fid, '%02X\t\t', img(cPos)); %%Write color value into text file
        if (cPos+MAX_CMP_SIZE >= imSize) % Last value
            cmp(cPosCmp, 2) = imSize - cPos;
            %fprintf(fid, '%02X', cmp(cPosCmp, 2) ); %write color repetitions to file
            cPos = imSize + 1;
        else
            if isempty(numFound) %All MAX_CMP_SIZE are the same color
                numFound =MAX_CMP_SIZE;
            end
            cmp(cPosCmp, 2) = numFound - 1;
            %fprintf(fid, '%02X\r\n', cmp(cPosCmp, 2) ); %write color repetitions to file
            cPos = cPos + numFound;
            cPosCmp = cPosCmp + 1;
        end
    end
    
    %fclose(fid); %Closes file.

        
   %% Place compressed image into variable
   Varname = cmp(1:cPosCmp, :);
   Varname = Varname';
end