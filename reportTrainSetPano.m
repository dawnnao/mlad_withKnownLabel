import mlreportgen.dom.*;
headObj{1} = append(doc, Heading1('Training set distribution'));
headObj{1}.FontSize = '18';

%% insert blank
cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

%% insert tabled images
dirName.plotPanoTrainSet = [dirName.mat 'panorama/']; % temp
dirName.panopanoTrainSet = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                        '_trainingSetLabelPanorama.tif']; % temp
panoRotate = imread([dirName.plotPanoTrainSet dirName.panopanoTrainSet]);
% panoRotate = imrotate(panoRotate, -90);
dirName.trainSetPanoRotate = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                    '_trainingSetLabelPanoramaRotated.png'];
imwrite(panoRotate, [dirName.plotPanoTrainSet dirName.trainSetPanoRotate]);
imgsize = size(imread([dirName.plotPanoTrainSet dirName.trainSetPanoRotate]));
width = [num2str(2.9 * imgsize(2)/imgsize(1)) 'in'];
imagePanoTrainSet = Image([dirName.plotPanoTrainSet dirName.trainSetPanoRotate]);
imagePanoTrainSet.Height = '2.9in';
imagePanoTrainSet.Width = width;

% image
if exist('countTable', 'var'), countTable = countTable + 1;
else countTable = 1; 
end
tableObj{countTable} = Table();
row{1} = TableRow();
append(row{1}, TableEntry(imagePanoTrainSet));
append(tableObj{countTable}, row{1});

% caption of image
if exist('countFig', 'var'), countFig = countFig + 1;
else countFig = 1; 
end

imageName = Paragraph(sprintf('Fig %d. Training set distribution (color gray means non-labeled data)', countFig));
imageName.Bold = false;
% imageName.FontSize = '18';
imageName.HAlign = 'center';
row{1} = TableRow();
append(row{1}, TableEntry(imageName));
append(tableObj{countTable}, row{1});
row{1} = TableRow();
tableObj{countTable}.HAlign = 'center';
append(doc, tableObj{countTable});

% %% insert paragraph
% paragraphObj = Paragraph('Version: 0.1');
% paragraphObj.Bold = false;
% paragraphObj.FontSize = '18';
% paragraphObj.HAlign = 'center';
% append(doc, paragraphObj);

%% insert next section
countSect = countSect + 1;
sect{countSect} = DOCXPageLayout;
sect{countSect}.PageSize.Orientation = 'landscape';
sect{countSect}.SectionBreak = 'Next Page';
sect{countSect}.PageSize.Height = '8.27in';
sect{countSect}.PageSize.Width = '11.69in';
append(doc, sect{countSect});