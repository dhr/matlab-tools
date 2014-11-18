function rgby = makeRGBY(img)

rgby = cat(3, img, (img(:,:,1) + img(:,:,2))/2);
