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

  static Uint8List buildExcel(List<ExportReportTable> reports) {
    if (reports.isEmpty) {
      throw ArgumentError.value(
          reports, 'reports', 'At least one report is required.');
    }
    final archive = Archive();
    final contentTypes = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
    );
    final workbookSheets = StringBuffer();
    final workbookRelationships = StringBuffer();
    final packageRelationships = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>',
    );

    for (var index = 0; index < reports.length; index++) {
      final report = reports[index];
      final sheetNumber = index + 1;
      final sheetName = _sheetName(report.name);
      final relationId = 'rId$sheetNumber';
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

      final rows = <List<String>>[report.headers, ...report.rows];
      final sheetData = StringBuffer();
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final rowNumber = rowIndex + 1;
        sheetData.write('<row r="$rowNumber">');
        for (var columnIndex = 0;
            columnIndex < rows[rowIndex].length;
            columnIndex++) {
          final reference = '${_columnName(columnIndex + 1)}$rowNumber';
          sheetData.write(
            '<c r="$reference" t="inlineStr"><is><t xml:space="preserve">'
            '${_xml(rows[rowIndex][columnIndex])}'
            '</t></is></c>',
          );
        }
        sheetData.write('</row>');
      }
      archive.addFile(_file(
        'xl/worksheets/sheet$sheetNumber.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            '<sheetData>$sheetData</sheetData></worksheet>',
      ));
    }

    contentTypes.write('</Types>');
    archive
      ..addFile(_file('[Content_Types].xml', contentTypes.toString()))
      ..addFile(_file('_rels/.rels', packageRelationships.toString()))
      ..addFile(_file(
        'xl/workbook.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '<sheets>$workbookSheets</sheets></workbook>',
      ))
      ..addFile(_file(
        'xl/_rels/workbook.xml.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '$workbookRelationships</Relationships>',
      ));
    return Uint8List.fromList(ZipEncoder().encode(archive));
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
                report.name,
                style: pw.TextStyle(
                  fontSize: 20,
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
                headers: report.headers,
                data: report.rows,
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
