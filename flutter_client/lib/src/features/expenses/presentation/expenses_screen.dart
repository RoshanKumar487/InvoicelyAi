import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
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
                      currencySymbol: _companyCurrencySymbol,
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
    this.currencySymbol = '₹',
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySymbol = (expense.currencySymbol == r'$' || expense.currency == 'USD')
        ? (currencySymbol.isNotEmpty ? currencySymbol : '₹')
        : (expense.currencySymbol.isNotEmpty ? expense.currencySymbol : currencySymbol);
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
                    '$displaySymbol${expense.amount.toStringAsFixed(2)}',
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
                          'Tax $displaySymbol${expense.taxAmount.toStringAsFixed(2)}',
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
