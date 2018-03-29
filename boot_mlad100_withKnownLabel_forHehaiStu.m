clear;clc;close all;

readRoot = 'D:/sutong_temp/sutong_2016_mat';
saveRoot = 'D:/results/sutongAnomalyDetection_2016_forHehaiStu';

% readRoot = '/Volumes/ssd/sutong-2012-tidy';
% saveRoot = '/Users/tangzhiyi/Documents/MATLAB/adi/case';

sensorNum = [1:28];
dateStart = '2016-05-01';
dateEnd = '2016-10-31';
% sensorTrainRatio = 3/100;
sensorPSize = 10;
fs = 20;
step = [5];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
% seed = 6; % for random number generation
maxEpoch = [300 500];
publicImagesetPath = 'D:/results/results_mlad_withKnownLabel/publicImageset/2012-01-01--2012-12-31_sensor_1-38_fusion/';
labelPath = 'C:/Users/Owner/Documents/GitHub/mlad_withKnownLabel/labelMan/label2012_modifiedAfterRound2Test.mat';

%%
for sensorTrainRatio = 0.03
    for seed = 2 % : 5
        sensor = mlad100_withKnownLabel(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
            sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, publicImagesetPath, labelPath);
    end
end

% Do not use GPU to train autoencoder 1 when sensorTrainRatio = 0.03!
