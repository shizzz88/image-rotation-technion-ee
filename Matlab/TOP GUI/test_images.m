%% test image 1
test_image1=uint8(zeros(480,640));
test_image1(:,:)=200;
test_image1(:,320)=15;

%% test image 2
test_image2=uint8(zeros(480,640));
test_image2(:,:)=200;
test_image2(240,:)=15;
%% test image 3
test_image3=uint8(zeros(480,640));
test_image3(:,:)=200;
test_image3(:,1:2:end)=15;%% test image 3
%% test image 4
test_image4=uint8(zeros(32,32));
for i=2:32
test_image4(i,:)=test_image4(i-1,:)+8
end
%% test 5 - chess
test_image5=uint8(zeros(32,32));
test_image5(:,:)=32;
test_image5(1:2:end,1:2:end)=254;
test_image5(2:2:end,2:2:end)=254;
