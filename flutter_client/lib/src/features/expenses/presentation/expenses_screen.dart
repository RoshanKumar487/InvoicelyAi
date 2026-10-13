import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/table_export_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/expense.dart';
import '../data/expenses_repository.dart';
import '../data/receipt_ocr_scanner.dart';
import 'widgets/expense_editor_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    required this.repository,
    this.initialLocalSettings = const <String, Object?>{},
    super.key,
  });

  final ExpensesRepository repository;
  final Map<String, Object?> initialLocalSettings;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String get _companyCurrency =>
      widget.initialLocalSettings['defaultCurrency']?.toString().trim().isNotEmpty == true
          ? widget.initialLocalSettings['defaultCurrency']!.toString().trim().toUpperCase()
          : 'INR';

  String get _companyCurrencySymbol =>
      widget.initialLocalSettings['defaultCurrencySymbol']?.toString().trim().isNotEmpty == true
          ? widget.initialLocalSettings['defaultCurrencySymbol']!.toString().trim()
          : _currencySymbol(_companyCurrency);

  static const List<String> _categories = [
    'All',
    'Software & IT',
    'Office & Rent',
    'Travel & Transport',
    'Meals & Entertainment',
    'Marketing & Ads',
    'Hardware & Equipment',
    'General Business',
    'General',
  ];

  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<Expense> _expenses = const [];
  String _selectedCategory = 'All';
  String _statusFilter = 'All';
  bool _isLoading = true;
  bool _usingCachedData = false;
  bool _isScanningReceipt = false;
  String? _error;
  int _loadRequest = 0;
  DateTimeRange? _dateRange;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses({bool showProgress = true}) async {
    final request = ++_loadRequest;
    if (showProgress && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final expenses = await widget.repository.list(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _expenses = expenses;
        _usingCachedData = widget.repository.lastLoadUsedCache;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = 'Could not load expenses. Please try again.');
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Expense> get _visibleExpenses {
    final query = _searchController.text.trim().toLowerCase();
    return _expenses.where((expense) {
      if (_statusFilter == 'Paid' && expense.isDue) return false;
      if (_statusFilter == 'Due' && !expense.isDue) return false;
      if (_statusFilter == 'TaxDeductible' && !expense.taxDeductible) return false;

      if (_dateRange != null) {
        final d = DateTime.tryParse(expense.date);
        if (d != null) {
          if (d.isBefore(_dateRange!.start) ||
              d.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      if (query.isNotEmpty) {
        return expense.title.toLowerCase().contains(query) ||
            expense.vendor.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query);
      }
      return true;
    }).toList(growable: false);
  }

  Future<void> _sendEmailAlert(Expense expense) async {
    final subject = Uri.encodeComponent('Payment Due Alert: ${expense.title}');
    final body = Uri.encodeComponent(
      'Dear Accounts / Vendor,\n\nThis is a notification regarding the pending expense liability for "${expense.title}".\nAmount: ${expense.currencySymbol}${expense.amount.toStringAsFixed(2)}\nDue Date: ${expense.dueDate.isNotEmpty ? expense.dueDate : "Immediate"}\nVendor: ${expense.vendor}\n\nPlease arrange settlement.\n\nThank you,\nFinance Department',
    );
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) _showMessage('Opening email client for ${expense.title}...');
    }
  }

  Future<void> _sendWhatsAppAlert(Expense expense) async {
    final text = Uri.encodeComponent(
      'Hello, notification regarding pending expense payment for "${expense.title}" of amount ${expense.currencySymbol}${expense.amount.toStringAsFixed(2)} due on ${expense.dueDate.isNotEmpty ? expense.dueDate : "immediate"}. Please arrange settlement.',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _showMessage('Could not open WhatsApp.');
    }
  }

  Future<void> _updateExpenseStatus(Expense expense, String newStatus) async {
    try {
      final updated = Expense(
        id: expense.id,
        companyId: expense.companyId,
        createdByUserId: expense.createdByUserId,
        createdByUserName: expense.createdByUserName,
        title: expense.title,
        category: expense.category,
        amount: expense.amount,
        currency: expense.currency,
        currencySymbol: expense.currencySymbol,
        date: expense.date,
        vendor: expense.vendor,
        paymentMethod: expense.paymentMethod,
        taxDeductible: expense.taxDeductible,
        taxAmount: expense.taxAmount,
        receiptImageUri: expense.receiptImageUri,
        notes: expense.notes,
        status: newStatus,
        dueDate: expense.dueDate,
      );
      await widget.repository.update(updated);
      if (mounted) {
        _showMessage('Expense status updated to $newStatus!');
        await _loadExpenses(showProgress: false);
      }
    } catch (e) {
      if (mounted) _showMessage('Could not update status: $e');
    }
  }

  Future<void> _markExpensePaid(Expense expense) => _updateExpenseStatus(expense, 'Paid');

  Future<void> _createExpense() async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) => ExpenseEditorDialog(
        defaultCurrency: _companyCurrency,
        defaultCurrencySymbol: _companyCurrencySymbol,
      ),
    );
    if (expense == null || !mounted) return;
    try {
      await widget.repository.create(expense);
      if (!mounted) return;
      _showMessage('Expense saved.');
      await _loadExpenses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not save expense. Please try again.');
    }
  }

  Future<void> _scanReceipt() async {
    if (_isScanningReceipt) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not open the camera or gallery: $error');
      }
      return;
    }
    if (image == null || !mounted) return;

    final mimeType = _receiptMimeType(image.name);
    if (mimeType == null) {
      _showMessage('Choose a JPEG, PNG, or WebP receipt image.');
      return;
    }

    setState(() {
      _isScanningReceipt = true;
      _error = null;
    });
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('The selected image is empty.');
      }
      Expense scannedDraft;
      try {
        final ocr = await ReceiptOcrScanner.scan(imagePath: image.path);
        scannedDraft = ocr.toExpenseDraft(receiptImageUri: image.path);
      } catch (_) {
        // Fall back to server AI scanning if on-device ML kit is unavailable
        try {
          final encoded = base64Encode(bytes);
          if (encoded.length <= 8000000) {
            final draft = await widget.repository.scanReceipt(
              imageBase64: encoded,
              mimeType: mimeType,
            );
            scannedDraft = Expense(
              id: draft.id,
              companyId: draft.companyId,
              createdByUserId: draft.createdByUserId,
              createdByUserName: draft.createdByUserName,
              title: draft.title,
              category: draft.category,
              amount: draft.amount,
              currency: draft.currency,
              currencySymbol: draft.currencySymbol,
              date: draft.date,
              vendor: draft.vendor,
              paymentMethod: draft.paymentMethod,
              taxDeductible: draft.taxDeductible,
              taxAmount: draft.taxAmount,
              receiptImageUri: image.path,
              notes: draft.notes,
            );
          } else {
            scannedDraft = Expense(
              title: 'Receipt Expense',
              currency: 'INR',
              currencySymbol: '₹',
              date: _dateFor(DateTime.now()),
              receiptImageUri: image.path,
            );
          }
        } catch (_) {
          scannedDraft = Expense(
            title: 'Receipt Expense',
            currency: 'INR',
            currencySymbol: '₹',
            date: _dateFor(DateTime.now()),
            receiptImageUri: image.path,
          );
        }
      }

      if (!mounted) return;
      final confirmedDraft = await showDialog<Expense>(
        context: context,
        builder: (context) => ExpenseEditorDialog(
          initialValues: scannedDraft,
          receiptImageBytes: bytes,
          defaultCurrency: _companyCurrency,
          defaultCurrencySymbol: _companyCurrencySymbol,
        ),
      );
      if (confirmedDraft == null || !mounted) return;
      await widget.repository.create(confirmedDraft);
      if (!mounted) return;
      _showMessage('Expense saved successfully!');
      await _loadExpenses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (e) {
      if (mounted) {
        _showMessage('Receipt scan error: $e');
      }
    } finally {
      if (mounted) setState(() => _isScanningReceipt = false);
    }
  }

  String? _receiptMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await showDialog<Expense>(
      context: context,
      builder: (context) => ExpenseEditorDialog(
        expense: expense,
        defaultCurrency: _companyCurrency,
        defaultCurrencySymbol: _companyCurrencySymbol,
      ),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.repository.update(updated);
      if (!mounted) return;
      _showMessage('Expense updated.');
      await _loadExpenses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not update expense. Please try again.');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final id = expense.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete “${expense.title}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.delete(id);
      if (!mounted) return;
      _showMessage('Expense deleted.');
      await _loadExpenses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not delete expense. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visibleExpenses = _visibleExpenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Bills'),
        actions: [
          if (_isScanningReceipt)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Scan receipt',
              onPressed: _scanReceipt,
              icon: const Icon(Icons.document_scanner_outlined),
            ),
          IconButton(
            tooltip: 'Refresh expenses',
            onPressed: _isLoading || _isScanningReceipt ? null : _loadExpenses,
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
          return RefreshIndicator(
            onRefresh: _loadExpenses,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 100),
              children: [
                if (_usingCachedData) const OfflineCacheBanner(),
                if (_error != null) ...[
                  _ErrorPanel(message: _error!, onRetry: _loadExpenses),
                  const SizedBox(height: 14),
                ],
                if (_isLoading && _expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  EnterpriseDataView<Expense>(
                    items: visibleExpenses,
                    headerTitle: 'Expense Ledger',
                    metrics: _buildMetrics(_expenses),
                    dateRange: _dateRange,
                    onDateRangeChanged: (range) => setState(() => _dateRange = range),
                    onDownloadReport: () => _downloadExpensesReport(visibleExpenses),
                    searchController: _searchController,
                    searchHint: 'Search title, vendor or category...',
                    filterChips: _categories,
                    selectedFilterChip: _selectedCategory,
                    onFilterChipSelected: (cat) {
                      setState(() => _selectedCategory = cat);
                      _loadExpenses();
                    },
                    idGetter: (exp) => exp.id?.toString() ?? exp.title,
                    selectedIds: _selectedIds,
                    onToggleSelect: (id) => setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                    onSelectAll: (ids) => setState(() => _selectedIds.addAll(ids)),
                    onDeselectAll: () => setState(() => _selectedIds.clear()),
                    onRowTap: (exp) => _editExpense(exp),
                    batchActions: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.check_circle, size: 15),
                        label: const Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _batchMarkPaid,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                        tooltip: 'Export Selected',
                        onPressed: () {
                          final selected = _expenses.where((e) => _selectedIds.contains(e.id?.toString()) || _selectedIds.contains(e.title)).toList();
                          _downloadExpensesReport(selected);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        tooltip: 'Delete Selected',
                        onPressed: _batchDeleteExpenses,
                      ),
                    ],
                    groupBy: (exp) => exp.category.isNotEmpty ? exp.category : 'General',
                    groupLabelBuilder: (cat, items) {
                      final total = items.fold<double>(0.0, (acc, e) => acc + e.amount);
                      return '$cat (${items.length} ${items.length == 1 ? "expense" : "expenses"} · $_companyCurrencySymbol${total.toStringAsFixed(2)})';
                    },
                    emptyWidget: _EmptyPanel(
                      hasFilter: _searchController.text.trim().isNotEmpty ||
                          _selectedCategory != 'All' ||
                          _statusFilter != 'All',
                      onAdd: _createExpense,
                      onReset: () {
                        _searchController.clear();
                        setState(() {
                          _selectedCategory = 'All';
                          _statusFilter = 'All';
                        });
                        _loadExpenses();
                      },
                    ),
                    cardBuilder: (context, expense) => _ExpenseCard(
                      expense: expense,
                      currencySymbol: _companyCurrencySymbol,
                      onEdit: () => _editExpense(expense),
                      onDelete: () => _deleteExpense(expense),
                      onSendEmail: () => _sendEmailAlert(expense),
                      onSendWhatsApp: () => _sendWhatsAppAlert(expense),
                      onMarkPaid: () => _markExpensePaid(expense),
                    ),
                    columns: _expenseTableColumns(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<EnterpriseMetricCardItem> _buildMetrics(List<Expense> allExpenses) {
    final totalAmount = allExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);
    final paidExpenses = allExpenses.where((e) => !e.isDue).toList();
    final paidAmount = paidExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);
    final dueExpenses = allExpenses.where((e) => e.isDue).toList();
    final dueAmount = dueExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);
    final taxDeductibleExpenses = allExpenses.where((e) => e.taxDeductible).toList();
    final taxAmount = taxDeductibleExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);

    return [
      EnterpriseMetricCardItem(
        label: 'Total Expenses',
        value: '$_companyCurrencySymbol${totalAmount.toStringAsFixed(0)}',
        count: '${allExpenses.length} entries',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF1E3A8A),
        filterKey: 'All',
        isSelected: _statusFilter == 'All',
        onTap: () => setState(() => _statusFilter = 'All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Paid / Settled',
        value: '$_companyCurrencySymbol${paidAmount.toStringAsFixed(0)}',
        count: '${paidExpenses.length} paid',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF047857),
        filterKey: 'Paid',
        isSelected: _statusFilter == 'Paid',
        onTap: () => setState(() => _statusFilter = _statusFilter == 'Paid' ? 'All' : 'Paid'),
      ),
      EnterpriseMetricCardItem(
        label: 'Pending / Due',
        value: '$_companyCurrencySymbol${dueAmount.toStringAsFixed(0)}',
        count: '${dueExpenses.length} unpaid',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFD97706),
        filterKey: 'Due',
        isSelected: _statusFilter == 'Due',
        onTap: () => setState(() => _statusFilter = _statusFilter == 'Due' ? 'All' : 'Due'),
      ),
      EnterpriseMetricCardItem(
        label: 'Tax Deductible',
        value: '$_companyCurrencySymbol${taxAmount.toStringAsFixed(0)}',
        count: '${taxDeductibleExpenses.length} eligible',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF7C3AED),
        filterKey: 'TaxDeductible',
        isSelected: _statusFilter == 'TaxDeductible',
        onTap: () => setState(() => _statusFilter = _statusFilter == 'TaxDeductible' ? 'All' : 'TaxDeductible'),
      ),
    ];
  }

  void _downloadExpensesReport(List<Expense> list) {
    TableExportHelper.showExportMenu(
      context: context,
      title: 'Expenses Ledger',
      headers: ['Title', 'Vendor', 'Category', 'Date', 'Amount', 'Payment Method', 'Tax Deductible', 'Status'],
      rows: list.map((e) => [
        e.title,
        e.vendor,
        e.category,
        e.date,
        '${e.currencySymbol}${e.amount.toStringAsFixed(2)}',
        e.paymentMethod,
        e.taxDeductible ? 'Yes' : 'No',
        e.isDue ? 'Due' : 'Paid',
      ]).toList(),
    );
  }

  Future<void> _batchMarkPaid() async {
    final count = _selectedIds.length;
    for (final exp in _expenses) {
      final idStr = exp.id?.toString() ?? exp.title;
      if (_selectedIds.contains(idStr) && exp.isDue) {
        await _markExpensePaid(exp);
      }
    }
    setState(() => _selectedIds.clear());
    _showMessage('Marked $count expenses as Paid');
  }

  Future<void> _batchDeleteExpenses() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected expenses?'),
        content: Text('Delete $count selected expenses permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final exp in _expenses) {
      final idStr = exp.id?.toString() ?? exp.title;
      if (_selectedIds.contains(idStr) && exp.id != null) {
        await widget.repository.delete(exp.id!);
      }
    }
    setState(() => _selectedIds.clear());
    _showMessage('Deleted $count expenses');
    await _loadExpenses();
  }

  List<EnterpriseTableColumn<Expense>> _expenseTableColumns() {
    return [
      EnterpriseTableColumn<Expense>(
        title: 'Date',
        width: 110,
        sortKey: (exp) => exp.date,
        cellBuilder: (ctx, exp) => Text(exp.date, style: const TextStyle(fontSize: 12)),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Title / Vendor',
        width: 190,
        sortKey: (exp) => exp.title.toLowerCase(),
        cellBuilder: (ctx, exp) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (exp.vendor.isNotEmpty)
              Text(exp.vendor, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Category',
        width: 140,
        sortKey: (exp) => exp.category.toLowerCase(),
        cellBuilder: (ctx, exp) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(exp.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Amount',
        width: 120,
        alignRight: true,
        sortKey: (exp) => exp.amount,
        cellBuilder: (ctx, exp) => Text(
          '${exp.currencySymbol}${exp.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Payment Method',
        width: 130,
        sortKey: (exp) => exp.paymentMethod.toLowerCase(),
        cellBuilder: (ctx, exp) => Text(
          exp.paymentMethod.isNotEmpty ? exp.paymentMethod : '—',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Status',
        width: 120,
        sortKey: (exp) => exp.status,
        cellBuilder: (ctx, exp) => EnterpriseStatusDropdown(
          currentStatus: exp.status.isNotEmpty ? exp.status : (exp.isDue ? 'Due' : 'Paid'),
          options: const ['Paid', 'Due', 'Pending'],
          onChanged: (newStatus) => _updateExpenseStatus(exp, newStatus),
        ),
      ),
      EnterpriseTableColumn<Expense>(
        title: 'Actions',
        width: 140,
        cellBuilder: (ctx, exp) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exp.isDue)
              IconButton(
                tooltip: 'Mark as Paid',
                icon: const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                onPressed: () => _markExpensePaid(exp),
              ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editExpense(exp),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _deleteExpense(exp),
            ),
          ],
        ),
      ),
    ];
  }

}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.onSendEmail,
    this.onSendWhatsApp,
    this.onMarkPaid,
    this.currencySymbol = '₹',
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSendEmail;
  final VoidCallback? onSendWhatsApp;
  final VoidCallback? onMarkPaid;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySymbol = (expense.currencySymbol == r'$' || expense.currency == 'USD')
        ? (currencySymbol.isNotEmpty ? currencySymbol : '₹')
        : (expense.currencySymbol.isNotEmpty ? expense.currencySymbol : currencySymbol);
    final isDue = expense.isDue;
    final isPaid = expense.status.toUpperCase() == 'PAID';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 540;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isDue
                        ? Colors.red.shade50
                        : (isPaid
                            ? Colors.green.shade50
                            : theme.colorScheme.secondaryContainer),
                    foregroundColor: isDue
                        ? Colors.red.shade700
                        : (isPaid
                            ? Colors.green.shade700
                            : theme.colorScheme.onSecondaryContainer),
                    child: Icon(
                      isDue
                          ? Icons.warning_amber_rounded
                          : (isPaid
                              ? Icons.check_circle_outline
                              : Icons.receipt_long_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                expense.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(theme, isPaid, isDue),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expense.vendor.isEmpty
                              ? expense.category
                              : '${expense.vendor} · ${expense.category}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$displaySymbol${expense.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (expense.dueDate.isNotEmpty)
                        Text(
                          'Due: ${expense.dueDate}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDue ? Colors.red.shade700 : AppColors.muted,
                            fontWeight: isDue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      tooltip: 'Expense actions',
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            onEdit();
                          case 'delete':
                            onDelete();
                          case 'paid':
                            onMarkPaid?.call();
                          case 'email':
                            onSendEmail?.call();
                          case 'whatsapp':
                            onSendWhatsApp?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (!isPaid) ...[
                          const PopupMenuItem(
                              value: 'paid', child: Text('Mark as Paid')),
                          const PopupMenuItem(
                              value: 'email', child: Text('Send Email Alert')),
                          const PopupMenuItem(
                              value: 'whatsapp', child: Text('Send WhatsApp Alert')),
                        ],
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (expense.date.isNotEmpty)
                    _ExpenseDetail(
                      icon: Icons.calendar_today_outlined,
                      value: expense.date,
                    ),
                  _ExpenseDetail(
                    icon: Icons.credit_card_outlined,
                    value: expense.paymentMethod,
                  ),
                  _ExpenseDetail(
                    icon: expense.taxDeductible
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    value: expense.taxDeductible
                        ? 'Tax deductible'
                        : 'Not deductible',
                  ),
                  if (expense.taxAmount > 0)
                    _ExpenseDetail(
                      icon: Icons.request_quote_outlined,
                      value:
                          'Tax $displaySymbol${expense.taxAmount.toStringAsFixed(2)}',
                    ),
                ],
              ),
              if (expense.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(expense.notes, style: theme.textTheme.bodyMedium),
              ],
              if (isDue && !isPaid) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm_on, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Payment due! Send instant reminder:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onSendWhatsApp != null)
                        InkWell(
                          onTap: onSendWhatsApp,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'WhatsApp',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (onSendEmail != null)
                        InkWell(
                          onTap: onSendEmail,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mail_outline,
                                    size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Email',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (onMarkPaid != null)
                        InkWell(
                          onTap: onMarkPaid,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Mark Paid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (compact) ...[
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (!isPaid && onMarkPaid != null)
                      TextButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Paid'),
                      ),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isPaid, bool isDue) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    String label = expense.status.toUpperCase();
    if (label.isEmpty) label = 'PENDING';

    if (isPaid) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'PAID';
    } else if (isDue) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = 'DUE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExpenseDetail extends StatelessWidget {
  const _ExpenseDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

String _dateFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _currencySymbol(String currency) => switch (currency.toUpperCase()) {
      'INR' => '₹',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'CAD' => r'$',
      'AUD' => r'$',
      'JPY' => '¥',
      _ => currency.toUpperCase(),
    };

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.overdue),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.hasFilter,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasFilter;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            Icon(
              hasFilter ? Icons.filter_alt_off_outlined : Icons.receipt_long,
              size: 42,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter ? 'No matching expenses' : 'No expenses yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try another search or reset the category filter.'
                  : 'Add an expense to start tracking business spending.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (hasFilter)
              OutlinedButton(
                onPressed: onReset,
                child: const Text('Reset filters'),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
          ],
        ),
      );
}
