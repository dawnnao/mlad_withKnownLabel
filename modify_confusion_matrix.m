% modify number
set(findobj(gca,'type','text'),'fontsize', 10.5, 'fontname', 'Helvetica')

% modify label
set(gca, 'fontsize', 13, 'fontname', 'Helvetica', 'fontweight', 'normal')

% accuracy
% change to normal font

% color
% recall and precision change to f1
% accuray change to f14
f1 = [220 220 220]/255;
f14 = [186 212 244]/255;

% set(findobj(gcf,'facecolor',[0.5,0.5,0.5]),'facecolor',f1)
% set(findobj(gcf,'facecolor',[120,150,230]./255),'facecolor',f14)
