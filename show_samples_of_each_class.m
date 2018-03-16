clear;clc;close all

samplePath = 'C:\Users\Owner\Documents\GitHub\mlad_withKnownLabel\samples_of_each_class';

%% coleect file names
count = 1;
fileNames = [];
for class = 1 : 7
    listNames = dir(sprintf('%s/class_%d', samplePath, class));
    for n = randperm(10)
        fileNames{count} = [listNames(n+2).folder '\' listNames(n+2).name];
        count = count + 1;
    end
end

%% plot
close all
figure
montage(fileNames, 'Size', [7 10]);
ax = gca;
ax.Units = 'normalized';
ax.Position = [0 0 1 1];

fig = gcf;
fig.Units = 'pixels';
fig.Position = [1000, 100, 1000, 700];

%%
samplesFolder = 'samples_of_each_class/';
if ~exist(samplesFolder, 'dir')
    mkdir(samplesFolder)
end
saveas(gcf, [samplesFolder 'montage_samples_' datestr(now,'yyyy-mm-dd_HH-MM-SS') '.tif'])
