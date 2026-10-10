import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/report_export.dart';
import '../data/report_repository.dart';
import 'widgets/report_data_views.dart';
import 'widgets/report_export_dialogs.dart';
import 'widgets/report_filter_bottom_sheet.dart';
import 'widgets/report_kpi_cards.dart';
import 'widgets/report_types.dart';

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
  ReportType _reportType = ReportType.invoices;
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
        ReportType.invoices => _invoices,
        ReportType.expenses => _expenses,
        ReportType.clients => _clients,
      };

  List<String> get _creators {
    if (_reportType == ReportType.clients) return const [];
    final names = _activeRows
        .map(creatorNameFromRow)
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
      if (_reportType == ReportType.invoices &&
          _statusFilter != 'All statuses' &&
          !_matchesStatus(row, _statusFilter)) {
        return false;
      }
      if (_creatorFilter != 'All creators' &&
          creatorNameFromRow(row) != _creatorFilter) {
        return false;
      }
      if (_dateRange != null) {
        final date = _recordDate(row);
        final range = _dateRange!;
        if (date == null ||
            date.isBefore(dayStart(range.start)) ||
            date.isAfter(dayEnd(range.end))) {
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

  List<Map<String, dynamic>> get _scopedInvoices {
    return _invoices.where((row) {
      if (_dateRange != null) {
        final date = _recordDate(row, ReportType.invoices);
        if (date == null ||
            date.isBefore(dayStart(_dateRange!.start)) ||
            date.isAfter(dayEnd(_dateRange!.end))) {
          return false;
        }
      }
      if (_creatorFilter != 'All creators' &&
          creatorNameFromRow(row) != _creatorFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> get _scopedExpenses {
    return _expenses.where((row) {
      if (_dateRange != null) {
        final date = _recordDate(row, ReportType.expenses);
        if (date == null ||
            date.isBefore(dayStart(_dateRange!.start)) ||
            date.isAfter(dayEnd(_dateRange!.end))) {
          return false;
        }
      }
      if (_creatorFilter != 'All creators' &&
          creatorNameFromRow(row) != _creatorFilter) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  double get _totalInvoiced =>
      _scopedInvoices.fold<double>(0, (sum, inv) => sum + calculateInvoiceTotal(inv));

  double get _cashCollected =>
      _scopedInvoices.fold<double>(0, (sum, inv) => sum + reportNumber(inv['amountPaid']));

  double get _totalExpensesAmount =>
      _scopedExpenses.fold<double>(0, (sum, exp) => sum + reportNumber(exp['amount']));

  double get _netCashflow => _cashCollected - _totalExpensesAmount;

  int get _paidInvoicesCount => _scopedInvoices
      .where((inv) => statusLabelFromRow(inv).toLowerCase() == 'paid')
      .length;

  int get _pendingInvoicesCount => _scopedInvoices.where((inv) {
        final s = statusLabelFromRow(inv).toLowerCase();
        return s == 'pending' || s == 'sent' || s == 'partially paid';
      }).length;

  int get _overdueInvoicesCount => _scopedInvoices
      .where((inv) => statusLabelFromRow(inv).toLowerCase() == 'overdue')
      .length;

  int get _draftInvoicesCount => _scopedInvoices
      .where((inv) => statusLabelFromRow(inv).toLowerCase() == 'draft')
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
    ReportFilterBottomSheet.show(
      context: context,
      initialPreset: _datePreset,
      initialYear: _selectedYear,
      initialRange: _dateRange,
      initialStatus: _statusFilter,
      initialCreator: _creatorFilter,
      availableYears: _availableYears,
      creators: _creators,
      statusOptions: _statusOptions,
      reportType: _reportType,
      activeRows: _activeRows,
      onApply: ({
        required String preset,
        required int? year,
        required DateTimeRange? range,
        required String status,
        required String creator,
      }) {
        setState(() {
          _datePreset = preset;
          _selectedYear = year;
          _dateRange = range;
          _statusFilter = status;
          _creatorFilter = creator;
        });
      },
      onReset: _clearFilters,
    );
  }

  Future<void> _export({
    required bool excel,
    DateTimeRange? customRange,
    int? customYear,
    bool allData = false,
    ReportType? singleTab,
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

      final typesToExport = singleTab != null ? [singleTab] : ReportType.values;
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
    showReportExportScopePicker(
      context: context,
      excel: excel,
      activeFilterCount: _activeFilterCount,
      reportType: _reportType,
      onExport: ({
        required bool excel,
        bool allData = false,
        ReportType? singleTab,
      }) {
        _export(excel: excel, allData: allData, singleTab: singleTab);
      },
    );
  }

  void _showYearExportOptions(int year) {
    showReportYearExportOptions(
      context: context,
      year: year,
      onExportYear: ({required bool excel, required int customYear}) {
        _export(excel: excel, customYear: customYear);
      },
    );
  }

  ExportReportTable _buildExportTable(
    ReportType type, {
    DateTimeRange? overrideRange,
    bool ignoreNonDateFilters = false,
  }) {
    final source = switch (type) {
      ReportType.invoices => _invoices,
      ReportType.expenses => _expenses,
      ReportType.clients => _clients,
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
      ReportType.invoices => ExportReportTable(
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
      ReportType.expenses => ExportReportTable(
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
      ReportType.clients => ExportReportTable(
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
    ReportType type,
    Map<String, dynamic> row, {
    DateTimeRange? overrideRange,
    bool ignoreNonDateFilters = false,
  }) {
    final range = overrideRange ?? _dateRange;
    if (range != null) {
      final date = _recordDate(row, type);
      if (date == null ||
          date.isBefore(dayStart(range.start)) ||
          date.isAfter(dayEnd(range.end))) {
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
    if (type != ReportType.clients &&
        _creatorFilter != 'All creators' &&
        creatorNameFromRow(row) != _creatorFilter) {
      return false;
    }
    if (type == ReportType.invoices &&
        _statusFilter != 'All statuses' &&
        !_matchesStatus(row, _statusFilter)) {
      return false;
    }
    return true;
  }

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
        formatReportDate(_recordDate(row, ReportType.clients)),
      ];

  void _changeReportType(ReportType value) {
    setState(() {
      _reportType = value;
      _statusFilter = 'All statuses';
      _creatorFilter = 'All creators';
    });
  }

  List<String> get _statusOptions => switch (_reportType) {
        ReportType.invoices => const [
            'All statuses',
            'Paid',
            'Due / overdue',
            'Draft',
            'Sent / pending',
            'Partially paid',
            'Cancelled',
          ],
        ReportType.expenses => const ['All statuses'],
        ReportType.clients => const ['All statuses'],
      };

  String _groupName(Map<String, dynamic> row) => switch (_reportType) {
        ReportType.invoices => statusLabelFromRow(row),
        ReportType.expenses => reportText(row['category'], fallback: 'Other'),
        ReportType.clients => 'Clients',
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
              ? ReportErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      if (_usingCachedData) ...[
                        const OfflineCacheBanner(),
                        const SizedBox(height: 12),
                      ],
                      ReportTabs(
                        selected: _reportType,
                        counts: {
                          ReportType.invoices: _invoices.length,
                          ReportType.expenses: _expenses.length,
                          ReportType.clients: _clients.length,
                        },
                        onSelected: _changeReportType,
                      ),
                      const SizedBox(height: 14),
                      ReportFinancialKpiCards(
                        netCashflow: _netCashflow,
                        collectionRate: _collectionRate,
                        totalInvoiced: _totalInvoiced,
                        cashCollected: _cashCollected,
                        totalExpenses: _totalExpensesAmount,
                        datePreset: _datePreset,
                        paidCount: _paidInvoicesCount,
                        scopedInvoicesCount: _scopedInvoices.length,
                        pendingCount: _pendingInvoicesCount,
                        overdueCount: _overdueInvoicesCount,
                        draftCount: _draftInvoicesCount,
                        formatCurrency: _formatCurrency,
                      ),
                      const SizedBox(height: 14),
                      ReportDownloadToolsCard(
                        availableYears: _availableYears,
                        onExportExcel: () => _showExportScopePicker(excel: true),
                        onExportPdf: () => _showExportScopePicker(excel: false),
                        onSelectYear: _showYearExportOptions,
                      ),
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
                            ReportActiveFiltersBar(
                              activeFilterCount: _activeFilterCount,
                              dateRange: _dateRange,
                              datePreset: _datePreset,
                              statusFilter: _statusFilter,
                              creatorFilter: _creatorFilter,
                              onClearDate: () => _applyDatePreset('All time'),
                              onClearStatus: () =>
                                  setState(() => _statusFilter = 'All statuses'),
                              onClearCreator: () =>
                                  setState(() => _creatorFilter = 'All creators'),
                              onClearAll: _clearFilters,
                            ),
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
                                  'Grouped by ${_reportType == ReportType.invoices ? 'status' : _reportType == ReportType.expenses ? 'category' : 'record type'}',
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
                      ReportDataGrid(
                        reportType: _reportType,
                        rows: filtered,
                        groupName: _groupName,
                      ),
                    ],
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
    final status = reportText(row['status']).toLowerCase().replaceAll('_', ' ');
    if (filter == 'Due / overdue') {
      return status == 'due' ||
          status == 'overdue' ||
          ((_isUnpaidStatus(status)) &&
              (parseRecordDateValue(row['dueDate'])?.isBefore(
                    dayStart(DateTime.now()),
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
    ReportType? type,
  ]) {
    final value = switch (type ?? _reportType) {
      ReportType.invoices => row['issueDate'] ?? row['createdAt'],
      ReportType.expenses => row['date'] ?? row['createdAt'],
      ReportType.clients => row['createdAt'],
    };
    return parseRecordDateValue(value);
  }
}
