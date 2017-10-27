clear; close all;clc;
load('F:\mlad\case\2012-01-01--2012-01-02_sensor_1,2_10_fusion\trainingSetMat\imageSet.mat')
% load('F:\mlad\case\2012-01-01--2012-05-31_sensor_1_3_5_13_25,26_32_36_fusion\trainingSetMat\imageSet.mat')

%%
data = cell2mat(sensor.image);
dataDown = downsample(data,16);

K = 8;
dataDown = dataDown';
% [coeff, score, latent] = pca(test);
idx = kmedoids(dataDown, K);

%% cluster overview
fprintf('\nCluster overview:\n')
NP = 100; % sample number per plot
for kk = 1 : K % Cluster
    count = 0;
    idxTemp = find(idx == kk);
    nIdxTemp = length(idxTemp);
    figure('position', [40, 40, 2000, 960])
    
    for pBig = 1 : ceil(nIdxTemp/NP) % overview plot
        fprintf('\nPlotting...\n')
        for pSmall = 1 : NP
            count = count + 1;
            if pSmall == 1
               set(gcf,'Name', sprintf('Sample %d-%d (total %d) in cluster %d', 100*(pBig-1)+1, min([nIdxTemp, 100*pBig]), nIdxTemp, kk));
            end
            % plot each sample
            if count <= nIdxTemp
               subaxis(10,20, 2*pSmall-1, 'S',0.005, 'M',0.005);
               imshow(reshape(data(1:10000, idxTemp(count)), [100 100]));
               subaxis(10,20, 2*pSmall, 'S',0.005, 'M',0.005);
               imshow(reshape(data(10001:20000, idxTemp(count)), [100 100]));
            else
               subaxis(10,20, 2*pSmall-1, 'S',0.005, 'M',0.005);
               imshow([]);
               subaxis(10,20, 2*pSmall, 'S',0.005, 'M',0.005);
               imshow([]);
            end
           
        end
        
        rightInput = 0;
        while rightInput == 0
            str = input('N/n: next big plot\nJ/j: jump to next cluster\nInput: ', 's');
            if strcmp(str,'n') || strcmp(str,'N')
                rightInput = 1;
            elseif strcmp(str,'j') || strcmp(str,'J')
                rightInput = 2;
            else
                fprintf('Invalid input! Please re-input.\n')
            end
        end
        
        if rightInput == 2
            break % to next cluster
        end
        
    end
    
    dirName = sprintf('clusterOverview/');
    if ~exist(dirName,'dir'), mkdir(dirName); end
    fprintf('\nSaving plot...\n')
    saveas(gcf, [dirName sprintf('Sample_%04d-%04d_Total-%04d_Cluster_%d.tif', 100*(pBig-1)+1, min([nIdxTemp, 100*pBig]), nIdxTemp, kk)]);
    close
end

%%
% for kk = 1 : K
%     idxTemp = find(idx == kk);
%     figure
%     for m = 1 : nIdxTemp
%       
%       str = sprintf('Number-%d of %d in cluster-%d', m, nIdxTemp, kk);
%       subplot(1,2,1); imshow(reshape(data(1:10000, idxTemp(m)), [100 100]));
%       title(str);
%       subplot(1,2,2); imshow(reshape(data(10001:20000, idxTemp(m)), [100 100]));
%       
%       str = input('n/N: next sample\nj/J: jump to next cluster\n', 's');
%       
%       if ~isempty(str)
%           if (str == 'n' || str == 'N')
%           elseif (str == 'j' || str == 'J')
%               break
%           end
%           
%       end
%       
%       
%       
%     end
%     close 
% end

%%

%   >> subaxis(2,1,1,'SpacingVert',0,'MR',0); 
%   >> imagesc(magic(3))
%   >> subaxis(2,'p',.02);
%   >> imagesc(magic(4))


%        p=mtit('the BIG title',...
%	     'fontsize',14,'color',[1 0 0],...
%	     'xoff',-.1,'yoff',.025);
% % refine title using its handle <p.th>
%	set(p.th,'edgecolor',.5*[1 1 1]);


% % randomization
% seed = 1;  % intialization 
% rng(seed,'twister');

