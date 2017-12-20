pathRoot = 'C:\Users\Owner\Google Drive\research\17-2 aut-phd-year2-1\secondPaper!\images\samples';

for n = 1 : 7
    img = imread(sprintf('%s/type-%d.tif', pathRoot, n));
    imgResize = imresize(img, [100, 100]);
    imwrite(imgResize, sprintf('%s/type-%d_resized.tif', pathRoot, n))
end