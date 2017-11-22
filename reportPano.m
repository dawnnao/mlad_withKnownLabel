import mlreportgen.dom.*;
headObj{1} = append(doc, Heading1('Panorama'));
headObj{1}.FontSize = '18';

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

br{cPageBreak} = PageBreak();
append(doc ,br{cPageBreak}); cPageBreak = cPageBreak + 1;



