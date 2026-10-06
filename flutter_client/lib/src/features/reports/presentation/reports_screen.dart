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

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
      helpText: 'Filter by date range',
      saveText: 'Apply',
    );
    if (!mounted) return;
    setState(() => _dateRange = range);
  }

  Future<void> _export({required bool excel}) async {
    setState(() => _exporting = true);
    try {
      final reports = _ReportType.values
          .map((type) => _buildExportTable(type))
          .toList(growable: false);
      final bytes = excel
          ? ReportExport.buildExcel(reports)
          : await ReportExport.buildPdf(reports);
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final filename = 'invoicely-reports-$date.${excel ? 'xlsx' : 'pdf'}';
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
          subject: 'Invoicely reports',
          text: 'Invoices, expenses and clients report',
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

  ExportReportTable _buildExportTable(_ReportType type) {
    final source = switch (type) {
      _ReportType.invoices => _invoices,
      _ReportType.expenses => _expenses,
      _ReportType.clients => _clients,
    };
    final rows = source
        .where((row) => _matchesCurrentFilters(type, row))
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
    Map<String, dynamic> row,
  ) {
    if (_dateRange != null) {
      final date = _recordDate(row, type);
      if (date == null ||
          date.isBefore(_dayStart(_dateRange!.start)) ||
          date.isAfter(_dayEnd(_dateRange!.end))) {
        return false;
      }
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
    final activeFilterCount = (_dateRange == null ? 0 : 1) +
        (_statusFilter == 'All statuses' ? 0 : 1) +
        (_creatorFilter == 'All creators' ? 0 : 1);
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
              'Explore and export your business data',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<bool>(
              tooltip: 'Export all reports',
              enabled: !_loading,
              onSelected: (excel) => _export(excel: excel),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: true,
                  child: ListTile(
                    leading: Icon(Icons.table_view_outlined),
                    title: Text('Export all as Excel'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Export all as PDF'),
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
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 620;
                                final search = TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText:
                                        'Search ${_reportType.label.toLowerCase()}',
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
                                );
                                final dateButton = OutlinedButton.icon(
                                  onPressed: _chooseDateRange,
                                  icon: const Icon(Icons.date_range_outlined),
                                  label: Text(
                                    _dateRange == null
                                        ? 'Date range'
                                        : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      search,
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(child: dateButton),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _clearFilters,
                                            tooltip: 'Clear filters',
                                            icon: Badge(
                                              isLabelVisible:
                                                  activeFilterCount > 0,
                                              label: Text('$activeFilterCount'),
                                              child: const Icon(
                                                Icons.filter_alt_off_outlined,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      _filterDropdowns(),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: search),
                                        const SizedBox(width: 10),
                                        dateButton,
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: _clearFilters,
                                          tooltip: 'Clear filters',
                                          icon: Badge(
                                            isLabelVisible:
                                                activeFilterCount > 0,
                                            label: Text('$activeFilterCount'),
                                            child: const Icon(
                                              Icons.filter_alt_off_outlined,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _filterDropdowns(),
                                  ],
                                );
                              },
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

  Widget _filterDropdowns() => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (_statusOptions.length > 1)
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Invoice status',
                  prefixIcon: Icon(Icons.flag_outlined),
                  isDense: true,
                ),
                items: [
                  for (final option in _statusOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _statusFilter = value);
                },
              ),
            ),
          if (_reportType != _ReportType.clients && _creators.isNotEmpty)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _creatorFilter,
                decoration: const InputDecoration(
                  labelText: 'Created by',
                  prefixIcon: Icon(Icons.person_outline),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'All creators',
                    child: Text('All creators'),
                  ),
                  for (final creator in _creators)
                    DropdownMenuItem(value: creator, child: Text(creator)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _creatorFilter = value);
                },
              ),
            ),
        ],
      );

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _dateRange = null;
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
