clear;clc;close all;

readRoot = 'C:/dataArchiveTemp/Sutong/';
saveRoot = 'D:/results/results_mlad_withKnownLabel/mlad100/';

% readRoot = '/Volumes/ssd/sutong-2012-tidy';
% saveRoot = '/Users/tangzhiyi/Documents/MATLAB/adi/case';

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
% sensorTrainRatio = 3/100;
sensorPSize = 10;
fs = 20;
step = [3];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
% seed = 6; % for random number generation
maxEpoch = [300 500];
publicImagesetPath = 'D:/results/results_mlad_withKnownLabel/publicImageset/2012-01-01--2012-12-31_sensor_1-38_fusion/';
labelPath = 'C:/Users/Owner/Documents/GitHub/adi/trainingSet_justLabel_inSensorCell_latest.mat';

%%
for sensorTrainRatio = 0.01 : 0.01 : 0.03
    for seed = 1 : 10
        sensor = mlad100_withKnownLabel(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
            sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, publicImagesetPath, labelPath);
    end
end
