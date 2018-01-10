clear; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rootFolder = 'D:/results/results_mlad_withKnownLabel/round2/';
caseNum = 0 : 7; % for convert to binary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

caseNumBin = fliplr(de2bi(caseNum));
caseNumBinChar = num2str(caseNumBin);
caseNumBinChar = caseNumBinChar(~isspace(caseNumBinChar));
caseNumBinChar = reshape(caseNumBinChar, [size(caseNumBin ,1), length(caseNumBinChar)/size(caseNumBin ,1)]);

folderBasic = '2012-01-01--2012-12-31_sensor_1-38_fusion';
fileBasicDNN = '2012-01-01--2012-12-31_sensor_1-38_fusion_autoenc1epoch_300_globalEpoch_500.mat';
fileBasicCNN = '2012-01-01--2012-12-31_sensor_1-38_fusion_globalEpoch_150_batchSize_100_sizeFilter_40_numFilter_20.mat';

out.intersect = cell(7,7);
out.intersect(:) = {[1:333792]}; % initialization

for nMlad = 1 : 8 % length(caseNum)
    for nTrainRatio = 1 : 3 % pct
        for nSeed = 1 : 5
            fprintf('\nLoading...    mlad%s  trainRatio: %d  seed: %d    ', caseNumBinChar(nMlad, :), nTrainRatio, nSeed)
            if mod(nMlad, 2) == 1
                fileBasic = fileBasicDNN;
            else
                fileBasic = fileBasicCNN;
            end
            fileFull = sprintf('%s/mlad%s/%s_trainRatio_%dpct_seed_%d/%s', rootFolder, caseNumBinChar(nMlad, :), folderBasic, nTrainRatio, nSeed, fileBasic);
            fileOrigin = load(fileFull);
            if  isfield(fileOrigin, 'confTrainAccuracy') && isfield(fileOrigin, 'confValiAccuracy') ...
                    && isfield(fileOrigin, 'confTestAccuracy') && isfield(fileOrigin, 'confTestInd')
                % collect accuracy
                out.train{nMlad}{nTrainRatio}(nSeed) = fileOrigin.confTrainAccuracy;
                out.vali{nMlad}{nTrainRatio}(nSeed) = fileOrigin.confValiAccuracy;
                out.test{nMlad}{nTrainRatio}(nSeed) = fileOrigin.confTestAccuracy;
                
                % collect precision
                out.trainPrecision{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confTrainPrecision;
                out.valiPrecision{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confValiPrecision;
                out.testPrecision{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confTestPrecision;
                
                % collect recall
                out.trainRecall{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confTrainRecall;
                out.valiRecall{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confValiRecall;
                out.testRecall{nMlad}{nTrainRatio}(:, nSeed) = fileOrigin.confTestRecall;
                
                % collect misclassified sample indexes for intersection
                out.testInd{nMlad}{nTrainRatio}{nSeed} = fileOrigin.confTestInd;
                for nCube = 1 : 49
                    out.intersect{nCube} = intersect(out.intersect{nCube}, out.testInd{nMlad}{nTrainRatio}{nSeed}{nCube}); 
                end
                
                fprintf('collected    ')
            else
                fprintf('Accuracy is not complete!    ')
                out.train{nMlad}{nTrainRatio}(nSeed) = NaN;
                out.vali{nMlad}{nTrainRatio}(nSeed) = NaN;
                out.test{nMlad}{nTrainRatio}(nSeed) = NaN;
            end
            
            clear fileOrigin
        end
        
        % calculate mean and std of accuracy
        out.trainMean{nMlad}(nTrainRatio) = nanmean(out.train{nMlad}{nTrainRatio});
        out.trainStd{nMlad}(nTrainRatio) = nanstd(out.train{nMlad}{nTrainRatio});
        out.valiMean{nMlad}(nTrainRatio) = nanmean(out.vali{nMlad}{nTrainRatio});
        out.valiStd{nMlad}(nTrainRatio) = nanstd(out.vali{nMlad}{nTrainRatio});
        out.testMean{nMlad}(nTrainRatio) = nanmean(out.test{nMlad}{nTrainRatio});
        out.testStd{nMlad}(nTrainRatio) = nanstd(out.test{nMlad}{nTrainRatio});
        
        % calculate f1 score
        for nSeed = 1 : 5
        out.trainF1{nMlad}{nTrainRatio}(:, nSeed) = ...
            2*(out.trainPrecision{nMlad}{nTrainRatio}(:, nSeed) .* out.trainRecall{nMlad}{nTrainRatio}(:, nSeed))./ ...
            (out.trainPrecision{nMlad}{nTrainRatio}(:, nSeed) + out.trainRecall{nMlad}{nTrainRatio}(:, nSeed));
        
        out.valiF1{nMlad}{nTrainRatio}(:, nSeed) = ...
            2*(out.valiPrecision{nMlad}{nTrainRatio}(:, nSeed) .* out.valiRecall{nMlad}{nTrainRatio}(:, nSeed))./ ...
            (out.valiPrecision{nMlad}{nTrainRatio}(:, nSeed) + out.valiRecall{nMlad}{nTrainRatio}(:, nSeed));
        
        out.testF1{nMlad}{nTrainRatio}(:, nSeed) = ...
            2*(out.testPrecision{nMlad}{nTrainRatio}(:, nSeed) .* out.testRecall{nMlad}{nTrainRatio}(:, nSeed))./ ...
            (out.testPrecision{nMlad}{nTrainRatio}(:, nSeed) + out.testRecall{nMlad}{nTrainRatio}(:, nSeed));
        
        end
        
        out.trainF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.trainF1{nMlad}{nTrainRatio}, 2);
        out.trainF1Std{nMlad}(:, nTrainRatio) = nanstd(out.trainF1{nMlad}{nTrainRatio}, 0, 2);
        out.valiF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.valiF1{nMlad}{nTrainRatio}, 2);
        out.valiF1Std{nMlad}(:, nTrainRatio) = nanstd(out.valiF1{nMlad}{nTrainRatio}, 0, 2);
        out.testF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.testF1{nMlad}{nTrainRatio}, 2);
        out.testF1Std{nMlad}(:, nTrainRatio) = nanstd(out.testF1{nMlad}{nTrainRatio}, 0, 2);
        
    end
end

sumFolder = 'summary/';
if ~exist(sumFolder, 'dir')
    mkdir(sumFolder)
end

save([sumFolder 'summary_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.mat'], 'out', '-v7.3')
fprintf('saved.\n')

%% plot
% out.testF1Mean{4} and out.testF1Mean{8}
barData = [];
for c = 1 : size(out.testF1Mean{4}, 2)
    barData = [barData, out.testF1Mean{4}(:, c), out.testF1Mean{8}(:, c)];
end
barData = barData';

%% barplot settings
legendText = {'Normal' 'Missing' 'Minor' 'Outlier' 'Square' 'Trend' 'Drift'};
% barColor = {...
% [000 130 000]/255;    % 1-normal            green
% [244 67 54]/255;      % 2-missing           red
% [121 85 72]/255;      % 3-minor             brown
% [255 235 59]/255;     % 4-outlier           yellow
% [50 50 50]/255;       % 5-square            black  
% [33 150 243]/255;     % 6-trend             blue
% [171 71 188]/255};     % 7-drift             purple

barColor = [ ...
51  190 122;    % 1-normal            green  52 162 126
244 67  54;      % 2-missing           red
121 85  72;      % 3-minor             brown
255 235 59;     % 4-outlier           yellow
50  50  50;       % 5-square            black  
33  150 243;     % 6-trend             blue
171 71  188]/255;     % 7-drift             purple


close all
figure
ba = bar(barData, 'EdgeColor', 'none');
xlabel('Case No.');
ylabel('F_1 Score');
le = legend(legendText);
le.Location = 'bestoutside';
le.FontSize = 14;

ax = gca;
ax.TickLength = [0 0];
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 14;
ax.YAxis.FontSize = 14;
ax.YGrid = 'on';

% b.CData = barColor(1,:);

% for c = 1 : size(barData, 2)
%     b.CData(c,:) = barColor(c,:);
% end

ba(1).Parent.Parent.Colormap = barColor;

ax.Units = 'normalized';
ax.Position = [0.07 0.15 0.8 0.8];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1100, 450];

saveas(gcf, [sumFolder 'barPlot_cases_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])

%%
lineData = barData;

close all
figure
li = plot(lineData, '-*');
for c = 1 : size(lineData, 2)
    li(c).LineWidth = 2;
%     li(c).CData = barColor(c,:);
end


xlabel('Case No.');
ylabel('F_1 Score');
le = legend(legendText);
le.Location = 'bestoutside';
le.FontSize = 14;

ax = gca;
ax.FontName = 'Helvetica';
ax.XAxis.FontSize = 14;
ax.YAxis.FontSize = 14;
ax.YGrid = 'on';

% li(1).Parent.Parent.Colormap = barColor;

ax.Units = 'normalized';
ax.Position = [0.08 0.11 0.76 0.86];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1000, 600];






