import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import 'report_types.dart';

void showReportExportScopePicker({
  required BuildContext context,
  required bool excel,
  required int activeFilterCount,
  required ReportType reportType,
  required void Function({
    required bool excel,
    bool allData,
    ReportType? singleTab,
  }) onExport,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      excel
                          ? Icons.table_view_rounded
                          : Icons.picture_as_pdf_rounded,
                      color: excel
                          ? const Color(0xFF107C41)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Export ${excel ? "Excel Workbook (.xlsx)" : "PDF Report (.pdf)"}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.filter_list_rounded),
                title: const Text('Export Current Filtered View'),
                subtitle: Text(
                  activeFilterCount > 0
                      ? 'Exports matching current filters and dates'
                      : 'Exports all current data',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onExport(excel: excel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('Export Full Company Database (All-Time)'),
                subtitle: const Text(
                    'Exports complete invoices, expenses & clients history'),
                onTap: () {
                  Navigator.pop(ctx);
                  onExport(excel: excel, allData: true);
                },
              ),
              ListTile(
                leading: Icon(reportType.icon),
                title: Text('Export Current Tab Only (${reportType.label})'),
                subtitle: Text('Exports only ${reportType.label} records'),
                onTap: () {
                  Navigator.pop(ctx);
                  onExport(excel: excel, singleTab: reportType);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void showReportYearExportOptions({
  required BuildContext context,
  required int year,
  required void Function({required bool excel, required int customYear})
      onExportYear,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$year Annual Report Export',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.table_view_rounded,
                    color: Color(0xFF107C41)),
                title: Text('Export $year to Excel (.xlsx)'),
                subtitle: const Text(
                    'Multi-sheet workbook for accounting and audits'),
                onTap: () {
                  Navigator.pop(ctx);
                  onExportYear(excel: true, customYear: year);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFDC2626)),
                title: Text('Export $year to PDF (.pdf)'),
                subtitle: const Text(
                    'Print-ready executive annual financial report'),
                onTap: () {
                  Navigator.pop(ctx);
                  onExportYear(excel: false, customYear: year);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class ReportDownloadToolsCard extends StatelessWidget {
  const ReportDownloadToolsCard({
    super.key,
    required this.availableYears,
    required this.onExportExcel,
    required this.onExportPdf,
    required this.onSelectYear,
  });

  final List<int> availableYears;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final ValueChanged<int> onSelectYear;

  Widget _buildExportActionButton({
    required bool excel,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_download_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Report Downloads',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Download multi-sheet Excel workbooks or executive PDFs',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildExportActionButton(
                  excel: true,
                  title: 'Export Excel',
                  subtitle: '.xlsx Workbook',
                  color: const Color(0xFF107C41),
                  icon: Icons.table_view_rounded,
                  onTap: onExportExcel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportActionButton(
                  excel: false,
                  title: 'Export PDF',
                  subtitle: 'Print Document',
                  color: const Color(0xFFDC2626),
                  icon: Icons.picture_as_pdf_rounded,
                  onTap: onExportPdf,
                ),
              ),
            ],
          ),
          if (availableYears.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.muted),
                const SizedBox(width: 6),
                const Text(
                  'Annual Reports:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final yr in availableYears)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.download, size: 13),
                              label: Text('$yr Report',
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onSelectYear(yr),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
