% import mlreportgen.dom.*;
% d = Document('mydoc','docx');
% open(d);
% 
% title = append(d, Paragraph('Document Title'));
% title.Bold = true;
% title.FontSize = '28pt';
% 
% 
% 
% h1 = append(d,Heading1('Chapter 1'));
% h1.Style = {PageBreakBefore(true)};
% p1 = append(d,Paragraph('Hello World'));
% 
% h2 = append(d,Heading2('Section 1.1'));
% p2 = append(d,Paragraph('Text for this section.'));
% 
% h3 = append(d,Heading3('My Subsection 1.1.a'));
% p3 = append(d,Paragraph('Text for this subsection'));
% 
% close(d);
% rptview(d.OutputPath);

import mlreportgen.dom.*
rpt = Document('test','docx');

append(rpt,Heading(1,'Magic Square Report','Heading 1'));

sect = DOCXPageLayout;
sect.PageSize.Orientation = 'landscape';
sect.PageSize.Height = '8.27in';
sect.PageSize.Width = '11.69in';
append(rpt,Paragraph('The next page shows a magic square.'),sect);
 
table = append(rpt,magic(22));
table.Border = 'solid';
table.ColSep = 'solid';
table.RowSep = 'solid';

sect2 = DOCXPageLayout;
sect2.PageSize.Orientation = 'portrait';
sect2.PageSize.Height = '8.27in';
sect2.PageSize.Width = '11.69in';
append(rpt,Paragraph('The next page shows a magic square, too.'),sect2);
 
table2 = append(rpt,magic(22));
table2.Border = 'solid';
table2.ColSep = 'solid';
table2.RowSep = 'solid';
 
close(rpt);
rptview(rpt.OutputPath);