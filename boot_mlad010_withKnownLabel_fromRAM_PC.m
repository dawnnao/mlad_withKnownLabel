clear;clc;close all;

% readRoot = 'C:/dataArchiveTemp/Sutong/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/mlad010/';
readRoot = 'D:/dataArchive/Sutong/';
saveRoot = 'D:/results/mlad_new/mlad010/';

% readRoot = '/Volumes/BOOTCAMP/data/Sutong';
% saveRoot = '/Users/zhiyitang/Programming/results';

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
% sensorTrainRatio = 1/100;
sensorPSize = 10;
fs = 20;
step = [4 5];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
% seed = 6; % for random number generation
maxEpoch = [300 500];
publicImagesetPath = 'D:/results/results_mlad_withKnownLabel/publicImageset/2012-01-01--2012-12-31_sensor_1-38_fusion/';
% labelPath = 'C:/Users/Owner/Documents/GitHub/adi/trainingSet_justLabel_inSensorCell_latest.mat';
labelPath = 'D:/results/mlad_new/additional/trainingSet_justLabel_inSensorCell_latest.mat';

% if ~exist('img2012', 'var')
%     fprintf('\nLoading image set of 2012...\n')
%     global img2012
% %     img2012 = load('E:\results\mlad111\2012-01-01--2012-12-31_sensor_1-38_fusion\data2imageSet\data2imageSet.mat'); % file path of img2012
%     img2012 = load('D:\results\mlad_new\additional\data2imageSet.mat'); % file path of img2012
% end

%%
% for sensorTrainRatio = 0.01 : 0.01 : 0.03
%     for seed = 1 : 10
%         sensor = mlad010_withKnownLabel_fromRAM(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
%             sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, publicImagesetPath, labelPath, img2012);
%     end
% end

for sensorTrainRatio = 0.02% : 0.01 : 0.03
    for seed = 1 : 10
        sensor = mlad010_withKnownLabel(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
            sensorTrainRatio, sensorPSize, fs, step, [], seed, maxEpoch, publicImagesetPath, labelPath);
    end
end

