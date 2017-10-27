function [dataForClust absIdx] = genDataForClust(sensorNumVec, clustRatio, sensorImage, downSampRatio)
% generating data set for clustering. The absolute index (absIdx) is the number
% of hour (time) and number of channel (location)

absIdx = [];
absIdxTemp = [];
hourTotal = size(sensorImage{sensorNumVec(1)}, 2);
num = floor(hourTotal*clustRatio);
for s = 1 : length(sensorNumVec)
    rng(s,'twister');
    absIdxTemp = randsample(hourTotal, num);
    absIdxTemp(:,2) = sensorNumVec(s);
    absIdx = [absIdx; absIdxTemp]; 
end

fprintf('\nGenerating randomly selected data set for clustering...\n')
dataForClust = single([]);
dyadNum = log2(downSampRatio);
for n = 1 : size(absIdx, 1)
    imgTemp1 = reshape(sensorImage{absIdx(n,2)}(1:10000, absIdx(n,1)), [100 100]);
    imgTemp2 = reshape(sensorImage{absIdx(n,2)}(10001:20000, absIdx(n,1)), [100 100]);
    for m = 1 : dyadNum
        imgTemp1 = dyaddown(imgTemp1, 'm', 1);
        imgTemp2 = dyaddown(imgTemp2, 'm', 1);
    end
    dataForClust(:,n) = [imgTemp1(:); imgTemp2(:)];
    if mod(n, 1000) == 0
        fprintf('\nNow: %d-%d finish! Total: %d\n', n-1000, n, size(absIdx, 1))
    end
end

end