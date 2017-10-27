clear; clc; close all;
load('E:\boxTransfer\trainingSet_justLabel_inSensorCell_toChannel29-absIdx3.mat')

%%
% modify labels
 for mTemp = 29 : 38
     sensor.label.manual{mTemp}(sensor.label.manual{mTemp} == 3) = 1;
 end

 %%
 sensor.label.manual{30} == 3;
 
 save('trainingSet_justLabel_inSensorCell_quick29to38.mat', 'sensor', '-v7.3')