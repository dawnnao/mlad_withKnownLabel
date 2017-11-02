clear;clc;close all;

readRoot = 'C:/dataArchiveTemp/Sutong/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/mlad111/';
saveRoot = 'D:/results/results_mlad_withKnownLabel/mlad111/';

% readRoot = '/Volumes/BOOTCAMP/data/Sutong/';
% saveRoot = '/Users/zhiyitang/Programming/results/';

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
sensorTrainRatio = 3/100;
sensorPSize = 10;
fs = 20;
step = [4];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
% seed = 6; % for random number generation
maxEpoch = [150];
batchSize = 100;
sizeFilter = [40];
numFilter = [20];
publicImagesetPath = 'D:/results/results_mlad_withKnownLabel/publicImageset/2012-01-01--2012-12-31_sensor_1-38_fusion/';
labelPath = 'C:/Users/Owner/Documents/GitHub/adi/trainingSet_justLabel_inSensorCell_latest.mat';

%%
for sensorTrainRatio = 0.03 %: 0.01 : 0.03
    for seed = 1 %: 10
        sensor = mlad111_withKnownLabel(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
            sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, batchSize, sizeFilter, numFilter, ...
            publicImagesetPath, labelPath);
    end
end

