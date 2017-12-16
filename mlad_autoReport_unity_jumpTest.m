function sensor = mlad_autoReport_unity_jumpTest(readRoot, saveRoot, sensorNum, ...
    dateStart, dateEnd, k, sensorClustRatio, sensorPSize, fs, step, labelName, ...
    seed, maxEpoch, batchSize, sizeFilter, numFilter, cpuOrGpu)
% DESCRIPTION:
%   This is a machine learning based anomaly detection (MLAD) pre-processing
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
%   k - number of clusters to make
%   sensorClustRatio (double) - (clusters' size)/(the whole data set size)
%   sensorPSize (double) - data points in a packet in wireless transmission
%                          (if a packet loses in transmission, all points
%                           within become outliers)
%   step (double) - choose steps, including: '1-Glance' '2-Label' '3-Train'
%                                            '4-Detect' '5-Inspect
%   labelName - user specified label names
%   seed - seed of random number generator for reproducible analysis
%   maxEpoch - epoch of training convolutional neural network (CNN)
%   batchSize - samples batch size for each iteration in training CNN
%   sizeFilter - size of the filter of the first layer in CNN (side length of a square)
%   numFilter - number of the filter of the first layer in CNN
%   cpuOrGpu - use cpu or gpu when training CNN, input format: 'cpu' or 'gpu'
% 
% DEFAULT VALUES:
%   sensorClustRatio = 10/100
%   sensorPSize = 10
%   step = [1 2 3 4 5] (then program will ask go on or stop)
%   labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
%   seed = 1;
%   maxEpoch = 150;
%   batchSize = 100;
%   sizeFilter = 40;
%   numFilter = 20;
%   cpuOrGpu = 'cpu';
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
%   mlad.m uses multiple subfunctions, insure they are there in the working directory.

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
if ~exist('sensorClustRatio', 'var') || isempty(sensorClustRatio), sensorClustRatio = 10/100; end
if ~exist('sensorPSize', 'var') || isempty(sensorPSize), sensorPSize = 10; end
if ~exist('step', 'var'), step = [1 2 3 4 5]; end
if ~exist('labelName', 'var') || isempty(labelName)
%     labelName = {'1-normal','2-outlier','3-minor','4-missing','5-trend','6-drift','7-bias','8-cutoff','9-square'};
    labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
end
if ~exist('seed', 'var'), seed = 1; end
if ~exist('maxEpoch', 'var'), maxEpoch = 150; end
if ~exist('batchSize', 'var'), batchSize = 100; end
if ~exist('sizeFilter', 'var'), sizeFilter = 40; end
if ~exist('numFilter', 'var'), numFilter = 20; end
if ~exist('cpuOrGpu', 'var'), cpuOrGpu = 'cpu'; end

%% common variables
labelTotal = length(labelName);
if ~iscell(sensorNum), sensorNum = {sensorNum}; end
groupTotal = length(sensorNum(:));
sensor.numVec = [];
for g = 1 : groupTotal, sensor.numVec = [sensor.numVec sensorNum{g}(:)']; end
sensorTotal = length(sensor.numVec);
color= {[129 199 132]/255;    % 1-normal            green
        [244 67 54]/255;      % 2-missing           red
        [121 85 72]/255;      % 3-minor             brown
        [255 235 59]/255;     % 4-outlier           yellow
        [50 50 50]/255;       % 5-square            black  
        [33 150 243]/255;     % 6-trend             blue
        [171 71 188]/255;     % 7-drift             purple

        [168 168 168]/255;    % for custom          gray
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
    sensor.trainRatio(sensor.numVec(s)) = sensorClustRatio;
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

dirName.home = sprintf('%s/%s--%s_sensor%s%s_trainRatio_%dpct_seed_%d/', saveRoot, date.start, date.end, sensorStr, netLayout, sensorClustRatio*100, seed);
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
                    prompt = '\ny(yes)/n(no): ';
                    go = input(prompt,'s');
                    if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
                        rightInput = 1;
                        fprintf('\nContinue...\n')
                    elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
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
            glanceInTimeFreqMulti_test(readRoot, sensor.num{g}, date.serial.start, date.serial.end, dirName.all, '0-all_', fs);
    %     util.hours = size(sensor.date.vec{s}, 1);

        elapsedTime(1) = toc(t(1)); [hours, mins, secs] = sec2hms(elapsedTime(1));
        fprintf('\nSTEP1:\nData plot completes, using %02d:%02d:%05.2f .\n', ...
            hours, mins, secs)
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
        prompt = '\ny(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
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
dirName.mat = [dirName.home 'trainingSetMat/'];
if exist(dirName.mat,'dir')
    check = ls(dirName.mat);
    if ispc, check(1:4) = []; end
    if ~isempty(check)
        fprintf('\n\nCAUTION:\n[%s]\nTraining set folder is not empty, continue?\n', dirName.mat)
        rightInput = 0;
        while rightInput == 0
            prompt = '\ny(yes)/n(no): ';
            go = input(prompt,'s');
            if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
                rightInput = 1;
                fprintf('\nContinue...\n')
            elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
                rightInput = 1;
                fprintf('\nFinish.\n')
                return
            else
                fprintf('Invalid input! Please re-input.\n')
            end
        end
    end
elseif ~exist(dirName.mat,'dir'), mkdir(dirName.mat);
end

dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
hourTotal = (date.serial.end-date.serial.start+1)*24;

goNext = 0;
while goNext == 0
    
    t(2) = tic;
    % convert all data to image and save in mat file
    dirName.imageSet = [dirName.home 'data2imageSet/'];
    if ~exist(dirName.imageSet, 'dir'), mkdir(dirName.imageSet); end
    
    dirName.imageSetFile = [dirName.imageSet sprintf('data2imageSet.mat')];
    
    if exist(dirName.imageSetFile, 'file')
        fprintf('\nLoading image set...\n')
        ticLoad = tic;
        load(dirName.imageSetFile);  %                                   !!! modify here
        tocLoad = toc(ticLoad); [hours, mins, secs] = sec2hms(tocLoad);
        fprintf('\nDone. Elapsed time for clustering: %02dh%02dm%05.2fs.\n', hours, mins, secs)
    else
        [sensor.image, dateVec, dateSerial] = data2img(readRoot, dirName.imageSet, ...
            sensor.numVec, date.serial.start, date.serial.end, fs);
        for s = sensor.numVec
           sensor.date.vec{s} = dateVec;
           sensor.date.serial{s} = dateSerial;																				 
        end
        fprintf('\nSaving image set (mat file)...\nLocation: %s\n', dirName.imageSet)
        save(dirName.imageSetFile, 'sensor', '-v7.3')
    end
    
    %% clustering
    % check before clustering
    dirName.clustMain = [dirName.home sprintf('clusterOverview/clusteringIn%d/', k)];
    if exist(dirName.clustMain,'dir')
        fprintf('\n\nCAUTION:\n[%s]\nClusters'' folder is not empty, reclustering?\n', dirName.clustMain)
        rightInput = 0;
        while rightInput == 0
            str = input('\ny(yes)/n(no): ', 's');
            if strcmp(str,'y') || strcmp(str,'yes') || strcmp(str,'Y')
                rightInput = 1;
                rmdir(dirName.clustMain,'s');
                mkdir(dirName.clustMain)                
            elseif strcmp(str,'n') || strcmp(str,'no') || strcmp(str,'N')
                rightInput = 1;
                fprintf('\nFinish.\n')
                return
            else
                fprintf('Invalid input! Please re-input.\n')
            end
        end
    else
        mkdir(dirName.clustMain) 
    end
    
    % random sampling from sensor.image
    downSampRatio = 4; % for width and height respectively of image
    [clust.data, clust.absIdx] = genDataForClust(sensor.numVec, sensorClustRatio, ...
                                                 sensor.image, downSampRatio);    
    % clustering
    fprintf('\nClustering...\n')
    ticClust = tic;
    
    if strcmp(cpuOrGpu, 'gpu') || strcmp(cpuOrGpu, 'GPU') || strcmp(cpuOrGpu, 'Gpu')
        clustDataInGPU = gpuArray(clust.data');
        clust.clustIdx = gather(kmeans(clustDataInGPU, k,'MaxIter', 1000, 'Display', 'iter'));
    else    
        clust.clustIdx = gather(kmeans(clust.data', k,'MaxIter', 1000, 'Display', 'iter'));
    end
    
    clust.label = zeros(size(labelName, 2), size(clust.data, 2));  % label initialization
    tocClust = toc(ticClust);
    [hours, mins, secs] = sec2hms(tocClust);
    fprintf('\nDone. Elapsed time for clustering: %02dh%02dm%05.2fs.\n', hours, mins, secs)
    fprintf('\nCluster overview:\n')
    
    % plot clustering results
    NP = 100; % sample number per plot
    numPlotPerClust = 5; % number of big plots for each cluster
    for kk = 1 : k
        count = 0;
        countPlot = 0;
        idxTemp = find(clust.clustIdx == kk);
        randTemp{kk} = randperm(length(idxTemp));
%         idxTemp = idxTemp(randTemp{kk});
        nIdxTemp = length(idxTemp);
        
        dirName.clustSub = sprintf('cluster-%02d/', kk);
        if ~exist([dirName.clustMain dirName.clustSub], 'dir')
            mkdir([dirName.clustMain dirName.clustSub]);
																									
																				 
        end
        
%         for pBig = 1 : ceil(nIdxTemp/NP) % overview plot
%             ticPlot = tic;
%             figure('position', [40, 40, 2000, 960])
%             fprintf('\nPloting... Cluster %d, sample %d-%d (total %d)\n', ...
%                 kk, 100*(pBig-1)+1, min([nIdxTemp, 100*pBig]), nIdxTemp)
%             for pSmall = 1 : NP
%                 count = count + 1;
%                 if pSmall == 1
%                    set(gcf,'Name', sprintf('cluster %d, sample %d-%d (total %d)', ...
%                        kk, 100*(pBig-1)+1, min([nIdxTemp, 100*pBig]), nIdxTemp));
%                 end
%                 % plot each sample in overview
%                 if count <= nIdxTemp
%                    s = size(clust.data(:, idxTemp(count)), 1);
%                    subaxis(10,20, 2*pSmall-1, 'S',0.005, 'M',0.005);
%                    imshow(reshape(clust.data(1:s/2, idxTemp(count)), [sqrt(s/2) sqrt(s/2)]));
%                    subaxis(10,20, 2*pSmall, 'S',0.005, 'M',0.005);
%                    imshow(reshape(clust.data(s/2+1:end, idxTemp(count)), [sqrt(s/2) sqrt(s/2)]));
%                 else
%                    subaxis(10,20, 2*pSmall-1, 'S',0.005, 'M',0.005);
%                    imshow([]);
%                    subaxis(10,20, 2*pSmall, 'S',0.005, 'M',0.005);
%                    imshow([]);
%                 end
%             end
%             tocPlot = toc(ticPlot);
%             tPlotRemain = tocPlot * ((k-kk)*numPlotPerClust + numPlotPerClust - countPlot - 1);
%             [hours, mins, secs] = sec2hms(tPlotRemain);
%             fprintf('About %02dh%02dm%05.2fs left for clusters overview.\n', hours, mins, secs)
%             
%             fprintf('\nSaving plot...\n')
%             saveas(gcf, [dirName.clustMain dirName.clustSub sprintf('cluster_%d_sample_%04d-%04d_total-%04d.tif', ...
%                 kk, 100*(pBig-1)+1, min([nIdxTemp, 100*pBig]), nIdxTemp)]);
%             close
%             
%             rightInput = 0;
%             while rightInput == 0
%                 
%                 countPlot = countPlot + 1;
%                 if countPlot < numPlotPerClust
%                     rightInput = 1;
%                 elseif countPlot == numPlotPerClust
%                     rightInput = 2;
%                 else
%                     fprintf('Invalid input! Please re-input.\n')
%                 end
%                 
%                 % human control
%                 str = input('N/n: next big plot\nJ/j: jump to next cluster\nInput: ', 's');
%                 if strcmp(str,'n') || strcmp(str,'N')
%                     rightInput = 1;
%                 elseif strcmp(str,'j') || strcmp(str,'J')
%                     rightInput = 2;
%                 else
%                     fprintf('Invalid input! Please re-input.\n')
%                 end
%                 
%             end
% 
%             if rightInput == 2
%                 break % to next cluster
%             end
%             
%         end
    end
    
    % labeling
    for m = 1 : k
        clust.sizeOfClust(m) = length(find(clust.clustIdx == m));
    end
    [clust.sortedSize clust.sortedIdx] = sort(clust.sizeOfClust);
    
    fprintf('\nSize of each cluster (ascending):\n')
    for m = 1 : k
       fprintf('Cluster %d    Size: %5d    Ratio: %3.2f\n', clust.sortedIdx(m), ...
           clust.sortedSize(m), clust.sortedSize(m)/sum(clust.sortedSize)) 
    end
    fprintf('Total: %5d\n', sum(clust.sortedSize))
    
    fprintf('\nInput the size of training set you want to make:\n')
    fprintf('(the selected samples are averagely from each cluster,\n')
    prompt = 'rather than random selection in the whole dataset)\n\nInput here:';
    trainSet.size = str2double(input(prompt, 's'));
    
    %% plot and label
%     n = 1; % modify here !!!
    % tidy data by cluster
    fprintf('\nGenerating training set...\n')
    for m = 1 : k
        fprintf('\nNow: %d Total: %d\n', m, k)
        clustAbsIdxTemp = clust.absIdx(clust.clustIdx == m, :);
        clustAbsIdxTemp = clustAbsIdxTemp(randTemp{m}, :);
        for n = 1 : size(clustAbsIdxTemp, 1)
            trainSet.data{m}(:, n) = sensor.image{clustAbsIdxTemp(n, 2)}(:, clustAbsIdxTemp(n, 1));
%             sensor.image{clustIdxTemp(n, 2)}(:, clustIdxTemp(n, 1)) = ...
%                 int8(sensor.image{clustIdxTemp(n, 2)}(:, clustIdxTemp(n, 1)));  % release memory
        end
        trainSet.label{m} = clust.label(:, clust.clustIdx == m);
%         trainSet.label{m} = trainSet.label{m}(:, randTemp{m});
        trainSet.absIdx{m} = clustAbsIdxTemp;
    end
    sensor = rmfield(sensor, 'image');
    
    sLeft = trainSet.size; % samples to label
    cAvai = [1:k]; % available clusters for labeling
    short = 0; % shortage for training set
    count = 0; % for labeled samples
    checkIn = [];
    trainSet.positionIn = zeros(k, 1);
    trainSet.positionOut = zeros(k, 1);
    trainSet.amountLeft = clust.sizeOfClust;
    ticLabel = tic;
    
    while sLeft > 0
        if ~isempty(cAvai)
            sAver = ceil(sLeft/length(cAvai)); % average size
            for m = cAvai
                [shortTemp, bina] = calcuShort(sAver, trainSet.amountLeft(m));
                % bina: binary switch
                if bina == 1 % no short
                    % label sAver samples in the cluster
                    trainSet.positionIn(m) = trainSet.positionOut(m) + 1;
                    trainSet.positionOut(m) = trainSet.positionIn(m) + sAver - 1;
                elseif bina == 2 % short
                    checkIn = [checkIn, m]; % record clusters that is short for labeling
                    % label all the rest samples in the cluster
                    trainSet.positionIn(m) = trainSet.positionOut(m) + 1;
                    trainSet.positionOut(m) = trainSet.positionIn(m) + trainSet.amountLeft(m) - 1;
                end

                short = short + shortTemp;
                trainSet.amountLeft(m) = trainSet.amountLeft(m) - sAver + shortTemp;

                [trainSet.label, count, shortHalfwayLeft, trainSet.positionOut(m)] = dispAndLabel_jumpTest(trainSet.data, trainSet.label, ...
                        m, clust.sizeOfClust, trainSet.amountLeft, ...
                        trainSet.positionIn(m), trainSet.positionOut(m), count, trainSet.size, labelName, ticLabel);
                
                if shortHalfwayLeft > 0
                   short = short + shortHalfwayLeft;
%                    checkIn = [checkIn, m]; % drop the unwanted cluster
												 
                end
            end
            sLeft = short; short = 0;
            cAvai = setdiff(cAvai, checkIn); checkIn = [];
        else
            fprintf('\nNo more available cluster!')
            fprintf('\nTarget training set size: %d', trainSet.size)
            fprintf('\nActual training set size: %d\n', trainSet.size - sLeft);
            break
        end
    end
    close
    
    %% training set visualization    
    trainSet.labelAll = [];
    trainSet.absIdxAll = [];
    
    % loop to combine clusters
    for m = 1 : size(trainSet.label, 2)
        trainSet.labelAll = [trainSet.labelAll trainSet.label{m}];
        trainSet.absIdxAll = [trainSet.absIdxAll; trainSet.absIdx{m}];
    end
    % adjust indexes of non-label samples for training set pnorama
    trainSet.labelAll = [trainSet.labelAll; zeros(1, size(trainSet.labelAll,2))];
    trainSet.labelAll(end, sum(trainSet.labelAll) == 0) = 1;
    trainSet.labelAll = vec2ind(trainSet.labelAll);
    
    % loop to separate each channel into cells
    for s = sensor.numVec
        idxTemp = [trainSet.absIdxAll(:, 2) == s];
        sensor.label.manualTrainSet{s} = trainSet.labelAll(idxTemp);
        sensor.absIdxTrainSet{s} = trainSet.absIdxAll(idxTemp, :);
    end

    % sort in time order
    for s = sensor.numVec
        [sensor.absIdxTrainSet{s}, idxTemp] = sortrows(sensor.absIdxTrainSet{s}, [1 2]);
        sensor.label.manualTrainSet{s} = sensor.label.manualTrainSet{s}(idxTemp);
    end
    
    % expand training set information to global view for panorama
    for s = sensor.numVec
        % initialization
        sensor.absIdx{s} = 1 : hourTotal;
        sensor.label.manual{s} = max(trainSet.labelAll) * ones(1, hourTotal);
        % embedding labeled sample into global label set
        sensor.label.manual{s}(sensor.absIdxTrainSet{s}(:, 1)) = ...
            sensor.label.manualTrainSet{s};
    end
    
    % training set panorama
    dirName.plotPanoTrainSet = [dirName.mat 'panorama/'];
    if ~exist(dirName.plotPanoTrainSet, 'dir'), mkdir(dirName.plotPanoTrainSet); end
    for s = sensor.numVec
        if mod(s,2) == 1
            yStrTemp = '';
        else
            yStrTemp = sprintf('      %02d', s);
        end
        panorama(sensor.date.serial{s}, sensor.label.manual{s}, yStrTemp, color(1:labelTotal+1));
        dirName.panoramaTrainSet{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_trainingSetLabelPanorama.png'];
        saveas(gcf,[dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]);
        fprintf('\nSensor-%02d training set panorama file location:\n%s\n', ...
            s, GetFullPath([dirName.plotPanoTrainSet dirName.panoramaTrainSet{s}]))
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
    
    %% clean non-labeled samples
    for m = 1 : k
        noLabel = find(sum(trainSet.label{m}) == 0);
        trainSet.data{m}(:, noLabel) = [];
        trainSet.label{m}(:, noLabel) = [];
    end
    
    %% save training set
    dirName.matFile = [dirName.mat sprintf('trainingSet.mat')];
    if exist(dirName.matFile, 'file'), delete(dirName.matFile); end
    fprintf('\nSaving training set...\nLocation: %s\n', dirName.matFile)
    save(dirName.matFile, 'trainSet', '-v7.3')

    elapsedTime(2) = toc(t(2));
    [hours, mins, secs] = sec2hms(elapsedTime(2));
    fprintf('\nTime consumption of training set making: %02dh%02dm%05.2fs\n\n', hours, mins, secs)
        
    fprintf('\nGo on, or re-clustering and re-labeling for any missing types?\n')
    rightInput = 0;
    while rightInput == 0
        prompt = 'g(go)/r(redo): ';
        go = input(prompt,'s');
        if strcmp(go,'r') || strcmp(go,'redo')
            rightInput = 1;
            seed = seed + 1;
        elseif strcmp(go,'g') || strcmp(go,'go')
            rightInput = 1;
            goNext = 1;
        else
            fprintf('Invalid input! Please re-input.\n')
        end
    end    
end

% update work flow status
sensor.status{s} = {'1-Glance' '2-Label' '3-Train' '4-Detect' '5-Inspect' ...
                     ; 0 0 0 0 0};
status(2,2) = {1};
savePath = [dirName.home dirName.status];
if exist(savePath, 'file'), delete(savePath); end
save(savePath, 'status', '-v7.3')

elapsedTime(2) = toc(t(2)); [hours, mins, secs] = sec2hms(elapsedTime(2));
fprintf('\n\nSTEP2:\nSensor(s) training set making completes, using %02d:%02d:%05.2f .\n', ...
    hours, mins, secs)

% ask go on or stop
head = 'Continue to step3, automatically train neural network now?';
tail = 'Continue to automatically train deep neural network(s)...';
savePath = [dirName.home dirName.file];
fprintf('\nSaving results...\nLocation: %s\n', savePath)
if exist(savePath, 'file'), delete(savePath); end
save(savePath, '-v7.3')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = '\ny(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
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

%% 3 train network
if ismember(3, step) || isempty(step)
% update new parameters and load training sets
if ~isempty(step) && step(1) == 3
    for s = sensor.numVec
        newP{1,s} = sensor.trainRatio(s);
    end
    newP{2,1} = sensor.pSize;
    newP{3,1} = step;
    dirName.mat = [dirName.home 'trainingSetMat/'];
    
    dirName.matFile = [dirName.mat sprintf('trainingSet.mat')];
    if ~exist(dirName.matFile, 'file')
        fprintf('\n\nCAUTION:\nNo traning set found!\n')
        fprintf('Need to make trainning set (step2) first.\nFinish.\n')
        return
    else
        fprintf('\nLoading...\n')
        load(dirName.matFile);        
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
    for m = 1 : size(trainSet.data, 2)
							 
        feature{g}.image = [feature{g}.image trainSet.data{m}];
        feature{g}.label.manual = [feature{g}.label.manual trainSet.label{m}];
    end
																		   
    % convert feature into 4D matrices for CNN training
    numTemp = size(feature{g}.image, 2);
    feature{g}.image = reshape(feature{g}.image, [100, 100, 2, numTemp]);
    % for define output layer size
    feature{g}.label.activeLabel = unique(vec2ind(feature{g}.label.manual));
    feature{g}.label.activeLabelNum = length(feature{g}.label.activeLabel);
    
%     vec2idx(feature{g}.label.manual)
    
end

% add channel 3 into image
for n = 1 : numTemp
    feature{g}.image(:, :, 3, n) = ones(100, 100); % need modification here !!!
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
        feature{g}.valiSize = size(feature{g}.image,4) - feature{g}.trainSize;
        % design architecture of CNN
        layers = [imageInputLayer([100 100 3])
                  
                  % design 1
                  convolution2dLayer(sizeFilter, numFilter)
                  reluLayer
                  maxPooling2dLayer(2,'Stride',2)

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
            'OutputFcn',@plotTrainingAccuracy,'ExecutionEnvironment', cpuOrGpu);

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
    
    yTrain = predict(sensor.neuralNet{s}, feature{g}.image(:, :, :, 1:feature{g}.trainSize))';  % output vector
%     yTrain = classify(sensor.neuralNet{s}, feature{g}.image(:, :, :, 1:feature{g}.trainSize))'; % output categorical
    
    % mapping output to original dimension
    yTrainGlobal = [];
    
    % convert from format categorical to double
    yTrainGlobal = vec2ind(yTrain);
%     for n = 1 : length(yTrain)
%         yTrainGlobal(n) = str2double(str2mat(yTrain(n)));
%     end
    
    % mapping
    for m = 1 : feature{g}.label.activeLabelNum
        yTrainGlobal(yTrainGlobal == m) = feature{g}.label.activeLabel(m);
    end
    
%     % convert from format double to categorical back
%     yTrainGlobal = double(ind2vec(yTrainGlobal));
%     yTrainGlobal = categorical(yTrainGlobal);
    
    % convert from format index to vec
    yTrainGlobal = ind2vec(yTrainGlobal);
    
    % check for row lacking
    zeroToAdd = size(feature{g}.label.manual, 1) - size(yTrainGlobal, 1);
    if zeroToAdd > 0
        yTrainGlobal = [yTrainGlobal; zeros(zeroToAdd, feature{g}.trainSize)];
    end
    
    featureLabelTrain = feature{g}.label.manual(:, 1:feature{g}.trainSize);
%     featureLabelManual = vec2ind(feature{g}.label.manual(:, 1:feature{g}.trainSize));
%     featureLabelManual = categorical(featureLabelManual);
    
    % comparison
    [confTrainC, confTrainCM, confTrainInd, confTrainPer] = ...
        confusion(featureLabelTrain, yTrainGlobal);
    confTrainAccuracy = 1 - confTrainC;
    confTrainPrecision = confTrainPer(:, 3);
    for m = 1 : 7
       confTrainRecall(m, 1) = confTrainCM(m, m) / sum(confTrainCM(m, :)); 
    end
    
    figure
    plotconfusion(yTrainGlobal, featureLabelTrain);
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
    
    % mapping output to original dimension
    yValiGlobal = [];
    % convert from format categorical to double
    yValiGlobal = vec2ind(yVali);
    % mapping
    for m = 1 : feature{g}.label.activeLabelNum
        yValiGlobal(yValiGlobal == m) = feature{g}.label.activeLabel(m);
    end
    % convert from format double to vec
    yValiGlobal = ind2vec(yValiGlobal);
    % check for row lacking
    zeroToAdd = size(feature{g}.label.manual, 1) - size(yValiGlobal, 1);
    if zeroToAdd > 0
        yValiGlobal = [yValiGlobal; zeros(zeroToAdd, feature{g}.valiSize)];
    end
    
    featureLabelVali = feature{g}.label.manual(:,feature{g}.trainSize+1 : end);
    [confValiC, confValiCM, confValiInd, confValiPer] = ...
        confusion(featureLabelVali, yValiGlobal);
    confValiAccuracy = 1 - confValiC;
    confValiPrecision = confValiPer(:, 3);        
    for m = 1 : 7
       confValiRecall(m, 1) = confValiCM(m, m) / sum(confValiCM(m, :)); 
    end
    
    figure
    plotconfusion(yValiGlobal, featureLabelVali);
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
save(savePath, '-v7.3')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = '\ny(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
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
    
    readPath = [dirName.home dirName.file];
    fprintf('\nLoading...\n')
    load(readPath)
    
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    sensor.label.name = newP{4,1};
    readRoot = newP{5,1};
    dirName.home = newP{6,1};
    clear newP
end

t(4) = tic;
dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
% hourTotal = (date.serial.end-date.serial.start+1)*24;

% anomaly detection
fprintf('\nDetecting...\n')
[labelTempNeural, countTempNeural, dateVec, dateSerial] = ...
    classifierMultiInTimeFreqWithBreakpointUnity(readRoot, sensor.numVec, date.serial.start, date.serial.end, ...
    dirName.home, sensor.label.name, feature{g}.label.activeLabel, sensor.neuralNet, fs);

for s = sensor.numVec
%     labelTempNeuralGlobal{s} = [];
%     % convert from categorical to double
%     for n = 1 : length(labelTempNeural{s})
%         labelTempNeuralGlobal{s}(n) = str2double(str2mat(labelTempNeural{s}(n)));
%     end
%     % mapping
%     for m = 1 : feature{g}.label.activeLabelNum
%         labelTempNeuralGlobal{s}(labelTempNeuralGlobal{s} == m) = feature{g}.label.activeLabel(m);
%     end
%     % convert from format double to categorical back
%     labelTempNeuralGlobal{s} = categorical(labelTempNeuralGlobal{s});  % check here!
    
    sensor.label.neuralNet{s} = labelTempNeural{s};
    for l = feature{g}.label.activeLabel
        sensor.count{feature{g}.label.activeLabel(l), s} = countTempNeural{l,s};
    end
    sensor.date.vec{s} = dateVec;
    sensor.date.serial{s} = dateSerial;
end
clear labelTempNeural countTempNeural

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
save(savePath, '-v7.3')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = '\ny(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
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
    
    readPath = [dirName.home dirName.file];
    fprintf('Loading...\n')
    load(readPath)
    
    sensor.pSize =  newP{2,1};
    step = newP{3,1};
    sensor.label.name = newP{4,1};
    readRoot = newP{5,1};
    dirName.home = newP{6,1};
    clear newP
end
t(5) = tic;
dirName.formatIn = 'yyyy-mm-dd';
date.serial.start = datenum(date.start, dirName.formatIn);  % day numbers from year 0000
date.serial.end   = datenum(date.end, dirName.formatIn);
hourTotal = (date.serial.end-date.serial.start+1)*24;

dirName.plot = [dirName.home sprintf('/plot_globalEpoch_%d_batchSize_%d_sizeFilter_%d_numFilter_%d/', maxEpoch(1), batchSize, sizeFilter, numFilter)];
if ~exist(dirName.plot, 'dir'), mkdir(dirName.plot); end

% plot sub-panorama
dirName.plotPano = [dirName.plot 'panorama/'];
if ~exist(dirName.plotPano, 'dir'), mkdir(dirName.plotPano); end
for s = sensor.numVec
    if mod(s,2) == 1
        yStrTemp = '';
    else
        yStrTemp = sprintf('      %02d', s);
    end
    panorama(sensor.date.serial{s}, sensor.label.neuralNet{s}, yStrTemp, color(1:labelTotal));
    dirName.panorama{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyDetectionPanorama.png'];
    saveas(gcf,[dirName.plotPano dirName.panorama{s}]);
    fprintf('\nSenor-%02d anomaly detection panorama file location:\n%s\n', ...
        s, GetFullPath([dirName.plotPano dirName.panorama{s}]))
    close
    
    % update sensor.status
    sensor.status{s}(2,5) = {1};
end
% combine panorama
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
                    '_anomalyDetectionPanorama.tif'];
imwrite(panopano, [dirName.plotPano dirName.panopano]);
clear height width p n

% plot monthly stats per sensor
dirName.plotSPS = [dirName.plot 'statsPerSensor/'];
if ~exist(dirName.plotSPS, 'dir'), mkdir(dirName.plotSPS); end
for s = sensor.numVec
    for n = 1 : 12
        for l = 1 : labelTotal
            aim = find(sensor.date.vec{s}(:,2) == n);
            sensor.statsPerSensor{s}(n, l) = length(find(sensor.label.neuralNet{s}(aim) == l));
        end
    end
    monthStatsPerSensorForPaper(sensor.statsPerSensor{s}, s, sensor.label.name, color);
    dirName.statsPerSensor{s} = [sprintf('%s--%s_sensor_%02d', date.start, date.end, s) '_anomalyStats.png'];
    saveas(gcf,[dirName.plotSPS dirName.statsPerSensor{s}]);
    fprintf('\nSenor-%02d anomaly stats bar-plot file location:\n%s\n', ...
        s, GetFullPath([dirName.plotSPS dirName.statsPerSensor{s}]))
    close
end

% plot anomaly space-time distribution per type
dirName.plotSPT = [dirName.plot 'statsPerType/'];
if ~exist(dirName.plotSPT, 'dir'), mkdir(dirName.plotSPT); end
for l = 1 : labelTotal
   for s = sensor.numVec
       for n = 1 : 12
           aim = find(sensor.date.vec{s}(:,2) == n);
           sensor.statsPerLabel{l}(n, s) = length(find(sensor.label.neuralNet{s}(aim) == l));
       end
   end
   if sum(sum(sensor.statsPerLabel{l})) >= 0
        monthStatsPerLabelForPaper(sensor.statsPerLabel{l}, l, sensor.label.name{l}, color);
        dirName.statsPerLabel{l} = sprintf('%s--%s_sensor%s_anomalyStats_%s.png', ...
            date.start, date.end, sensorStr, sensor.label.name{l});
        saveas(gcf,[dirName.plotSPT dirName.statsPerLabel{l}]);
        fprintf('\n%s anomaly stats bar-plot file location:\n%s\n', ...
            sensor.label.name{l}, GetFullPath([dirName.plotSPT dirName.statsPerLabel{l}]))
        close
    end
end

% plot sensor-type bar stats
dirName.plotSum = [dirName.plot 'statsSumUp/'];
if ~exist(dirName.plotSum, 'dir'), mkdir(dirName.plotSum); end
for s = sensor.numVec
   for l = 1 : labelTotal
       statsSum(s, l) = length(find(sensor.label.neuralNet{s} == l));
   end
end

if ~isempty(statsSum(1,1)) && size(statsSum, 1) == 1
    statsSum(2,1:labelTotal) = 0;
end

figure
h = bar(statsSum, 'stacked');
xlabel('Sensor');
ylabel('Count (hours)');
legend(sensor.label.name);
lh=findall(gcf,'tag','legend');
set(lh,'location','northeastoutside');
title(sprintf('%s -- %s', date.start, date.end));
grid on
for n = 1 : labelTotal
    set(h(n),'FaceColor', color{n});
end
set(gca, 'fontsize', 13, 'fontname', 'Times New Roman', 'fontweight', 'bold');
set(gcf,'Units','pixels','Position',[100, 100, 1000, 500]);  % control figure's position
xlim([0 39]);
% digit = ceil(log10(abs(hourTotal)));
% ylim([0 ceil(hourTotal/(10^(digit-1)))*(10^(digit-1))]);
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

dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats.png', ...
    date.start, date.end, sensorStr);

saveas(gcf,[dirName.plotSum dirName.statsSum]);
dirName.statsSum = sprintf('%s--%s_sensor%s_anomalyStats.png', ...
    date.start, date.end, sensorStr);
saveas(gcf,[dirName.plotSum dirName.statsSum]);
fprintf('\nSum-up anomaly stats image file location:\n%s\n', ...
    GetFullPath([dirName.plotSum dirName.statsSum]))
close

% sum results to check ratios of each anomaly
sensor.ratioOfCategory = zeros(3,labelTotal+1);
for s = sensor.numVec
    for m = 1 : labelTotal
        sensor.ratioOfCategory(1,m) = sensor.ratioOfCategory(1,m) + length(cell2mat(sensor.count(m,s)));
    end
end
sensor.ratioOfCategory(1,end) = sum(sensor.ratioOfCategory(1,:));
sensor.ratioOfCategory(2,2:end-1) = (sensor.ratioOfCategory(1,2:end-1)./(sensor.ratioOfCategory(1,end)-sensor.ratioOfCategory(1,1))).*100;
sensor.ratioOfCategory(3,:) = (sensor.ratioOfCategory(1,:)./sensor.ratioOfCategory(1,end)).*100;

% report generation
fprintf('\nGenerating report...\n')
reportCover;
reportNet;
reportTrainSetPano;
reportPano;
reportStatsTotal;
reportStatsSensor;
reportStatsLabel;

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

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp
% sensorLabelNetSerial = [];
% for mTemp = 1 : 38
%     sensorLabelNetSerial = cat(1, sensorLabelNetSerial, sensor.label.neuralNet{mTemp});
% end
% % savePath = [GetFullPath(dirName.home) '/' 'sensorLabelNetSerial.mat'];
% % save(savePath, 'sensorLabelNetSerial', '-v7.3')
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
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% temp

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
save(savePath, '-v7.3')
if isempty(step)
    rightInput = 0;
    while rightInput == 0
        fprintf('\n%s\n', head)
        prompt = '\ny(yes)/n(no): ';
        go = input(prompt,'s');
        if strcmp(go,'y') || strcmp(go,'yes') || strcmp(go,'Y')
            rightInput = 1; fprintf('\n%s\n\n\n', tail)
        elseif strcmp(go,'n') || strcmp(go,'no') || strcmp(go,'N')
            rightInput = 1; fprintf('\nFinish.\n'), return
        else fprintf('Invalid input! Please re-input.\n')
        end
    end
elseif step == 5, fprintf('\nFinish.\n'), return
elseif ismember(6, step), fprintf('\n%s\n\n\n', tail)
end
clear head tail savePath

end

end
