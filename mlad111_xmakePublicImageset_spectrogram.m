function sensor = mlad111_xmakePublicImageset_spectrogram(readRoot, saveRoot, sensorNum, dateStart, dateEnd, k, sensorClustRatio, sensorPSize, fs, step, labelName)
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
%   sensorClustRatio (double) - (training set size)/(the whole data set size)
%   sensorPSize (double) - data points in a packet in wireless transmission
%                          (if a packet loses in transmission, all points
%                           within become outliers)
%   step (double) - choose steps, including: '1-Glance' '2-Label' '3-Train'
%                                            '4-Detect' '5-Inspect
% 
% DEFAULT VALUES:
%   sensorClustRatio = 5/100
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
if ~exist('sensorClustRatio', 'var') || isempty(sensorClustRatio), sensorClustRatio = 5/100; end
if ~exist('sensorPSize', 'var') || isempty(sensorPSize), sensorPSize = 10; end
if ~exist('step', 'var'), step = []; end
if ~exist('labelName', 'var') || isempty(labelName)
%     labelName = {'1-normal','2-outlier','3-minor','4-missing','5-trend','6-drift','7-bias','8-cutoff','9-square'};
    labelName = {'1-normal','2-missing','3-minor','4-outlier','5-square','6-trend','7-drift'};
end

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

        [255 112 67]/255;     % for custom          orange        
        [168 168 168]/255;    % for custom          gray
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

dirName.home = sprintf('%s%s--%s_sensor%s%s/', saveRoot, date.start, date.end, sensorStr, netLayout);
dirName.home = GetFullPath(dirName.home);
dirName.file = sprintf('%s--%s_sensor%s%s.mat', date.start, date.end, sensorStr, netLayout);
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

%         [~, sensor.date.vec, sensor.date.serial] = ...
        [~, sensor.date.vec{s}, sensor.date.serial{s}] = ...
            glanceInTimeFreqMulti_spectrogram(readRoot, sensor.num{g}, date.serial.start, date.serial.end, dirName.all, '0-all_', fs);
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



end
