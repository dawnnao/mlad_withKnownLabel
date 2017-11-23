import mlreportgen.dom.*;
headObj{2} = append(doc, Heading1('Statistics by sensor'));
headObj{2}.FontSize = '18';

cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

tableObj{1} = Table(3);
row{1} = TableRow();
c = 1;
for s = sensor.numVec
    imgsize = size(imread([dirName.plotSPS dirName.statsPerSensor{s}]));
    width = [num2str(2.5 * imgsize(2)/imgsize(1)) 'in'];
    imageSPS{s} = Image([dirName.plotSPS dirName.statsPerSensor{s}]);
    imageSPS{s}.Height = '2.5in';
    imageSPS{s}.Width = width;
    append(row{1}, TableEntry(imageSPS{s}));
    if mod(c,3) == 0
        append(tableObj{1},row{1});
        row{1} = TableRow();
    elseif s == sensor.numVec(end)
        append(tableObj{1},row{1});
    end
    c = c + 1;
end
tableObj{1}.HAlign = 'center';
append(doc, tableObj{1});

% br{cPageBreak} = PageBreak();
% append(doc ,br{cPageBreak}); cPageBreak = cPageBreak + 1;

sect{3} = DOCXPageLayout;
sect{3}.PageSize.Orientation = 'portrait';
sect{3}.SectionBreak = 'Next Page';
sect{3}.PageSize.Height = '8.27in';
sect{3}.PageSize.Width = '11.69in';
append(doc, sect{3});