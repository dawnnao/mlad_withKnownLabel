clear;clc;close all;

% win
% readRoot = 'C:/dataArchiveTemp/Sutong/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/mlad111/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/round2/mlad111/';

% mac
readRoot = '/Volumes/BOOTCAMP/data/Sutong/';
saveRoot = '/Users/zhiyitang/Programming/results/';

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
k = 100; % number of clusters
sensorClustRatio = 5/100;
sensorPSize = 10;
fs = 20;
step = [2];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
seed = 1; % for random number generation
maxEpoch = [150];
batchSize = 100;
sizeFilter = [40];
numFilter = [20];

%%
sensor = mlad111_forReportGen(readRoot, saveRoot, sensorNum, dateStart, dateEnd, ...
    sensorClustRatio, sensorPSize, fs, step, [], seed, maxEpoch, batchSize, sizeFilter, numFilter);

