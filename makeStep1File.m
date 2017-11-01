clear; clc; close all;

root = 'D:/results/results_mlad_withKnownLabel/step1backup/';

caseNum = 0 : 7;
caseNumBin = fliplr(de2bi(caseNum));
caseNumBinChar = num2str(caseNumBin);
caseNumBinChar = caseNumBinChar(~isspace(caseNumBinChar));
caseNumBinChar = reshape(caseNumBinChar, [size(caseNumBin ,1), length(caseNumBinChar)/size(caseNumBin ,1)]);

fileBasic = '2012-01-01--2012-12-31_sensor_1-38_fusion';
netFolderName = sprintf('net_globalEpoch_500/');
trainSetFolderName = sprintf('trainingSetByType_globalEpoch_500/');
trainSetFolderNameNew = sprintf('trainingSetByType/');
matFile1Name = sprintf('2012-01-01--2012-12-31_sensor_1-38_fusion_globalEpoch_500.mat');
matFile2Name = sprintf('2012-01-01--2012-12-31_sensor_1-38_fusion_status.mat');

seed = 1 : 10;
trainRatio = 1 : 3;
for m = 1 : 8
    rootName = sprintf('%smlad%s/', root, caseNumBinChar(m, :));
    for t = trainRatio
       for s = seed
           folderName = sprintf('%s%s_seed_%d_trainRatio_%dpct/', rootName, fileBasic, s, t);
           folderNameNew = sprintf('%s%s_trainRatio_%dpct_seed_%d/', rootName, fileBasic, t, s);
           
           if exist([folderName trainSetFolderNameNew], 'dir')
               movefile([folderName trainSetFolderNameNew], [folderNameNew 'trainingSetByType/']);
               rmdir(folderName, 's');
           end

%            if exist([folderName netFolderName], 'dir')
%                rmdir([folderName netFolderName], 's');
%            end
% 
%            if exist([folderName matFile1Name], 'file')
%                delete([folderName matFile1Name]);
%            end
% 
%            if exist([folderName matFile2Name], 'file')
%                delete([folderName matFile2Name]);
%            end
%            
%            if exist([folderName trainSetFolderName], 'dir')
%                copyfile([folderName trainSetFolderName], [folderName trainSetFolderNameNew]);
%                rmdir([folderName trainSetFolderName], 's');
%                fprintf('\nyes\n')
%            else
%                fprintf('\nno\n')
%            end
           
           fprintf('\nmlad%s  trainRatio %d pct  seed %d done\n', caseNumBinChar(m, :), t, s)
           
       end
    end
end