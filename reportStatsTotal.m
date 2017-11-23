import mlreportgen.dom.*;
headObj{4} = append(doc, Heading1('Statistics in total'));
headObj{4}.FontSize = '18';

cBlank = cBlankNew; frag = 1;
cBlankNew = cBlank + frag;
for n = cBlank+1 : cBlankNew
    blankObj{n} = Paragraph('');
    append(doc, blankObj{n});
end

imgsize = size(imread([dirName.plotSum dirName.statsSum]));
width = [num2str(4 * imgsize(2)/imgsize(1)) 'in'];
statsObj = Image([dirName.plotSum dirName.statsSum]);
statsObj.Height = '4in';
statsObj.Width = width;
statsPara = Paragraph(statsObj);
statsPara.HAlign = 'center';
append(doc, statsPara);

% br{cPageBreak} = PageBreak();
% append(doc ,br{cPageBreak}); cPageBreak = cPageBreak + 1;

% sect{5} = DOCXPageLayout;
% sect{5}.PageSize.Orientation = 'landscape';
% sect{5}.SectionBreak = 'Next Page';
% sect{5}.PageSize.Height = '8.27in';
% sect{5}.PageSize.Width = '11.69in';
% append(doc, sect{5});

close(doc);
