import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/expense.dart';

class ExpenseEditorDialog extends StatefulWidget {
  const ExpenseEditorDialog({
    this.expense,
    this.initialValues,
    this.receiptImageBytes,
    this.defaultCurrency = 'INR',
    this.defaultCurrencySymbol = '₹',
    super.key,
  });

  final Expense? expense;
  final Expense? initialValues;
  final Uint8List? receiptImageBytes;
  final String defaultCurrency;
  final String defaultCurrencySymbol;

  @override
  State<ExpenseEditorDialog> createState() => _ExpenseEditorDialogState();
}

class _ExpenseEditorDialogState extends State<ExpenseEditorDialog> {
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
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _title;
  late final TextEditingController _vendor;
  late final TextEditingController _amount;
  late final TextEditingController _taxAmount;
  late final TextEditingController _date;
  late final TextEditingController _notes;
  late final TextEditingController _currency;
  late final TextEditingController _dueDate;
  late String _category;
  late String _paymentMethod;
  late String _status;
  late bool _taxDeductible;
  Uint8List? _attachedBillBytes;
  String? _receiptDataUri;

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
    _dueDate = TextEditingController(
      text: expense?.dueDate ?? '',
    );
    _notes = TextEditingController(text: expense?.notes ?? '');
    final initialCur = (expense != null && expense.currency.isNotEmpty && expense.currency != 'USD')
        ? expense.currency
        : widget.defaultCurrency;
    _currency = TextEditingController(
      text: initialCur,
    );
    _category =
        expense?.category.isNotEmpty == true ? expense!.category : 'General Business';
    _paymentMethod = expense?.paymentMethod.isNotEmpty == true
        ? expense!.paymentMethod
        : 'Credit Card';
    _status = expense?.status.isNotEmpty == true ? expense!.status : 'Paid';
    _taxDeductible = expense?.taxDeductible ?? true;

    _attachedBillBytes = widget.receiptImageBytes;
    _receiptDataUri = expense?.receiptImageUri;
    if (_attachedBillBytes != null &&
        (_receiptDataUri == null || !_receiptDataUri!.startsWith('data:'))) {
      _receiptDataUri = 'data:image/jpeg;base64,${base64Encode(_attachedBillBytes!)}';
    } else if (_attachedBillBytes == null &&
        _receiptDataUri != null &&
        _receiptDataUri!.startsWith('data:')) {
      final commaIdx = _receiptDataUri!.indexOf(',');
      if (commaIdx != -1) {
        try {
          _attachedBillBytes = base64Decode(_receiptDataUri!.substring(commaIdx + 1));
        } catch (_) {}
      }
    }
  }

  Future<void> _pickBillImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      final ext = file.name.toLowerCase();
      final mime = ext.endsWith('.png')
          ? 'image/png'
          : (ext.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      setState(() {
        _attachedBillBytes = bytes;
        _receiptDataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach expense bill: $error')),
        );
      }
    }
  }

  void _previewBillImage() {
    if (_attachedBillBytes == null) return;
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
                    const Expanded(
                      child: Text(
                        'Organization Expense Bill / Receipt',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                  child: Image.memory(_attachedBillBytes!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _vendor.dispose();
    _amount.dispose();
    _taxAmount.dispose();
    _date.dispose();
    _dueDate.dispose();
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

  Future<void> _chooseDueDate() async {
    final selected = DateTime.tryParse(_dueDate.text) ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) _dueDate.text = _dateFor(date);
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
        receiptImageUri: _receiptDataUri,
        notes: _notes.text.trim(),
        status: _status,
        dueDate: _dueDate.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.expense != null;
    final isScanned = _attachedBillBytes != null || (_receiptDataUri != null && _receiptDataUri!.isNotEmpty);

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
                            ? 'Organization bill attached • Saved with workspace'
                            : 'Enter expense information & attach bill',
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
                // RECEIPT / EXPENSE BILL ATTACHMENT (ORG-SCOPED)
                Container(
                  decoration: BoxDecoration(
                    color: _attachedBillBytes != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _attachedBillBytes != null ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      if (_attachedBillBytes != null)
                        GestureDetector(
                          onTap: _previewBillImage,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _attachedBillBytes!,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachedBillBytes != null
                                  ? 'Expense Bill / Receipt Attached'
                                  : 'Attach Expense Bill / Receipt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _attachedBillBytes != null
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _attachedBillBytes != null
                                  ? 'Stored with your organization workspace. Tap thumbnail to zoom.'
                                  : 'Upload bill image to store securely under your organization.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _attachedBillBytes != null
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_attachedBillBytes != null) ...[
                        IconButton(
                          onPressed: _previewBillImage,
                          tooltip: 'View Full Bill',
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF15803D)),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _attachedBillBytes = null;
                            _receiptDataUri = null;
                          }),
                          tooltip: 'Remove Bill',
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: _pickBillImage,
                        icon: Icon(
                          _attachedBillBytes != null ? Icons.sync_rounded : Icons.upload_file_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _attachedBillBytes != null ? 'Replace' : 'Upload Bill',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. EXPENSE TITLE & VENDOR
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Expense Description / Item *',
                    hintText: 'e.g. Server hosting, Security badges, Flight ticket',
                    prefixIcon: Icon(Icons.description_rounded, size: 18),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vendor,
                  decoration: const InputDecoration(
                    labelText: 'Vendor / Merchant / Store',
                    hintText: 'e.g. AWS, Uber, Staples, D-Mart',
                    prefixIcon: Icon(Icons.storefront_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. AMOUNT, CURRENCY & TAX ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount *',
                          prefixText: '${_currencySymbol(_currency.text.trim())} ',
                          prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                          prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                        ),
                        validator: _validAmount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _taxAmount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tax / GST (Opt.)',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.percent_rounded, size: 18),
                        ),
                        validator: _validOptionalAmount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _currency,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. CATEGORY & PAYMENT METHOD
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded, size: 18),
                        ),
                        items: [
                          for (final cat in _categoryOptions)
                            DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 13)),
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
                        isExpanded: true,
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

                // 4. DATE & STATUS ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.verified_outlined, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Paid', child: Text('Paid (Settled)')),
                          DropdownMenuItem(value: 'Due', child: Text('Due (Unpaid)')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending Approval')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                if (_status == 'Due' || _status == 'Pending') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dueDate,
                    readOnly: true,
                    onTap: _chooseDueDate,
                    decoration: InputDecoration(
                      labelText: 'Payment Due Date *',
                      hintText: 'Select when payment is due',
                      prefixIcon: const Icon(Icons.event_busy_rounded, size: 18, color: Color(0xFFDC2626)),
                      suffixIcon: IconButton(
                        onPressed: _chooseDueDate,
                        icon: const Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
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
