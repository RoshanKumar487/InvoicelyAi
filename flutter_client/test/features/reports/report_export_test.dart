import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/reports/data/report_export.dart';

void main() {
  const reports = [
    ExportReportTable(
      name: 'Invoices',
      headers: ['Invoice', 'Client'],
      rows: [
        ['INV-01', 'A&B Services'],
      ],
    ),
    ExportReportTable(
      name: 'Expenses',
      headers: ['Expense', 'Amount'],
      rows: [
        ['Travel', '45.00'],
      ],
    ),
    ExportReportTable(
      name: 'Clients',
      headers: ['Name', 'Email'],
      rows: [
        ['Client One', 'client@example.test'],
      ],
    ),
  ];

  test('builds a valid Excel workbook with a sheet for each report', () {
    final bytes = ReportExport.buildExcel(reports);
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(
      archive.files.map((file) => file.name),
      containsAll([
        '[Content_Types].xml',
        'xl/workbook.xml',
        'xl/worksheets/sheet1.xml',
        'xl/worksheets/sheet2.xml',
        'xl/worksheets/sheet3.xml',
      ]),
    );
    final invoices = archive.findFile('xl/worksheets/sheet1.xml')!;
    expect(utf8.decode(invoices.readBytes()!), contains('A&amp;B Services'));
    expect(
      utf8.decode(archive.findFile('xl/workbook.xml')!.readBytes()!),
      contains('name="Clients"'),
    );
  });

  test('builds a readable PDF containing every report page', () async {
    final bytes = await ReportExport.buildPdf(reports);

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });

  test('rejects an empty export request', () {
    expect(() => ReportExport.buildExcel([]), throwsArgumentError);
    expect(ReportExport.buildPdf([]), throwsArgumentError);
  });
}
