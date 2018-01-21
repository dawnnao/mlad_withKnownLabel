% clear;clc; close all
% load('D:\results\results_mlad_withKnownLabel\round2\mlad111\test\2012-01-01--2012-12-31_sensor_1-38_fusion_trainRatio_3pct_seed_1 - visualizationTest\2012-01-01--2012-12-31_sensor_1-38_fusion_globalEpoch_150_batchSize_100_sizeFilter_40_numFilter_20.mat')
% load('D:\results\results_mlad_withKnownLabel\round2\mlad011\2012-01-01--2012-12-31_sensor_1-38_fusion_trainRatio_3pct_seed_1\2012-01-01--2012-12-31_sensor_1-38_fusion_globalEpoch_150_batchSize_100_sizeFilter_40_numFilter_20.mat')
% pathRoot = 'C:\Users\Owner\Google Drive\research\17-2 aut-phd-year2-1\secondPaper!\images\samples';

%%
net = sensor.neuralNet{1};
net.Layers

layer = 2;
channels = 1 : 20;

I = deepDreamImage(net, layer, channels, 'PyramidLevels', 2, 'PyramidScale', 1.4, 'NumIterations', 20);

figure
montage(I, 'Size', [5 4])
name = 'Convolutional'; % net.Layers(layer).Name;
title([name ' Layer Features'])

%%
ax = gca;
set(gca, 'fontsize', 14);
set(gca, 'fontname', 'Times New Roman', 'fontweight', 'bold');
ax.Position = [0.01 0.1 0.99 0.8];  % control ax's position in figure

fig = gcf;
fig.Units = 'pixels';
fig.Position = [20 50 400 500];  % control figure's position
% saveas(gcf, sprintf('%s/filterVisualization.tif', pathRoot));
% saveas(gcf, sprintf('%s/filterVisualization.emf', pathRoot));

%%
close all
name = {'Normal', 'Missing', 'Minor', 'Outlier', 'Square', 'Trend', 'Drift'};
for n = 1 : 7
    img = imread(sprintf('%s/type-%d_resized.tif', pathRoot, n));
%     imshow(img)
    imgSize = size(img);
    imgSize = imgSize(1:2);

    net.Layers
    act1 = activations(net,img,'conv','OutputAs','channels');
    sz = size(act1);
    act1 = reshape(act1,[sz(1) sz(2) 1 sz(3)]);
    figure
    montage(mat2gray(act1),'Size',[5 4])
    title(['Feature maps of Pattern ',name{n}])
    
    ax = gca;
    set(gca, 'fontsize', 14);
    set(gca, 'fontname', 'Times New Roman', 'fontweight', 'bold');
    ax.Position = [0.01 0.1 0.99 0.8];  % control ax's position in figure

    fig = gcf;
    fig.Units = 'pixels';
    fig.Position = [20 50 400 500];  % control figure's position
%     saveas(gcf, sprintf('%s/type-%d_featureMaps.tif', pathRoot, n));
%     saveas(gcf, sprintf('%s/type-%d_featureMaps.emf', pathRoot, n));
    clear img
end



