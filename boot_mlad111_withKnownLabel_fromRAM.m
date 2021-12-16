clear;
clc;close all;

% readRoot = 'C:/dataArchive/Sutong/';
readRoot = 'C:/Data/sutong_2012/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/round4/mlad111/';
saveRoot = 'C:/Results/';

% readRoot = '/Volumes/BOOTCAMP/data/Sutong/';
% saveRoot = '/Users/zhiyitang/Programming/results/';

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
% sensorTrainRatio = 3/100;
sensorPSize = 10;
fs = 20;
step = [3];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
% seed = 6; % for random number generation
maxEpoch = [150];
batchSize = 100;
sizeFilter = [40];
numFilter = [20];
% publicImagesetPath = 'D:/results/results_mlad_withKnownLabel/publicImageset/2012-01-01--2012-12-31_sensor_1-38_fusion/';
publicImagesetPath = 'C:/Data/sutong_2012_images_labels/2012-01-01--2012-12-31_sensor_1-38_fusion/';

% labelPath = 'C:/Users/Owner/Documents/GitHub/mlad_withKnownLabel/labelMan/label2012_modifiedAfterRound2Test.mat';
labelPath = 'C:/Data/sutong_2012_images_labels/label2012_modifiedAfterRound2Test.mat';

% if ~exist('img2012', 'var')
%     fprintf('\nLoading image set of 2012...\n')
%     global img2012
%     img2012 = load('C:\dataArchive\data2imageSet.mat'); % file path of img2012
% end

%%
for sensorTrainRatio = 0.01 % : 0.01 : 0.02
    for seed = 1 % : 5
        sensor = mlad111_withKnownLabel_fromRAM(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
            sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, batchSize, sizeFilter, numFilter, ...
            publicImagesetPath, labelPath, []);
    end
end

