import mlreportgen.dom.*;
headObj{3} = append(doc, Heading1('Detector performance'));
headObj{3}.FontSize = '18';

%% insert blank
cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

%% insert tabled images
netPerformTemp = {[dirName.net sprintf('group-%d_netConfuseTrain.png', g)];
                  [dirName.net sprintf('group-%d_netConfuseVali.png', g)]};

imageCap = {'Training set';'Validation set'};

countTable = countTable + 1;
tableObj{countTable} = Table();
rowImg{2} = TableRow();
rowCap{2} = TableRow();
c = 1;
for l = 1 : 2
    imgsize = size(imread(netPerformTemp{l}));
    width = [num2str(2.6 * imgsize(2)/imgsize(1)) 'in'];
    imageNetPerform{l} = Image(netPerformTemp{l});
    imageNetPerform{l}.Height = '2.6in';
    imageNetPerform{l}.Width = width;
    append(rowImg{2}, TableEntry(imageNetPerform{l}));
    
    if exist('countFig', 'var'), countFig = countFig + 1;
    else countFig = 1; 
    end
    imageNetPerformCap{l} = Paragraph(sprintf('Fig %d. %s', countFig, imageCap{l}));
    imageNetPerformCap{l}.Bold = false;
    % imageNetPerformCap.FontSize = '18';
    imageNetPerformCap{l}.HAlign = 'center';
    append(rowCap{2}, TableEntry(imageNetPerformCap{l}));
    
    if mod(c,2) == 0 % change here to customize column number
        append(tableObj{countTable},rowImg{2});
        append(tableObj{countTable},rowCap{2});
        rowImg{2} = TableRow();
        rowCap{2} = TableRow();
    elseif l == labelTotal
        append(tableObj{countTable},rowImg{2});
        append(tableObj{countTable},rowCap{2});
    end
    c = c + 1;
end
tableObj{countTable}.HAlign = 'center';
append(doc, tableObj{countTable});

%% insert blank
cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

%% insert tabled image
netPerformTemp = {[dirName.net sprintf('group-%d_netAccuracy.png', g)]};
imageCap = {'Accuracy'};

countTable = countTable + 1;
tableObj{countTable} = Table();
rowImg{2} = TableRow();
rowCap{2} = TableRow();
c = 1;
for l = 1
    imgsize = size(imread(netPerformTemp{l}));
    width = [num2str(2.6 * imgsize(2)/imgsize(1)) 'in'];
    imageNetPerform{l} = Image(netPerformTemp{l});
    imageNetPerform{l}.Height = '2.6in';
    imageNetPerform{l}.Width = width;
    append(rowImg{2}, TableEntry(imageNetPerform{l}));
    
    if exist('countFig', 'var'), countFig = countFig + 1;
    else countFig = 1; 
    end
    imageNetPerformCap{l} = Paragraph(sprintf('Fig %d. %s', countFig, imageCap{l}));
    imageNetPerformCap{l}.Bold = false;
    % imageNetPerformCap.FontSize = '18';
    imageNetPerformCap{l}.HAlign = 'center';
    append(rowCap{2}, TableEntry(imageNetPerformCap{l}));
    
    if mod(c,1) == 0 % change here to customize column number
        append(tableObj{countTable},rowImg{2});
        append(tableObj{countTable},rowCap{2});
        rowImg{2} = TableRow();
        rowCap{2} = TableRow();
    elseif l == labelTotal
        append(tableObj{countTable},rowImg{2});
        append(tableObj{countTable},rowCap{2});
    end
    c = c + 1;
end
tableObj{countTable}.HAlign = 'center';
append(doc, tableObj{countTable});

%% insert next section
countSect = countSect + 1;
sect{countSect} = DOCXPageLayout;
sect{countSect}.PageSize.Orientation = 'portrait';
sect{countSect}.SectionBreak = 'Next Page';
sect{countSect}.PageSize.Height = '8.27in';
sect{countSect}.PageSize.Width = '11.69in';
append(doc, sect{countSect});