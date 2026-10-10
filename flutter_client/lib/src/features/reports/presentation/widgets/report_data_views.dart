import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import 'report_types.dart';

class ReportTabs extends StatelessWidget {
  const ReportTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
    super.key,
  });

  final ReportType selected;
  final Map<ReportType, int> counts;
  final ValueChanged<ReportType> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            for (final type in ReportType.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == ReportType.clients ? 0 : 8,
                  ),
                  child: ReportTab(
                    type: type,
                    count: counts[type] ?? 0,
                    selected: selected == type,
                    compact: constraints.maxWidth < 380,
                    onTap: () => onSelected(type),
                  ),
                ),
              ),
          ],
        ),
      );
}

class ReportTab extends StatelessWidget {
  const ReportTab({
    required this.type,
    required this.count,
    required this.selected,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final ReportType type;
  final int count;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 18, color: color),
              if (!compact) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    type.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ReportActiveFiltersBar extends StatelessWidget {
  const ReportActiveFiltersBar({
    super.key,
    required this.activeFilterCount,
    required this.dateRange,
    required this.datePreset,
    required this.statusFilter,
    required this.creatorFilter,
    required this.onClearDate,
    required this.onClearStatus,
    required this.onClearCreator,
    required this.onClearAll,
  });

  final int activeFilterCount;
  final DateTimeRange? dateRange;
  final String datePreset;
  final String statusFilter;
  final String creatorFilter;
  final VoidCallback onClearDate;
  final VoidCallback onClearStatus;
  final VoidCallback onClearCreator;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (activeFilterCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.date_range, size: 14),
                  label: Text(
                    datePreset != 'Custom' && datePreset != 'All time'
                        ? datePreset
                        : '${formatReportDate(dateRange!.start)} - ${formatReportDate(dateRange!.end)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearDate,
                ),
              ),
            if (statusFilter != 'All statuses')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.flag_outlined, size: 14),
                  label: Text(
                    statusFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearStatus,
                ),
              ),
            if (creatorFilter != 'All creators')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.person_outline, size: 14),
                  label: Text(
                    creatorFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearCreator,
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.close, size: 14),
              label: const Text('Clear all', style: TextStyle(fontSize: 11)),
              onPressed: onClearAll,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportDataGrid extends StatelessWidget {
  const ReportDataGrid({
    super.key,
    required this.reportType,
    required this.rows,
    required this.groupName,
  });

  final ReportType reportType;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) groupName;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_outlined,
                  size: 34,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 8),
                Text(
                  'No ${reportType.label.toLowerCase()} match these filters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final headers = switch (reportType) {
      ReportType.invoices => const [
          'INVOICE',
          'CLIENT',
          'ISSUED',
          'DUE DATE',
          'CREATED BY',
          'TOTAL',
          'PAID',
          'BALANCE',
          'STATUS',
        ],
      ReportType.expenses => const [
          'EXPENSE',
          'VENDOR',
          'CATEGORY',
          'DATE',
          'CREATED BY',
          'AMOUNT',
          'TAX',
        ],
      ReportType.clients => const [
          'CLIENT',
          'COMPANY',
          'EMAIL',
          'PHONE',
          'PAYMENT TERMS',
          'ADDED',
        ],
    };
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(groupName(row), () => []).add(row);
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: groupColorForStatus(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${entry.value.length} ${entry.value.length == 1 ? 'record' : 'records'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                horizontalMargin: 16,
                columnSpacing: 18,
                headingTextStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                columns: [
                  for (final header in headers) DataColumn(label: Text(header)),
                ],
                rows: [
                  for (final row in entry.value)
                    DataRow(
                      cells: [
                        for (final cell in _rowCells(reportType, row))
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 210),
                              child: Text(
                                cell,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (entry.key != grouped.keys.last)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  List<String> _rowCells(
    ReportType type,
    Map<String, dynamic> row,
  ) =>
      switch (type) {
        ReportType.invoices => _invoiceCells(row),
        ReportType.expenses => _expenseCells(row),
        ReportType.clients => _clientCells(row),
      };

  List<String> _invoiceCells(Map<String, dynamic> row) {
    final total = calculateInvoiceTotal(row);
    final paid = reportNumber(row['amountPaid']);
    return [
      reportText(row['invoiceNumber'], fallback: 'Invoice'),
      reportText(row['clientName']),
      reportText(row['issueDate']),
      reportText(row['dueDate']),
      creatorNameFromRow(row),
      reportMoney(total, row),
      reportMoney(paid, row),
      reportMoney((total - paid).clamp(0, double.infinity).toDouble(), row),
      statusLabelFromRow(row),
    ];
  }

  List<String> _expenseCells(Map<String, dynamic> row) => [
        reportText(row['title'], fallback: 'Expense'),
        reportText(row['vendor']),
        reportText(row['category']),
        reportText(row['date']),
        creatorNameFromRow(row),
        reportMoney(reportNumber(row['amount']), row),
        reportMoney(reportNumber(row['taxAmount']), row),
      ];

  List<String> _clientCells(Map<String, dynamic> row) => [
        reportText(row['name'], fallback: 'Client'),
        reportText(row['companyName']),
        reportText(row['email']),
        reportText(row['phone']),
        reportText(row['defaultPaymentTerms']),
        formatReportDate(parseRecordDateValue(row['createdAt'])),
      ];
}

class ReportErrorState extends StatelessWidget {
  const ReportErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
