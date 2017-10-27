labelTotal


trainSet.labelAll = [];
trainSet.absIdxAll = [];

% loop to combine clusters
for m = 1 : size(trainSet.label, 2)
    trainSet.labelAll = [trainSet.labelAll trainSet.label{m}];
    trainSet.absIdxAll = [trainSet.absIdxAll; trainSet.absIdx{m}];  % row or column?
end
trainSet.labelAll = vec2ind(trainSet.labelAll);

% loop to separate each channel into cells
for s = sensor.numVec
    idxTemp = [trainSet.absIdxAll(:, 2) == s];
    sensor.label.manual{s} = trainSet.labelAll(idxTemp);
    sensor.absIdx{s} = trainSet.absIdxAll(idxTemp, :);
end

% sort in time order
for s = sensor.numVec
    [sensor.absIdx{s}, idxTemp] = sortrows(sensor.absIdx{s}, [1 2]);
    sensor.label.manual{s} = sensor.label.manual{s}(idxTemp);
end

% training set panorama
dirName.plotPanoTrainSet = [dirName.mat 'panorama/'];
if ~exist(dirName.plotPanoTrainSet, 'dir'), mkdir(dirName.plotPanoTrainSet); end
for s = sensor.numVec
    if mod(s,2) == 1
        yStrTemp = '';
    else
        yStrTemp = sprintf('      %02d', s);
    end
    panorama(sensor.date.serial{s}, sensor.label.manual{s}, yStrTemp, color(1:labelTotal));
    dirName.panoramaTrainSet{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_trainingSetLabelPanorama.png'];
    saveas(gcf,[dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]);
    fprintf('\nSenor-%02d training set panorama file location:\n%s\n', ...
        s, GetFullPath([dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]))
    close
    
end

n = 0;
panopano = [];
for s = sensor.numVec
    n = n + 1;
    p{s} = imread(GetFullPath([dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]));
    if n > 1
        height = size(p{s},1);
        width = size(p{s},2);
        p{s} = p{s}(1:ceil(height*0.22), :, :);
    end
    panopano = cat(1, p{s}, panopano);
end
dirName.panopanoTrainSet = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                    '_trainingSetLabelPanorama.tif'];
imwrite(panopano, [dirName.plotPanoTrainSet dirName.panopanoTrainSet]);




