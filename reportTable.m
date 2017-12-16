import mlreportgen.dom.*;
headObj{2} = append(doc, Heading1('Counting Table'));
headObj{2}.FontSize = '18';

%% insert blank
cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

%% insert tabled images

sensor.label.name

countTable = countTable + 1;
tableObj{countTable} = Table();
rowImg{1} = TableRow();
rowCap{1} = TableRow();
c = 1;
for s = sensor.numVec
    imgsize = size(imread([dirName.plotSPS dirName.statsPerSensor{s}]));
    width = [num2str(2.5 * imgsize(2)/imgsize(1)) 'in'];
    imageSPS{s} = Image([dirName.plotSPS dirName.statsPerSensor{s}]);
    imageSPS{s}.Height = '2.2in';
    imageSPS{s}.Width = width;
    append(rowImg{1}, TableEntry(imageSPS{s}));
    
    if exist('countFig', 'var'), countFig = countFig + 1;
    else countFig = 1; 
    end
    imageStatsPerSensorCap{s} = Paragraph(sprintf('Fig %d. %s', countFig, imageCap{s}));
    imageStatsPerSensorCap{s}.Bold = false;
    % imageNetPerformCap.FontSize = '18';
    imageStatsPerSensorCap{s}.HAlign = 'center';
    append(rowCap{1}, TableEntry(imageStatsPerSensorCap{s}));
    
    if mod(c,3) == 0 % change here to customize column number
        append(tableObj{countTable},rowImg{1});
        append(tableObj{countTable},rowCap{1});
        rowImg{1} = TableRow();
        rowCap{1} = TableRow();
    elseif s == sensor.numVec(end)
        append(tableObj{countTable},rowImg{1});
        append(tableObj{countTable},rowCap{1});
    end
    c = c + 1;
end
tableObj{countTable}.HAlign = 'center';
append(doc, tableObj{countTable});

% br{cPageBreak} = PageBreak();
% append(doc ,br{cPageBreak}); cPageBreak = cPageBreak + 1;

%% insert next section
countSect = countSect + 1;
sect{countSect} = DOCXPageLayout;
sect{countSect}.PageSize.Orientation = 'portrait';
sect{countSect}.SectionBreak = 'Next Page';
sect{countSect}.PageSize.Height = '8.27in';
sect{countSect}.PageSize.Width = '11.69in';
append(doc, sect{countSect});

