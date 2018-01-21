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
        
        out.trainRecallMean{nMlad}(:, nTrainRatio) = nanmean(out.trainRecall{nMlad}{nTrainRatio}, 2);
        out.trainRecallStd{nMlad}(:, nTrainRatio) = nanstd(out.trainRecall{nMlad}{nTrainRatio}, 0, 2);
        out.valiRecallMean{nMlad}(:, nTrainRatio) = nanmean(out.valiRecall{nMlad}{nTrainRatio}, 2);
        out.valiRecallStd{nMlad}(:, nTrainRatio) = nanstd(out.valiRecall{nMlad}{nTrainRatio}, 0, 2);
        out.testRecallMean{nMlad}(:, nTrainRatio) = nanmean(out.testRecall{nMlad}{nTrainRatio}, 2);
        out.testRecallStd{nMlad}(:, nTrainRatio) = nanstd(out.testRecall{nMlad}{nTrainRatio}, 0, 2);
        
        out.trainPrecisionMean{nMlad}(:, nTrainRatio) = nanmean(out.trainPrecision{nMlad}{nTrainRatio}, 2);
        out.trainPrecisionStd{nMlad}(:, nTrainRatio) = nanstd(out.trainPrecision{nMlad}{nTrainRatio}, 0, 2);
        out.valiPrecisionMean{nMlad}(:, nTrainRatio) = nanmean(out.valiPrecision{nMlad}{nTrainRatio}, 2);
        out.valiPrecisionStd{nMlad}(:, nTrainRatio) = nanstd(out.valiPrecision{nMlad}{nTrainRatio}, 0, 2);
        out.testPrecisionMean{nMlad}(:, nTrainRatio) = nanmean(out.testPrecision{nMlad}{nTrainRatio}, 2);
        out.testPrecisionStd{nMlad}(:, nTrainRatio) = nanstd(out.testPrecision{nMlad}{nTrainRatio}, 0, 2);
        
        out.trainF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.trainF1{nMlad}{nTrainRatio}, 2);
        out.trainF1Std{nMlad}(:, nTrainRatio) = nanstd(out.trainF1{nMlad}{nTrainRatio}, 0, 2);
        out.valiF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.valiF1{nMlad}{nTrainRatio}, 2);
        out.valiF1Std{nMlad}(:, nTrainRatio) = nanstd(out.valiF1{nMlad}{nTrainRatio}, 0, 2);
        out.testF1Mean{nMlad}(:, nTrainRatio) = nanmean(out.testF1{nMlad}{nTrainRatio}, 2);
        out.testF1Std{nMlad}(:, nTrainRatio) = nanstd(out.testF1{nMlad}{nTrainRatio}, 0, 2);
        
    end
end

%%
sumFolder = 'summary/';
if ~exist(sumFolder, 'dir')
    mkdir(sumFolder)
end

save([sumFolder 'summary_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.mat'], 'out', '-v7.3')
fprintf('saved.\n')

% %% plot settings
% legendText = {'Normal' 'Missing' 'Minor' 'Outlier' 'Square' 'Trend' 'Drift'};
% 
% % barColor = {...
% % [000 130 000]/255;    % 1-normal            green
% % [244 67 54]/255;      % 2-missing           red
% % [121 85 72]/255;      % 3-minor             brown
% % [255 235 59]/255;     % 4-outlier           yellow
% % [50 50 50]/255;       % 5-square            black  
% % [33 150 243]/255;     % 6-trend             blue
% % [171 71 188]/255};     % 7-drift             purple
% 
% classColor = [ ...
% 51  190 122;    % 1-normal            green  52 162 126
% 244 67  54;      % 2-missing           red
% 121 85  72;      % 3-minor             brown
% 255 235 59;     % 4-outlier           yellow
% 50  50  50;       % 5-square            black  
% 33  150 243;     % 6-trend             blue
% 171 71  188]/255;     % 7-drift             purple
% 
% %% plot for mean data
% % out.testF1Mean{4} and out.testF1Mean{8}
% meanData = [];
% for c = 1 : size(out.testF1Mean{4}, 2)
%     meanData = [meanData, out.testF1Mean{4}(:, c), out.testF1Mean{8}(:, c)];
% end
% meanData = meanData';
% 
% %% plot for mean data
% % out.testF1Mean{1}, out.testF1Mean{5} and out.testF1Mean{8} | just column 3
% meanData = [];
% for c = 3 % 1 : size(out.testF1Mean{4}, 2)
%     meanData = [meanData, out.testF1Mean{1}(:, c), out.testF1Mean{5}(:, c), out.testF1Mean{8}(:, c)];
% end
% meanData = meanData';
% 
% %% mean bar plot - by case
% close all
% figure
% ba = bar(meanData, 'EdgeColor', 'none');
% % xlabel('Case Number');
% ylabel('F_1 Score');
% le = legend(legendText);
% le.Location = 'bestoutside';
% le.FontSize = 14;
% 
% ax = gca;
% ax.TickLength = [0 0];
% ax.XTickLabel = {'DNN 3% Imbal.' 'DNN 3% Bal.' 'CNN 3% Bal.'};
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.YGrid = 'on';
% 
% % b.CData = barColor(1,:);
% 
% % for c = 1 : size(barData, 2)
% %     b.CData(c,:) = barColor(c,:);
% % end
% 
% ba(1).Parent.Parent.Colormap = classColor;
% 
% ax.Units = 'normalized';
% % ax.Position = [0.08 0.15 0.8 0.8];
% ax.Position = [0.07 0.15 0.8 0.8];
% 
% fig = gcf;
% fig.Units = 'pixels';
% % fig.Position = [1000, 100, 1400, 450];
% fig.Position = [1000, 100, 1100, 600];
% 
% saveas(gcf, [sumFolder 'barPlot_mean_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% 
% %% mean bar plot - by class
% legendTextByClass = {};
% % for n = 1 : 6
% %     legendTextByClass{n} = sprintf('Case %d', n);
% % end
% % legendTextByClass = {' 1% Imbal.' ' 1% Bal.' ' 2% Imbal.' ' 2% Bal.' ' 3% Imbal.' ' 3% Bal.'};
% 
% legendTextByClass = {'DNN 3% Imbal.' 'DNN 3% Bal.' 'CNN 3% Bal.'};
% 
% close all
% figure
% ba = bar(meanData, 'EdgeColor', 'none');
% % xlabel('Class');
% ylabel('F_1 Score');
% le = legend(legendTextByClass);
% le.Location = 'bestoutside';
% le.FontSize = 14;
% 
% ax = gca;
% ax.XTickLabel = legendText;
% ax.TickLength = [0 0];
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.YTick = 0:0.1:1;
% ax.YGrid = 'on';
% % ba(1).Clim = [1 20];
% 
% % b.CData = barColor(1,:);
% 
% % for c = 1 : size(barData, 2)
% %     b.CData(c,:) = barColor(c,:);
% % end
% 
% caseColor = [ ...
% 0.85 0.85 0.85;      % 2-missing           red
% 0.7  0.7  0.7;      % 3-minor             brown
% 0.55 0.55 0.55;     % 4-outlier           yellow
% 0.4  0.4  0.4;       % 5-square            black  
% 0.25 0.25 0.25
% 0.1  0.1  0.1]-0.1;     % 7-drift             purple
% 
% ba(1).Parent.Parent.Colormap = caseColor;
% 
% ax.Units = 'normalized';
% % ax.Position = [0.08 0.15 0.8 0.8];
% ax.Position = [0.055 0.15 0.8 0.8];
% 
% fig = gcf;
% fig.Units = 'pixels';
% % fig.Position = [1000, 100, 1400, 450];
% fig.Position = [1000, 100, 1400, 600];
% 
% saveas(gcf, [sumFolder 'barPlot_mean_by_class_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.emf'])
% 
% %% mean line plot
% close all
% figure
% 
% for c = 1 : size(meanData, 2)
%     li = plot(meanData(:, c), '-*', 'Color', [classColor(c, :)], 'LineWidth', 2);
% %     li(c).LineWidth = 2;
%     hold on
% %     li(c).CData = barColor(c,:);
% end
% hold off
% 
% xlabel('Case Number');
% ylabel('F_1 Score');
% le = legend(legendText);
% le.Location = 'bestoutside';
% le.FontSize = 14;
% 
% ax = gca;
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.YGrid = 'on';
% ax.XTick = [1:1:6];
% % xlim([0 6]);
% 
% % li(1).Parent.Parent.Colormap = barColor;
% colormap(classColor);
% 
% ax.Units = 'normalized';
% ax.Position = [0.08 0.11 0.76 0.86];
% 
% fig = gcf;
% fig.Units = 'pixels';
% fig.Position = [1000, 100, 1000, 600];
% 
% saveas(gcf, [sumFolder 'linePlot_mean_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% 
% %% plot for std data
% stdData = [];
% for c = 1 : size(out.testF1Std{4}, 2)
%     stdData = [stdData, out.testF1Std{4}(:, c), out.testF1Std{8}(:, c)];
% end
% stdData = stdData';
% 
% %% std bar plot
% close all
% figure
% ba = bar(stdData*100, 'EdgeColor', 'none');
% xlabel('Case Number');
% ylabel('Std of F_1 Score (%)');
% le = legend(legendText);
% le.Location = 'bestoutside';
% le.FontSize = 14;
% 
% ax = gca;
% ax.TickLength = [0 0];
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.YGrid = 'on';
% 
% % b.CData = barColor(1,:);
% 
% % for c = 1 : size(barData, 2)
% %     b.CData(c,:) = barColor(c,:);
% % end
% 
% ba(1).Parent.Parent.Colormap = classColor;
% 
% ax.Units = 'normalized';
% ax.Position = [0.1 0.15 0.8 0.8];
% 
% fig = gcf;
% fig.Units = 'pixels';
% fig.Position = [1000, 100, 1400, 450];
% 
% saveas(gcf, [sumFolder 'barPlot_std_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% 
% %% box plot training
% boxData = [NaN(5,1) ...
%            out.testF1{4}{1}' NaN(5,3) out.testF1{8}{1}' NaN(5,3) ...
%            out.testF1{4}{2}' NaN(5,3) out.testF1{8}{2}' NaN(5,3) ...
%            out.testF1{4}{3}' NaN(5,3) out.testF1{8}{3}' NaN(5,1)];
% 
% boxTickLabel = {};
% boxTickDispl = [4 14 24 34 44 54]+1;
% for n = 1 : length(boxTickDispl)
%     
%     boxTickLabel{n} = sprintf('%d', n);
%     
% end
% 
% close all
% figure
% bo = boxplot(boxData);
% xlabel('Case Number');
% ylabel('F_1 Score (%)');
% 
% ax = gca;
% % ax.TickLength = [0 0];
% ax.XTick = boxTickDispl;
% ax.XTickLabel = boxTickLabel;
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.XGrid = 'on';
% ax.YGrid = 'on';
% 
% ax.Units = 'normalized';
% ax.Position = [0.1 0.13 0.8 0.85];
% 
% fig = gcf;
% fig.Units = 'pixels';
% fig.Position = [1000, 100, 1400, 500];
% 
% saveas(gcf, [sumFolder 'boxPlot_test_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% 
% 
% %% box plot test
% boxData = [NaN(5,1) ...
%            out.testF1{4}{1}' NaN(5,3) out.testF1{8}{1}' NaN(5,3) ...
%            out.testF1{4}{2}' NaN(5,3) out.testF1{8}{2}' NaN(5,3) ...
%            out.testF1{4}{3}' NaN(5,3) out.testF1{8}{3}' NaN(5,1)];
% 
% boxTickLabel = {};
% boxTickDispl = [4 14 24 34 44 54]+1;
% for n = 1 : length(boxTickDispl)
%     
%     boxTickLabel{n} = sprintf('%d', n);
%     
% end
% 
% close all
% figure
% bo = boxplot(boxData, 'PlotStyle', 'compact');
% xlabel('Case Number');
% ylabel('F_1 Score (%)');
% 
% ax = gca;
% % ax.TickLength = [0 0];
% ax.XTick = boxTickDispl;
% ax.YTick = 0:0.1:1;
% ax.XTickLabel = boxTickLabel;
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.XGrid = 'on';
% ax.YGrid = 'on';
% 
% ax.Units = 'normalized';
% ax.Position = [0.1 0.13 0.8 0.85];
% 
% fig = gcf;
% fig.Units = 'pixels';
% fig.Position = [1000, 100, 1400, 500];
% 
% % saveas(gcf, [sumFolder 'boxPlot_test_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
% 
% %% box plot test trial
% boxData = {...
%            [out.testF1{4}{1}'] [out.testF1{8}{1}]' ...
%            [out.testF1{4}{2}'] [out.testF1{8}{2}'] ...
%            [out.testF1{4}{3}'] [out.testF1{8}{3}']};
% 
% boxTickLabel = {};
% boxTickDispl = [4 11 18 25 32 39]+1;
% for n = 1 : length(boxTickDispl)
%     
%     boxTickLabel{n} = sprintf('%d', n);
%     
% end
% 
% close all
% figure
% bo = boxplot(boxData, 'FactorGap', 10);
% xlabel('Case Number');
% ylabel('F_1 Score (%)');
% 
% ax = gca;
% % ax.TickLength = [0 0];
% % ax.XTick = boxTickDispl;
% ax.YTick = 0:0.1:1;
% % ax.XTickLabel = boxTickLabel;
% ax.FontName = 'Helvetica';
% ax.XAxis.FontSize = 14;
% ax.YAxis.FontSize = 14;
% ax.XGrid = 'on';
% ax.YGrid = 'on';
% 
% ax.Units = 'normalized';
% ax.Position = [0.1 0.13 0.8 0.85];
% 
% fig = gcf;
% fig.Units = 'pixels';
% fig.Position = [1000, 100, 1400, 500];
% 
% % saveas(gcf, [sumFolder 'boxPlot_test_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])








