import 'package:flutter/material.dart';

import '../../features/reports/data/report_export.dart';
import 'file_download_helper.dart';

class TableExportHelper {
  TableExportHelper._();

  static Future<void> showExportMenu({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Text(
                      'Download & Save $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF0284C7)),
                title: const Text('Download CSV (.csv)'),
                subtitle: Text('Save ${rows.length} records as CSV spreadsheet'),
                onTap: () => Navigator.pop(ctx, 'csv'),
              ),
              ListTile(
                leading: const Icon(Icons.table_view_rounded, color: Color(0xFF107C41)),
                title: const Text('Download Excel Workbook (.xlsx)'),
                subtitle: Text('Save ${rows.length} records as styled Excel file'),
                onTap: () => Navigator.pop(ctx, 'xlsx'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626)),
                title: const Text('Download PDF Document (.pdf)'),
                subtitle: Text('Save ${rows.length} records as printable PDF file'),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
            ],
          ),
        ),
      ),
    );

    if (format == null) return;

    try {
      final reportTable = ExportReportTable(
        name: title,
        headers: headers,
        rows: rows,
      );

      final date = DateTime.now().toIso8601String().substring(0, 10);
      final sanitizedTitle = title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final filename = '$sanitizedTitle-$date.$format';

      final bytes = switch (format) {
        'xlsx' => ReportExport.buildExcel([reportTable]),
        'pdf' => await ReportExport.buildPdf([reportTable]),
        _ => ReportExport.buildCsv([reportTable]),
      };

      final mimeType = switch (format) {
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'pdf' => 'application/pdf',
        _ => 'text/csv',
      };

      await FileDownloadHelper.downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Saved $filename to Downloads'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not download file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
