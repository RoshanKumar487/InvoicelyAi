import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../clients/data/client.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../invoices/data/invoice.dart';
import '../../invoices/data/invoice_pdf_export.dart';
import '../../invoices/data/invoice_repository.dart';
import '../../invoices/presentation/invoice_editor_screen.dart';
import '../../invoices/presentation/invoice_preview_screen.dart';
import '../data/report_export.dart';
import '../data/report_repository.dart';
import 'widgets/report_data_views.dart';
import 'widgets/report_filter_bottom_sheet.dart';
import 'widgets/report_kpi_cards.dart';
import 'widgets/report_types.dart';

enum ExportFormat { excel, pdf, csv }

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
  late final InvoiceRepository _invoiceRepository;
  late final ClientsRepository _clientsRepository;
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _exporting = false;
  bool _usingCachedData = false;
  String? _error;

  ReportType _reportType = ReportType.all;
  String _statusFilter = 'All statuses';
  String _creatorFilter = 'All creators';
  String _datePreset = 'All time';
  int? _selectedYear;
  DateTimeRange? _dateRange;

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _clients = [];

  final Set<String> _selectedIds = {};
  Invoice? _inlineEditingInvoice;
  Invoice? _inlinePreviewInvoice;

  @override
  void initState() {
    super.initState();
    _repository = ReportRepository(apiClient: widget.apiClient);
    _invoiceRepository = InvoiceRepository(apiClient: widget.apiClient);
    _clientsRepository = ClientsRepository(apiClient: widget.apiClient);
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
        ReportType.all => [..._invoices, ..._expenses, ..._clients],
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
      if (_statusFilter != 'All statuses' &&
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
    required ExportFormat format,
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

      final requestedType = singleTab ?? _reportType;
      final typesToExport = switch (requestedType) {
        ReportType.all => [ReportType.invoices, ReportType.expenses, ReportType.clients],
        _ => [requestedType],
      };

      final reports = typesToExport
          .map((type) => _buildExportTable(
                type,
                overrideRange: effectiveRange,
                ignoreNonDateFilters: allData || customYear != null,
                selectedOnlyIds: _selectedIds.isNotEmpty ? _selectedIds : null,
              ))
          .toList(growable: false);

      final bytes = switch (format) {
        ExportFormat.excel => ReportExport.buildExcel(reports),
        ExportFormat.pdf => await ReportExport.buildPdf(reports),
        ExportFormat.csv => ReportExport.buildCsv(reports),
      };

      final date = DateTime.now().toIso8601String().substring(0, 10);
      final selectionTag = _selectedIds.isNotEmpty ? 'selected' : (allData ? 'all-time' : 'filtered');
      final ext = switch (format) {
        ExportFormat.excel => 'xlsx',
        ExportFormat.pdf => 'pdf',
        ExportFormat.csv => 'csv',
      };
      final filename = 'invoicely-records-$selectionTag-$date.$ext';

      final mimeType = switch (format) {
        ExportFormat.excel =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ExportFormat.pdf => 'application/pdf',
        ExportFormat.csv => 'text/csv',
      };

      final file = XFile.fromData(
        bytes,
        mimeType: mimeType,
        name: filename,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'Invoicely Ledger Report ($selectionTag)',
          text: 'Export of company financial and operational records',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✓ Successfully exported $filename'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export reports: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showDownloadMenu() {
    final count = _selectedIds.length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.download_rounded, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  count > 0 ? 'Download $count Selected Records' : 'Download Report Records',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count > 0
                  ? 'Will export only the $count records you checked'
                  : 'Will export all current filtered records by default',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.table_view_rounded, color: Color(0xFF107C41)),
              title: const Text('Export as Excel Workbook (.xlsx)'),
              subtitle: const Text('Includes styled worksheets and formulas'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _export(format: ExportFormat.excel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626)),
              title: const Text('Export as PDF Document (.pdf)'),
              subtitle: const Text('Professional printable ledger format'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _export(format: ExportFormat.pdf);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7)),
              title: const Text('Export as CSV Spreadsheet (.csv)'),
              subtitle: const Text('Compatible with Google Sheets, Excel, & Accounting tools'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _export(format: ExportFormat.csv);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  ExportReportTable _buildExportTable(
    ReportType type, {
    DateTimeRange? overrideRange,
    bool ignoreNonDateFilters = false,
    Set<String>? selectedOnlyIds,
  }) {
    final source = switch (type) {
      ReportType.invoices => _invoices,
      ReportType.expenses => _expenses,
      ReportType.clients => _clients,
      ReportType.all => _activeRows,
    };

    final rows = source
        .where((row) {
          if (selectedOnlyIds != null &&
              !selectedOnlyIds.contains(rowRecordId(row))) {
            return false;
          }
          return _matchesCurrentFilters(
            type,
            row,
            overrideRange: overrideRange,
            ignoreNonDateFilters: ignoreNonDateFilters,
          );
        })
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
          name: 'Invoices',
          headers: const [
            'Invoice',
            'Company',
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
          name: 'Expenses',
          headers: const [
            'Expense',
            'Company',
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
          name: 'Clients',
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
      ReportType.all => ExportReportTable(
          name: 'General Ledger Records',
          headers: const [
            'Date',
            'Reference / Voucher',
            'Particulars / Account',
            'Record Type',
            'Debit (Dr)',
            'Credit (Cr)',
            'Net Value',
            'Status',
          ],
          rows: rows.map((r) {
            final isExp = rowRecordType(r) == 'EXPENSE';
            final isInv = rowRecordType(r) == 'INVOICE';
            final eff = rowEffectiveAmount(r);
            return [
              formatReportDate(_recordDate(r)),
              reportText(r['invoiceNumber'] ?? r['title'] ?? r['name']),
              companyNameFromRow(r),
              rowRecordType(r),
              isExp ? reportMoney(eff, r) : '—',
              isInv ? reportMoney(eff, r) : '—',
              '${isExp ? '-' : ''}${reportMoney(eff, r)}',
              statusLabelFromRow(r),
            ];
          }).toList(growable: false),
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
    if (_statusFilter != 'All statuses' &&
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
      companyNameFromRow(row),
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
        companyNameFromRow(row),
        reportText(row['vendor']),
        reportText(row['category']),
        reportText(row['date']),
        creatorNameFromRow(row),
        reportMoney(reportNumber(row['amount']), row),
        reportMoney(reportNumber(row['taxAmount']), row),
      ];

  List<String> _clientCells(Map<String, dynamic> row) => [
        reportText(row['name'], fallback: 'Client'),
        companyNameFromRow(row),
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
      _selectedIds.clear();
    });
  }

  List<String> get _statusOptions => switch (_reportType) {
        ReportType.all => const [
            'All statuses',
            'Active / Paid',
            'Pending / In Progress',
            'Overdue / Attention',
            'Draft',
            'Cancelled',
          ],
        ReportType.invoices => const [
            'All statuses',
            'Paid',
            'Due / overdue',
            'Draft',
            'Sent / pending',
            'Partially paid',
            'Cancelled',
          ],
        ReportType.expenses => const [
            'All statuses',
            'Paid',
            'Approved',
            'Pending',
            'Draft',
            'Rejected',
          ],
        ReportType.clients => const ['All statuses', 'Active', 'Inactive'],
      };

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _dateRange = null;
      _datePreset = 'All time';
      _selectedYear = null;
      _statusFilter = 'All statuses';
      _creatorFilter = 'All creators';
      _selectedIds.clear();
    });
  }

  bool _matchesStatus(Map<String, dynamic> row, String filter) {
    final status = reportText(row['status']).toLowerCase().replaceAll('_', ' ');
    if (filter == 'Active / Paid') {
      return status == 'active' || status == 'paid' || status == 'approved';
    }
    if (filter == 'Pending / In Progress') {
      return status == 'pending' || status == 'sent' || status == 'in progress';
    }
    if (filter == 'Overdue / Attention') {
      return status == 'overdue' || status == 'due' || status == 'inactive';
    }
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
      ReportType.all => row['issueDate'] ?? row['date'] ?? row['createdAt'],
    };
    return parseRecordDateValue(value);
  }

  // Row Action Handlers
  void _handleEditRow(Map<String, dynamic> row) {
    final type = rowRecordType(row);
    if (type == 'INVOICE') {
      try {
        final invoice = Invoice.fromJson(row);
        setState(() {
          _inlineEditingInvoice = invoice;
          _inlinePreviewInvoice = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open invoice editor: $e')),
        );
      }
    } else if (type == 'CLIENT') {
      try {
        final client = Client.fromJson(row);
        showDialog<Client>(
          context: context,
          builder: (ctx) => ClientEditorDialog(client: client),
        ).then((updated) async {
          if (updated != null && mounted) {
            try {
              await _clientsRepository.update(updated);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text('✓ Client updated successfully'),
                ),
              );
              _load();
            } catch (err) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update client: $err')),
                );
              }
            }
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open client editor: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viewing ${companyNameFromRow(row)} ($type)')),
      );
    }
  }

  Future<void> _createNewClient() async {
    final client = await showDialog<Client>(
      context: context,
      builder: (ctx) => const ClientEditorDialog(),
    );
    if (client == null || !mounted) return;
    try {
      await _clientsRepository.create(client);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('✓ Client created successfully'),
        ),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create client: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteRow(Map<String, dynamic> row) async {
    final type = rowRecordType(row);
    final label = reportText(row['invoiceNumber'] ?? row['title'] ?? row['name'], fallback: 'Record');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Are you sure you want to permanently delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final id = row['id'];
      if (id != null && id is num) {
        if (type == 'INVOICE') {
          await _invoiceRepository.deleteInvoice(id.toInt());
        } else if (type == 'CLIENT') {
          await _clientsRepository.delete(id.toInt());
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✓ $label deleted successfully'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting record: $e')),
        );
      }
    }
  }

  Future<void> _handleShareRow(Map<String, dynamic> row) async {
    final type = rowRecordType(row);
    if (type == 'INVOICE') {
      try {
        final invoice = Invoice.fromJson(row);
        final pdfBytes = await InvoicePdfExport.build(invoice);
        final file = XFile.fromData(
          pdfBytes,
          mimeType: 'application/pdf',
          name: 'invoice-${invoice.invoiceNumber}.pdf',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [file],
            subject: 'Invoice ${invoice.invoiceNumber}',
            text: 'Here is invoice ${invoice.invoiceNumber} for ${companyNameFromRow(row)}.',
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not share invoice: $e')),
          );
        }
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          subject: '$type Record: ${companyNameFromRow(row)}',
          text: '$type: ${companyNameFromRow(row)} - Status: ${statusLabelFromRow(row)}',
        ),
      );
    }
  }

  Future<void> _handleChangeStatus(Map<String, dynamic> row, String newStatus) async {
    final type = rowRecordType(row);
    try {
      final id = row['id'];
      if (id != null && id is num && type == 'INVOICE') {
        await _invoiceRepository.updateStatus(id.toInt(), newStatus);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✓ Status updated to $newStatus'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update status: $e')),
        );
      }
    }
  }

  void _handleViewDetails(Map<String, dynamic> row) {
    final type = rowRecordType(row);
    if (type == 'INVOICE') {
      try {
        final invoice = Invoice.fromJson(row);
        setState(() {
          _inlinePreviewInvoice = invoice;
          _inlineEditingInvoice = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open invoice preview: $e')),
        );
      }
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$type Details: ${companyNameFromRow(row)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${statusLabelFromRow(row)}'),
              const SizedBox(height: 6),
              Text('Region: ${rowRegion(row)}'),
              const SizedBox(height: 6),
              Text('Tier: ${rowTier(row)}'),
              const SizedBox(height: 6),
              Text('Assigned CIS: ${rowAssignedMember(row)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showCustomizeViewSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Customize Ledger View',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tailor table columns, density, and display preferences',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Divider(height: 20),
            SwitchListTile(
              value: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Company & Counterparty Avatar', style: TextStyle(fontSize: 13)),
              onChanged: (_) {},
            ),
            SwitchListTile(
              value: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Due Date & Timeline Columns', style: TextStyle(fontSize: 13)),
              onChanged: (_) {},
            ),
            SwitchListTile(
              value: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Monetary Balance Breakdown', style: TextStyle(fontSize: 13)),
              onChanged: (_) {},
            ),
            SwitchListTile(
              value: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Quick Actions Menu', style: TextStyle(fontSize: 13)),
              onChanged: (_) {},
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_inlineEditingInvoice != null) {
      return InvoiceEditorScreen(
        repository: _invoiceRepository,
        invoice: _inlineEditingInvoice,
        onCancel: () => setState(() => _inlineEditingInvoice = null),
        onSaved: (saved) {
          setState(() => _inlineEditingInvoice = null);
          _load();
        },
      );
    }

    if (_inlinePreviewInvoice != null) {
      return InvoicePreviewScreen(
        invoice: _inlinePreviewInvoice!,
        repository: _invoiceRepository,
        onBack: () => setState(() => _inlinePreviewInvoice = null),
        onEdit: (inv) {
          setState(() {
            _inlinePreviewInvoice = null;
            _inlineEditingInvoice = inv;
          });
        },
        onDeleted: () {
          setState(() => _inlinePreviewInvoice = null);
          _load();
        },
      );
    }

    final filtered = _filteredRows;
    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
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
            Text(
              'Customer Management & Ledger',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Records maintenance, table grid & multi-entity reports',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Filter Icon with badge
          IconButton(
            onPressed: _openFilterBottomSheet,
            tooltip: 'Filter Records',
            icon: Badge(
              isLabelVisible: _activeFilterCount > 0,
              label: Text('$_activeFilterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          // Download Report Icon on right header side!
          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _showDownloadMenu,
              tooltip: 'Download Report',
              icon: Badge(
                isLabelVisible: _selectedIds.isNotEmpty,
                label: Text('${_selectedIds.length}'),
                child: const Icon(Icons.download_rounded, color: Color(0xFF0284C7)),
              ),
            ),
          // Refresh Icon
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh data',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ReportErrorState(message: _error!, onRetry: _load)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 36),
                        children: [
                          if (_usingCachedData) ...[
                            const OfflineCacheBanner(),
                            const SizedBox(height: 12),
                          ],

                      // Top Scope Tabs (All Records, Invoices, Expenses, Clients)
                      ReportTabs(
                        selected: _reportType,
                        counts: {
                          ReportType.all: _invoices.length + _expenses.length + _clients.length,
                          ReportType.invoices: _invoices.length,
                          ReportType.expenses: _expenses.length,
                          ReportType.clients: _clients.length,
                        },
                        onSelected: _changeReportType,
                      ),
                      const SizedBox(height: 16),

                      // Metrics Strip (exactly styled as the top of user's image)
                      EnterpriseMetricSummaryStrip(
                        totalCount: switch (_reportType) {
                          ReportType.invoices => _scopedInvoices.length,
                          ReportType.expenses => _scopedExpenses.length,
                          ReportType.clients => _clients.length,
                          ReportType.all => _activeRows.length,
                        },
                        inProgressCount: switch (_reportType) {
                          ReportType.invoices => _pendingInvoicesCount,
                          ReportType.expenses => _scopedExpenses.where((e) => statusLabelFromRow(e).toLowerCase() == 'pending').length,
                          ReportType.clients => _clients.where((c) => statusLabelFromRow(c).toLowerCase() == 'active').length,
                          ReportType.all => _pendingInvoicesCount,
                        },
                        sentCount: switch (_reportType) {
                          ReportType.invoices => _scopedInvoices.where((i) => statusLabelFromRow(i).toLowerCase() == 'sent').length,
                          ReportType.expenses => _scopedExpenses.where((e) => statusLabelFromRow(e).toLowerCase() == 'approved').length,
                          ReportType.clients => _clients.where((c) => (c['email']?.toString() ?? '').isNotEmpty).length,
                          ReportType.all => _scopedInvoices.where((i) => statusLabelFromRow(i).toLowerCase() == 'sent').length,
                        },
                        pendingApprovalCount: switch (_reportType) {
                          ReportType.invoices => _overdueInvoicesCount > 0 ? _overdueInvoicesCount : _draftInvoicesCount,
                          ReportType.expenses => _scopedExpenses.where((e) => statusLabelFromRow(e).toLowerCase() == 'draft').length,
                          ReportType.clients => _clients.where((c) => statusLabelFromRow(c).toLowerCase() == 'inactive').length,
                          ReportType.all => _overdueInvoicesCount,
                        },
                        completedCount: switch (_reportType) {
                          ReportType.invoices => _paidInvoicesCount,
                          ReportType.expenses => _scopedExpenses.where((e) => statusLabelFromRow(e).toLowerCase() == 'paid').length,
                          ReportType.clients => _clients.where((c) => (c['companyName']?.toString() ?? '').isNotEmpty).length,
                          ReportType.all => _paidInvoicesCount,
                        },
                        cycleTimeLabel: switch (_reportType) {
                          ReportType.invoices => _formatCurrency(_totalInvoiced),
                          ReportType.expenses => _formatCurrency(_totalExpensesAmount),
                          ReportType.clients => '${_clients.length} Accounts',
                          ReportType.all => _formatCurrency(_netCashflow),
                        },
                        totalLabel: switch (_reportType) {
                          ReportType.invoices => 'Total Invoices',
                          ReportType.expenses => 'Total Expenses',
                          ReportType.clients => 'Total Clients',
                          ReportType.all => 'Total Records',
                        },
                        inProgressLabel: switch (_reportType) {
                          ReportType.invoices => 'Pending / Sent',
                          ReportType.expenses => 'Pending Review',
                          ReportType.clients => 'Active Clients',
                          ReportType.all => 'In Progress',
                        },
                        sentLabel: switch (_reportType) {
                          ReportType.invoices => 'Sent to Client',
                          ReportType.expenses => 'Approved',
                          ReportType.clients => 'With Email',
                          ReportType.all => 'Sent / Approved',
                        },
                        pendingApprovalLabel: switch (_reportType) {
                          ReportType.invoices => _overdueInvoicesCount > 0 ? 'Overdue' : 'Drafts',
                          ReportType.expenses => 'Drafts',
                          ReportType.clients => 'Inactive',
                          ReportType.all => 'Overdue / Alerts',
                        },
                        completedLabel: switch (_reportType) {
                          ReportType.invoices => 'Paid Invoices',
                          ReportType.expenses => 'Paid Expenses',
                          ReportType.clients => 'Verified Companies',
                          ReportType.all => 'Completed',
                        },
                        cycleTimeHeader: switch (_reportType) {
                          ReportType.invoices => 'Total Invoiced',
                          ReportType.expenses => 'Total Expenses',
                          ReportType.clients => 'Client Base',
                          ReportType.all => 'Net Cashflow',
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subheader Bar matching user's image exactly!
                      // "Show me All Invoices v  (refresh) (download)     (search all...)"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Show me ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _statusFilter,
                                  isDense: true,
                                  underline: const SizedBox.shrink(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                  items: _statusOptions
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s == 'All statuses' ? switch (_reportType) {
                                              ReportType.invoices => 'All Invoices',
                                              ReportType.expenses => 'All Expenses',
                                              ReportType.clients => 'All Clients',
                                              ReportType.all => 'All Records',
                                            } : s),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _statusFilter = val);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _load,
                                  tooltip: 'Refresh',
                                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: _showDownloadMenu,
                                  tooltip: 'Download Report',
                                  icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF64748B)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (_reportType == ReportType.clients) ...[
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: _createNewClient,
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                                    label: const Text('Add Client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Search bar on the right
                            SizedBox(
                              width: 260,
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Search all...',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 14),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0284C7)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tool section row (Customize View | Add/Change Filter | View Applied Filters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: _showCustomizeViewSheet,
                              icon: const Icon(Icons.settings_outlined, size: 15, color: Color(0xFF475569)),
                              label: const Text(
                                'Customize View',
                                style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: _openFilterBottomSheet,
                                  icon: const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF475569)),
                                  label: const Text(
                                    'Add/Change Filter',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openFilterBottomSheet,
                                  icon: const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF475569)),
                                  label: Text(
                                    'View Applied Filters ($_activeFilterCount)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Active Filter chips bar
                      ReportActiveFiltersBar(
                        activeFilterCount: _activeFilterCount,
                        dateRange: _dateRange,
                        datePreset: _datePreset,
                        statusFilter: _statusFilter,
                        creatorFilter: _creatorFilter,
                        onClearDate: () => _applyDatePreset('All time'),
                        onClearStatus: () => setState(() => _statusFilter = 'All statuses'),
                        onClearCreator: () => setState(() => _creatorFilter = 'All creators'),
                        onClearAll: _clearFilters,
                      ),
                      const SizedBox(height: 12),

                      // Enterprise Data Grid & Table with Row Grouping by Company Name & Actions!
                      ReportEnterpriseDataGrid(
                        reportType: _reportType,
                        rows: filtered,
                        selectedIds: _selectedIds,
                        initialIsGrouped: false, // Classical flat table view by default
                        pageSize: 20, // 20 items per page
                        formatCurrency: _formatCurrency,
                        onToggleSelect: (id) {
                          setState(() {
                            if (_selectedIds.contains(id)) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          });
                        },
                        onSelectAll: (ids) {
                          setState(() {
                            _selectedIds.addAll(ids);
                          });
                        },
                        onDeselectAll: () {
                          setState(() {
                            _selectedIds.clear();
                          });
                        },
                        onExportSelected: _showDownloadMenu,
                        onEditRow: _handleEditRow,
                        onDeleteRow: _handleDeleteRow,
                        onShareRow: _handleShareRow,
                        onChangeStatus: _handleChangeStatus,
                        onViewDetails: _handleViewDetails,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
