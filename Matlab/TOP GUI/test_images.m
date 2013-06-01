%% test image 1
test_image=uint8(zeros(480,640));
test_image(:,:)=200;
test_image(:,320)=15;
imshow(test_image)

%% test image 2
test_image=uint8(zeros(480,640));
test_image(:,:)=200;
test_image(240,:)=15;
imshow(test_image)

%% test image 3
test_image=uint8(zeros(480,640));
test_image(:,:)=200;
test_image(:,1:2:end)=15;%% test image 3

imshow(test_image)

%% test image 4
test_image=uint8(zeros(4,512));
for i=2:4
test_image(i,:)=test_image(i-1,:)+8
end
imshow(test_image)


%% test 5 - chess
test_image=uint8(zeros(32,32));
test_image(:,:)=32;
test_image(1:2:end,1:2:end)=254;
test_image(2:2:end,2:2:end)=254;
imshow(test_image)

%% test 6 - 
test_image=uint8(zeros(384,512));
for i=2:2:512
test_image(:,i)=test_image(:,i-1)+1;
test_image(:,i+1)=test_image(:,i-1)+1;
end
imshow(test_image)

%% test image 7
test_image=uint8(zeros(12,512));
x=uint8(linspace(1,256,512));
for i=1:2:12
    test_image(i,:)=x;
end

for i=2:2:12
    test_image(i,:)=fliplr(x);
end
imshow(test_image)
