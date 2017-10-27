function [sensorImage, dateVec, dateSerial] = data2img(pathRead, imageSetSaveRoot, sensorNum, dayStart, dayEnd, fs)
% DESCRIPTION:
%   This is a subfunction of mvad.m, to read user specified data, and
%   display the progress in command window.

% AUTHOR:
%   Zhiyi Tang
%   tangzhi1@hit.edu.cn
%   Center of Structural Monitoring and Control
% 
% DATE CREATED:
%   06/20/2017

for s = sensorNum
    sensorData{s} = [];
    sensorImage{s} = single([]);
    sensorImageTemp{s} = single([]);
end

path.root = pathRead;
chunkSize = 100;
hourTotal = (dayEnd-dayStart+1)*24;
count = 1;
countForChunk = 1;
countForFileName = 1;
figure
set(gcf,'Units','pixels','Position',[100, 100, 100, 100]);
ticTotal = tic;
for day = dayStart : dayEnd
    string = datestr(day);
    for hour = 0:23
        ticRemain = tic;
        dateVec(count,:) = datevec(string,'dd-mmm-yyyy');
        dateVec(count,4) = hour;
        dateSerial(count,1) = datenum(dateVec(count,:));
        path.folder = sprintf('%04d-%02d-%02d',dateVec(count,1),dateVec(count,2), dateVec(count,3));
        path.file = [path.folder sprintf(' %02d-VIB.mat',hour)];
        path.full = [path.root '/' path.folder '/' path.file];
        
        if ~exist(path.full, 'file')
            fprintf('\nCAUTION:\n%s\nNo such file! Filled with a zero.\n', path.full)
            for s = sensorNum
                sensorData{s}(1, 1) = zeros; % just add a point rather than vector
            end
        else
            read = ['load(''' path.full ''');']; eval(read);
            for s = sensorNum
                sensorData{s}(:, 1) = data(:, s);
                
                % time series signals plot
                plot(sensorData{s}(:, 1),'color','k');
                position = get(gcf,'Position');
                set(gca,'visible','off');
                set(gcf,'color','white');
                set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
                set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
                xlim([0 size(sensorData{s}(:, 1),1)]);
                imgTime = getframe(gcf);
                imgTime = imresize(imgTime.cdata, [100 100]);  % expected dimension
                imgTime = rgb2gray(imgTime);
                imgTime = im2double(imgTime);
                
                % frequency domain plot
                N = length(sensorData{s}(:, 1));
                f = (0 : N/2-1)*(fs/N);
                sensorData{s}(isnan(sensorData{s}(:, 1)), 1) = 0;
                freqData = fft(sensorData{s}(:, 1)-median(sensorData{s}(:, 1)));

                plot(f, abs(real(freqData(1:N/2))),'color','k');
                set(gca, 'visible', 'off');
                set(gcf,'color','white');
                set(gcf,'Units','pixels','Position',[position(1), position(2), 100, 100]);  % control figure's position
                set(gca,'Units','normalized', 'Position',[0 0 1 1]);  % control axis's position in figure
                imgFreq = getframe(gcf);
                imgFreq = imresize(imgFreq.cdata, [100 100]);  % expected dimension
                imgFreq = rgb2gray(imgFreq);
                imgFreq = im2double(imgFreq);
                
                sensorImageTemp{s}(:, countForChunk) = [imgTime(:) ; imgFreq(:)];
            end
            
            tocRemain = toc(ticRemain);
            tRemain = tocRemain * (hourTotal - count);
            [hours, mins, secs] = sec2hms(tRemain);
            
            fprintf('\nGenerating images for each sensor...  %d-%02d-%02d  %02d:00-%02d:00  Done!', ...
                dateVec(count,1), dateVec(count,2), dateVec(count,3), hour, hour+1)
            fprintf('\nTotal: %d  Now: %d  ', hourTotal, count)
            fprintf('About %02dh%02dm%05.2fs left.\n', hours, mins, secs)
            
            if countForChunk == chunkSize || count == hourTotal
               fileName{countForFileName} = sprintf('data2imageSubSet_%05d-%05d.mat', count-countForChunk+1, count);
               save([imageSetSaveRoot fileName{countForFileName}], 'sensorImageTemp', '-v7.3')
               countForChunk = 0;
               sensorImageTemp = [];
               countForFileName = countForFileName+1;
            end
            
            count = count+1;
            countForChunk = countForChunk+1;
            data = [];
            sensorData = [];
            
            
        end
    end
end
count = count-1;
countForFileName = countForFileName-1;
close

% read from mat file and combine
fprintf('\nCombining data...\n')
for m = 1 : countForFileName
    load([imageSetSaveRoot fileName{m}]);
    for s = sensorNum
        sensorImage{s} = cat(2, sensorImage{s}, sensorImageTemp{s});
    end
    delete([imageSetSaveRoot fileName{m}]);
    sensorImageTemp = [];
end

tocTotal = toc(ticTotal);
[hours, mins, secs] = sec2hms(tocTotal);
fprintf('\nTotal time consumption: %02dh%02dm%05.2fs.\n', hours, mins, secs)

end
