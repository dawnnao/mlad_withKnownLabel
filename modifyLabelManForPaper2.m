clear; clc; close all;

% this program is to check the common misclassifed samples in the results from summary

load('D:\results\results_mlad_withKnownLabel\round3\mlad111\2012-01-01--2012-12-31_sensor_1-38_fusion_trainRatio_3pct_seed_1\2012-01-01--2012-12-31_sensor_1-38_fusion_globalEpoch_150_batchSize_100_sizeFilter_40_numFilter_20.mat');
clearvars -except confTestInd

labelManPath = 'C:/Users/Owner/Documents/GitHub/mlad_withKnownLabel/labelMan/label2012_modifiedAfterRound2Test.mat';
load(labelManPath);

pathSave = 'C:/Users/Owner/Google Drive/research/17-2 aut-phd-year2-1/secondPaper!/images/image_matrix/';

path.root = 'C:/dataArchiveTemp/Sutong/'; % raw data path
fs = 20;

sequenceCube = [12 16 43 44]; %[19 31 20 38 21 45 26 32 27 39 28 46 34 40 35 47 42 48]; % [2 8 3 15 4 22 5 29 6 36 7 43 10 16 11 23 12 30 13 37 14 44 18 24 
labelTotal = size(label2012.sensor.label.name, 2);
for nCube = sequenceCube
    count = 1;
    while count <= length(confTestInd{nCube})
        idxTime = mod(confTestInd{nCube}(count), 8784);
        if idxTime == 0
            idxTime = 8784;
        end
        idxChan = (confTestInd{nCube}(count) - idxTime)/8784 + 1;
        [date, hour] = colLocation(idxTime, '2012-01-01');
        dateVec = datevec(date, 'yyyy-mm-dd');
        path.folder = sprintf('%04d-%02d-%02d',dateVec(1,1),dateVec(1,2), dateVec(1,3));
        path.file = [path.folder sprintf(' %02d-VIB.mat',hour)];
        path.full = [path.root '/' path.folder '/' path.file];
        if ~exist(path.full, 'file')
            fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
            sensorData(1, 1) = zeros;  % always save in column 1
        else
            read = ['load(''' path.full ''');']; eval(read);
            sensorData(:, 1) = data(:, idxChan);  % always save in column 1
        end
        
        %% plot
        % time series signals plot
        figure(1)
        plot(sensorData(:, 1),'color','k');
        position = get(gcf,'Position');
        set(gcf,'Units','pixels','Position',[1200, position(2), 100, 100]);  % control figure's position
        set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
        set(gca,'visible','off');
        xlim([0 size(sensorData,1)]);
        set(gcf,'color','white');
        imgTime = getframe(gcf);
        imgTime = imresize(imgTime.cdata, [100 100]);  % expected dimension
        imgTime = rgb2gray(imgTime);
        imgTime = im2double(imgTime);
        
        % frequency domain plot
        figure(2)
        N = size(sensorData, 1);
        f = (0 : N/2-1)*(fs/N);
        sensorData(isnan(sensorData(:, 1)), 1) = 0;
        freqData = fft(sensorData(:, 1)-median(sensorData(:, 1)));
        plot(f, abs(real(freqData(1:N/2))),'color','k');
        set(gca, 'visible', 'off');
        set(gcf,'color','white');
        set(gcf,'Units','pixels','Position',[1350, position(2), 100, 100]);  % control figure's position
        set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
        imgFreq = getframe(gcf);
        imgFreq = imresize(imgFreq.cdata, [100 100]);  % expected dimension
        imgFreq = rgb2gray(imgFreq);
        imgFreq = im2double(imgFreq);
        
        % time-frequency plot
        imgTF = [];
        imgTF(:, :, 1) = imgFreq;
        imgTF(:, :, 2) = imgTime;

        imgBlue = (imgTime + imgFreq)/2;
        imgBlue(imgBlue <= 170/256) = 0;
        imgTF(:, :, 3) = imgBlue;
        
        figure(3)
        imshow(imgTF,'Border','tight'); % 'InitialMagnification', 100
%         set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
        set(gcf,'Units','pixels','Position',[1500, position(2), 150, 150]);  % control figure's position
%         
%         fileSaveTemp = [pathSave '/' sprintf('%scube_%d_numb_%d', nCube, count) '_TF.tif'];
%         imwrite(imgTF, fileSaveTemp);
%         fileSaveTemp = [pathSave '/' sprintf('%scube_%d_numb_%d', nCube, count) '_TF.emf'];
%         imwrite(imgTF, fileSaveTemp);
        
        
        %% modify label
        fprintf('\nCube %d', nCube)
        fprintf('\nAll: %d, Now: %d', length(confTestInd{nCube}), count)
        fprintf('\nCurrent label: %d\n', label2012.sensor.label.manual{idxChan}(idxTime))
        fprintf('\nData type:')
        for l = 1 : labelTotal
            fprintf('\n%s', label2012.sensor.label.name{l})
        end
        fprintf('\n\n9-jump 10 samples without change\n0-previous\n999-next cube of confusion matrix\n909-save current progress\n')
        
        prompt = '\nInput: ';
        classify = input(prompt,'s');
        classify = str2double(classify);  % filter charactor input
        if classify <= labelTotal && classify >= 1
            label2012.sensor.label.manual{idxChan}(idxTime) = classify;
            count = count + 1;
        elseif classify == 9
            count = count + 10;
        elseif classify == 999
            count = length(labelNetInter.out.intersect{nCube}) + 1;
        elseif classify == 0
            if count > 1
                fprintf('\nRedo previous one.\n')
                count = count - 1;
            else fprintf('\nThis is already the first!\n')
            end
        elseif classify == 909
            fprintf('\nSaving current progress...\n')
            if ~exist('labelMan/', 'dir')
                mkdir('labelMan/')
            end
            saveNameTemp = sprintf('labelMan/trainingSet_justLabel_inSensorCell_cube%d-idx%d_', nCube, count-1);
            save([saveNameTemp datestr(now,'yyyy-mm-dd_HH-MM-SS') '.mat'], 'label2012', '-v7.3')
        else
            fprintf('\n\n\n\n\n\nInvalid input! Input 1-7 for labelling, 0 for redoing previous one,\n')
            fprintf('9 for jumping to the next without change, 909 for saving current progress.\n')
        end
        fprintf('-----------------------------------\n')
        
        
        
        
    end
    
end











