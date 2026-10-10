import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/expense.dart';
import '../data/expenses_repository.dart';
import '../data/receipt_ocr_scanner.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    required this.repository,
    super.key,
  });

  final ExpensesRepository repository;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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
  bool _isLoading = true;
  bool _usingCachedData = false;
  bool _isScanningReceipt = false;
  String? _error;
  int _loadRequest = 0;

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
    if (query.isEmpty) return _expenses;
    return _expenses
        .where(
          (expense) =>
              expense.title.toLowerCase().contains(query) ||
              expense.vendor.toLowerCase().contains(query) ||
              expense.category.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _createExpense() async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) => const _ExpenseEditorDialog(),
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
        builder: (context) => _ExpenseEditorDialog(
          initialValues: scannedDraft,
          receiptImageBytes: bytes,
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
      builder: (context) => _ExpenseEditorDialog(expense: expense),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: RefreshIndicator(
            onRefresh: _loadExpenses,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (_usingCachedData) const OfflineCacheBanner(),
                Text(
                  'Record business spending and keep tax details organized.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search title, vendor or category',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in _categories) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: category == _selectedCategory,
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _selectedCategory = category);
                              _loadExpenses();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_error != null) ...[
                  _ErrorPanel(message: _error!, onRetry: _loadExpenses),
                  const SizedBox(height: 14),
                ],
                if (_isLoading && _expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visibleExpenses.isEmpty && _error == null)
                  _EmptyPanel(
                    hasFilter: _searchController.text.trim().isNotEmpty ||
                        _selectedCategory != 'All',
                    onAdd: _createExpense,
                    onReset: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = 'All');
                      _loadExpenses();
                    },
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        '${visibleExpenses.length} ${visibleExpenses.length == 1 ? 'expense' : 'expenses'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final expense in visibleExpenses) ...[
                    _ExpenseCard(
                      expense: expense,
                      onEdit: () => _editExpense(expense),
                      onDelete: () => _deleteExpense(expense),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                  Text(
                    '${expense.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (!compact)
                    PopupMenuButton<String>(
                      tooltip: 'Expense actions',
                      onSelected: (action) =>
                          action == 'edit' ? onEdit() : onDelete(),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
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
                          'Tax ${expense.currencySymbol}${expense.taxAmount.toStringAsFixed(2)}',
                    ),
                ],
              ),
              if (expense.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(expense.notes, style: theme.textTheme.bodyMedium),
              ],
              if (compact) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
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

class _ExpenseEditorDialog extends StatefulWidget {
  const _ExpenseEditorDialog({
    this.expense,
    this.initialValues,
    this.receiptImageBytes,
  });

  final Expense? expense;
  final Expense? initialValues;
  final Uint8List? receiptImageBytes;

  @override
  State<_ExpenseEditorDialog> createState() => _ExpenseEditorDialogState();
}

class _ExpenseEditorDialogState extends State<_ExpenseEditorDialog> {
  static const List<String> _categories = [
    'Software & IT',
    'Office & Rent',
    'Travel & Transport',
    'Meals & Entertainment',
    'Marketing & Ads',
    'Hardware & Equipment',
    'General Business',
    'General',
  ];
  static const List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Bank Transfer',
    'Other',
  ];

  List<String> get _categoryOptions {
    final currentCategory = (widget.expense ?? widget.initialValues)?.category;
    if (currentCategory == null || _categories.contains(currentCategory)) {
      return _categories;
    }
    return [..._categories, currentCategory];
  }

  List<String> get _paymentMethodOptions {
    final currentMethod =
        (widget.expense ?? widget.initialValues)?.paymentMethod;
    if (currentMethod == null || _paymentMethods.contains(currentMethod)) {
      return _paymentMethods;
    }
    return [..._paymentMethods, currentMethod];
  }

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _vendor;
  late final TextEditingController _amount;
  late final TextEditingController _taxAmount;
  late final TextEditingController _date;
  late final TextEditingController _notes;
  late final TextEditingController _currency;
  late String _category;
  late String _paymentMethod;
  late bool _taxDeductible;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense ?? widget.initialValues;
    _title = TextEditingController(text: expense?.title ?? '');
    _vendor = TextEditingController(text: expense?.vendor ?? '');
    _amount = TextEditingController(
      text: expense == null || expense.amount <= 0 ? '' : expense.amount.toStringAsFixed(2),
    );
    _taxAmount = TextEditingController(
      text: expense == null || expense.taxAmount <= 0 ? '' : expense.taxAmount.toStringAsFixed(2),
    );
    _date = TextEditingController(
      text: expense?.date.isNotEmpty == true
          ? expense!.date
          : _dateFor(DateTime.now()),
    );
    _notes = TextEditingController(text: expense?.notes ?? '');
    _currency = TextEditingController(
      text: expense?.currency.isNotEmpty == true ? expense!.currency : 'INR',
    );
    _category =
        expense?.category.isNotEmpty == true ? expense!.category : 'General Business';
    _paymentMethod = expense?.paymentMethod.isNotEmpty == true
        ? expense!.paymentMethod
        : 'Credit Card';
    _taxDeductible = expense?.taxDeductible ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _vendor.dispose();
    _amount.dispose();
    _taxAmount.dispose();
    _date.dispose();
    _notes.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = DateTime.tryParse(_date.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) _date.text = _dateFor(date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final previous = widget.expense ?? widget.initialValues;
    final symbol = _currencySymbol(_currency.text.trim());
    Navigator.pop(
      context,
      Expense(
        id: previous?.id,
        companyId: previous?.companyId,
        createdByUserId: previous?.createdByUserId,
        createdByUserName: previous?.createdByUserName,
        title: _title.text.trim(),
        category: _category,
        amount: double.parse(_amount.text.trim()),
        currency: _currency.text.trim().toUpperCase(),
        currencySymbol: symbol,
        date: _date.text.trim(),
        vendor: _vendor.text.trim(),
        paymentMethod: _paymentMethod,
        taxDeductible: _taxDeductible,
        taxAmount: double.tryParse(_taxAmount.text.trim()) ?? 0,
        receiptImageUri: previous?.receiptImageUri,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.expense != null;
    final isScanned = widget.receiptImageBytes != null || widget.initialValues?.receiptImageUri != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isScanned ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  child: Icon(
                    isScanned ? Icons.document_scanner_rounded : Icons.receipt_long_rounded,
                    size: 18,
                    color: isScanned ? const Color(0xFF2563EB) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        editing
                            ? 'Edit Expense'
                            : (isScanned ? 'Review Scanned Expense' : 'Add New Expense'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isScanned
                            ? 'Extracted via ML Kit OCR • Verify & Save'
                            : 'Enter expense information',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // RECEIPT PREVIEW (IF ATTACHED)
                if (widget.receiptImageBytes != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            widget.receiptImageBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Receipt Attached & Scanned',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Merchant, amount, tax & date extracted. You can review or edit below.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. AMOUNT & CURRENCY CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _amount,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Total Amount *',
                                prefixText: '${_currencySymbol(_currency.text.trim())} ',
                                prefixStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                                hintText: '0.00',
                                isDense: true,
                              ),
                              validator: _validAmount,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: ['INR', 'USD', 'EUR', 'GBP'].contains(_currency.text.toUpperCase())
                                  ? _currency.text.toUpperCase()
                                  : 'INR',
                              decoration: const InputDecoration(labelText: 'Currency', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                                DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _currency.text = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _taxAmount,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Tax / GST Amount',
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.percent_rounded, size: 16),
                                isDense: true,
                              ),
                              validator: _validOptionalAmount,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _taxDeductible,
                                  onChanged: (val) => setState(() => _taxDeductible = val ?? true),
                                ),
                                const Expanded(
                                  child: Text('Tax Deductible', style: TextStyle(fontSize: 11.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. VENDOR & DESCRIPTION
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Expense Description *',
                    hintText: 'e.g. Flight to Mumbai, Office Lunch, Server Renewal',
                    prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vendor,
                  decoration: const InputDecoration(
                    labelText: 'Vendor / Merchant Name',
                    hintText: 'e.g. Starbucks, Uber, Amazon, HP India',
                    prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. CATEGORY & PAYMENT METHOD
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 18),
                        ),
                        items: [
                          for (final category in _categoryOptions)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category, style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payment_rounded, size: 18),
                        ),
                        items: [
                          for (final method in _paymentMethodOptions)
                            DropdownMenuItem(
                              value: method,
                              child: Text(method, style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _paymentMethod = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. DATE & NOTES
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  onTap: _chooseDate,
                  decoration: InputDecoration(
                    labelText: 'Expense Date',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    suffixIcon: IconButton(
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Purpose / Itemized Lines',
                    hintText: 'Add additional details or project reference...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(editing ? 'Save Changes' : 'Save Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Description is required' : null;

  String? _validAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || amount <= 0) return 'Enter an amount greater than 0';
    return null;
  }

  String? _validOptionalAmount(String? value) {
    final text = value?.trim() ?? '';
    final amount = text.isEmpty ? 0 : double.tryParse(text);
    if (amount == null || amount < 0) return 'Enter a valid tax amount';
    return null;
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
