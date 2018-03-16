% use MATLAB 2017a to get correct color

sumFolder = 'summary/';
if ~exist(sumFolder, 'dir')
    mkdir(sumFolder)
end

legendText = {'1-Normal' '2-Missing' '3-Minor' '4-Outlier' '5-Square' '6-Trend' '7-Drift'};

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

%% plot for mean data F1
% out.trainF1Mean{1}, out.trainF1Mean{5} and out.trainF1Mean{8} | just column 3
meanData = [];
for c = 3 % 1 : size(out.trainF1Mean{4}, 2)
    meanData = [meanData, out.trainF1Mean{1}(:, c), out.trainF1Mean{5}(:, c), out.trainF1Mean{4}(:, c), out.trainF1Mean{8}(:, c)];
end
meanData = meanData';

close all
figure
xBar = [10 25 40 55];
ba = bar(xBar, meanData, 'EdgeColor', 'none');
% xlabel('Case Number');
ylabel('F_1 Score');
% ylabel('Recall');
% ylabel('Precision');
le = legend(legendText);
le.Location = 'bestoutside';
le.FontSize = 24;
xlim([1 64]);

ax = gca;
ax.TickLength = [0 0];
ax.XTickLabel = {'DNN Imbal.' 'DNN Bal.' 'CNN Imbal.' 'CNN Bal.'};
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 24;
ax.YAxis.FontSize = 24;
ax.YTick = [0 0.2 0.4 0.6 0.8 1];
ax.YGrid = 'on';

% b.CData = barColor(1,:);

% for c = 1 : size(barData, 2)
%     b.CData(c,:) = barColor(c,:);
% end

ba(1).Parent.Parent.Colormap = classColor;

ax.Units = 'normalized';
ax.Position = [0.09 0.12 0.76 0.85];
% ax.Position = [0.09 0.11 0.76 0.85];
% ax.Position = [0.07 0.15 0.8 0.8];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1450, 400];
% fig.Position = [1000, 100, 1450, 450];
% fig.Position = [1000, 100, 1100, 600];

% saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_F1_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.fig'])
% saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_F1_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_F1_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.emf'])

%% plot for mean data Recall
% out.trainF1Mean{1}, out.trainF1Mean{5} and out.trainF1Mean{8} | just column 3
meanData = [];
for c = 3 % 1 : size(out.trainF1Mean{4}, 2)
    meanData = [meanData, out.trainRecallMean{1}(:, c), out.trainRecallMean{5}(:, c), out.trainRecallMean{4}(:, c), out.trainRecallMean{8}(:, c)];
end
meanData = meanData';

close all
figure
ba = bar(meanData, 'EdgeColor', 'none');
% xlabel('Case Number');
% ylabel('F_1 Score');
ylabel('Recall');
% ylabel('Precision');
le = legend(legendText);
le.Location = 'bestoutside';
le.FontSize = 26;

ax = gca;
ax.TickLength = [0 0];
ax.XTickLabel = {'DNN 3% Imbal.' 'DNN 3% Bal.' 'CNN 3% Bal.'};
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 26;
ax.YAxis.FontSize = 26;
ax.YTick = [0 0.2 0.4 0.6 0.8 1];
ax.YGrid = 'on';

% b.CData = barColor(1,:);

% for c = 1 : size(barData, 2)
%     b.CData(c,:) = barColor(c,:);
% end

ba(1).Parent.Parent.Colormap = classColor;

ax.Units = 'normalized';
ax.Position = [0.09 0.11 0.76 0.85];
% ax.Position = [0.07 0.15 0.8 0.8];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1450, 450];
% fig.Position = [1000, 100, 1100, 600];

saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_Recall_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_Recall_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.emf'])

%% plot for mean data Precision
% out.trainF1Mean{1}, out.trainF1Mean{5} and out.trainF1Mean{8} | just column 3
meanData = [];
for c = 3 % 1 : size(out.trainF1Mean{4}, 2)
    meanData = [meanData, out.trainPrecisionMean{1}(:, c), out.trainPrecisionMean{5}(:, c), out.trainPrecisionMean{4}(:, c), out.trainPrecisionMean{8}(:, c)];
end
meanData = meanData';

close all
figure
ba = bar(meanData, 'EdgeColor', 'none');
% xlabel('Case Number');
% ylabel('F_1 Score');
% ylabel('Recall');
ylabel('Precision');
le = legend(legendText);
le.Location = 'bestoutside';
le.FontSize = 26;

ax = gca;
ax.TickLength = [0 0];
ax.XTickLabel = {'DNN 3% Imbal.' 'DNN 3% Bal.' 'CNN 3% Bal.'};
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 26;
ax.YAxis.FontSize = 26;
ax.YTick = [0 0.2 0.4 0.6 0.8 1];
ax.YGrid = 'on';

% b.CData = barColor(1,:);

% for c = 1 : size(barData, 2)
%     b.CData(c,:) = barColor(c,:);
% end

ba(1).Parent.Parent.Colormap = classColor;

ax.Units = 'normalized';
ax.Position = [0.09 0.11 0.76 0.85];
% ax.Position = [0.07 0.15 0.8 0.8];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1450, 450];
% fig.Position = [1000, 100, 1100, 600];

saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_Precision_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
saveas(gcf, [sumFolder 'barPlot_stage1_train_mean_Precision_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.emf'])



