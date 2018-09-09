% based on the main file
%% added on 20180907
labelNet_testSet_forROC = sensor.labelDecimal;
for s = sensor.numVec
    index_train_set = find(sensor.label.manualTrainSet{s} == 8);
    labelNet_testSet_forROC.neuralNet{s} = labelNet_testSet_forROC.neuralNet{s}(:, index_train_set);
    index_train_set = [];
end

sensorLabelDecimalNetSerial = [];
for mTemp = 1 : 38
    sensorLabelDecimalNetSerial = cat(2, sensorLabelDecimalNetSerial, labelNet_testSet_forROC.neuralNet{mTemp});
end

%% labelNet
% sensorLabelDecimalNetSerial = [];
% for mTemp = 1 : 38
%     sensorLabelDecimalNetSerial = cat(2, sensorLabelDecimalNetSerial, labelNet_testSet_forROC{mTemp});
% end

%% labelMan
labelPath = 'C:/Users/Owner/Documents/GitHub/mlad_withKnownLabel/labelMan/label2012_modifiedAfterRound2Test.mat';
fprintf('\nLoading actual labels of 2012...\n')
sensorTemp = load(labelPath);

labelMan = [];
for mTemp = 1 : 38
    labelMan = cat(1, labelMan, sensorTemp.label2012.sensor.label.manual{mTemp}');
end
labelMan = ind2vec(labelMan');

%% plot settings
legendText = {'Normal', 'Missing', 'Minor', 'Outlier', 'Square', 'Trend', 'Drift'};

% barColor = {...
% [000 130 000]/255;    % 1-normal            green
% [244 67 54]/255;      % 2-missing           red
% [121 85 72]/255;      % 3-minor             brown
% [255 235 59]/255;     % 4-outlier           yellow
% [50 50 50]/255;       % 5-square            black  
% [33 150 243]/255;     % 6-trend             blue
% [171 71 188]/255};     % 7-drift             purple

classColor = [ ...
51  190 122;    % 1-normal            green  52 162 126
244 67  54;      % 2-missing           red
121 85  72;      % 3-minor             brown
255 235 59;     % 4-outlier           yellow
50  50  50;       % 5-square            black  
33  150 243;     % 6-trend             blue
171 71  188]/255;     % 7-drift             purple

%%
close all
figure
rocPlot = plotroc(labelManTestSet, sensorLabelDecimalNetSerial);
% rocPlot = plotroc(labelManTestSet, labelNetTestSet);

% plotroc(feature{g}.label.manual(:,feature{g}.trainSize+1 : end), yVali)
% [tpr, fpr, thresholds] = roc(labelMan, labelNet);
% le = legend(legendText);
le.Location = 'southeast';
le.FontSize = 14;

ax = gca;
% % ax.TickLength = [0 0];
% % ax.XTickLabel = {'DNN 3% Imbal.' 'DNN 3% Bal.' 'CNN 3% Bal.'};
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 16;
ax.YAxis.FontSize = 16;
% title = (' ');
% 
% % rocPlot(1).Parent.Parent.Colormap = classColor;
% 
% ax.Units = 'normalized';
% % ax.Position = [0.07 0.15 0.8 0.8];
% 
fig = gcf;
fig.Units = 'pixels';
% ax.Position = [0.07 0.15 0.8 0.8];
% fig.Position = [1000, 100, 1400, 450];
% ax.Position = [0.08 0.15 0.8 0.8];
% fig.Position = [1000, 100, 600, 600];
grid on
ax.XTick = 0 : 0.2 : 1;

% gca.Position = [0.08 0.15 0.8 0.8];
% gcf.Position = [1000, 100, 600, 600];

% delete title

%%
sumFolder = 'summary/';
if ~exist(sumFolder, 'dir')
    mkdir(sumFolder)
end

saveas(gcf, [sumFolder 'rocPlot_mlad100_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
saveas(gcf, [sumFolder 'rocPlot_mlad100_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.emf'])
saveas(gcf, [sumFolder 'rocPlot_mlad100_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.fig'])

