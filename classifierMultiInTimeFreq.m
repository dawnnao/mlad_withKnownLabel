function [label, labelCount, dateVec, dateSerial] = classifierMultiInTimeFreq(pathRead, sensorNum, dayStart, dayEnd, pathSave, labelName, neuralNet, fs)
% DESCRIPTION:
%   This is a subfunction of mvad.m, to do step 4 - anomaly detection.

% AUTHOR:
%   Zhiyi Tang
%   tangzhi1@hit.edu.cn
%   Center of Structural Monitoring and Control
% 
% DATE CREATED:
%   12/19/2016

path.root = pathRead;
hourTotal = (dayEnd-dayStart+1)*24;
for s = sensorNum
    for l = 1 : length(labelName)
        pathSaveType{s,l} = [pathSave sprintf('sensor%02d/', s) labelName{l} '/'];
        pathSaveNet{s,l} = [pathSaveType{s,l} 'neuralNet/'];
        if ~exist(pathSaveNet{s,l},'dir'), mkdir(pathSaveNet{s,l}); end
        if strcmp(class(neuralNet{s}), 'SeriesNetwork') % CNN
            label{s} = categorical(zeros(hourTotal,1));
        elseif strcmp(class(neuralNet{s}), 'network') % ANN 
            label{s} = zeros(hourTotal,1);
        end
    end
end

count = 1;
figure
set(gcf,'Units','pixels','Position',[1180, 70, 100, 100]);
for day = dayStart : dayEnd
    string = datestr(day);
    for hour = 0:23
        dateVec(count,:) = datevec(string,'dd-mmm-yyyy');
        dateVec(count,4) = hour;
        dateSerial(count,1) = datenum(dateVec(count,:));
        path.folder = sprintf('%04d-%02d-%02d',dateVec(count,1), dateVec(count,2), dateVec(count,3));
        path.file = [path.folder sprintf(' %02d-VIB.mat',hour)];
        path.full = [path.root '/' path.folder '/' path.file];
        if ~exist(path.full, 'file')
            fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
            sensorData(1, sensorNum) = zeros;  % always save in column 1
        else
            read = ['load(''' path.full ''');']; eval(read);
            sensorData(:, sensorNum) = data(:, sensorNum);  % always save in column 1
        end
        data = [];
%         set(gcf, 'visible', 'off');
        
        for s = sensorNum
            ticRemain = tic;
            % time series signals plot
            plot(sensorData(:, s),'color','k');
            position = get(gcf,'Position');
            set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
            set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
            set(gca,'visible','off');
            xlim([0 size(sensorData(:,s),1)]);
            set(gcf,'color','white');
            
            imgTime = getframe(gcf);
            imgTime = imresize(imgTime.cdata, [100 100]);  % expected dimension
            imgTime = rgb2gray(imgTime);
            imgTime = im2double(imgTime);
            
            % frequency domain plot
            N = size(sensorData, 1);
            f = (0 : N/2-1)*(fs/N);
            sensorData(isnan(sensorData(:, s)), s) = 0;
            freqData = fft(sensorData(:, s)-median(sensorData(:, s)));
            
            plot(f, abs(real(freqData(1:N/2))),'color','k');
            set(gca, 'visible', 'off');
            set(gcf,'color','white');
            set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
            set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
            imgFreq = getframe(gcf);
            imgFreq = imresize(imgFreq.cdata, [100 100]);  % expected dimension
            imgFreq = rgb2gray(imgFreq);
            imgFreq = im2double(imgFreq);
            
            if strcmp(class(neuralNet{s}), 'SeriesNetwork') % CNN
                img(:, :, 1) = imgTime;
                img(:, :, 2) = imgFreq;
                img(:, :, 3) = ones(100, 100);
                imshow(img)
%                 set(gcf, 'visible', 'on');
                label{s}(count) = classify(neuralNet{s}, img);
                labelIdx = str2double(str2mat(label{s}(count)));
            elseif strcmp(class(neuralNet{s}), 'network') % ANN
                img = [imgTime(:); imgFreq(:)];
%                 imshow(img)
%                 set(gcf, 'visible', 'on');
                label{s}(count) = vec2ind(neuralNet{s}(img));
                labelIdx = label{s}(count);
            end
            
            pathSaveAll = [pathSaveNet{s,labelIdx} labelName{labelIdx} '_' num2str(count) '_time.png'];
            imwrite(imgTime, pathSaveAll);
            pathSaveAll = [pathSaveNet{s,labelIdx} labelName{labelIdx} '_' num2str(count) '_freq.png'];
            imwrite(imgFreq, pathSaveAll);
            
            tocRemain = toc(ticRemain);
            tRemain = tocRemain * (hourTotal - count) * length(sensorNum);
            [hours, mins, secs] = sec2hms(tRemain);
            fprintf('\nSensor-%02d  %d-%02d-%02d  %02d:00-%02d:00  %s', ...
                s, dateVec(count,1), dateVec(count,2), dateVec(count,3), ...
                hour, hour+1, labelName{labelIdx})
            fprintf('\nTotal: %d  Now: %d  ', hourTotal, count)
            fprintf('About %02dh%02dm%05.2fs left.\n', hours, mins, secs)
        end
        count = count+1;
        sensorData = [];
    end
end
count = count-1;

for s = sensorNum
    for l = 1 : length(labelName)
        if strcmp(class(neuralNet{s}), 'SeriesNetwork') % CNN
            labelCount{l,s} = find(label{s} == categorical(l)); % pass to sensor.count{l,s}
        elseif strcmp(class(neuralNet{s}), 'network') % ANN
            labelCount{l,s} = find(label{s} == l);
        end
        check = ls(pathSaveNet{s,l});
        if ispc, check(1:4) = []; end
        if isempty(check), rmdir(pathSaveType{s,l}, 's'); end % delete useless folder(s)
    end
end

% for l = 1:length(labelName)
%     check = ls(pathSaveNet{l});
%     if ispc, check(1:4) = []; end
%     if isempty(check), rmdir(pathSaveType{l}, 's'); end
% end

close
clear data

end
