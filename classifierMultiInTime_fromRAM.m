function [label, labelCount, dateVec, dateSerial] = classifierMultiInTime_fromRAM(pathRead, ...
    sensorNum, dayStart, dayEnd, pathSave, labelName, neuralNet, img2012)
% DESCRIPTION:
%   This is a subfunction of mvad.m, to do step 4 anomaly detection.

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
        pathSaveType{s,l} = [pathSave sprintf('/sensor%02d/', s) labelName{l}];
        pathSaveNet{s,l} = [pathSaveType{s,l} '/neuralNet'];
        if ~exist(pathSaveNet{s,l},'dir'), mkdir(pathSaveNet{s,l}); end
        if strcmp(class(neuralNet{s}), 'SeriesNetwork') % CNN
            label{s} = categorical(zeros(hourTotal,1));
        elseif strcmp(class(neuralNet{s}), 'Neural Network') % ANN 
            label{s} = zeros(hourTotal,1);
        end
    end
end

count = 1;
figure
% set(gcf,'Units','pixels','Position',[1180, 70, 100, 100]);
for day = dayStart : dayEnd
    string = datestr(day);
    for hour = 0:23
        dateVec(count,:) = datevec(string,'dd-mmm-yyyy');
        dateVec(count,4) = hour;
        dateSerial(count,1) = datenum(dateVec(count,:));
        
        for s = sensorNum
            sensorData(:, s) = img2012.sensor.image{s}(1:10000, count);
        end
        
        for s = sensorNum
            ticRemain = tic;
            img = reshape(sensorData(:, s), [100 100]);

    %         imshow(img)            
            if strcmp(class(neuralNet{s}), 'SeriesNetwork') % CNN
%                 imshow(img)
                set(gcf, 'visible', 'on');
                label{s}(count) = classify(neuralNet{s}, img);
                labelIdx = str2double(char(label{s}(count)));
            elseif strcmp(class(neuralNet{s}), 'network') % ANN
%                 imshow(img)
                set(gcf, 'visible', 'on');
                label{s}(count) = vec2ind(neuralNet{s}(img(:)));
                labelIdx = label{s}(count);
            end

            pathSaveAll = [pathSaveNet{s,labelIdx} '/' labelName{labelIdx} '_' num2str(count) '.png'];
%             imwrite(img, pathSaveAll);
            
            tocRemain = toc(ticRemain);
            tRemain = tocRemain * (hourTotal - count) * length(sensorNum);
            [hours, mins, secs] = sec2hms(tRemain);
            if mod(count, 24) == 0
                fprintf('\nSensor-%02d  %d-%02d-%02d  %02d:00-%02d:00  %s', ...
                    s, dateVec(count,1), dateVec(count,2), dateVec(count,3), ...
                    hour, hour+1, labelName{labelIdx})
                fprintf('\nTotal: %d  Now: %d  ', hourTotal, count)
                fprintf('About %02dh%02dm%05.2fs left.\n', hours, mins, secs)
            end
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
