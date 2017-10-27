function [trainSetLabel, count] = dispAndLabelInTime(trainSetData, trainSetLabel, clust, in, out, count, all, labelName)

m = in;
while m <= out
    %% plot
    s = size(trainSetData{clust}, 1);
    
    plotTime = reshape(trainSetData{clust}(:, m), [sqrt(s) sqrt(s)]);
%     plotFreq = reshape(trainSetData{clust}(s/2+1:end, m), [sqrt(s/2) sqrt(s/2)]);
    
    subplot(1,2,1);
    imshow(plotTime);
    xlabel('time')
    ylabel('amplitude')
    title('time domain')
%     subplot(1,2,2);
%     imshow(plotFreq);
%     xlabel('frequency')
%     ylabel('amplitude')
%     title('frequency domain')
    set(gcf,'Units','pixels','Position',[100, 100, 610, 300]);
    pbaspect([1 1 1]);
    
    %% label
    if count == all % incase of the exceeding due to round after division
        return
    end
    
    fprintf('\nNow: %d / %d\n', count+1, all)
    fprintf('Data type:')
    labelTotal = size(labelName, 2);
    for l = 1 : labelTotal
        fprintf('\n%s', labelName{l})
    end
    fprintf('\n0-redo the previous.')
    
    prompt = '\nInput: ';
    classify = input(prompt,'s');
    classify = str2double(classify);
    
    if classify <= labelTotal && classify >= 1
        trainSetLabel{clust}(classify, m) = 1;
        m = m + 1;
        count = count + 1;
    elseif classify == 0
        if m > 1
            fprintf('\nRedo the previous.\n')
            m = m - 1;
            count = count - 1;
        else fprintf('\nThis is already the first!\n')
        end
    else
        fprintf('\n\n\n\n\n\nInvalid input! Input 1-9 for labelling, 0 for redoing previous one.\n')
    end
    
end

end