clear;clc;close all;

readRoot = 'C:/dataArchiveTemp/Sutong/';
% saveRoot = 'D:/results/results_mlad_withKnownLabel/publicImageset/';
saveRoot = 'D:/results/results_mlad_withKnownLabel/publicImageset_spectrogram/';

% readRoot = '/Volumes/BOOTCAMP/data/Sutong/';
% saveRoot = '/Users/zhiyitang/Programming/results/';

% for n = 1 : 38, sensorNum{n} = n; end
% sensorNum = [1 3 10 15 16 25 26 28 29 32];

% sensorNum = [24 25];
% dateStart = '2012-01-01';
% dateEnd = '2012-01-02';
% k = 3; % number of clusters
% sensorTrainRatio = 100/100; % for clustering-based method, it is sampling ratio to excute clutering
% sensorPSize = 10;
% fs = 20;
% step = [2];

sensorNum = [1:38];
dateStart = '2012-01-01';
dateEnd = '2012-12-31';
k = 100; % number of clusters
sensorTrainRatio = 100/100; % for clustering-based method, it is sampling ratio to excute clutering
sensorPSize = 10;
fs = 20;
step = [1];
% labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend up','7-trend down','8-trend random'};

%%
% sensor = mlad111(readRoot, saveRoot, sensorNum, dateStart, dateEnd, k, sensorTrainRatio, sensorPSize, fs, step, []);
sensor = mlad111_makePublicImageset(readRoot, saveRoot, sensorNum, dateStart, dateEnd, k, sensorTrainRatio, sensorPSize, fs, step, []);

