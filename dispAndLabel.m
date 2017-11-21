function [trainSetLabel, count, shortHalfwayLeft] = dispAndLabel(trainSetData, trainSetLabel, clust, clustSize, clustAvail, in, out, count, all, labelName, ticLabel)

shortHalfwayLeft = out - in + 1;
availInClust = clustAvail(clust) + shortHalfwayLeft;
m = in;
while m <= out
    %% plot
    s = size(trainSetData{clust}, 1);
    
    plotTime = reshape(trainSetData{clust}(1:s/2, m), [sqrt(s/2) sqrt(s/2)]);
    plotFreq = reshape(trainSetData{clust}(s/2+1:end, m), [sqrt(s/2) sqrt(s/2)]);
    
    subplot(1,2,1);
    imshow(plotTime);
    xlabel('time')
    ylabel('amplitude')
    title('time domain')
    subplot(1,2,2);
    imshow(plotFreq);
    xlabel('frequency')
    ylabel('amplitude')
    title('frequency domain')
    position = get(gcf,'Position');
    set(gcf,'Units','pixels','Position',[position(1), position(2), 610, 300]);
    pbaspect([1 1 1]);
    
    %% real-time count number of each label
    countNumOfLabel = zeros(size(labelName, 2), 1);
    for n = 1 : length(trainSetLabel)
        countNumOfLabel = countNumOfLabel + sum(trainSetLabel{n} ,2);
    end
    
    %% label
    if count == all % incase of the exceeding due to round after division
        return
    end
    fprintf('\n-----------------------------------------------------------------------------------------\n')    
    fprintf('\nRealtime count:\n')
    for n = 1 : length(countNumOfLabel)
        fprintf('label %d: %d | ', n, countNumOfLabel(n))
    end    
    fprintf('\nNow: %d / %d\n', count+1, all)
    fprintf('\nCluster infomation: No.%d  total: %d  available: %d\n', clust, clustSize(clust), availInClust)
    fprintf('\nData type:')
    labelTotal = size(labelName, 2);
    for l = 1 : labelTotal
        fprintf('\n%s', labelName{l})
    end
    fprintf('\n0-redo the previous.')
    fprintf('\n909-jump to next cluster.\n')
    prompt = '\nInput: ';
    classify = input(prompt,'s');
    classify = str2double(classify);
    
    if classify <= labelTotal && classify >= 1
        trainSetLabel{clust}(classify, m) = 1;
        m = m + 1;
        count = count + 1;
        shortHalfwayLeft = shortHalfwayLeft - 1;
        availInClust = availInClust - 1;
    elseif classify == 0
        if m > 1
            fprintf('\nRedo the previous.\n')
            m = m - 1;
            count = count - 1;
            shortHalfwayLeft = shortHalfwayLeft + 1;
            availInClust = availInClust + 1;
        else fprintf('\nThis is already the first!\n')
        end
    elseif classify == 909
        fprintf('\nGoing to next available cluster.\n')
        return
    else
        fprintf('\n\n\n\n\n\nInvalid input! Input 1-7 for labelling, 0 for redoing previous one.\n')
    end
    
    tocLabel = toc(ticLabel);
    tocLabelLeft = tocLabel/count * (all - count);
    [hours, mins, secs] = sec2hms(tocLabelLeft);
    fprintf('\nTime left to finish labeling: %02dh%02dm%05.2fs\n', hours, mins, secs)
end

end