import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportReportTable {
  const ExportReportTable({
    required this.name,
    required this.headers,
    required this.rows,
  });

  final String name;
  final List<String> headers;
  final List<List<String>> rows;
}

class ReportExport {
  ReportExport._();

  /// Builds a 100% compliant OpenXML Microsoft Excel (.xlsx) workbook.
  /// Includes full styles.xml, docProps, frozen header row, styled column widths,
  /// and numeric cell detection so Excel opens cleanly without any recovery warning.
  static Uint8List buildExcel(List<ExportReportTable> reports) {
    if (reports.isEmpty) {
      throw ArgumentError.value(
          reports, 'reports', 'At least one report is required.');
    }
    final archive = Archive();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 1. [Content_Types].xml
    final contentTypes = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
    );

    // 2. Package relationships: _rels/.rels
    const packageRelationships =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
        '</Relationships>';

    // 3. docProps/core.xml
    final coreProperties =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:creator>Invoicely AI</dc:creator>'
        '<cp:lastModifiedBy>Invoicely AI</cp:lastModifiedBy>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">$nowIso</dcterms:created>'
        '<dcterms:modified xsi:type="dcterms:W3CDTF">$nowIso</dcterms:modified>'
        '</cp:coreProperties>';

    // 4. docProps/app.xml
    final appProperties =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">'
        '<Application>Microsoft Excel</Application>'
        '<DocSecurity>0</DocSecurity>'
        '<ScaleCrop>false</ScaleCrop>'
        '<HeadingPairs><vt:vector size="2" baseType="variant" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
        '<vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>'
        '<vt:variant><vt:i4>${reports.length}</vt:i4></vt:variant>'
        '</vt:vector></HeadingPairs>'
        '</Properties>';

    // 5. xl/styles.xml (Complete style sheet required by Microsoft Excel)
    const stylesXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2">'
        '<font><sz val="10"/><color theme="1"/><name val="Calibri"/><family val="2"/></font>'
        '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
        '</fonts>'
        '<fills count="3">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1E3A8A"/><bgColor indexed="64"/></patternFill></fill>'
        '</fills>'
        '<borders count="2">'
        '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border>'
        '<left style="thin"><color rgb="FFE2E8F0"/></left>'
        '<right style="thin"><color rgb="FFE2E8F0"/></right>'
        '<top style="thin"><color rgb="FFE2E8F0"/></top>'
        '<bottom style="thin"><color rgb="FFE2E8F0"/></bottom>'
        '<diagonal/>'
        '</border>'
        '</borders>'
        '<cellStyleXfs count="1">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
        '</cellStyleXfs>'
        '<cellXfs count="3">'
        '<!-- 0: Standard Body cell -->'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0"><alignment vertical="center"/></xf>'
        '<!-- 1: Header (Navy Blue, Bold White text, centered) -->'
        '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="center" vertical="center" wrapText="1"/>'
        '</xf>'
        '<!-- 2: Numeric cell (right aligned) -->'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1">'
        '<alignment horizontal="right" vertical="center"/>'
        '</xf>'
        '</cellXfs>'
        '</styleSheet>';

    final workbookSheets = StringBuffer();
    final workbookRelationships = StringBuffer(
      '<Relationship Id="rIdStyles" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
      'Target="styles.xml"/>',
    );

    for (var index = 0; index < reports.length; index++) {
      final report = reports[index];
      final sheetNumber = index + 1;
      final sheetName = _sheetName(report.name);
      final relationId = 'rIdSheet$sheetNumber';

      workbookSheets.write(
        '<sheet name="${_xml(sheetName)}" sheetId="$sheetNumber" '
        'r:id="$relationId"/>',
      );
      workbookRelationships.write(
        '<Relationship Id="$relationId" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet$sheetNumber.xml"/>',
      );
      contentTypes.write(
        '<Override PartName="/xl/worksheets/sheet$sheetNumber.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );

      final maxCols = report.headers.isNotEmpty ? report.headers.length : 1;
      final maxRows = 1 + report.rows.length;

      // Column widths definition
      final colsBuffer = StringBuffer('<cols>');
      for (var c = 1; c <= maxCols; c++) {
        colsBuffer.write('<col min="$c" max="$c" width="22" customWidth="1"/>');
      }
      colsBuffer.write('</cols>');

      final sheetData = StringBuffer();

      // Header row (Row 1)
      sheetData.write('<row r="1" ht="26" customHeight="1">');
      for (var colIdx = 0; colIdx < report.headers.length; colIdx++) {
        final reference = '${_columnName(colIdx + 1)}1';
        final headerText = report.headers[colIdx];
        sheetData.write(
          '<c r="$reference" s="1" t="inlineStr"><is><t xml:space="preserve">'
          '${_xml(headerText)}'
          '</t></is></c>',
        );
      }
      sheetData.write('</row>');

      // Data rows (Row 2 .. N)
      final numRegex = RegExp(r'^-?\d+(\.\d+)?$');
      for (var rowIdx = 0; rowIdx < report.rows.length; rowIdx++) {
        final rowNumber = rowIdx + 2;
        final rowData = report.rows[rowIdx];
        sheetData.write('<row r="$rowNumber" ht="20" customHeight="1">');

        for (var colIdx = 0; colIdx < rowData.length; colIdx++) {
          final reference = '${_columnName(colIdx + 1)}$rowNumber';
          final val = rowData[colIdx];
          final trimmed = val.trim();

          // Check if purely numeric
          if (trimmed.isNotEmpty && numRegex.hasMatch(trimmed)) {
            sheetData.write('<c r="$reference" s="2"><v>$trimmed</v></c>');
          } else {
            sheetData.write(
              '<c r="$reference" s="0" t="inlineStr"><is><t xml:space="preserve">'
              '${_xml(val)}'
              '</t></is></c>',
            );
          }
        }
        sheetData.write('</row>');
      }

      final worksheetXml =
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<dimension ref="A1:${_columnName(maxCols)}$maxRows"/>'
          '<sheetViews>'
          '<sheetView tabSelected="${sheetNumber == 1 ? "1" : "0"}" workbookViewId="0">'
          '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
          '</sheetView>'
          '</sheetViews>'
          '<sheetFormatPr defaultRowHeight="18" defaultColWidth="14"/>'
          '$colsBuffer'
          '<sheetData>$sheetData</sheetData>'
          '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>'
          '</worksheet>';

      archive.addFile(_file('xl/worksheets/sheet$sheetNumber.xml', worksheetXml));
    }

    contentTypes.write('</Types>');

    archive
      ..addFile(_file('[Content_Types].xml', contentTypes.toString()))
      ..addFile(_file('_rels/.rels', packageRelationships))
      ..addFile(_file('docProps/core.xml', coreProperties))
      ..addFile(_file('docProps/app.xml', appProperties))
      ..addFile(_file('xl/styles.xml', stylesXml))
      ..addFile(_file(
        'xl/workbook.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<workbookPr defaultThemeVersion="166925"/>'
        '<bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews>'
        '<sheets>$workbookSheets</sheets>'
        '<calcPr calcId="191029"/>'
        '</workbook>',
      ))
      ..addFile(_file(
        'xl/_rels/workbook.xml.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '$workbookRelationships</Relationships>',
      ));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Builds a UTF-8 encoded CSV file with UTF-8 Byte Order Mark (BOM: 0xEF, 0xBB, 0xBF)
  /// so Microsoft Excel and other desktop tools immediately recognize character encodings.
  static Uint8List buildCsv(List<ExportReportTable> reports) {
    if (reports.isEmpty) {
      throw ArgumentError.value(reports, 'reports', 'At least one report is required.');
    }
    final buffer = StringBuffer();
    for (final report in reports) {
      if (reports.length > 1) {
        buffer.writeln('# ${report.name}');
      }
      buffer.writeln(report.headers.map(_escapeCsv).join(','));
      for (final row in report.rows) {
        buffer.writeln(row.map(_escapeCsv).join(','));
      }
      if (reports.length > 1) {
        buffer.writeln();
      }
    }

    // Prepend UTF-8 BOM so Excel opens with correct Unicode characters without encoding dialogs
    final utf8Bytes = utf8.encode(buffer.toString());
    final result = Uint8List(3 + utf8Bytes.length);
    result[0] = 0xEF;
    result[1] = 0xBB;
    result[2] = 0xBF;
    result.setRange(3, result.length, utf8Bytes);
    return result;
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2B50}-\u{2B55}\u{200D}\u{FE0F}]',
    unicode: true,
  );

  static String cleanPdfText(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input.replaceAll(_emojiRegex, '');
    text = text
        .replaceAll('₹', 'Rs. ')
        .replaceAll('€', 'EUR ')
        .replaceAll('£', 'GBP ')
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('…', '...')
        .replaceAll('™', '')
        .replaceAll('®', '')
        .replaceAll('©', '(c)');
    // Strip non-ASCII characters that standard Helvetica cannot print
    text = text.replaceAll(RegExp(r'[^\x20-\x7E\r\n\t]'), '');
    return text.replaceAll(RegExp(r'Rs\.\s+Rs\.'), 'Rs.').trim();
  }

  static Future<Uint8List> buildPdf(
    List<ExportReportTable> reports,
  ) async {
    if (reports.isEmpty) {
      throw ArgumentError.value(
          reports, 'reports', 'At least one report is required.');
    }
    final document = pw.Document();
    for (final report in reports) {
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                cleanPdfText(report.name),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (report.rows.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Text('No records match the current filters.'),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: report.headers.map(cleanPdfText).toList(),
                data: report.rows
                    .map((row) => row.map(cleanPdfText).toList())
                    .toList(),
                headerStyle: pw.TextStyle(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E3A8A),
                ),
                cellPadding: const pw.EdgeInsets.all(5),
                border: pw.TableBorder.all(
                  color: PdfColor.fromInt(0xFFD9E0EA),
                  width: 0.5,
                ),
              ),
          ],
        ),
      );
    }
    return Uint8List.fromList(await document.save());
  }

  static ArchiveFile _file(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _columnName(int value) {
    var number = value;
    final name = StringBuffer();
    while (number > 0) {
      number--;
      name.writeCharCode(65 + number % 26);
      number ~/= 26;
    }
    return name.toString().split('').reversed.join();
  }

  static String _sheetName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    return cleaned.isEmpty
        ? 'Report'
        : cleaned.substring(0, cleaned.length > 31 ? 31 : cleaned.length);
  }

  static String _xml(String value) => value
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
