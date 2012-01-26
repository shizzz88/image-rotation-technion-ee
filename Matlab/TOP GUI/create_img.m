
clear all
a=[0.9 0.8 0.7 0.6 0.5]
b=[ 0 0 0 0 0]
c=[a b]
for i=1:64
    for j=1:10
    row(j+10*(i-1))=c(j);
    end
end
for i=1:480
    Image(i,:)=row;
end;

imshow(Image)
imwrite(
