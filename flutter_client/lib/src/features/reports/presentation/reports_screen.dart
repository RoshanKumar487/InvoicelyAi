 import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/report_export.dart';
import '../data/report_repository.dart';

enum _ReportType {
  invoices('Invoices', Icons.receipt_long_outlined),
  expenses('Expenses', Icons.payments_outlined),
  clients('Clients', Icons.people_outline);

  const _ReportType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.apiClient,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback? onBack;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportRepository _repository;
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _exporting = false;
  bool _usingCachedData = false;
  String? _error;
  _ReportType _reportType = _ReportType.invoices;
  String _statusFilter = 'All statuses';
  String _creatorFilter = 'All creators';
  String _datePreset = 'All time';
  int? _selectedYear;
  DateTimeRange? _dateRange;
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _repository = ReportRepository(apiClient: widget.apiClient);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoices = await _repository.loadInvoices();
      final invoicesFromCache = widget.apiClient.lastGetUsedCache;
      final expenses = await _repository.loadExpenses();
      final expensesFromCache = widget.apiClient.lastGetUsedCache;
      final clients = await _repository.loadClients();
      final clientsFromCache = widget.apiClient.lastGetUsedCache;
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _expenses = expenses;
        _clients = clients;
        _usingCachedData =
            invoicesFromCache || expensesFromCache || clientsFromCache;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load reports: $error';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _activeRows => switch (_reportType) {
        _ReportType.invoices => _invoices,
        _ReportType.expenses => _expenses,
        _ReportType.clients => _clients,
      };

  List<String> get _creators {
    if (_reportType == _ReportType.clients) return const [];
    final names = _activeRows
        .map(_creatorName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    final years = <int>{currentYear, currentYear - 1};
    for (final row in [..._invoices, ..._expenses]) {
      final d = _recordDate(row);
      if (d != null && d.year >= 2000 && d.year <= currentYear + 5) {
        years.add(d.year);
      }
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_dateRange != null || _datePreset != 'All time') count++;
    if (_statusFilter != 'All statuses') count++;
    if (_creatorFilter != 'All creators') count++;
    return count;
  }

  List<Map<String, dynamic>> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _activeRows.where((row) {
      if (_reportType == _ReportType.invoices &&
          _statusFilter != 'All statuses' &&
          !_matchesStatus(row, _statusFilter)) {
        return false;
      }
      if (_creatorFilter != 'All creators' &&
          _creatorName(row) != _creatorFilter) {
        return false;
      }
      if (_dateRange != null) {
        final date = _recordDate(row);
        final range = _dateRange!;
        if (date == null ||
            date.isBefore(_dayStart(range.start)) ||
            date.isAfter(_dayEnd(range.end))) {
          return false;
        }
      }
      if (query.isNotEmpty &&
          !row.values.any(
            (value) => value?.toString().toLowerCase().contains(query) == true,
          )) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((a, b) {
        final dateA = _recordDate(a);
        final dateB = _recordDate(b);
        if (dateA == null) return dateB == null ? 0 : 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
  }

  // Scoped lists for KPI calculations
  List<Map<String, dynamic>> get _scopedInvoices {
    return _invoices.where((row) {
      if (_dateRange != null) {
        final date = _recordDate(row, _ReportType.invoices);
        if (date == null ||
            date.isBefore(_dayStart(_dateRange!.start)) ||
            date.isAfter(_dayEnd(_dateRange!.end))) {
          return false;
        }
      }
      if (_creatorFilter != 'All creators' &&
          _creatorName(row) != _creatorFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> get _scopedExpenses {
    return _expenses.where((row) {
      if (_dateRange != null) {
        final date = _recordDate(row, _ReportType.expenses);
        if (date == null ||
            date.isBefore(_dayStart(_dateRange!.start)) ||
            date.isAfter(_dayEnd(_dateRange!.end))) {
          return false;
        }
      }
      if (_creatorFilter != 'All creators' &&
          _creatorName(row) != _creatorFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  double get _totalInvoiced =>
      _scopedInvoices.fold<double>(0, (sum, inv) => sum + _invoiceTotal(inv));

  double get _cashCollected =>
      _scopedInvoices.fold<double>(0, (sum, inv) => sum + _number(inv['amountPaid']));

  double get _totalExpensesAmount =>
      _scopedExpenses.fold<double>(0, (sum, exp) => sum + _number(exp['amount']));

  double get _netCashflow => _cashCollected - _totalExpensesAmount;

  int get _paidInvoicesCount => _scopedInvoices
      .where((inv) => _statusLabel(inv).toLowerCase() == 'paid')
      .length;

  int get _pendingInvoicesCount => _scopedInvoices.where((inv) {
        final s = _statusLabel(inv).toLowerCase();
        return s == 'pending' || s == 'sent' || s == 'partially paid';
      }).length;

  int get _overdueInvoicesCount => _scopedInvoices
      .where((inv) => _statusLabel(inv).toLowerCase() == 'overdue')
      .length;

  int get _draftInvoicesCount => _scopedInvoices
      .where((inv) => _statusLabel(inv).toLowerCase() == 'draft')
      .length;

  double get _collectionRate =>
      _totalInvoiced > 0 ? (_cashCollected / _totalInvoiced).clamp(0.0, 1.0) : 0.0;

  String get _defaultCurrencySymbol {
    for (final inv in _invoices) {
      final sym = inv['currencySymbol']?.toString().trim();
      if (sym != null && sym.isNotEmpty) return sym;
      final code =
          inv['currencyCode']?.toString().trim() ?? inv['currency']?.toString().trim();
      if (code != null && code.isNotEmpty) return '$code ';
    }
    return '₹';
  }

  String _formatCurrency(double amount) {
    final symbol = _defaultCurrencySymbol;
    final isNeg = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];
    final buffer = StringBuffer();
    final len = whole.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
    }
    return '${isNeg ? '-' : ''}$symbol${buffer.toString()}.$dec';
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _datePreset = preset;
      switch (preset) {
        case 'All time':
          _dateRange = null;
          _selectedYear = null;
          break;
        case 'This month':
          final start = DateTime(now.year, now.month, 1);
          final nextMonth = (now.month == 12)
              ? DateTime(now.year + 1, 1, 1)
              : DateTime(now.year, now.month + 1, 1);
          final end = nextMonth.subtract(const Duration(days: 1));
          _dateRange = DateTimeRange(start: start, end: end);
          _selectedYear = now.year;
          break;
        case 'Last month':
          final year = now.month == 1 ? now.year - 1 : now.year;
          final month = now.month == 1 ? 12 : now.month - 1;
          final start = DateTime(year, month, 1);
          final nextMonth = (month == 12)
              ? DateTime(year + 1, 1, 1)
              : DateTime(year, month + 1, 1);
          final end = nextMonth.subtract(const Duration(days: 1));
          _dateRange = DateTimeRange(start: start, end: end);
          _selectedYear = year;
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
          _dateRange = DateTimeRange(start: start, end: end);
          _selectedYear = now.year;
          break;
        case 'This year':
          _dateRange = DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31),
          );
          _selectedYear = now.year;
          break;
        case 'Last year':
          final yr = now.year - 1;
          _dateRange = DateTimeRange(
            start: DateTime(yr, 1, 1),
            end: DateTime(yr, 12, 31),
          );
          _selectedYear = yr;
          break;
      }
    });
  }



  void _openFilterBottomSheet() {
    var tempPreset = _datePreset;
    var tempYear = _selectedYear;
    DateTimeRange? tempRange = _dateRange;
    var tempStatus = _statusFilter;
    var tempCreator = _creatorFilter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

            void updatePreset(String preset) {
              final now = DateTime.now();
              setModalState(() {
                tempPreset = preset;
                switch (preset) {
                  case 'All time':
                    tempRange = null;
                    tempYear = null;
                    break;
                  case 'This month':
                    final start = DateTime(now.year, now.month, 1);
                    final nextMonth = (now.month == 12)
                        ? DateTime(now.year + 1, 1, 1)
                        : DateTime(now.year, now.month + 1, 1);
                    final end = nextMonth.subtract(const Duration(days: 1));
                    tempRange = DateTimeRange(start: start, end: end);
                    tempYear = now.year;
                    break;
                  case 'Last month':
                    final year = now.month == 1 ? now.year - 1 : now.year;
                    final month = now.month == 1 ? 12 : now.month - 1;
                    final start = DateTime(year, month, 1);
                    final nextMonth = (month == 12)
                        ? DateTime(year + 1, 1, 1)
                        : DateTime(year, month + 1, 1);
                    final end = nextMonth.subtract(const Duration(days: 1));
                    tempRange = DateTimeRange(start: start, end: end);
                    tempYear = year;
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
                    tempRange = DateTimeRange(start: start, end: end);
                    tempYear = now.year;
                    break;
                  case 'This year':
                    tempRange = DateTimeRange(
                      start: DateTime(now.year, 1, 1),
                      end: DateTime(now.year, 12, 31),
                    );
                    tempYear = now.year;
                    break;
                  case 'Last year':
                    final yr = now.year - 1;
                    tempRange = DateTimeRange(
                      start: DateTime(yr, 1, 1),
                      end: DateTime(yr, 12, 31),
                    );
                    tempYear = yr;
                    break;
                }
              });
            }

            void updateYear(int year) {
              setModalState(() {
                if (tempYear == year && tempPreset == '$year') {
                  tempPreset = 'All time';
                  tempYear = null;
                  tempRange = null;
                } else {
                  tempYear = year;
                  tempPreset = '$year';
                  tempRange = DateTimeRange(
                    start: DateTime(year, 1, 1),
                    end: DateTime(year, 12, 31),
                  );
                }
              });
            }

            final matchCount = _activeRows.where((row) {
              if (_reportType == _ReportType.invoices &&
                  tempStatus != 'All statuses' &&
                  !_matchesStatus(row, tempStatus)) {
                return false;
              }
              if (tempCreator != 'All creators' &&
                  _creatorName(row) != tempCreator) {
                return false;
              }
              if (tempRange != null) {
                final date = _recordDate(row);
                if (date == null ||
                    date.isBefore(_dayStart(tempRange!.start)) ||
                    date.isAfter(_dayEnd(tempRange!.end))) {
                  return false;
                }
              }
              final query = _searchController.text.trim().toLowerCase();
              if (query.isNotEmpty &&
                  !row.values.any((v) =>
                      v?.toString().toLowerCase().contains(query) == true)) {
                return false;
              }
              return true;
            }).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: AppColors.primary),
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
                              setModalState(() {
                                tempPreset = 'All time';
                                tempYear = null;
                                tempRange = null;
                                tempStatus = 'All statuses';
                                tempCreator = 'All creators';
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
                                  selected: tempPreset == preset,
                                  onSelected: (_) => updatePreset(preset),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _filterSectionHeader('CALENDAR YEAR'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final yr in _availableYears)
                                FilterChip(
                                  label: Text('$yr'),
                                  selected:
                                      tempYear == yr && tempPreset == '$yr',
                                  onSelected: (_) => updateYear(yr),
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
                                    tempRange == null
                                        ? 'No custom range selected'
                                        : '${_formatDate(tempRange!.start)}  →  ${_formatDate(tempRange!.end)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: tempRange == null
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
                                      initialDateRange: tempRange,
                                      helpText: 'Select Date Range',
                                      saveText: 'Apply',
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempRange = picked;
                                        tempPreset = 'Custom';
                                        tempYear = picked.start.year ==
                                                picked.end.year
                                            ? picked.start.year
                                            : null;
                                      });
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('Pick Range'),
                                ),
                                if (tempRange != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setModalState(() {
                                        tempRange = null;
                                        tempPreset = 'All time';
                                        tempYear = null;
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_statusOptions.length > 1) ...[
                            _filterSectionHeader('INVOICE STATUS'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final status in _statusOptions)
                                  FilterChip(
                                    label: Text(status),
                                    selected: tempStatus == status,
                                    onSelected: (_) {
                                      setModalState(() => tempStatus = status);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_reportType != _ReportType.clients &&
                              _creators.isNotEmpty) ...[
                            _filterSectionHeader('CREATED BY / STAFF'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('All creators'),
                                  selected: tempCreator == 'All creators',
                                  onSelected: (_) {
                                    setModalState(
                                        () => tempCreator = 'All creators');
                                  },
                                ),
                                for (final cr in _creators)
                                  FilterChip(
                                    label: Text(cr),
                                    selected: tempCreator == cr,
                                    onSelected: (_) {
                                      setModalState(() => tempCreator = cr);
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _clearFilters();
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
                                setState(() {
                                  _datePreset = tempPreset;
                                  _selectedYear = tempYear;
                                  _dateRange = tempRange;
                                  _statusFilter = tempStatus;
                                  _creatorFilter = tempCreator;
                                });
                                Navigator.pop(context);
                              },
                              child: Text('Apply ($matchCount records)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  Future<void> _export({
    required bool excel,
    DateTimeRange? customRange,
    int? customYear,
    bool allData = false,
    _ReportType? singleTab,
  }) async {
    setState(() => _exporting = true);
    try {
      DateTimeRange? effectiveRange = customRange;
      if (customYear != null) {
        effectiveRange = DateTimeRange(
          start: DateTime(customYear, 1, 1),
          end: DateTime(customYear, 12, 31, 23, 59, 59),
        );
      } else if (!allData && customRange == null) {
        effectiveRange = _dateRange;
      }

      final typesToExport = singleTab != null ? [singleTab] : _ReportType.values;
      final reports = typesToExport
          .map((type) => _buildExportTable(
                type,
                overrideRange: effectiveRange,
                ignoreNonDateFilters: allData || customYear != null,
              ))
          .toList(growable: false);

      final bytes = excel
          ? ReportExport.buildExcel(reports)
          : await ReportExport.buildPdf(reports);

      final date = DateTime.now().toIso8601String().substring(0, 10);
      final scopeLabel = allData
          ? 'all-time'
          : (customYear != null
              ? 'year-$customYear'
              : (effectiveRange != null ? 'filtered' : 'summary'));
      final filename =
          'invoicely-$scopeLabel-$date.${excel ? 'xlsx' : 'pdf'}';
      final file = XFile.fromData(
        bytes,
        mimeType: excel
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf',
        name: filename,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'Invoicely Reports ($scopeLabel)',
          text: 'Company financial and operations report ($scopeLabel)',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export reports: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportScopePicker({required bool excel}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                    _activeFilterCount > 0
                        ? 'Exports matching current filters and dates'
                        : 'Exports all current data',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _export(excel: excel);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive_rounded),
                  title: const Text('Export Full Company Database (All-Time)'),
                  subtitle: const Text(
                      'Exports complete invoices, expenses & clients history'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _export(excel: excel, allData: true);
                  },
                ),
                ListTile(
                  leading: Icon(_reportType.icon),
                  title: Text('Export Current Tab Only (${_reportType.label})'),
                  subtitle: Text('Exports only ${_reportType.label} records'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _export(excel: excel, singleTab: _reportType);
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

  void _showYearExportOptions(int year) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                  subtitle:
                      const Text('Multi-sheet workbook for accounting and audits'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _export(excel: true, customYear: year);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFDC2626)),
                  title: Text('Export $year to PDF (.pdf)'),
                  subtitle:
                      const Text('Print-ready executive annual financial report'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _export(excel: false, customYear: year);
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

  ExportReportTable _buildExportTable(
    _ReportType type, {
    DateTimeRange? overrideRange,
    bool ignoreNonDateFilters = false,
  }) {
    final source = switch (type) {
      _ReportType.invoices => _invoices,
      _ReportType.expenses => _expenses,
      _ReportType.clients => _clients,
    };
    final rows = source
        .where((row) => _matchesCurrentFilters(
              type,
              row,
              overrideRange: overrideRange,
              ignoreNonDateFilters: ignoreNonDateFilters,
            ))
        .toList(growable: false)
      ..sort((a, b) {
        final dateA = _recordDate(a, type);
        final dateB = _recordDate(b, type);
        if (dateA == null) return dateB == null ? 0 : 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
    return switch (type) {
      _ReportType.invoices => ExportReportTable(
          name: type.label,
          headers: const [
            'Invoice',
            'Client',
            'Issue date',
            'Due date',
            'Created by',
            'Total',
            'Paid',
            'Balance',
            'Status',
          ],
          rows: rows.map(_invoiceCells).toList(growable: false),
        ),
      _ReportType.expenses => ExportReportTable(
          name: type.label,
          headers: const [
            'Expense',
            'Vendor',
            'Category',
            'Date',
            'Created by',
            'Amount',
            'Tax',
          ],
          rows: rows.map(_expenseCells).toList(growable: false),
        ),
      _ReportType.clients => ExportReportTable(
          name: type.label,
          headers: const [
            'Client',
            'Company',
            'Email',
            'Phone',
            'Payment terms',
            'Added',
          ],
          rows: rows.map(_clientCells).toList(growable: false),
        ),
    };
  }

  bool _matchesCurrentFilters(
    _ReportType type,
    Map<String, dynamic> row, {
    DateTimeRange? overrideRange,
    bool ignoreNonDateFilters = false,
  }) {
    final range = overrideRange ?? _dateRange;
    if (range != null) {
      final date = _recordDate(row, type);
      if (date == null ||
          date.isBefore(_dayStart(range.start)) ||
          date.isAfter(_dayEnd(range.end))) {
        return false;
      }
    }
    if (ignoreNonDateFilters) {
      return true;
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty &&
        !row.values.any(
          (value) => value?.toString().toLowerCase().contains(query) == true,
        )) {
      return false;
    }
    if (type != _ReportType.clients &&
        _creatorFilter != 'All creators' &&
        _creatorName(row) != _creatorFilter) {
      return false;
    }
    if (type == _ReportType.invoices &&
        _statusFilter != 'All statuses' &&
        !_matchesStatus(row, _statusFilter)) {
      return false;
    }
    return true;
  }

  List<String> _invoiceCells(Map<String, dynamic> row) {
    final total = _invoiceTotal(row);
    final paid = _number(row['amountPaid']);
    return [
      _text(row['invoiceNumber'], fallback: 'Invoice'),
      _text(row['clientName']),
      _text(row['issueDate']),
      _text(row['dueDate']),
      _creatorName(row),
      _money(total, row),
      _money(paid, row),
      _money((total - paid).clamp(0, double.infinity).toDouble(), row),
      _statusLabel(row),
    ];
  }

  List<String> _expenseCells(Map<String, dynamic> row) => [
        _text(row['title'], fallback: 'Expense'),
        _text(row['vendor']),
        _text(row['category']),
        _text(row['date']),
        _creatorName(row),
        _money(_number(row['amount']), row),
        _money(_number(row['taxAmount']), row),
      ];

  List<String> _clientCells(Map<String, dynamic> row) => [
        _text(row['name'], fallback: 'Client'),
        _text(row['companyName']),
        _text(row['email']),
        _text(row['phone']),
        _text(row['defaultPaymentTerms']),
        _formatDate(_recordDate(row, _ReportType.clients)),
      ];

  void _changeReportType(_ReportType value) {
    setState(() {
      _reportType = value;
      _statusFilter = 'All statuses';
      _creatorFilter = 'All creators';
    });
  }

  List<String> get _statusOptions => switch (_reportType) {
        _ReportType.invoices => const [
            'All statuses',
            'Paid',
            'Due / overdue',
            'Draft',
            'Sent / pending',
            'Partially paid',
            'Cancelled',
          ],
        _ReportType.expenses => const ['All statuses'],
        _ReportType.clients => const ['All statuses'],
      };

  String _groupName(Map<String, dynamic> row) => switch (_reportType) {
        _ReportType.invoices => _statusLabel(row),
        _ReportType.expenses => _text(row['category'], fallback: 'Other'),
        _ReportType.clients => 'Clients',
      };

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRows;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports'),
            Text(
              'Explore, track and download company data',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openFilterBottomSheet,
            tooltip: 'Filter & Date Range',
            icon: Badge(
              isLabelVisible: _activeFilterCount > 0,
              label: Text('$_activeFilterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<bool>(
              tooltip: 'Export reports',
              enabled: !_loading,
              onSelected: (excel) => _showExportScopePicker(excel: excel),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: true,
                  child: ListTile(
                    leading: Icon(Icons.table_view_outlined,
                        color: Color(0xFF107C41)),
                    title: Text('Export as Excel (.xlsx)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFFDC2626)),
                    title: Text('Export as PDF (.pdf)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              icon: const Icon(Icons.download_outlined),
            ),
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh data',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      if (_usingCachedData) ...[
                        const OfflineCacheBanner(),
                        const SizedBox(height: 12),
                      ],
                      _ReportTabs(
                        selected: _reportType,
                        counts: {
                          _ReportType.invoices: _invoices.length,
                          _ReportType.expenses: _expenses.length,
                          _ReportType.clients: _clients.length,
                        },
                        onSelected: _changeReportType,
                      ),
                      const SizedBox(height: 14),
                      _buildFinancialKpiCards(),
                      const SizedBox(height: 14),
                      _buildDownloadToolsCard(),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      hintText:
                                          'Search ${_reportType.label.toLowerCase()}...',
                                      isDense: true,
                                      suffixIcon: _searchController.text.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                              tooltip: 'Clear search',
                                              icon: const Icon(Icons.close),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _openFilterBottomSheet,
                                  tooltip: 'Filter & Date Range',
                                  icon: Badge(
                                    isLabelVisible: _activeFilterCount > 0,
                                    label: Text('$_activeFilterCount'),
                                    child: const Icon(Icons.tune_rounded),
                                  ),
                                ),
                              ],
                            ),
                            _buildActiveFiltersBar(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '${filtered.length} records',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  'Grouped by ${_reportType == _ReportType.invoices ? 'status' : _reportType == _ReportType.expenses ? 'category' : 'record type'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReportDataGrid(
                        reportType: _reportType,
                        rows: filtered,
                        groupName: _groupName,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActiveFiltersBar() {
    if (_activeFilterCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_dateRange != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.date_range, size: 14),
                  label: Text(
                    _datePreset != 'Custom' && _datePreset != 'All time'
                        ? _datePreset
                        : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: () => _applyDatePreset('All time'),
                ),
              ),
            if (_statusFilter != 'All statuses')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.flag_outlined, size: 14),
                  label: Text(
                    _statusFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: () =>
                      setState(() => _statusFilter = 'All statuses'),
                ),
              ),
            if (_creatorFilter != 'All creators')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.person_outline, size: 14),
                  label: Text(
                    _creatorFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: () =>
                      setState(() => _creatorFilter = 'All creators'),
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.close, size: 14),
              label: const Text('Clear all', style: TextStyle(fontSize: 11)),
              onPressed: _clearFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialKpiCards() {
    final net = _netCashflow;
    final netColor = net >= 0 ? AppColors.paid : AppColors.overdue;
    final rate = _collectionRate;
    final invoiced = _totalInvoiced;
    final paid = _cashCollected;
    final expenses = _totalExpensesAmount;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Net Cashflow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _datePreset,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(net),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: netColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      net >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: netColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      net >= 0 ? 'Surplus' : 'Deficit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Invoiced',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(invoiced),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cash Collected',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(paid),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.paid),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Expenses',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(expenses),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Rate: ${(rate * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
              ),
              Text(
                '$_paidInvoicesCount of ${_scopedInvoices.length} paid',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.paid),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusPill('Paid', _paidInvoicesCount, AppColors.paid),
              const SizedBox(width: 8),
              _buildStatusPill(
                  'Pending', _pendingInvoicesCount, AppColors.warning),
              const SizedBox(width: 8),
              _buildStatusPill(
                  'Overdue', _overdueInvoicesCount, AppColors.overdue),
              const SizedBox(width: 8),
              _buildStatusPill('Draft', _draftInvoicesCount, AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadToolsCard() {
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
                  onTap: () => _showExportScopePicker(excel: true),
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
                  onTap: () => _showExportScopePicker(excel: false),
                ),
              ),
            ],
          ),
          if (_availableYears.isNotEmpty) ...[
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
                        for (final yr in _availableYears)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.download, size: 13),
                              label: Text('$yr Report',
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _showYearExportOptions(yr),
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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _dateRange = null;
      _datePreset = 'All time';
      _selectedYear = null;
      _statusFilter = 'All statuses';
      _creatorFilter = 'All creators';
    });
  }

  bool _matchesStatus(Map<String, dynamic> row, String filter) {
    final status = _text(row['status']).toLowerCase().replaceAll('_', ' ');
    if (filter == 'Due / overdue') {
      return status == 'due' ||
          status == 'overdue' ||
          ((_isUnpaidStatus(status)) &&
              (_recordDateValue(row['dueDate'])?.isBefore(
                    _dayStart(DateTime.now()),
                  ) ??
                  false));
    }
    if (filter == 'Sent / pending') {
      return status == 'sent' || status == 'pending';
    }
    if (filter == 'Partially paid') {
      return status == 'partial' || status == 'partially paid';
    }
    return status == filter.toLowerCase();
  }

  bool _isUnpaidStatus(String status) =>
      status == 'sent' ||
      status == 'pending' ||
      status == 'partial' ||
      status == 'partially paid';

  DateTime? _recordDate(
    Map<String, dynamic> row, [
    _ReportType? type,
  ]) {
    final value = switch (type ?? _reportType) {
      _ReportType.invoices => row['issueDate'] ?? row['createdAt'],
      _ReportType.expenses => row['date'] ?? row['createdAt'],
      _ReportType.clients => row['createdAt'],
    };
    return _recordDateValue(value);
  }

  DateTime? _recordDateValue(Object? value) {
    if (value is num) {
      final milliseconds = value.toInt();
      if (milliseconds <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    if (value is String && value.trim().isNotEmpty) {
      final numeric = int.tryParse(value);
      if (numeric != null) return _recordDateValue(numeric);
      return DateTime.tryParse(value);
    }
    return null;
  }

  DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _dayEnd(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final _ReportType selected;
  final Map<_ReportType, int> counts;
  final ValueChanged<_ReportType> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            for (final type in _ReportType.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == _ReportType.clients ? 0 : 8,
                  ),
                  child: _ReportTab(
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

class _ReportTab extends StatelessWidget {
  const _ReportTab({
    required this.type,
    required this.count,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _ReportType type;
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

class _ReportDataGrid extends StatelessWidget {
  const _ReportDataGrid({
    required this.reportType,
    required this.rows,
    required this.groupName,
  });

  final _ReportType reportType;
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
      _ReportType.invoices => const [
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
      _ReportType.expenses => const [
          'EXPENSE',
          'VENDOR',
          'CATEGORY',
          'DATE',
          'CREATED BY',
          'AMOUNT',
          'TAX',
        ],
      _ReportType.clients => const [
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
                      color: _groupColor(entry.key),
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
    _ReportType type,
    Map<String, dynamic> row,
  ) =>
      switch (type) {
        _ReportType.invoices => _invoiceCells(row),
        _ReportType.expenses => _expenseCells(row),
        _ReportType.clients => _clientCells(row),
      };

  List<String> _invoiceCells(Map<String, dynamic> row) {
    final total = _invoiceTotal(row);
    final paid = _number(row['amountPaid']);
    return [
      _text(row['invoiceNumber'], fallback: 'Invoice'),
      _text(row['clientName']),
      _text(row['issueDate']),
      _text(row['dueDate']),
      _creatorName(row),
      _money(total, row),
      _money(paid, row),
      _money((total - paid).clamp(0, double.infinity).toDouble(), row),
      _statusLabel(row),
    ];
  }

  List<String> _expenseCells(Map<String, dynamic> row) => [
        _text(row['title'], fallback: 'Expense'),
        _text(row['vendor']),
        _text(row['category']),
        _text(row['date']),
        _creatorName(row),
        _money(_number(row['amount']), row),
        _money(_number(row['taxAmount']), row),
      ];

  List<String> _clientCells(Map<String, dynamic> row) => [
        _text(row['name'], fallback: 'Client'),
        _text(row['companyName']),
        _text(row['email']),
        _text(row['phone']),
        _text(row['defaultPaymentTerms']),
        _formatDate(_date(row['createdAt'])),
      ];
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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

Color _groupColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'paid' || normalized == 'partially paid') {
    return AppColors.paid;
  }
  if (normalized.contains('overdue') || normalized.contains('due')) {
    return AppColors.overdue;
  }
  if (normalized.contains('draft')) return AppColors.muted;
  if (normalized.contains('sent') || normalized.contains('pending')) {
    return AppColors.warning;
  }
  return AppColors.blue;
}

String _statusLabel(Map<String, dynamic> row) {
  final status = _text(row['status'], fallback: 'Unknown');
  final normalized = status.toLowerCase().replaceAll('_', ' ');
  if (normalized == 'paid' ||
      normalized == 'overdue' ||
      normalized == 'draft' ||
      normalized == 'cancelled') {
    return status;
  }
  final dueDate = _date(row['dueDate']);
  if (dueDate != null &&
      dueDate.isBefore(DateTime.now()) &&
      _number(row['amountPaid']) < _invoiceTotal(row)) {
    return 'Overdue';
  }
  return status;
}

String _creatorName(Map<String, dynamic> row) {
  for (final key in const [
    'createdByUserName',
    'creatorName',
    'createdByName',
    'createdBy',
  ]) {
    final value = row[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String _text(Object? value, {String fallback = '—'}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _invoiceTotal(Map<String, dynamic> invoice) {
  final explicit = invoice['total'] ?? invoice['grandTotal'];
  if (explicit != null) return _number(explicit);
  final items = invoice['itemsJson'];
  Object? decodedItems = items;
  if (items is String && items.isNotEmpty) {
    try {
      decodedItems = jsonDecode(items);
    } on FormatException {
      return 0;
    }
  }
  if (decodedItems is! List<Object?>) return 0;
  var subtotal = 0.0;
  var itemDiscounts = 0.0;
  for (final item in decodedItems.whereType<Map<String, dynamic>>()) {
    final base = _number(item['quantity'] ?? 1) * _number(item['unitPrice']);
    subtotal += base;
    itemDiscounts += base * _number(item['discountRate']) / 100;
  }
  final taxableBase = (subtotal -
          itemDiscounts -
          (subtotal - itemDiscounts) *
              _number(invoice['discountPercent']) /
              100 -
          _number(invoice['discountAmount']))
      .clamp(0, double.infinity)
      .toDouble();
  final taxRate = _number(invoice['taxRate']);
  final isTaxInclusive = invoice['isTaxInclusive'] == true;
  final tax = isTaxInclusive
      ? taxableBase - taxableBase / (1 + taxRate / 100)
      : taxableBase * taxRate / 100;
  return (taxableBase +
          (isTaxInclusive ? 0 : tax) +
          _number(invoice['shippingFee']) +
          _number(invoice['additionalCharges']) +
          _number(invoice['roundOff']))
      .clamp(0, double.infinity)
      .toDouble();
}

String _money(double amount, Map<String, dynamic> row) {
  final symbol = row['currencySymbol']?.toString() ?? '';
  final currency =
      row['currencyCode']?.toString() ?? row['currency']?.toString() ?? '';
  final prefix =
      symbol.isNotEmpty ? symbol : (currency.isNotEmpty ? '$currency ' : '');
  return '$prefix${amount.toStringAsFixed(2)}';
}

DateTime? _date(Object? value) {
  if (value is num) {
    final milliseconds = value.toInt();
    return milliseconds <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  if (value is String && value.isNotEmpty) {
    final numeric = int.tryParse(value);
    if (numeric != null) return _date(numeric);
    return DateTime.tryParse(value);
  }
  return null;
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
