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

for nMlad = 8 % 1 : 8 % length(caseNum)
    for nTrainRatio = 1 % : 3 % pct
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
        out.trainMean{nMlad}(nTrainRatio) = nanmean(out.train{nMlad}{nTrainRatio});
        out.trainStd{nMlad}(nTrainRatio) = nanstd(out.train{nMlad}{nTrainRatio});
        out.valiMean{nMlad}(nTrainRatio) = nanmean(out.vali{nMlad}{nTrainRatio});
        out.valiStd{nMlad}(nTrainRatio) = nanstd(out.vali{nMlad}{nTrainRatio});
        out.testMean{nMlad}(nTrainRatio) = nanmean(out.test{nMlad}{nTrainRatio});
        out.testStd{nMlad}(nTrainRatio) = nanstd(out.test{nMlad}{nTrainRatio});
    end
end

sumFolder = 'summary/';
if ~exist(sumFolder, 'dir')
    mkdir(sumFolder)
end

save([sumFolder 'summary_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.mat'], 'out', '-v7.3')
fprintf('saved.\n')








