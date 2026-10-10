import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import 'report_types.dart';

class ReportFilterBottomSheet extends StatefulWidget {
  const ReportFilterBottomSheet({
    super.key,
    required this.initialPreset,
    required this.initialYear,
    required this.initialRange,
    required this.initialStatus,
    required this.initialCreator,
    required this.availableYears,
    required this.creators,
    required this.statusOptions,
    required this.reportType,
    required this.activeRows,
    required this.onApply,
    required this.onReset,
  });

  final String initialPreset;
  final int? initialYear;
  final DateTimeRange? initialRange;
  final String initialStatus;
  final String initialCreator;
  final List<int> availableYears;
  final List<String> creators;
  final List<String> statusOptions;
  final ReportType reportType;
  final List<Map<String, dynamic>> activeRows;

  final void Function({
    required String preset,
    required int? year,
    required DateTimeRange? range,
    required String status,
    required String creator,
  }) onApply;

  final VoidCallback onReset;

  static void show({
    required BuildContext context,
    required String initialPreset,
    required int? initialYear,
    required DateTimeRange? initialRange,
    required String initialStatus,
    required String initialCreator,
    required List<int> availableYears,
    required List<String> creators,
    required List<String> statusOptions,
    required ReportType reportType,
    required List<Map<String, dynamic>> activeRows,
    required void Function({
      required String preset,
      required int? year,
      required DateTimeRange? range,
      required String status,
      required String creator,
    }) onApply,
    required VoidCallback onReset,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportFilterBottomSheet(
        initialPreset: initialPreset,
        initialYear: initialYear,
        initialRange: initialRange,
        initialStatus: initialStatus,
        initialCreator: initialCreator,
        availableYears: availableYears,
        creators: creators,
        statusOptions: statusOptions,
        reportType: reportType,
        activeRows: activeRows,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<ReportFilterBottomSheet> createState() =>
      _ReportFilterBottomSheetState();
}

class _ReportFilterBottomSheetState extends State<ReportFilterBottomSheet> {
  late String _tempPreset;
  late int? _tempYear;
  DateTimeRange? _tempRange;
  late String _tempStatus;
  late String _tempCreator;

  @override
  void initState() {
    super.initState();
    _tempPreset = widget.initialPreset;
    _tempYear = widget.initialYear;
    _tempRange = widget.initialRange;
    _tempStatus = widget.initialStatus;
    _tempCreator = widget.initialCreator;
  }

  void _updatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _tempPreset = preset;
      switch (preset) {
        case 'All time':
          _tempRange = null;
          _tempYear = null;
          break;
        case 'This month':
          final start = DateTime(now.year, now.month, 1);
          final nextMonth = (now.month == 12)
              ? DateTime(now.year + 1, 1, 1)
              : DateTime(now.year, now.month + 1, 1);
          final end = nextMonth.subtract(const Duration(days: 1));
          _tempRange = DateTimeRange(start: start, end: end);
          _tempYear = now.year;
          break;
        case 'Last month':
          final year = now.month == 1 ? now.year - 1 : now.year;
          final month = now.month == 1 ? 12 : now.month - 1;
          final start = DateTime(year, month, 1);
          final nextMonth = (month == 12)
              ? DateTime(year + 1, 1, 1)
              : DateTime(year, month + 1, 1);
          final end = nextMonth.subtract(const Duration(days: 1));
          _tempRange = DateTimeRange(start: start, end: end);
          _tempYear = year;
          break;
        case 'This quarter':
          final q = ((now.month - 1) ~/ 3);
          final startMonth = q * 3 + 1;
          final endMonth = startMonth + 2;
          final start = DateTime(now.year, startMonth, 1);
          final nextMonth = (endMonth == 12)
              ? DateTime(now.year + 1, 1, 1)
              : DateTime(now.year, endMonth + 1, 1);
          final end = nextMonth.subtract(const Duration(days: 1));
          _tempRange = DateTimeRange(start: start, end: end);
          _tempYear = now.year;
          break;
        case 'This year':
          _tempRange = DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31),
          );
          _tempYear = now.year;
          break;
        case 'Last year':
          final yr = now.year - 1;
          _tempRange = DateTimeRange(
            start: DateTime(yr, 1, 1),
            end: DateTime(yr, 12, 31),
          );
          _tempYear = yr;
          break;
      }
    });
  }

  void _updateYear(int year) {
    setState(() {
      if (_tempYear == year && _tempPreset == '$year') {
        _tempPreset = 'All time';
        _tempYear = null;
        _tempRange = null;
      } else {
        _tempYear = year;
        _tempPreset = '$year';
        _tempRange = DateTimeRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
      }
    });
  }

  bool _matchesStatus(Map<String, dynamic> row, String filter) {
    final status = reportText(row['status']).toLowerCase().replaceAll('_', ' ');
    if (filter == 'Due / overdue') {
      final isUnpaid = status == 'sent' ||
          status == 'pending' ||
          status == 'partial' ||
          status == 'partially paid';
      final dueDate = parseRecordDateValue(row['dueDate']);
      return status == 'due' ||
          status == 'overdue' ||
          (isUnpaid && (dueDate?.isBefore(dayStart(DateTime.now())) ?? false));
    }
    if (filter == 'Sent / pending') {
      return status == 'sent' || status == 'pending';
    }
    if (filter == 'Partially paid') {
      return status == 'partial' || status == 'partially paid';
    }
    return status == filter.toLowerCase();
  }

  DateTime? _recordDate(Map<String, dynamic> row) {
    final value = switch (widget.reportType) {
      ReportType.invoices => row['issueDate'] ?? row['createdAt'],
      ReportType.expenses => row['date'] ?? row['createdAt'],
      ReportType.clients => row['createdAt'],
    };
    return parseRecordDateValue(value);
  }

  int get _matchCount => widget.activeRows.where((row) {
        if (widget.reportType == ReportType.invoices &&
            _tempStatus != 'All statuses' &&
            !_matchesStatus(row, _tempStatus)) {
          return false;
        }
        if (_tempCreator != 'All creators' &&
            creatorNameFromRow(row) != _tempCreator) {
          return false;
        }
        if (_tempRange != null) {
          final date = _recordDate(row);
          if (date == null ||
              date.isBefore(dayStart(_tempRange!.start)) ||
              date.isAfter(dayEnd(_tempRange!.end))) {
            return false;
          }
        }
        return true;
      }).length;

  Widget _filterSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filters & Date Range',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempPreset = 'All time';
                        _tempYear = null;
                        _tempRange = null;
                        _tempStatus = 'All statuses';
                        _tempCreator = 'All creators';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _filterSectionHeader('QUICK DATE RANGE'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in const [
                        'All time',
                        'This month',
                        'Last month',
                        'This quarter',
                        'This year',
                        'Last year',
                      ])
                        FilterChip(
                          label: Text(preset),
                          selected: _tempPreset == preset,
                          onSelected: (_) => _updatePreset(preset),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _filterSectionHeader('CALENDAR YEAR'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final yr in widget.availableYears)
                        FilterChip(
                          label: Text('$yr'),
                          selected: _tempYear == yr && _tempPreset == '$yr',
                          onSelected: (_) => _updateYear(yr),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _filterSectionHeader('CUSTOM CALENDAR RANGE'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tempRange == null
                                ? 'No custom range selected'
                                : '${formatReportDate(_tempRange!.start)}  →  ${formatReportDate(_tempRange!.end)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tempRange == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(now.year - 15),
                              lastDate: DateTime(now.year + 2),
                              initialDateRange: _tempRange,
                              helpText: 'Select Date Range',
                              saveText: 'Apply',
                            );
                            if (picked != null) {
                              setState(() {
                                _tempRange = picked;
                                _tempPreset = 'Custom';
                                _tempYear = null;
                              });
                            }
                          },
                          child: const Text('Pick Range'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.reportType == ReportType.invoices) ...[
                    _filterSectionHeader('INVOICE STATUS'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in widget.statusOptions)
                          FilterChip(
                            label: Text(status),
                            selected: _tempStatus == status,
                            onSelected: (_) {
                              setState(() => _tempStatus = status);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (widget.reportType != ReportType.clients &&
                      widget.creators.isNotEmpty) ...[
                    _filterSectionHeader('CREATED BY / STAFF'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All creators'),
                          selected: _tempCreator == 'All creators',
                          onSelected: (_) {
                            setState(() => _tempCreator = 'All creators');
                          },
                        ),
                        for (final cr in widget.creators)
                          FilterChip(
                            label: Text(cr),
                            selected: _tempCreator == cr,
                            onSelected: (_) {
                              setState(() => _tempCreator = cr);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onReset();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(
                          preset: _tempPreset,
                          year: _tempYear,
                          range: _tempRange,
                          status: _tempStatus,
                          creator: _tempCreator,
                        );
                        Navigator.pop(context);
                      },
                      child: Text('Apply ($_matchCount records)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
