function sensor = mlad111_withKnownLabel_fromRAM_spectrogram(readRoot, saveRoot, sensorNum, ...
    dateStart, dateEnd, sensorTrainRatio, sensorPSize, fs, step, labelName, ...
    seed, maxEpoch, batchSize, sizeFilter, numFilter, publicImagesetPath, labelPath, img2012)
% DESCRIPTION:
%   This is a machine vision based anomaly detection (MVAD) pre-processing
%   function for structural health monitoring data. The work flow is:
%   read tidy data -> assist user label partial data to make a training set ->
%   automatically train deep neural network(s) and classify all data ->
%   automatically remove bad data (undone) -> automatically recover data using
%   multiple data recovery techniques (undone).

% OUTPUTS:
%   sensor (structure):
%   sensor.num (cell) - column number of channel in the input data
%   sensor.numVec (double) - convert sensor.num into array format (useless to user)
%   sensor.trainRatio (cell) - (training set size)/(the whole data set size)
%   sensor.pSize (double) - data points in a packet in wireless transmission
%                           (if a packet loses in transmission, all points
%                            within become outliers)
%   sensor.date (structure) - date information of each data piece
%   sensor.label (structure) - label information of each data piece
%   sensor.neuralNet (cell) - neural network(s) for each channel
%   sensor.trainRecord (cell) - training record
%   sensor.count (structure) - statistics of each category of data
%   sensor.statsPerSensor - information to auto-draw bar plot
%   sensor.statsPerLabel - information to auto-draw bar plot
%   sensor.ratioOfCategory - ratio of each category to auto-draw table
%   sensor.status (cell) - work flow status
% 
% INPUTS:
%   readRoot (char) - raw data folder (absolute path)
%   saveRoot (char) - detection result folder (absolute path)
%   sensorNum (double/cell) - column nubmer of channel-to-detect. Example:
%                 if channel 1, 2, 3 share a network, sensorNum = [1,2,3];
%                 if channel 1 individually use a network, and channel 2, 3
%                 share a network, sensorNum = {[1], [2,3]}
%   dateStart (char) - start date of data, input format: 'yyyy-mm-dd'
%   dateEnd (char) - end date of data, input format: 'yyyy-mm-dd'
%   sensorTrainRatio (double) - (training set size)/(the whole data set size)
%   sensorPSize (double) - data points in a packet in wireless transmission
%                          (if a packet loses in transmission, all points
%                           within become outliers)
%   step (double) - choose steps, including: '1-Glance' '2-Label' '3-Train'
%                                            '4-Detect' '5-Inspect
% 
% DEFAULT VALUES:
%   sensorTrainRatio = 5/100
%   sensorPSize = 10
%   step = 1 (then program will ask go on or stop)
% 
% DATA FORMAT:
%   Each mat file contains an hour data for all channels, and each channel's
%   signal is a column vector. For example, 10 channels, all with a 1Hz
%   sampling frequency, there would be a 3600*10 array, named 'data'.
%   Folder structure should be like this:
%   -- 2016
%      |
%       - 2016-01-01
%         |
%          - 2016-01-01 00-VIB.mat
%          - 2016-01-01 01-VIB.mat
%          - 2016-01-01 02-VIB.mat
%          .
%          .
%          .
%          - 2016-01-01 23-VIB.mat
%       - 2016-01-02
%       - 2016-01-03
%       .
%       .
%       .
%       - 2016-12-31
%   Subfolder and mat file's name should strictly follow the format above,
%   otherwise data would cannot be read in.
% 
% CAUTION:
%   mvad.m uses multiple subfunctions, insure they are there in the working directory.

% VERSION:
%   0.4
% 
% WHAT'S NEW
% 0.4: 04/05/2017
% * Add
% 
% AUTHOR:
%   Zhiyi Tang
%   tangzhi1@hit.edu.cn
%   Center of Structural Monitoring and Control
% 
% DATE CREATED:
%   12/09/2016

% set input defaults:
if ~exist('sensorTrainRatio', 'var') || isempty(sensorTrainRatio), sensorTrainRatio = 5/100; end
if ~exist('sensorPSize', 'var') || isempty(sensorPSize), sensorPSize = 10; end
if ~exist('step', 'var'), step = []; end
if ~exist('labelName', 'var') || isempty(labelName)
%     labelName = {'1-normal','2-outlier','3-minor','4-missing','5-trend','6-drift','7-bias','8-cutoff','9-square'};
    labelName = {'1-Normal','2-Missing','3-Minor','4-Outlier','5-Square','6-Trend','7-Drift'};
end

%% common variables
labelTotal = length(labelName);
if ~iscell(sensorNum), sensorNum = {sensorNum}; end
groupTotal = length(sensorNum(:));
sensor.numVec = [];
for g = 1 : groupTotal, sensor.numVec = [sensor.numVec sensorNum{g}(:)']; end
sensorTotal = length(sensor.numVec);
color= {[129 199 132]/255;    % 1-normal            green
%         [000 130 000]/255;    % 1-normal            green
        [244 67 54]/255;      % 2-missing           red
        [121 85 72]/255;      % 3-minor             brown
        [255 235 59]/255;     % 4-outlier           yellow
        [50 50 50]/255;       % 5-square            black  
        [33 150 243]/255;     % 6-trend             blue
        [171 71 188]/255;     % 7-drift             purple
        
%         [168 168 168]/255;    % for custom          gray
        [255 255 255]/255;    % for custom          white
        [250 250 250]/255;    % for custom          gray
        [255 112 67]/255;     % for custom          orange        
        [0 121 107]/255;      % for custom          dark green
        [24 255 255]/255;     % for custom          high-light blue
        [118 255 3]/255;      % for custom          high-light green
        [255 255 0]/255;      % for custom          high-light yellow
        [50 50 50]/255};      % for custom          dark green

% pass parameters to variables inside
sensor.num = sensorNum;
date.start = dateStart;
date.end = dateEnd;
for s = 1 : sensorTotal
    sensor.trainRatio(sensor.numVec(s)) = sensorTrainRatio;
end
sensor.pSize = sensorPSize;
sensor.label.name = labelName;

%% 0 generate file and folder names
sensorStr = tidyName(abbr(sensor.numVec));
if groupTotal == sensorTotal
    netLayout = '_parallel';
elseif groupTotal == 1
    netLayout = '_fusion';
elseif groupTotal > 1 && groupTotal < sensorTotal
    netLayout = '_customGroups';
end

dirName.home = sprintf('%s/%s--%s_sensor%s%s_trainRatio_%dpct_seed_%d/', saveRoot, date.start, date.end, sensorStr, netLayout, sensorTrainRatio*100, seed);
dirName.home = GetFullPath(dirName.home);
dirName.file = sprintf('%s--%s_sensor%s%s_globalEpoch_%d_batchSize_%d_sizeFilter_%d_numFilter_%d.mat', date.start, date.end, sensorStr, netLayout, maxEpoch(1), batchSize, sizeFilter, numFilter);
dirName.status = sprintf('%s--%s_sensor%s%s_status.mat', date.start, date.end, sensorStr, netLayout);

if ~exist(dirName.home,'dir'), mkdir(dirName.home); end
for g = 1 : groupTotal
    for s = sensor.num{g}
        dirName.sensor{s} = [dirName.home sprintf('sensor%02d/', s)];
        if ~exist(dirName.sensor{s},'dir'), mkdir(dirName.sensor{s}); end
    end
end

%% 1 glance at data
if ismember(1, step) || isempty(step)
for g = 1 : groupTotal
    for s = sensor.num{g}
        t(1) = tic;
        
        dirName.formatIn = 'yyyy-mm-dd';
        date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
        date.serial.end   = datenum(date.end, dirName.formatIn);

        % plot from mat file
        dirName.all{s} = [dirName.sensor{s} '0-all/'];
        if ~exist(dirName.all{s},'dir'), mkdir(dirName.all{s});
        else
            if ~isempty(ls(dirName.all{s}))
                fprintf('\n%s\n\nFolder is already there and not empty, continue?\n', dirName.all{s})
                rightInput = 0;
                while rightInput == 0
                    prompt = 'y(yes)/n(no): ';
                    go = input(prompt,'s');
                    if strcmp(go,'y') || strcmp(go,'yes')
                        rightInput = 1;
                        fprintf('\nContinue...\n')
                    elseif strcmp(go,'n') || strcmp(go,'no')
                        rightInput = 1;
                        fprintf('\nFinish.\n')
                        return
                    else
                        fprintf('Invalid input! Please re-input.\n')
                    end
                end
            end
        end
    end
            [~, sensor.date.vec{s}, sensor.date.serial{s}] = ...
            glanceInTimeFreqMulti_spectrogram(readRoot, sensor.num{g}, date.serial.start, date.serial.end, dirName.all, '0-all_');
    %     util.hours = size(sensor.date.vec{s}, 1);

        elapsedTime(1) = toc(t(1)); [hours, mins, secs] = sec2hms(elapsedTime(1));
        fprintf('\nSTEP1:\nSensor-%02d data plot completes, using %02d:%02d:%05.2f .\n', ...
            s, hours, mins, secs)
end

% update work flow status
sensor.status{s} = {'1-Glance' '2-Label' '3-Train' '4-Detect' '5-Inspect' ...
                     ; 0 0 0 0 0};
sensor.status{s}(2,1) = {1};
status = sensor.status{s};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

% ask go on or stop
head = 'Continue to step2, label some data for building neural networks?';
tail = 'Continue to manually make training set...';
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = 'y(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 1, fprintf('\nFinish.\n'), return
elseif ismember(2, step), fprintf('\n%s\n\n\n', tail)
end
pause(0.5)
clear head tail

end

%% 2 make training set
if ismember(2, step) || isempty(step)
% update new parameters and load training sets
if ~isempty(step) && step(1) == 2
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    newP{4,1} = sensor.label.name;
    newP{5,1} = readRoot;
    newP{6,1} = dirName.home;
    newP{7,1} = color;
    
    readPath = [dirName.home dirName.file];
    fprintf('\nLoading...\n')
    load(readPath)
    
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    sensor.label.name = newP{4,1};
    readRoot = newP{5,1};
    dirName.home = newP{6,1};
    color = newP{7,1};
    clear newP
end

dirName.trainSetByType = [GetFullPath(dirName.home) sprintf('trainingSetByType/')];
if exist(dirName.trainSetByType,'dir')
    check = ls(dirName.trainSetByType);
    if ispc, check(1:4) = []; end
    if ~isempty(check)
        fprintf('\nCAUTION:\n%s\nTraining set folder is already there and not empty, continue?\n', dirName.trainSetByType)
        rightInput = 0;
%         while rightInput == 0
%             prompt = 'y(yes)/n(no): ';
%             go = input(prompt,'s');
%             if strcmp(go,'y') || strcmp(go,'yes')
%                 rightInput = 1;
%                 fprintf('\nContinue...\n')
%             elseif strcmp(go,'n') || strcmp(go,'no')
%                 rightInput = 1;
%                 fprintf('\nFinish.\n')
%                 return
%             else
%                 fprintf('Invalid input! Please re-input.\n')
%             end
%         end
    end
elseif ~exist(dirName.trainSetByType,'dir'), mkdir(dirName.trainSetByType);
end

dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
hourTotal = (date.serial.end-date.serial.start+1)*24;

t(2) = tic;
goNext = 0;
while goNext == 0
    for g = 1 : groupTotal % ingore group in mvad2.m
        labelTemp = load(labelPath); % label2012
        label2012.bySensor = labelTemp.label2012.sensor.label.manual;
        clear labelTemp;
        
        for n = 1 : labelTotal
            label2012.byType{n} = [];
            label2012.absIdx{n} = [];
            label2012.image{n} = [];
        end
        
        % count labels by type
        for s = sensor.num{g}
            for n = 1 : labelTotal
                labelByType = find(label2012.bySensor{s} == n)';
                labelByType = [s*ones(size(labelByType)) labelByType];
                label2012.byType{n} = cat(1, label2012.byType{n}, labelByType);
                labelByType = [];
                label2012.actualNum(1, n) = size(label2012.byType{n}, 1);
            end
        end
        clear labelByType
        
        label2012.ratioByType = [];
        label2012.amount = size(label2012.bySensor{n}, 2) * size(label2012.bySensor, 2);
        for n = 1 : labelTotal
            label2012.ratioByType(n) = size(label2012.byType{n}, 1) / label2012.amount * 100;
        end
        
        [actualNumSorted, idx] = sort(label2012.actualNum);
        
        leftNumToTrain = ceil(label2012.amount * sensorTrainRatio);
        averageNumToTrain =  ceil(leftNumToTrain / labelTotal);
        count = 0;
        for n = idx
            if averageNumToTrain <= label2012.actualNum(n)
                label2012.trainNum(n) = averageNumToTrain;
                leftNumToTrain = leftNumToTrain - averageNumToTrain;
                count = count + 1;
            else
                label2012.trainNum(n) = label2012.actualNum(n);
                leftNumToTrain = leftNumToTrain - label2012.actualNum(n);
                count = count + 1;
                averageNumToTrain = ceil(leftNumToTrain/(labelTotal - count));
            
            end
        end
        
        % get abs index
        for n = 1 : labelTotal
            rng(seed + n)
            label2012.idxInType{n} = randperm(size(label2012.byType{n}, 1), label2012.trainNum(n))';
            label2012.absIdx{n} = label2012.byType{n}(label2012.idxInType{n}, :);
        end
        
        % get image from public imageset       
        for n = 1 : labelTotal
            if ~exist([dirName.trainSetByType labelName{n}], 'dir')
                mkdir([dirName.trainSetByType labelName{n}]);
            end
            for m = 1 : label2012.trainNum(n)
                path.sourceFolder = sprintf('%ssensor%02d/0-all/', publicImagesetPath , label2012.absIdx{n}(m, 1));
                
                path.sourceFile1 = sprintf('%s0-all_absIdx_%d_%d_time.png', path.sourceFolder, label2012.absIdx{n}(m, 1), label2012.absIdx{n}(m, 2));
                path.goalFile1 = sprintf('%s%s/%s_absIdx_%02d_%d_time.png', dirName.trainSetByType, labelName{n}, labelName{n}, label2012.absIdx{n}(m, 1), label2012.absIdx{n}(m, 2));
                
                path.sourceFile2 = sprintf('%s0-all_absIdx_%d_%d_freq.png', path.sourceFolder, label2012.absIdx{n}(m, 1), label2012.absIdx{n}(m, 2));
                path.goalFile2 = sprintf('%s%s/%s_absIdx_%02d_%d_freq.png', dirName.trainSetByType, labelName{n}, labelName{n}, label2012.absIdx{n}(m, 1), label2012.absIdx{n}(m, 2));
                
%                 if exist(path.sourceFile1, 'file')
%                    fprintf('\nGenerating training set... %s Now: %d Total: %d\n', labelName{n}, m, label2012.trainNum(n))
%                    if mod(m, 100) == 0
%                       fprintf('\nHome folder: %s\n', dirName.home)
%                    end
%                    img1 = imread(path.sourceFile1);
%                    img1 = im2double(img1);
%                    copyfile(path.sourceFile1, path.goalFile1, 'f');                   
%                 else
%                    fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
%                    sensorData(1, 1) = zeros;
%                    plot(sensorData(:, 1),'color','k');
%                    position = get(gcf,'Position');
%                    set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
%                    set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
%                    set(gca,'visible','off');
%                    xlim([0 size(sensorData,1)]);
%                    set(gcf,'color','white');
%                    img1 = getframe(gcf);
%                    img1 = imresize(img1.cdata, [100 100]);  % expected dimension
%                    img1 = rgb2gray(img1);
%                    img1 = im2double(img1);
%                    imwrite(img1, path.goalFile);
%                 end
%                    imshow(img1)
%                    label2012.image{n}(1:10000, m) = single(img1(:));
%                    
%                 if exist(path.sourceFile2, 'file')
%                    fprintf('\nGenerating training set... %s Now: %d Total: %d\n', labelName{n}, m, label2012.trainNum(n))
%                    img2 = imread(path.sourceFile2);
%                    img2 = im2double(img2);
%                    copyfile(path.sourceFile2, path.goalFile2, 'f');                   
%                 else
%                    fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
%                    sensorData(1, 1) = zeros;
%                    plot(sensorData(:, 1),'color','k');
%                    position = get(gcf,'Position');
%                    set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
%                    set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
%                    set(gca,'visible','off');
%                    xlim([0 size(sensorData,1)]);
%                    set(gcf,'color','white');
%                    img2 = getframe(gcf);
%                    img2 = imresize(img2.cdata, [100 100]);  % expected dimension
%                    img2 = rgb2gray(img2);
%                    img2 = im2double(img2);
%                    imwrite(img2, path.goalFile2);
%                 end
%                    imshow(img2)
%                    label2012.image{n}(10001:20000, m) = single(img2(:));


                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 [day, hour] = colLocation(label2012.absIdx{n}(m, 2) ,'2012-01-01');
%                 dateVec(1, :) = datevec(day,'yyyy-mm-dd');
%                 dateVec(1, 4) = hour;
%                 path.folder = sprintf('%04d-%02d-%02d', dateVec(1,1),dateVec(1,2), dateVec(1,3));
%                 path.file = [path.folder sprintf(' %02d-VIB.mat', hour)];
%                 path.full = [readRoot '/' path.folder '/' path.file];
%                 if ~exist(path.full, 'file')
%                     fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
%                     sensorData(1, 1) = zeros;  % always save in column 1
%                 else
%                     read = ['load(''' path.full ''');']; eval(read);
%                     sensorData(:, 1) = data(:, label2012.absIdx{n}(m, 1));  % always save in column 1
%                 end
%                 
%                 fprintf('\nGenerating training set... %s Now: %d Total: %d\n', labelName{n}, m, label2012.trainNum(n))
%                 plot(sensorData(:, 1),'color','k');
%                 position = get(gcf,'Position');
%                 set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
%                 set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
%                 set(gca,'visible','off');
%                 xlim([0 size(sensorData,1)]);
%                 set(gcf,'color','white');
%                 img = getframe(gcf);
%                 img = imresize(img.cdata, [100 100]);  % expected dimension
%                 img = rgb2gray(img);
%                 img = im2double(img);
%                 imshow(img)
%                 imwrite(img, [dirName.trainSetByType labelName{n} ...
%                     sprintf('/%s_absIdx_%02d_%d.png', labelName{n}, label2012.absIdx{n}(m, 1), label2012.absIdx{n}(m, 2))]);
%                 label2012.image{n}(:, m) = single(img(:));
            end
            clear img
            label2012.imgLabel{n} = zeros(labelTotal, label2012.trainNum(n));
            label2012.imgLabel{n}(n, :) = 1;
        end
        close
        
        %% added on 2018-01-08 for training set visualization | start here
        for s = sensor.numVec
            sensor.label.manualTrainSet{s} = zeros(labelTotal, hourTotal);
            sensor.date.serial{s} = dateSerial;
        end
        
        % form global label set
        for n = 1 : labelTotal
            for m = 1 : size(label2012.absIdx{n}, 1)
                sensor.label.manualTrainSet{label2012.absIdx{n}(m,1)}(:, label2012.absIdx{n}(m,2)) = ...
                    label2012.imgLabel{n}(:, m);
            end
        end
        
        % add a new line for non-labeled data
        for s = sensor.numVec
            sensor.label.manualTrainSet{s} = [sensor.label.manualTrainSet{s}; ...
                                              zeros(1, size(sensor.label.manualTrainSet{s},2))];
            sensor.label.manualTrainSet{s}(end, sum(sensor.label.manualTrainSet{s}) == 0) = 1;
            sensor.label.manualTrainSet{s} = vec2ind(sensor.label.manualTrainSet{s});
        end
        
        % training set panorama
        dirName.plotPanoTrainSet = [dirName.trainSetByType 'panorama/'];
        if ~exist(dirName.plotPanoTrainSet, 'dir'), mkdir(dirName.plotPanoTrainSet); end
        for s = sensor.numVec
            if mod(s,2) == 1
                yStrTemp = '';
            else
                yStrTemp = sprintf('      %02d', s);
            end
            panorama(sensor.date.serial{s}, sensor.label.manualTrainSet{s}, yStrTemp, color(1:labelTotal+1));
            dirName.panoramaTrainSet{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_trainingSetLabelPanorama.png'];
            saveas(gcf,[dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]);
            fprintf('\nSensor-%02d training set panorama file location:\n%s\n', ...
                s, GetFullPath([dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]));
            close																 
        end

        n = 0;
        panopano = [];
        for s = sensor.numVec
            n = n + 1;
            p{s} = imread(GetFullPath([dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]));
            if n > 1
                height = size(p{s},1);
                width = size(p{s},2);
                p{s} = p{s}(1:ceil(height*0.22), :, :);
            end
            panopano = cat(1, p{s}, panopano);
        end
        dirName.panopanoTrainSet = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                            '_trainingSetLabelPanorama.tif'];
        imwrite(panopano, [dirName.plotPanoTrainSet dirName.panopanoTrainSet]);
        
        %% added on 2018-01-08 for training set visualization | end here
        
        
        
        
        
        save([dirName.trainSetByType 'trainSetByType.mat'], 'label2012', '-v7.3')
    end
    goNext = 1;
    
end

% update work flow status
status(2,2) = {1};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

elapsedTime(2) = toc(t(2)); [hours, mins, secs] = sec2hms(elapsedTime(2));
fprintf('\n\n\nSTEP2:\nSensor(s) training set making completes, using %02d:%02d:%05.2f .\n', ...
    hours, mins, secs)

% ask go on or stop
head = 'Continue to step3, automatically train deep neural network(s) now?';
tail = 'Continue to automatically train deep neural network(s)...';
savePath = [dirName.home dirName.file];
fprintf('\nSaving results...\nLocation: %s\n', savePath)
if exist(savePath, 'file'), delete(savePath); end
save(savePath, '-v7.3', '-regexp', '^(?!(img2012)$).')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = 'y(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 2, fprintf('\nFinish.\n'), return
elseif ismember(3, step), fprintf('\n%s\n\n\n', tail)
end
pause(0.5)
clear head tail savePath

end

%% 3 train network(s)
if ismember(3, step) || isempty(step)
% update new parameters and load training sets
if ~isempty(step) && step(1) == 3
    for s = sensor.numVec
        newP{1,s} = sensor.trainRatio(s);
    end
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    dirName.trainSetByType = [GetFullPath(dirName.home) sprintf('/trainingSetByType/')];
    
    for g = 1 : groupTotal
        load([dirName.trainSetByType 'trainSetByType.mat']);
    end
    % update
    sensor.numVec = [];
    for g = 1 : groupTotal, sensor.numVec = [sensor.numVec sensor.num{g}(:)']; end
    if isempty(sensor.numVec)
        fprintf('\nCAUTION:\nNo training set found in\n%s\n', dirName.mat)
        fprintf('Need to make trainning set (step2) first.\nFinish.\n')
        return
    end
    
    for s = sensor.numVec
        sensor.trainRatio(s) = newP{1,s};
    end
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    clear newP
end

t(3) = tic;
dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
% hourTotal = (date.serial.end-date.serial.start+1)*24;

dirName.net = [dirName.home sprintf('/net_globalEpoch_%d_batchSize_%d_sizeFilter_%d_numFilter_%d/', maxEpoch(1), batchSize, sizeFilter, numFilter)];
if ~exist(dirName.net,'dir'), mkdir(dirName.net); end

fprintf('\nHome folder: %s\n', dirName.home)
fprintf('\nData combining...\n')
for g = 1 : groupTotal
    feature{g}.image = [];
    feature{g}.label.manual = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for l = 1 : 7 %labelTotal
        feature{g}.image = [feature{g}.image label2012.image{l}];
        feature{g}.label.manual = [feature{g}.label.manual label2012.imgLabel{l}];
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % convert feature into 4D matrices for CNN training
    numTemp = size(feature{g}.image, 2);
    feature{g}.image = reshape(feature{g}.image, [100, 100, 2, numTemp]);
    % for define output layer size
    feature{g}.label.activeLabelNum = length(unique(vec2ind(feature{g}.label.manual)));
end

% add channel-3 into image
for n = 1 : numTemp
    feature{g}.image(:, :, 3, n) = ones(100, 100);
end

rng(seed,'twister');
fprintf('\nTraining...\n')
for g = 1 : groupTotal
    ticRemain = tic;
    randp{g} = randperm(size(feature{g}.image, 4));  % randomization
    feature{g}.image = feature{g}.image(:, :, :, randp{g});
    feature{g}.label.manual = feature{g}.label.manual(:, randp{g});
    for s = sensor.num{g}(1)
        feature{g}.trainRatio = 50/100;
        feature{g}.trainSize = floor(size(feature{g}.image,4) * feature{g}.trainRatio);
        % design architecture of CNN
        layers = [imageInputLayer([100 100 3])
                  
                  % design 1
                  convolution2dLayer(sizeFilter, numFilter)
                  reluLayer
                  maxPooling2dLayer(2,'Stride',2)
                  
%                   convolution2dLayer(20, 20)
%                   reluLayer
%                   maxPooling2dLayer(2,'Stride',2)

%                   % design 2
%                   convolution2dLayer(10, numFilter)
%                   convolution2dLayer(6, 40)
%                   reluLayer
%                   maxPooling2dLayer(2,'Stride',2)
                  
                  fullyConnectedLayer(feature{g}.label.activeLabelNum)
                  softmaxLayer
                  classificationLayer()];

        % set options of training
        options = trainingOptions('sgdm','MaxEpochs',maxEpoch(1), ...
            'InitialLearnRate',0.0001, 'MiniBatchSize',batchSize, 'Momentum',0.8,...
            'OutputFcn',@plotTrainingAccuracy,'ExecutionEnvironment','gpu');

        % train CNN
        trainLabel = categorical(vec2ind(feature{g}.label.manual));
        [sensor.neuralNet{s},sensor.trainRecord{s}] = ...
            trainNetwork(feature{g}.image(:, :, :, 1:feature{g}.trainSize), ...
            trainLabel(1:feature{g}.trainSize), layers, options);
        box on
        set(gca, 'fontsize',11, 'fontname', 'Times New Roman', 'fontweight', 'bold');
        saveas(gcf,[dirName.net sprintf('group-%d_netAccuracy.png', g)]);
        close
    end
    
    yTrain = predict(sensor.neuralNet{s}, feature{g}.image(:, :, :, 1:feature{g}.trainSize))';
    
    [confTrainC, confTrainCM, confTrainInd, confTrainPer] = ...
        confusion(feature{g}.label.manual(:, 1:feature{g}.trainSize), yTrain); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    confTrainAccuracy = 1 - confTrainC;
    confTrainPrecision = confTrainPer(:, 3);
    for m = 1 : 7
       confTrainRecall(m, 1) = confTrainCM(m, m) / sum(confTrainCM(m, :)); 
    end
    
    figure
    plotconfusion(yTrain, feature{g}.label.manual(:, 1:feature{g}.trainSize));
    xlabel('Predicted');
    ylabel('Actual');
    title([]);
    set(gca,'fontname', 'Times New Roman', 'fontweight', 'bold', 'fontsize', 12);
    % minimize white space
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2) + 0.03;
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4) - 0.03;
    ax.Position = [left bottom ax_width ax_height];
    saveas(gcf,[dirName.net sprintf('group-%d_netConfuseTrain.png', g)]);
    close
    
    yVali = predict(sensor.neuralNet{s}, feature{g}.image(:, :, :, feature{g}.trainSize+1:end))';
    
    [confValiC, confValiCM, confValiInd, confValiPer] = ...
        confusion(feature{g}.label.manual(:,feature{g}.trainSize+1 : end), yVali); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    confValiAccuracy = 1 - confValiC;
    confValiPrecision = confValiPer(:, 3);        
    for m = 1 : 7
       confValiRecall(m, 1) = confValiCM(m, m) / sum(confValiCM(m, :)); 
    end
    
    figure
    plotconfusion(yVali, feature{g}.label.manual(:, feature{g}.trainSize+1:end));
%     plotconfusion(feature{g}.label.manual, yTrain);
    xlabel('Predicted');
    ylabel('Actual');
    title([]);
    set(gca,'fontname', 'Times New Roman', 'fontweight', 'bold', 'fontsize', 12);
    % minimize white space
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2) + 0.03;
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4) - 0.03;
    ax.Position = [left bottom ax_width ax_height];
    saveas(gcf,[dirName.net sprintf('group-%d_netConfuseVali.png', g)]);
    close
    
    % copy to every sensor
    if length(sensor.num{g} > 1)
        for s = sensor.num{g}(2:end)
            sensor.neuralNet{s} = sensor.neuralNet{sensor.num{g}(1)};
            sensor.trainRecord{s} = sensor.trainRecord{sensor.num{g}(1)};
        end
    end
    
    fprintf('\nGroup-%d neural network training done. ', g)
    tocRemain = toc(ticRemain);
    tRemain = tocRemain * (groupTotal - g);
    [hours, mins, secs] = sec2hms(tRemain);
    fprintf('About %02dh%02dm%05.2fs left.\n', hours, mins, secs)
    
end

elapsedTime(3) = toc(t(3)); [hours, mins, secs] = sec2hms(elapsedTime(3));
fprintf('\n\n\nSTEP3:\nNeural network(s) training completes, using %02dh%02dm%05.2fs .\n', ...
    hours, mins, secs)

% update work flow status
status(2,3) = {1};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

% ask go on or stop
head = 'Continue to step4 - anomaly detection?';
tail = 'Continue to anomaly detection...';
savePath = [dirName.home dirName.file];
fprintf('\nSaving results...\nLocation: %s\n', savePath)
if exist(savePath, 'file'), delete(savePath); end
save(savePath, '-v7.3', '-regexp', '^(?!(img2012)$).')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = 'y(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 3, fprintf('\nFinish.\n'), return
elseif ismember(4, step), fprintf('\n%s\n\n\n', tail)
end
pause(0.5)
clear head tail savePath

end

%% 4 anomaly detection
if ismember(4, step) || isempty(step)
% update new parameters and load training sets
if ~isempty(step) && step(1) == 4
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    newP{4,1} = sensor.label.name;
    newP{5,1} = readRoot;
    newP{6,1} = dirName.home;
    newP{7,1} = labelPath;
    
    readPath = [dirName.home dirName.file];
    load(readPath)
    
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    sensor.label.name = newP{4,1};
    readRoot = newP{5,1};
    dirName.home = newP{6,1};
    labelPath = newP{7,1};
    clear newP
end

t(4) = tic;
dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
% hourTotal = (date.serial.end-date.serial.start+1)*24;

% anomaly detection
fprintf('\nDetecting...\n')
[labelTempNeural, countTempNeural, dateVec, dateSerial, labelDecimalTempNeural] = ...
    classifierMultiInTimeFreq_fromRAM(readRoot, sensor.numVec, date.serial.start, date.serial.end, ...
    dirName.home, sensor.label.name, sensor.neuralNet, fs, img2012);

for s = sensor.numVec
    sensor.label.neuralNet{s} = labelTempNeural{s};
    for l = 1 : labelTotal
        sensor.count{l,s} = countTempNeural{l,s};
    end
    sensor.date.vec{s} = dateVec;
    sensor.date.serial{s} = dateSerial;
end
clear labelTempNeural countTempNeural

% temp for roc plot
for s = sensor.numVec
    sensor.labelDecimal.neuralNet{s} = labelDecimalTempNeural{s};
end
% clear labelDecimalTempNeural

elapsedTime(4) = toc(t(4)); [hours, mins, secs] = sec2hms(elapsedTime(4));
fprintf('\n\n\nSTEP4:\nAnomaly detection completes, using %02dh%02dm%05.2fs .\n', ...
    hours, mins, secs)

% update work flow status
status(2,4) = {1};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

% ask go on or stop
head = 'Continue to step5, anomaly statistics?';
tail = 'Continue to do anomaly statistics...';
savePath = [dirName.home dirName.file];
fprintf('\nSaving results...\nLocation: %s\n', savePath)
if exist(savePath, 'file'), delete(savePath); end
save(savePath, '-v7.3', '-regexp', '^(?!(img2012)$).')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = 'y(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 4, fprintf('\nFinish.\n'), return
elseif ismember(5, step), fprintf('\n%s\n\n\n', tail)
end
pause(0.5)
clear head tail savePath

end

%% 5 statistics
if ismember(5, step) || isempty(step)
% update new parameters and load training sets
if ~isempty(step) && step(1) == 5
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    newP{4,1} = sensor.label.name;
    newP{5,1} = readRoot;
    newP{6,1} = dirName.home;
    newP{7,1} = labelPath;
    newP{8,1} = color;
    
    readPath = [dirName.home dirName.file];
    fprintf('Loading...\n')
    load(readPath)
    
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    sensor.label.name = newP{4,1};
    readRoot = newP{5,1};
    dirName.home = newP{6,1};
    labelPath = newP{7,1};
    color = newP{8,1};
    clear newP
end
t(5) = tic;
dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
hourTotal = (date.serial.end-date.serial.start+1)*24;


%% extract test set
% extract test set from the whole nn predicted set
sensor.label.neuralNetTestSet = sensor.label.neuralNet;
for s = sensor.numVec
    index_train_set = find(sensor.label.manualTrainSet{s} ~= 8);
    sensor.label.neuralNetTestSet{s}(index_train_set) = categorical(8);
    index_train_set = [];
end

fprintf('\nLoading actual labels of 2012...\n')
sensorTemp = load(labelPath);

% extract test set from the whole manual labeled set
sensor.label.manualTestSet = sensorTemp.label2012.sensor.label.manual;
for s = sensor.numVec
    index_train_set = find(sensor.label.manualTrainSet{s} ~= 8);
    sensor.label.manualTestSet{s}(index_train_set) = 8;
    index_train_set = [];
end

%%

% reportCover; % make report cover!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

dirName.plot = [dirName.home sprintf('/plot_globalEpoch_%d_batchSize_%d_sizeFilter_%d_numFilter_%d/', maxEpoch(1), batchSize, sizeFilter, numFilter)];
if ~exist(dirName.plot, 'dir'), mkdir(dirName.plot); end

%% plot panorama of test set

%% temp
% fprintf('\nLoading actual labels of 2012...\n') % groundTruth visualization
% sensorTemp = load(labelPath);
%% temp ends

dirName.plotPano = [dirName.plot 'panorama/'];
if ~exist(dirName.plotPano, 'dir'), mkdir(dirName.plotPano); end
for s = sensor.numVec
    if mod(s,2) == 1
        yStrTemp = '';
    else
        yStrTemp = sprintf('      %02d', s);
    end
    panorama(sensor.date.serial{s}, sensor.label.neuralNetTestSet{s}, yStrTemp, color(1:labelTotal+1));
%     panorama(sensor.date.serial{s}, sensor.label.manualTestSet{s}, yStrTemp, color(1:labelTotal+1));
    dirName.panorama{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyDetectionPanorama_groundtruth.png'];
    saveas(gcf,[dirName.plotPano dirName.panorama{s}]);
    fprintf('\nSenor-%02d anomaly detection panorama file location:\n%s\n', ...
        s, GetFullPath([dirName.plotPano dirName.panorama{s}]))
    close
    
    % update sensor.status
    sensor.status{s}(2,5) = {1};
end

n = 0;
panopano = [];
for s = sensor.numVec
    n = n + 1;
    p{s} = imread(GetFullPath([dirName.plotPano dirName.panorama{s}]));
    if n > 1
        height = size(p{s},1);
        width = size(p{s},2);
        p{s} = p{s}(1:ceil(height*0.22), :, :);
    end
    panopano = cat(1, p{s}, panopano);
end
dirName.panopano = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                    '_anomalyDetectionPanorama_testSet.tif'];
imwrite(panopano, [dirName.plotPano dirName.panopano]);

% reportPano; % make report chapter - Panorama!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear height width p n

% plot monthly stats per sensor
dirName.plotSPS = [dirName.plot 'statsPerSensor/'];
if ~exist(dirName.plotSPS, 'dir'), mkdir(dirName.plotSPS); end
for s = sensor.numVec
    for n = 1 : 12
        for l = 1 : labelTotal
            aim = find(sensor.date.vec{s}(:,2) == n);
            sensor.statsPerSensor{s}(n, l) = length(find(sensor.label.neuralNetTestSet{s}(aim) == categorical(l)));
        end
    end
    monthStatsPerSensorForPaper(sensor.statsPerSensor{s}, s, sensor.label.name, color);
    dirName.statsPerSensor{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyStats_testSet.png'];
    saveas(gcf,[dirName.plotSPS dirName.statsPerSensor{s}]);
    fprintf('\nSenor-%02d anomaly stats bar-plot file location:\n%s\n', ...
        s, GetFullPath([dirName.plotSPS dirName.statsPerSensor{s}]))

    close
end

% reportStatsSensor;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

% plot anomaly space-time distribution per class
dirName.plotSPT = [dirName.plot 'statsPerType/'];
if ~exist(dirName.plotSPT, 'dir'), mkdir(dirName.plotSPT); end
for l = 1 : labelTotal
   for s = sensor.numVec
       for n = 1 : 12
           aim = find(sensor.date.vec{s}(:,2) == n);
           sensor.statsPerLabel{l}(n, s) = length(find(sensor.label.neuralNetTestSet{s}(aim) == categorical(l)));
       end
   end
   if sum(sum(sensor.statsPerLabel{l})) > 0
        monthStatsPerLabelForPaper(sensor.statsPerLabel{l}, l, sensor.label.name{l}, color);
        dirName.statsPerLabel{l} = sprintf('%s--%s_sensor%s_anomalyStats_%s_testSet.png', ...
            date.start, date.end, sensorStr, sensor.label.name{l});
        saveas(gcf,[dirName.plotSPT dirName.statsPerLabel{l}]);
        fprintf('\n%s anomaly stats bar-plot file location:\n%s\n', ...
            sensor.label.name{l}, GetFullPath([dirName.plotSPT dirName.statsPerLabel{l}]))
        close
    end
end

% reportStatsLabel;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

% plot sensor-type bar stats
dirName.plotSum = [dirName.plot 'statsSumUp/'];
if ~exist(dirName.plotSum, 'dir'), mkdir(dirName.plotSum); end
for s = sensor.numVec
   for l = 1 : labelTotal
       statsSum(s, l) = length(find(sensor.label.neuralNetTestSet{s} == categorical(l)));
   end
end

if ~isempty(statsSum(1,1)) && size(statsSum, 1) == 1
    statsSum(2,1:labelTotal) = 0;
end

%%
figure
h = bar(statsSum, 'stacked', 'EdgeColor', 'none');
xlabel('Channel');
ylabel('Count (hours)');
legend(sensor.label.name);
lh=findall(gcf,'tag','legend');
set(lh,'location','northeastoutside');
% title(sprintf('%s -- %s', date.start, date.end));
grid on
for n = 1 : labelTotal
    set(h(n),'FaceColor', color{n});
end
set(gca, 'fontsize', 14, 'fontname', 'Helvetica'); % 'fontweight', 'bold'
set(gcf,'Units','pixels','Position',[100, 100, 1000, 500]);  % control figure's position
xlim([0 39]);
ylim([0 9000]);
set(gca,'xtick',[1,5:5:35, 38]);

% minimize white space
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2);
ax_width = outerpos(3) - ti(1) - ti(3) - 0.01;
ax_height = outerpos(4) - ti(2) - ti(4);
ax.Position = [left bottom ax_width ax_height];

%%
dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats_testSet.emf', ...
    date.start, date.end, sensorStr);
saveas(gcf,[dirName.plotSum dirName.statsSum]);
dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats_testSet.tif', ...
    date.start, date.end, sensorStr);
saveas(gcf,[dirName.plotSum dirName.statsSum]);
dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats_testSet.fig', ...
    date.start, date.end, sensorStr);
saveas(gcf,[dirName.plotSum dirName.statsSum]);

fprintf('\nSum-up anomaly stats image file location:\n%s\n', ...
    GetFullPath([dirName.plotSum dirName.statsSum]))
% close

%%

% reportStatsTotal;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

% sum results to check ratios of each anomaly

% for s = sensor.numVec
%     sensor.label.neuralNet{s} = labelTempNeural{s};
%     for l = 1 : labelTotal
%         sensor.count_testSet{l,s} = countTempNeural{l,s};
%     end
% %     sensor.date.vec{s} = dateVec;
% %     sensor.date.serial{s} = dateSerial;
% end
% % clear labelTempNeural countTempNeural

sensor.ratioOfCategory_testSet = zeros(3,labelTotal+1);
for s = sensor.numVec
    for m = 1 : labelTotal
        sensor.ratioOfCategory_testSet(1,m) = sensor.ratioOfCategory_testSet(1,m) + length(cell2mat(sensor.count(m,s)));
    end
end
sensor.ratioOfCategory_testSet(1,end) = sum(sensor.ratioOfCategory_testSet(1,:));
sensor.ratioOfCategory_testSet(2,:) = (sensor.ratioOfCategory_testSet(1,:)./(sensor.ratioOfCategory_testSet(1,end)-sensor.ratioOfCategory_testSet(1,1))).*100;
sensor.ratioOfCategory_testSet(3,:) = (sensor.ratioOfCategory_testSet(1,:)./sensor.ratioOfCategory_testSet(1,end)).*100;

% % crop legend to panorama's folder
% img = imread([dirName.plotSum dirName.statsSum]);
% if ispc
% %     imgLegend = imcrop(img, [646.5 42.5 172 300]);
%     imgLegend = imcrop(img, [596.5 36.5 272 232]);
% elseif ismac
% %     imgLegend = imcrop(img, [660.5 42.5 160 229]);
%     imgLegend = imcrop(img, [882.5 57.5 204 280]);
% end
% figure, imshow(imgLegend)
% saveas(gcf, [dirName.plotPano 'legend.png']); close


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp
sensorLabelNetSerialTestSet = [];
for mTemp = 1 : 38
    sensorLabelNetSerialTestSetTemp = sensor.label.neuralNetTestSet{mTemp};
%     sensorLabelNetSerialTestSetTemp_idx8 = find(sensorLabelNetSerialTestSetTemp == categorical(8));
%     sensorLabelNetSerialTestSetTemp(sensorLabelNetSerialTestSetTemp_idx8) = categorical(NaN);
    sensorLabelNetSerialTestSet = cat(1, sensorLabelNetSerialTestSet, sensorLabelNetSerialTestSetTemp);
end
% savePath = [GetFullPath(dirName.home) '/' 'sensorLabelNetSerial.mat'];
% save(savePath, 'sensorLabelNetSerial', '-v7.3')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp

%% comparison between detection results and actual labels of 2012 (only for test set)
% convert data format
labelNetTestSet = [];
for n = 1 : length(sensorLabelNetSerialTestSet)
    labelNetTestSet(n) = str2double(str2mat(sensorLabelNetSerialTestSet(n)));
end
labelNetTestSet = ind2vec(labelNetTestSet);
labelNetTestSet = labelNetTestSet(1:end-1, :);

% clear classes that not show up
for n = 1 : labelTotal
    if ~ismember(categorical(n), sensorLabelNetSerialTestSet)
       labelNetTestSet(n, :) = 0;
    end
end

labelManTestSet = [];
for mTemp = 1 : 38
    labelManTestSetTemp = sensorTemp.label2012.sensor.label.manual{mTemp}';
    index_train_set = find(sensor.label.manualTrainSet{mTemp} ~= 8);
    labelManTestSetTemp(index_train_set) = 8;
    index_train_set = [];
%     labelManTestSetTemp_idx8 = find(labelManTestSetTemp == 8);
%     labelManTestSetTemp(labelManTestSetTemp_idx8) = NaN;
    labelManTestSet = cat(1, labelManTestSet, labelManTestSetTemp);
end
labelManTestSet = ind2vec(labelManTestSet');
labelManTestSet = labelManTestSet(1:end-1, :);

% delete empty columns
labelManTestSet = labelManTestSet(:, sum(labelManTestSet) ~= 0);
labelNetTestSet = labelNetTestSet(:, sum(labelNetTestSet) ~= 0);

fprintf('\nPlotting confusion matrix...\n')
[confTestC_testSet, confTestCM_testSet, confTestInd_testSet, confTestPer_testSet] = confusion(labelManTestSet, labelNetTestSet); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
confTestAccuracy_testSet = 1 - confTestC_testSet;
confTestPrecision_testSet = confTestPer_testSet(:, 3);        
for m = 1 : 7
   confTestRecall_testSet(m, 1) = confTestCM_testSet(m, m) / sum(confTestCM_testSet(m, :)); 
end

figure
plotconfusion(labelNetTestSet, labelManTestSet)
set(findall(gcf,'-property','FontSize'),'FontSize',18)
xlabel('Predicted');
ylabel('Actual');
title([]);
% set(gca,'fontname', 'Times New Roman', 'fontweight', 'bold', 'fontsize', 12);
% minimize white space
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset;
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2) + 0.03;
ax_width = outerpos(3) - ti(1) - ti(3);
ax_height = outerpos(4) - ti(2) - ti(4) - 0.03;
ax.Position = [left bottom ax_width ax_height];
dirName.plotConfusionMatrix2012 = [dirName.plot '/confusionMatrix2012/'];
if ~exist(dirName.plotConfusionMatrix2012, 'dir'), mkdir(dirName.plotConfusionMatrix2012); end
saveas(gcf, [dirName.plotConfusionMatrix2012 sprintf('comfusionMatrix_2012_testSet_') datestr(now,'yyyy-mm-dd_HH-MM-SS') sprintf('.tif')]);
saveas(gcf, [dirName.plotConfusionMatrix2012 sprintf('comfusionMatrix_2012_testSet_') datestr(now,'yyyy-mm-dd_HH-MM-SS') sprintf('.fig')]);
close

%% plot panorama of the whole data set

% %% temp
% % fprintf('\nLoading actual labels of 2012...\n') % groundTruth visualization
% % sensorTemp = load(labelPath);
% %% temp ends
% 
% dirName.plotPano = [dirName.plot 'panorama/'];
% if ~exist(dirName.plotPano, 'dir'), mkdir(dirName.plotPano); end
% for s = sensor.numVec
%     if mod(s,2) == 1
%         yStrTemp = '';
%     else
%         yStrTemp = sprintf('      %02d', s);
%     end
%     panorama(sensor.date.serial{s}, sensor.label.neuralNet{s}, yStrTemp, color(1:labelTotal));
% %     panorama(sensor.date.serial{s}, sensorTemp.label2012.sensor.label.manual{s}, yStrTemp, color(1:labelTotal));
%     dirName.panorama{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyDetectionPanorama.png'];
%     saveas(gcf,[dirName.plotPano dirName.panorama{s}]);
%     fprintf('\nSenor-%02d anomaly detection panorama file location:\n%s\n', ...
%         s, GetFullPath([dirName.plotPano dirName.panorama{s}]))
%     close
%     
%     % update sensor.status
%     sensor.status{s}(2,5) = {1};
% end
% 
% n = 0;
% panopano = [];
% for s = sensor.numVec
%     n = n + 1;
%     p{s} = imread(GetFullPath([dirName.plotPano dirName.panorama{s}]));
%     if n > 1
%         height = size(p{s},1);
%         width = size(p{s},2);
%         p{s} = p{s}(1:ceil(height*0.22), :, :);
%     end
%     panopano = cat(1, p{s}, panopano);
% end
% dirName.panopano = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
%                     '_anomalyDetectionPanorama.tif'];
% imwrite(panopano, [dirName.plotPano dirName.panopano]);
% 
% % reportPano; % make report chapter - Panorama!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
% clear height width p n
% 
% % plot monthly stats per sensor
% dirName.plotSPS = [dirName.plot 'statsPerSensor/'];
% if ~exist(dirName.plotSPS, 'dir'), mkdir(dirName.plotSPS); end
% for s = sensor.numVec
%     for n = 1 : 12
%         for l = 1 : labelTotal
%             aim = find(sensor.date.vec{s}(:,2) == n);
%             sensor.statsPerSensor{s}(n, l) = length(find(sensor.label.neuralNet{s}(aim) == categorical(l)));
%         end
%     end
%     monthStatsPerSensorForPaper(sensor.statsPerSensor{s}, s, sensor.label.name, color);
%     dirName.statsPerSensor{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyStats.png'];
%     saveas(gcf,[dirName.plotSPS dirName.statsPerSensor{s}]);
%     fprintf('\nSenor-%02d anomaly stats bar-plot file location:\n%s\n', ...
%         s, GetFullPath([dirName.plotSPS dirName.statsPerSensor{s}]))
% 
%     close
% end
% 
% % reportStatsSensor;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
% % plot anomaly space-time distribution per class
% dirName.plotSPT = [dirName.plot 'statsPerType/'];
% if ~exist(dirName.plotSPT, 'dir'), mkdir(dirName.plotSPT); end
% for l = 1 : labelTotal
%    for s = sensor.numVec
%        for n = 1 : 12
%            aim = find(sensor.date.vec{s}(:,2) == n);
%            sensor.statsPerLabel{l}(n, s) = length(find(sensor.label.neuralNet{s}(aim) == categorical(l)));
%        end
%    end
%    if sum(sum(sensor.statsPerLabel{l})) > 0
%         monthStatsPerLabelForPaper(sensor.statsPerLabel{l}, l, sensor.label.name{l}, color);
%         dirName.statsPerLabel{l} = sprintf('%s--%s_sensor%s_anomalyStats_%s.png', ...
%             date.start, date.end, sensorStr, sensor.label.name{l});
%         saveas(gcf,[dirName.plotSPT dirName.statsPerLabel{l}]);
%         fprintf('\n%s anomaly stats bar-plot file location:\n%s\n', ...
%             sensor.label.name{l}, GetFullPath([dirName.plotSPT dirName.statsPerLabel{l}]))
%         close
%     end
% end
% 
% % reportStatsLabel;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
% % plot sensor-type bar stats
% dirName.plotSum = [dirName.plot 'statsSumUp/'];
% if ~exist(dirName.plotSum, 'dir'), mkdir(dirName.plotSum); end
% for s = sensor.numVec
%    for l = 1 : labelTotal
%        statsSum(s, l) = length(find(sensor.label.neuralNet{s} == categorical(l)));
%    end
% end
% 
% if ~isempty(statsSum(1,1)) && size(statsSum, 1) == 1
%     statsSum(2,1:labelTotal) = 0;
% end
% 
% %%
% figure
% h = bar(statsSum, 'stacked', 'EdgeColor', 'none');
% xlabel('Channel');
% ylabel('Count (hours)');
% legend(sensor.label.name);
% lh=findall(gcf,'tag','legend');
% set(lh,'location','northeastoutside');
% % title(sprintf('%s -- %s', date.start, date.end));
% grid on
% for n = 1 : labelTotal
%     set(h(n),'FaceColor', color{n});
% end
% set(gca, 'fontsize', 14, 'fontname', 'Helvetica'); % 'fontweight', 'bold'
% set(gcf,'Units','pixels','Position',[100, 100, 1000, 500]);  % control figure's position
% xlim([0 39]);
% ylim([0 9000]);
% set(gca,'xtick',[1,5:5:35, 38]);
% 
% % minimize white space
% ax = gca;
% outerpos = ax.OuterPosition;
% ti = ax.TightInset; 
% left = outerpos(1) + ti(1);
% bottom = outerpos(2) + ti(2);
% ax_width = outerpos(3) - ti(1) - ti(3) - 0.01;
% ax_height = outerpos(4) - ti(2) - ti(4);
% ax.Position = [left bottom ax_width ax_height];
% 
% %%
% dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats.emf', ...
%     date.start, date.end, sensorStr);
% saveas(gcf,[dirName.plotSum dirName.statsSum]);
% dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats.tif', ...
%     date.start, date.end, sensorStr);
% saveas(gcf,[dirName.plotSum dirName.statsSum]);
% dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats.fig', ...
%     date.start, date.end, sensorStr);
% saveas(gcf,[dirName.plotSum dirName.statsSum]);
% 
% fprintf('\nSum-up anomaly stats image file location:\n%s\n', ...
%     GetFullPath([dirName.plotSum dirName.statsSum]))
% % close
% 
% %%
% 
% % reportStatsTotal;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
% % sum results to check ratios of each anomaly
% sensor.ratioOfCategory = zeros(3,labelTotal+1);
% for s = sensor.numVec
%     for m = 1 : labelTotal
%         sensor.ratioOfCategory(1,m) = sensor.ratioOfCategory(1,m) + length(cell2mat(sensor.count(m,s)));
%     end
% end
% sensor.ratioOfCategory(1,end) = sum(sensor.ratioOfCategory(1,:));
% sensor.ratioOfCategory(2,:) = (sensor.ratioOfCategory(1,:)./(sensor.ratioOfCategory(1,end)-sensor.ratioOfCategory(1,1))).*100;
% sensor.ratioOfCategory(3,:) = (sensor.ratioOfCategory(1,:)./sensor.ratioOfCategory(1,end)).*100;
% 
% % % crop legend to panorama's folder
% % img = imread([dirName.plotSum dirName.statsSum]);
% % if ispc
% % %     imgLegend = imcrop(img, [646.5 42.5 172 300]);
% %     imgLegend = imcrop(img, [596.5 36.5 272 232]);
% % elseif ismac
% % %     imgLegend = imcrop(img, [660.5 42.5 160 229]);
% %     imgLegend = imcrop(img, [882.5 57.5 204 280]);
% % end
% % figure, imshow(imgLegend)
% % saveas(gcf, [dirName.plotPano 'legend.png']); close
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp
% sensorLabelNetSerial = [];
% for mTemp = 1 : 38
%     sensorLabelNetSerial = cat(1, sensorLabelNetSerial, sensor.label.neuralNet{mTemp});
% end
% % savePath = [GetFullPath(dirName.home) '/' 'sensorLabelNetSerial.mat'];
% % save(savePath, 'sensorLabelNetSerial', '-v7.3')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp
% 
% %% comparison between detection results and actual labels of 2012
% labelNet = [];
% for n = 1 : length(sensorLabelNetSerial)
%     labelNet(n) = str2double(str2mat(sensorLabelNetSerial(n)));
% end
% labelNet = ind2vec(labelNet);
% 
% for n = 1 : labelTotal
%     if ~ismember(categorical(n), sensorLabelNetSerial)
%        labelNet(n, :) = 0;
%     end
% end
% 
% fprintf('\nLoading actual labels of 2012...\n')
% sensorTemp = load(labelPath);
% 
% labelMan = [];
% for mTemp = 1 : 38
%     labelMan = cat(1, labelMan, sensorTemp.label2012.sensor.label.manual{mTemp}');
% end
% labelMan = ind2vec(labelMan');
% 
% fprintf('\nPlotting confusion matrix...\n')
% [confTestC, confTestCM, confTestInd, confTestPer] = confusion(labelMan, labelNet); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% confTestAccuracy = 1 - confTestC;
% confTestPrecision = confTestPer(:, 3);        
% for m = 1 : 7
%    confTestRecall(m, 1) = confTestCM(m, m) / sum(confTestCM(m, :)); 
% end
% 
% figure
% plotconfusion(labelNet, labelMan)
% xlabel('Predicted');
% ylabel('Actual');
% title([]);
% set(gca,'fontname', 'Times New Roman', 'fontweight', 'bold', 'fontsize', 12);
% % minimize white space
% ax = gca;
% outerpos = ax.OuterPosition;
% ti = ax.TightInset; 
% left = outerpos(1) + ti(1);
% bottom = outerpos(2) + ti(2) + 0.03;
% ax_width = outerpos(3) - ti(1) - ti(3);
% ax_height = outerpos(4) - ti(2) - ti(4) - 0.03;
% ax.Position = [left bottom ax_width ax_height];
% dirName.plotConfusionMatrix2012 = [dirName.plot '/confusionMatrix2012/'];
% if ~exist(dirName.plotConfusionMatrix2012, 'dir'), mkdir(dirName.plotConfusionMatrix2012); end
% saveas(gcf, [dirName.plotConfusionMatrix2012 sprintf('comfusionMatrix_2012_') datestr(now,'yyyy-mm-dd_HH-MM-SS') sprintf('.png')]);
% saveas(gcf, [dirName.plotConfusionMatrix2012 sprintf('comfusionMatrix_2012_') datestr(now,'yyyy-mm-dd_HH-MM-SS') sprintf('.fig')]);
% close

%%
elapsedTime(5) = toc(t(5)); [hours, mins, secs] = sec2hms(elapsedTime(5));
fprintf('\n\n\nSTEP5:\nAnomaly statistics completes, using %02dh%02dm%05.2fs .\n', ...
    hours, mins, secs)

% update work flow status
status(2,5) = {1};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

% ask go on or stop
head = 'Continue to step6, automatically remove outliers?';
tail = 'Continue to automatically remove outliers...';
savePath = [dirName.home dirName.file];
fprintf('\nSaving results...\nLocation: %s\n', savePath)
if exist(savePath, 'file'), delete(savePath); end
save(savePath, '-v7.3', '-regexp', '^(?!(img2012)$).')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = 'y(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 5, fprintf('\nFinish.\n'), return
elseif ismember(6, step), fprintf('\n%s\n\n\n', tail)
end
clear head tail savePath

end

%% 6 clean outliers
if ismember(6, step) || isempty(step)
% update new parameters
if step == 6
    for s = sensor.num
        newP{1,s} = sensor.trainRatio(s);
    end
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    load([dirName.home dirName.file]);
    for s = sensor.num
        sensor.trainRatio(s) = newP{1,s};
    end
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    clear newP
end
t(6) = tic;
dirName.outlierCleaned = [dirName.home 'outlierCleaned/'];
if ~exist(dirName.outlierCleaned,'dir'), mkdir(dirName.outlierCleaned); end

figure
n = 1;
out.dotCount = 0;
out.pieceCount = 0;
while n <= util.hours       
    if sensor.label.neuralNet{s}(n) == 3  % 3-outlier
        ticRemain = tic;
        % hour location
        out.dotCount = out.dotCount + 1;
        [out.date, out.hour] = colLocation(n, date.start);
        fprintf('\n\n\nSensor-%02d:\nCount maximum as outlier.\n\n', s)
        fprintf('Data:\nDate:  %s  %02d:00-%02d:00  hour%d (from %s 00:00)\n\n', ...
            out.date, out.hour, out.hour+1, n, date.start)

        % outlier location
        [out.value, out.index] = max(abs(sensor.data{s}(:,n)));
        fprintf('Outlier:\nPosition: %d-%d\nValue: %d\nCount: %d (packet size: %d)\n\n', ...
            out.index, out.index+sensor.pSize-1, out.value, out.dotCount*sensor.pSize, sensor.pSize)

        % remove outlier
        sensor.data{s}(out.index:out.index+sensor.pSize-1, n) = 0;  % update sensor.data
        fprintf('Outliers are replaced by 0.\n')
        fprintf('Continue deleting outliers...\n\n')

        plot(sensor.data{s}(:,n),'color','k');
        position = get(gcf,'Position');
        set(gcf,'Units','pixels','Position',[position(1) position(2) 100 100]);  % control figure's position
        set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
        set(gca,'visible','off');
        xlim([0 size(sensor.data{s},1)]);

        % save fixed data plot
        saveas(gcf,[dirName.outlierCleaned 'outlierCleaned_' num2str(n) '.png']);
        temp.image = imread([dirName.outlierCleaned 'outlierCleaned_' num2str(n) '.png']);
        temp.image = rgb2gray(temp.image);
        temp.image = im2double(temp.image(:));
        sensor.image{s}(:,n) = temp.image;  % update sensor.image
        temp.classify = vec2ind(sensor.neuralNet{s}(sensor.image{s}(:,n)));
        sensor.label.neuralNet{s}(n) = temp.classify;  % update sensor.label.neuralNet
%         nPrevious = n;
        if temp.classify == 1
            out.pieceCount = out.pieceCount + 1;
            sensor.label.neuralNet{s}(n) = temp.classify;
            fprintf('\n\nOutliers cleaned!\n%d outliers are in the data piece.\n%d data pieces remain to clean.\n', ...
                out.dotCount*sensor.pSize, length(sensor.count{3,s})-out.pieceCount)
            tocRemain = toc(ticRemain);
            tRemain = tocRemain * out.dotCount * (length(sensor.count{3,s})-out.pieceCount);
            [hours, mins, secs] = sec2hms(tRemain);
            fprintf('%02dh%02dm%05.2fs estimated time left.\n', hours, mins, secs)
            pause(2.5)
            out.dotCount = 0;
            n = n + 1;
%         elseif temp.classify == 2
%             fprintf('Continue deleting outlier...\n\n')
        end
    else
        n = n + 1;
    end

    if n == util.hours+1
        elapsedTime(6) = toc(t(6));
        [hours, mins, secs] = sec2hms(elapsedTime(6));
        fprintf('\n\n\n\n\n\nSTEP6:\nSensor-%02d outlier cleaning done, using %02d:%02d:%05.2f .\n', ...
            s, hours, mins, secs)
        fprintf('%d data pieces cleaned.\n', length(sensor.count{3,s}))
    end
end
close

% update sensor.status
sensor.status{s}(2,6) = {1};
fprintf('\nSaving results...\nLocation: %s\n', dirName.home)
if exist([dirName.home dirName.file], 'file'), delete([dirName.home dirName.file]); end
save([dirName.home dirName.file])
elapsedTime(6) = toc(t(6)); [hours, mins, secs] = sec2hms(elapsedTime(1));
fprintf('\nTime consumption: %02dh%02dm%05.2fs .\n', hours, mins, secs)
fprintf('\nFinish!\n')
close
end

end
