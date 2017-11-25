import mlreportgen.dom.*;

dirName.docFile = sprintf('%s%s--%s_sensor%s%s', dirName.home, date.start, date.end, sensorStr, netLayout);
reportType = 'docx';
doc = Document(dirName.docFile, reportType);

% insert blank
cBlank = 0; frag = 4;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

titleObj{1} = Paragraph('Machine Learning-based SHM Data Anomaly Detection Auto-Report');
titleObj{1}.Bold = false;
titleObj{1}.FontSize = '26';
titleObj{1}.HAlign = 'center';
append(doc, titleObj{1});

titleObj{2} = Paragraph('Version: 0.1');
titleObj{2}.Bold = false;
titleObj{2}.FontSize = '18';
titleObj{2}.HAlign = 'center';
append(doc, titleObj{2});

% insert blank
cBlank = cBlankNew; frag = 12;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

arthurObj = Paragraph('Center of Structural Monitoring and Control');
arthurObj.Bold = false;
arthurObj.FontSize = '18';
arthurObj.HAlign = 'center';
append(doc, arthurObj);

% insert blank
cBlank = cBlankNew; frag = 2;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

% dateObj = Paragraph(datetime('now','Format','yyyy-MM-dd'));
% datestr(datetime('now'),'yyyy-MM-dd');
dateObj = Paragraph(datestr(datetime('now'),'yyyy-mm-dd'));
dateObj.Bold = false;
dateObj.FontSize = '18';
dateObj.HAlign = 'center';
% append(dateObj, ['' datetime('now','Format','yyyy-MM-dd') '']);
append(doc, dateObj);

countFig = 0; % initialization for image count
countTable = 0;

% sizeCurrent = doc.CurrentPageLayout;
% sizeCurrent.PageSize.Orientation  ='portrait';
% sizeCurrent.PageSize.Height = '8.27in';
% sizeCurrent.PageSize.Width = '11.69in';
% % append(doc,'This document has portrait pages');
% append(doc, sizeCurrent);

%% insert next section
countSect = 1;
sect{countSect} = DOCXPageLayout;
sect{countSect}.PageSize.Orientation = 'portrait';
sect{countSect}.SectionBreak = 'Next Page';
sect{countSect}.PageSize.Height = '11.69in';
sect{countSect}.PageSize.Width = '8.27in';
append(doc, sect{countSect});