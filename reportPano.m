import mlreportgen.dom.*;
headObj{1} = append(doc, Heading1('Panorama'));
headObj{1}.FontSize = '18';

cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

panoRotate = imread([dirName.plotPano dirName.panopano]);
% panoRotate = imrotate(panoRotate, -90);
dirName.panoRotate = [sprintf('%s--%s_sensor_all%s', date.start, date.end, sensorStr) ...
                    '_anomalyDetectionPanoramaRotate.png'];
imwrite(panoRotate, [dirName.plotPano dirName.panoRotate]);

imgsize = size(imread([dirName.plotPano dirName.panoRotate]));
width = [num2str(2.8 * imgsize(2)/imgsize(1)) 'in'];
panoObj = Image([dirName.plotPano dirName.panoRotate]);
panoObj.Height = '2.8in';
panoObj.Width = width;
panoPara = Paragraph(panoObj);
panoPara.HAlign = 'center';
append(doc, panoPara);

% cPageBreak = 1;
% br{cPageBreak} = PageBreak();
% append(doc ,br{cPageBreak}); cPageBreak = cPageBreak + 1;

sect{2} = DOCXPageLayout;
sect{2}.PageSize.Orientation = 'landscape';
sect{2}.SectionBreak = 'Next Page';
sect{2}.PageSize.Height = '8.27in';
sect{2}.PageSize.Width = '11.69in';
append(doc, sect{2});



