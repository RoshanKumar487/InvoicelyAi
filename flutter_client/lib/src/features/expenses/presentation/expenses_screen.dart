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
import 'widgets/expense_card.dart';
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
      final encoded = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$encoded';
      Expense scannedDraft;
      try {
        final ocr = await ReceiptOcrScanner.scan(imagePath: image.path);
        scannedDraft = ocr.toExpenseDraft(receiptImageUri: dataUri);
      } catch (_) {
        // Fall back to server AI scanning if on-device ML kit is unavailable
        try {
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
              receiptImageUri: dataUri,
              notes: draft.notes,
            );
          } else {
            scannedDraft = Expense(
              title: 'Receipt Expense',
              currency: 'INR',
              currencySymbol: '₹',
              date: _dateFor(DateTime.now()),
              receiptImageUri: dataUri,
            );
          }
        } catch (_) {
          scannedDraft = Expense(
            title: 'Receipt Expense',
            currency: 'INR',
            currencySymbol: '₹',
            date: _dateFor(DateTime.now()),
            receiptImageUri: dataUri,
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
          const SizedBox(width: 16),
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
                else ...[
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
                    cardBuilder: (context, expense) => ExpenseCard(
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
        width: 165,
        cellBuilder: (ctx, exp) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exp.receiptImageUri != null && exp.receiptImageUri!.startsWith('data:'))
              IconButton(
                tooltip: 'View Uploaded Bill',
                icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF2563EB)),
                onPressed: () => _previewBill(exp),
              ),
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

  void _previewBill(Expense exp) {
    final uri = exp.receiptImageUri ?? '';
    if (!uri.startsWith('data:')) return;
    final commaIdx = uri.indexOf(',');
    if (commaIdx == -1) return;
    try {
      final bytes = base64Decode(uri.substring(commaIdx + 1));
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 740),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expense Bill: ${exp.title}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

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