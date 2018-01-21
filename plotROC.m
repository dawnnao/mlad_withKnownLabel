figure
% plotroc(labelMan, labelNet);
plotroc(feature{g}.label.manual(:,feature{g}.trainSize+1 : end), yVali)

% [tpr, fpr, thresholds] = roc(labelMan, labelNet);