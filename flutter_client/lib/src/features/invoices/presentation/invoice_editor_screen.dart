import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../clients/data/client.dart';
import '../../clients/data/clients_repository.dart';
import '../../../theme/app_theme.dart';
import '../../templates/data/template_config.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';

class InvoiceEditorScreen extends StatefulWidget {
  const InvoiceEditorScreen({
    required this.repository,
    required this.onCancel,
    required this.onSaved,
    this.invoice,
    this.preferredTemplate,
    this.initialLocalSettings = const <String, Object?>{},
    this.clientRepository,
    this.onOpenInvoiceSettings,
    this.onSaveLocalSettings,
    super.key,
  });

  final InvoiceRepository repository;
  final Invoice? invoice;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> initialLocalSettings;
  final ClientsRepository? clientRepository;
  final VoidCallback onCancel;
  final ValueChanged<Invoice> onSaved;
  final VoidCallback? onOpenInvoiceSettings;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _clientName;
  late final TextEditingController _company;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _clientTaxId;
  late final TextEditingController _poNumber;
  late final TextEditingController _taxRate;
  late final TextEditingController _taxLabel;
  late final TextEditingController _discountPercent;
  late final TextEditingController _discountAmount;
  late final TextEditingController _shippingFee;
  late final TextEditingController _additionalCharges;
  late final TextEditingController _roundOff;
  late final TextEditingController _amountPaid;
  late final TextEditingController _currencyCode;
  late final TextEditingController _currencySymbol;
  late final TextEditingController _notes;
  late final TextEditingController _terms;
  late final TextEditingController _paymentInstructions;
  late final TextEditingController _shippingDetails;
  late Map<String, Object?> _localSettings;
  late String _issueDate;
  late String _dueDate;
  late String _paymentTerms;
  late String _taxType;
  late String _template;
  late bool _taxInclusive;
  late List<InvoiceItem> _items;
  List<Client> _clients = const [];
  int? _selectedClientId;
  bool _loadingClients = false;
  bool _loadingPreviousItems = false;
  bool _showClientSuggestions = false;
  bool _showNotesSection = false;
  bool _showShippingSection = false;
  bool _showPaymentSection = false;
  String? _clientLoadError;
  bool _globalShowItemDescriptions = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
    final now = DateTime.now();
    final today = _dateString(now);
    final defaultPaymentTerms =
        _settingString(_localSettings['defaultPaymentTerms'], 'Net 30');
    final defaultDue = _dateString(
      now.add(Duration(days: _paymentTermDays(defaultPaymentTerms))),
    );
    _number = TextEditingController(
      text: invoice?.invoiceNumber ??
          'INV-${now.year}-${now.millisecondsSinceEpoch % 100000}',
    );
    _clientName = TextEditingController(text: invoice?.clientName ?? '');
    _company = TextEditingController(text: invoice?.clientCompany ?? '');
    _email = TextEditingController(text: invoice?.clientEmail ?? '');
    _phone = TextEditingController(text: invoice?.clientPhone ?? '');
    _address = TextEditingController(text: invoice?.clientAddress ?? '');
    _clientTaxId = TextEditingController(text: invoice?.clientTaxId ?? '');
    _poNumber = TextEditingController(text: invoice?.poNumber ?? '');
    _taxRate = TextEditingController(
      text: _num(
        invoice?.taxRate ?? _settingNumber(_localSettings['defaultTaxRate']),
      ),
    );
    _taxLabel = TextEditingController(
      text: invoice?.taxLabel ??
          _settingString(_localSettings['defaultTaxLabel'], 'Tax'),
    );
    _discountPercent =
        TextEditingController(text: _num(invoice?.discountPercent ?? 0));
    _discountAmount =
        TextEditingController(text: _num(invoice?.discountAmount ?? 0));
    _shippingFee = TextEditingController(text: _num(invoice?.shippingFee ?? 0));
    _additionalCharges =
        TextEditingController(text: _num(invoice?.additionalCharges ?? 0));
    _roundOff = TextEditingController(text: _num(invoice?.roundOff ?? 0));
    _amountPaid = TextEditingController(text: _num(invoice?.amountPaid ?? 0));
    final defaultCurrency =
        _settingString(_localSettings['defaultCurrency'], 'USD');
    _currencyCode = TextEditingController(
      text: invoice?.currencyCode ?? defaultCurrency,
    );
    _currencySymbol = TextEditingController(
      text: invoice?.currencySymbol ??
          _settingString(
            _localSettings['defaultCurrencySymbol'],
            _currencySymbolFor(defaultCurrency),
          ),
    );
    _notes = TextEditingController(
      text:
          invoice?.notes ?? _settingString(_localSettings['defaultNotes'], ''),
    );
    _terms = TextEditingController(
      text:
          invoice?.terms ?? _settingString(_localSettings['defaultTerms'], ''),
    );
    _paymentInstructions = TextEditingController(
      text: invoice?.paymentInstructions ??
          _settingString(_localSettings['defaultPaymentInstructions'], ''),
    );
    _shippingDetails = TextEditingController(
      text: _readShippingDetails(invoice?.shippingDetailsJson),
    );
    _issueDate = invoice?.issueDate ?? today;
    _dueDate = invoice?.dueDate ?? defaultDue;
    _paymentTerms = invoice?.paymentTerms ?? defaultPaymentTerms;
    _taxType = invoice?.taxType ??
        _settingString(_localSettings['defaultTaxType'], 'GST');
    _template = invoice?.templateId ?? widget.preferredTemplate?.id ?? 'modern';
    _taxInclusive = invoice?.isTaxInclusive ??
        (_localSettings['defaultTaxInclusive'] == true);
    _selectedClientId = invoice?.clientId;
    _showNotesSection = invoice != null ||
        _localSettings['showNotesSection'] == true ||
        _notes.text.isNotEmpty ||
        _terms.text.isNotEmpty;
    _showShippingSection = invoice != null ||
        _localSettings['showShippingSection'] == true ||
        _shippingDetails.text.isNotEmpty;
    _showPaymentSection = invoice != null ||
        _localSettings['showPaymentInstructions'] == true ||
        _paymentInstructions.text.isNotEmpty;
    _items = List<InvoiceItem>.of(invoice?.items ?? const []);
    _items = [
      for (var index = 0; index < _items.length; index++)
        _items[index].id.isEmpty
            ? _items[index].copyWith(
                id: 'local-${now.microsecondsSinceEpoch}-$index',
              )
            : _items[index],
    ];
    if (_items.isEmpty) {
      final isSecurity = _localSettings['industryPresetId'] == 'security' ||
          _localSettings['showItemDuty'] == true;
      _items.add(_newLineItem(isSecurity));
    }
    unawaited(_loadClients());
  }

  @override
  void dispose() {
    _number.dispose();
    _clientName.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _clientTaxId.dispose();
    _poNumber.dispose();
    _taxRate.dispose();
    _taxLabel.dispose();
    _discountPercent.dispose();
    _discountAmount.dispose();
    _shippingFee.dispose();
    _additionalCharges.dispose();
    _roundOff.dispose();
    _amountPaid.dispose();
    _currencyCode.dispose();
    _currencySymbol.dispose();
    _notes.dispose();
    _terms.dispose();
    _paymentInstructions.dispose();
    _shippingDetails.dispose();
    super.dispose();
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  Future<void> _loadClients() async {
    final repository = widget.clientRepository;
    if (repository == null) return;
    setState(() {
      _loadingClients = true;
      _clientLoadError = null;
    });
    try {
      final clients = await repository.list();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _loadingClients = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _clientLoadError = 'Saved clients could not be loaded: $error';
        _loadingClients = false;
      });
    }
  }

  List<Client> get _matchingClients {
    final query = _clientName.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _clients
        .where((client) =>
            client.name.toLowerCase().contains(query) ||
            client.companyName.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query))
        .take(6)
        .toList(growable: false);
  }

  bool get _hasExactClientMatch {
    final query = _clientName.text.trim().toLowerCase();
    if (query.isEmpty) return false;
    return _matchingClients.any((client) =>
        client.name.trim().toLowerCase() == query ||
        client.companyName.trim().toLowerCase() == query);
  }

  void _applyClient(Client client) {
    setState(() {
      _selectedClientId = client.id;
      _clientName.text = client.name;
      _company.text = client.companyName;
      _email.text = client.email;
      _phone.text = client.phone;
      _address.text = client.address;
      _clientTaxId.text = client.taxId;
      if (widget.invoice == null) {
        _paymentTerms = client.defaultPaymentTerms;
        _dueDate = _dateString(
          (DateTime.tryParse(_issueDate) ?? DateTime.now()).add(
            Duration(days: _paymentTermDays(_paymentTerms)),
          ),
        );
        if (client.preferredCurrency.trim().isNotEmpty) {
          _currencyCode.text = client.preferredCurrency.toUpperCase();
          _currencySymbol.text =
              _currencySymbolFor(client.preferredCurrency);
        }
      }
      _showClientSuggestions = false;
    });
  }

  Future<void> _createClientFromInvoice() async {
    final repository = widget.clientRepository;
    final name = _clientName.text.trim();
    if (repository == null || name.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      final client = await repository.create(
        Client(
          name: name,
          companyName: _company.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          taxId: _clientTaxId.text.trim(),
          preferredCurrency: _currencyCode.text.trim().isEmpty
              ? 'USD'
              : _currencyCode.text.trim().toUpperCase(),
          defaultPaymentTerms: _paymentTerms,
        ),
      );
      if (!mounted) return;
      setState(() {
        _clients = [..._clients, client];
        _selectedClientId = client.id;
        _showClientSuggestions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${client.name} saved to clients.')),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save client: $error');
    }
  }

  Future<void> _copyPreviousItems() async {
    final clientId = _selectedClientId;
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a saved client first.')),
      );
      return;
    }
    if (_items.any(
        (item) => item.description.trim().isNotEmpty || item.unitPrice != 0)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace current items?'),
          content: const Text(
            'The line items on this invoice will be replaced with items from the client’s latest invoice.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep current items'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace items'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    setState(() => _loadingPreviousItems = true);
    try {
      final invoices = await widget.repository.getInvoices();
      final previous = invoices
          .where((invoice) =>
              invoice.clientId == clientId &&
              invoice.id != widget.invoice?.id &&
              invoice.items.isNotEmpty)
          .toList()
        ..sort((left, right) =>
            (right.createdAt ?? 0).compareTo(left.createdAt ?? 0));
      if (!mounted) return;
      if (previous.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous invoice items found for this client.'),
          ),
        );
        return;
      }
      setState(() {
        _items = [
          for (var index = 0; index < previous.first.items.length; index++)
            previous.first.items[index].copyWith(
              id: 'local-${DateTime.now().microsecondsSinceEpoch}-$index',
            ),
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Previous invoice items copied.')),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not load previous invoice: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingPreviousItems = false);
    }
  }

  Invoice get _draft => Invoice(
        id: widget.invoice?.id,
        invoiceNumber: _number.text.trim(),
        clientId: _selectedClientId,
        clientName: _clientName.text.trim(),
        clientCompany: _company.text.trim(),
        clientEmail: _email.text.trim(),
        clientPhone: _phone.text.trim(),
        clientAddress: _address.text.trim(),
        clientTaxId: _clientTaxId.text.trim(),
        issueDate: _issueDate,
        dueDate: _dueDate,
        poNumber: _poNumber.text.trim(),
        paymentTerms: _paymentTerms,
        currencyCode: _currencyCode.text.trim().isEmpty
            ? 'USD'
            : _currencyCode.text.trim().toUpperCase(),
        currencySymbol:
            _currencySymbol.text.trim().isEmpty ? r'$' : _currencySymbol.text,
        items: _items,
        notes: _showNotesSection ? _notes.text.trim() : '',
        terms: _showNotesSection ? _terms.text.trim() : '',
        paymentInstructions:
            _showPaymentSection ? _paymentInstructions.text.trim() : '',
        shippingDetailsJson: _serializeShippingDetails(
          _showShippingSection ? _shippingDetails.text : '',
        ),
        taxRate: _value(_taxRate),
        taxLabel: _taxLabel.text.trim().isEmpty ? 'Tax' : _taxLabel.text.trim(),
        taxType: _taxType,
        isTaxInclusive: _taxInclusive,
        discountPercent: _value(_discountPercent),
        discountAmount: _value(_discountAmount),
        shippingFee: _value(_shippingFee),
        additionalCharges: _value(_additionalCharges),
        roundOff: _value(_roundOff),
        amountPaid: _value(_amountPaid),
        status: widget.invoice?.status ?? 'Draft',
        templateId: _template,
        createdAt: widget.invoice?.createdAt,
        paidDate: widget.invoice?.paidDate,
      );

  Future<void> _pickDate({required bool issue}) async {
    final currentValue = issue ? _issueDate : _dueDate;
    final initial = DateTime.tryParse(currentValue) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (issue) {
        _issueDate = _dateString(selected);
      } else {
        _dueDate = _dateString(selected);
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (DateTime.parse(_dueDate).isBefore(DateTime.parse(_issueDate))) {
      setState(() => _error = 'The due date cannot be before the issue date.');
      return;
    }
    if (_items.isEmpty ||
        _items.any((item) => item.description.trim().isEmpty)) {
      setState(() => _error = 'Add a description to every line item.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = _draft;
      final saved = draft.id == null
          ? await widget.repository.createInvoice(draft)
          : await widget.repository.updateInvoice(draft);
      if (mounted) widget.onSaved(saved);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save invoice: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openItemCustomizerDialog() {
    final tempSettings = Map<String, Object?>.from(_localSettings);
    final itemHeaderCtrl = TextEditingController(
      text: tempSettings['customItemHeader']?.toString() ?? 'Description',
    );
    final qtyHeaderCtrl = TextEditingController(
      text: tempSettings['customQtyHeader']?.toString() ?? 'Qty',
    );
    final dutyHeaderCtrl = TextEditingController(
      text: tempSettings['customDutyHeader']?.toString() ?? 'No. of Duty / Days',
    );
    final unitHeaderCtrl = TextEditingController(
      text: tempSettings['customUnitHeader']?.toString() ?? 'Unit',
    );
    final rateHeaderCtrl = TextEditingController(
      text: tempSettings['customRateHeader']?.toString() ?? 'Rate',
    );
    final discountHeaderCtrl = TextEditingController(
      text: tempSettings['customDiscountHeader']?.toString() ?? 'Discount',
    );
    final taxHeaderCtrl = TextEditingController(
      text: tempSettings['customTaxHeader']?.toString() ?? 'Tax',
    );
    final amountHeaderCtrl = TextEditingController(
      text: tempSettings['customAmountHeader']?.toString() ?? 'Amount',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void applyPreset(String presetId) {
              setSheetState(() {
                tempSettings['industryPresetId'] = presetId;
                switch (presetId) {
                  case 'security':
                    tempSettings['customTitle'] = 'TAX INVOICE';
                    tempSettings['customItemHeader'] = 'Designation / Post';
                    tempSettings['customQtyHeader'] = 'No. of Staff / Guards';
                    tempSettings['customDutyHeader'] = 'No. of Duty / Days';
                    tempSettings['customUnitHeader'] = 'Duty / Shift';
                    tempSettings['customRateHeader'] = 'Rate / Salary per Month';
                    tempSettings['customDiscountHeader'] = 'Deductions';
                    tempSettings['customTaxHeader'] = 'GST (18%)';
                    tempSettings['customAmountHeader'] = 'Total Amount';
                    tempSettings['showItemDuty'] = true;
                    tempSettings['showItemUnit'] = true;
                    tempSettings['showItemQty'] = true;
                    tempSettings['showItemRate'] = true;
                    tempSettings['showItemDiscount'] = false;
                    tempSettings['showItemTax'] = true;
                    itemHeaderCtrl.text = 'Designation / Post';
                    qtyHeaderCtrl.text = 'No. of Staff / Guards';
                    dutyHeaderCtrl.text = 'No. of Duty / Days';
                    unitHeaderCtrl.text = 'Duty / Shift';
                    rateHeaderCtrl.text = 'Rate / Salary per Month';
                    discountHeaderCtrl.text = 'Deductions';
                    taxHeaderCtrl.text = 'GST (18%)';
                    amountHeaderCtrl.text = 'Total Amount';
                  case 'hr_staffing':
                    tempSettings['customTitle'] = 'Staffing & Salary Invoice';
                    tempSettings['customItemHeader'] = 'Employee Name / Role';
                    tempSettings['customQtyHeader'] = 'Staff Count';
                    tempSettings['customDutyHeader'] = 'Days Worked';
                    tempSettings['customUnitHeader'] = 'Days Worked';
                    tempSettings['customRateHeader'] = 'Monthly Salary';
                    tempSettings['customTaxHeader'] = 'GST (18%)';
                    tempSettings['customAmountHeader'] = 'Total Salary Due';
                    tempSettings['showItemDuty'] = true;
                    tempSettings['showItemUnit'] = true;
                    tempSettings['showItemQty'] = true;
                    tempSettings['showItemRate'] = true;
                    tempSettings['showItemDiscount'] = false;
                    tempSettings['showItemTax'] = true;
                    itemHeaderCtrl.text = 'Employee Name / Role';
                    qtyHeaderCtrl.text = 'Staff Count';
                    dutyHeaderCtrl.text = 'Days Worked';
                    unitHeaderCtrl.text = 'Days Worked';
                    rateHeaderCtrl.text = 'Monthly Salary';
                    taxHeaderCtrl.text = 'GST (18%)';
                    amountHeaderCtrl.text = 'Total Salary Due';
                  case 'gst':
                    tempSettings['customItemHeader'] = 'Goods / Services';
                    tempSettings['customQtyHeader'] = 'Qty';
                    tempSettings['customUnitHeader'] = 'Unit';
                    tempSettings['customRateHeader'] = 'Rate';
                    tempSettings['customTaxHeader'] = 'GST Rate (%)';
                    tempSettings['customAmountHeader'] = 'Total (INR)';
                    tempSettings['showItemDuty'] = false;
                    tempSettings['showItemTax'] = true;
                    itemHeaderCtrl.text = 'Goods / Services';
                    qtyHeaderCtrl.text = 'Qty';
                    unitHeaderCtrl.text = 'Unit';
                    rateHeaderCtrl.text = 'Rate';
                    taxHeaderCtrl.text = 'GST Rate (%)';
                    amountHeaderCtrl.text = 'Total (INR)';
                  case 'it':
                    tempSettings['customItemHeader'] = 'Milestone / Deliverable';
                    tempSettings['customQtyHeader'] = 'Hours';
                    tempSettings['customUnitHeader'] = 'hrs';
                    tempSettings['customRateHeader'] = 'Hourly Rate';
                    tempSettings['customTaxHeader'] = 'Tax (%)';
                    tempSettings['customAmountHeader'] = 'Total Fee';
                    tempSettings['showItemDuty'] = false;
                    itemHeaderCtrl.text = 'Milestone / Deliverable';
                    qtyHeaderCtrl.text = 'Hours';
                    unitHeaderCtrl.text = 'hrs';
                    rateHeaderCtrl.text = 'Hourly Rate';
                    taxHeaderCtrl.text = 'Tax (%)';
                    amountHeaderCtrl.text = 'Total Fee';
                  case 'retail':
                    tempSettings['customItemHeader'] = 'Product / Item';
                    tempSettings['customQtyHeader'] = 'Quantity';
                    tempSettings['customUnitHeader'] = 'Pcs';
                    tempSettings['customRateHeader'] = 'Unit Price';
                    tempSettings['customDiscountHeader'] = 'Discount (%)';
                    tempSettings['customAmountHeader'] = 'Total';
                    tempSettings['showItemDuty'] = false;
                    tempSettings['showItemDiscount'] = true;
                    itemHeaderCtrl.text = 'Product / Item';
                    qtyHeaderCtrl.text = 'Quantity';
                    unitHeaderCtrl.text = 'Pcs';
                    rateHeaderCtrl.text = 'Unit Price';
                    discountHeaderCtrl.text = 'Discount (%)';
                    amountHeaderCtrl.text = 'Total';
                }
              });
            }

            Widget presetChip(String id, String title, String subtitle) {
              final isSelected = tempSettings['industryPresetId'] == id ||
                  (id == 'security' && (itemHeaderCtrl.text.contains('Guards') || itemHeaderCtrl.text.contains('Designation')));
              return InkWell(
                onTap: () => applyPreset(id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, size: 13, color: Color(0xFF2563EB)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item Columns & Industry Setup',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Text(
                                'Customize column headers, duty/salary formulas & presets',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      '1-Click Business Industry Preset',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        presetChip('security', '🛡️ Security Agency & Guards', 'Designation, Staff, Duty, Rate/Salary'),
                        presetChip('hr_staffing', '👤 HR Staffing & Payroll', 'Staff, Days Worked, Monthly Salary'),
                        presetChip('gst', '⚖️ GST Tax Invoice', 'HSN/SAC, Qty, Rate, GST%'),
                        presetChip('it', '💻 IT & Consulting', 'Milestones, Hours, Hourly Rate'),
                        presetChip('retail', '🛍️ Retail Store', 'Product, Qty, Price, Discount'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Column Header Names',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: itemHeaderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item / Service Column Name',
                        hintText: 'e.g. Designation / Post, Particulars',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyHeaderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Quantity / Staff Column Name',
                              hintText: 'e.g. No. of Staff, Qty',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: dutyHeaderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Duty / Days Column Name',
                              hintText: 'e.g. No. of Duty / Days',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitHeaderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Unit Badge Name',
                              hintText: 'e.g. Duty, Days, Shift',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: rateHeaderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Rate / Salary Column Name',
                              hintText: 'e.g. Rate/Salary per Month',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountHeaderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Total Column Name',
                        hintText: 'e.g. Total Amount, Amount',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Column Visibility Toggles',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Duty / Days Column (Staff × Duty × Rate)', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Calculates Total = Staff × Duty Days × Rate', style: TextStyle(fontSize: 11)),
                      value: tempSettings['showItemDuty'] == true,
                      onChanged: (val) => setSheetState(() => tempSettings['showItemDuty'] = val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Unit Badge (Duty/Days/hrs)', style: TextStyle(fontSize: 13)),
                      value: tempSettings['showItemUnit'] != false,
                      onChanged: (val) => setSheetState(() => tempSettings['showItemUnit'] = val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Discount / Deduction Column', style: TextStyle(fontSize: 13)),
                      value: tempSettings['showItemDiscount'] == true,
                      onChanged: (val) => setSheetState(() => tempSettings['showItemDiscount'] = val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Item Tax Column', style: TextStyle(fontSize: 13)),
                      value: tempSettings['showItemTax'] != false,
                      onChanged: (val) => setSheetState(() => tempSettings['showItemTax'] = val),
                    ),
                    const SizedBox(height: 16),
                    if (widget.onOpenInvoiceSettings != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          widget.onOpenInvoiceSettings!();
                        },
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Open Full Invoice Settings Page (Logo, Bank, Sign)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          tempSettings['customItemHeader'] = itemHeaderCtrl.text.trim();
                          tempSettings['customQtyHeader'] = qtyHeaderCtrl.text.trim();
                          tempSettings['customDutyHeader'] = dutyHeaderCtrl.text.trim();
                          tempSettings['customUnitHeader'] = unitHeaderCtrl.text.trim();
                          tempSettings['customRateHeader'] = rateHeaderCtrl.text.trim();
                          tempSettings['customDiscountHeader'] = discountHeaderCtrl.text.trim();
                          tempSettings['customTaxHeader'] = taxHeaderCtrl.text.trim();
                          tempSettings['customAmountHeader'] = amountHeaderCtrl.text.trim();
                          _localSettings = tempSettings;

                          if (tempSettings['industryPresetId'] == 'security' &&
                              _items.isNotEmpty &&
                              _items.first.description.trim().isEmpty) {
                            _items[0] = InvoiceItem(
                              id: _items[0].id,
                              description: 'Security Guard (12 Hrs Shift)',
                              itemDetails: 'Deployment of uniformed security guard for 12 hours shift. Access control and premise surveillance.',
                              quantity: 1,
                              dutyCount: 26,
                              unitPrice: 18500,
                              unit: 'Duty',
                              taxRate: _items[0].taxRate,
                              discountRate: _items[0].discountRate,
                            );
                          }
                        });
                        widget.onSaveLocalSettings?.call(tempSettings);
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item columns & template settings applied!')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Apply to Invoice'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateItem(int index, InvoiceItem item) {
    setState(() => _items[index] = item);
  }

  void _removeItem(int index) {
    final isSecurity = _localSettings['industryPresetId'] == 'security' ||
        _localSettings['showItemDuty'] == true;
    if (_items.length == 1) {
      setState(() => _items[index] = _newLineItem(isSecurity));
    } else {
      setState(() => _items.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final paymentTermOptions = <String>[
      'Due on Receipt',
      'Net 15',
      'Net 30',
      'Net 60',
      if (!const ['Due on Receipt', 'Net 15', 'Net 30', 'Net 60']
          .contains(_paymentTerms))
        _paymentTerms,
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _saving ? null : widget.onCancel,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.invoice == null ? 'Create invoice' : 'Edit invoice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 14),
            ],
            _SectionCard(
              title: 'Invoice details',
              subtitle: 'Number, dates and payment terms',
              children: [
                _ResponsiveFields(
                  children: [
                    _textField(
                      controller: _number,
                      label: 'Invoice number',
                      validator: _required,
                    ),
                    _dateField(
                      label: 'Issue date',
                      date: _issueDate,
                      onTap: () => _pickDate(issue: true),
                    ),
                    _dateField(
                      label: 'Due date',
                      date: _dueDate,
                      onTap: () => _pickDate(issue: false),
                    ),
                    DropdownButtonFormField<String>(
                      value: _paymentTerms,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Payment terms'),
                      items: paymentTermOptions
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      selectedItemBuilder: (context) => paymentTermOptions
                          .map((value) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _paymentTerms = value ?? 'Net 30'),
                    ),
                    _textField(
                      controller: _poNumber,
                      label: 'Purchase order number',
                      isRequired: false,
                    ),
                    DropdownButtonFormField<String>(
                      value: _template,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Invoice style'),
                      items: [
                        if (!templatePresets
                            .any((item) => item.id == _template))
                          DropdownMenuItem<String>(
                            value: _template,
                            child: Text(
                              widget.preferredTemplate?.id == _template
                                  ? widget.preferredTemplate!.name
                                  : _template,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ...templatePresets
                            .map((template) => DropdownMenuItem<String>(
                                  value: template.id,
                                  child: Text(
                                    template.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                      ],
                      selectedItemBuilder: (context) => [
                        if (!templatePresets
                            .any((item) => item.id == _template))
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.preferredTemplate?.id == _template
                                  ? widget.preferredTemplate!.name
                                  : _template,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ...templatePresets.map(
                          (template) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              template.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _template = value ?? 'modern'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Bill to',
              subtitle: 'Client contact details',
              children: [
                _ResponsiveFields(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _clientName,
                          decoration: InputDecoration(
                            labelText: 'Client name',
                            prefixIcon: const Icon(Icons.person_outline),
                            suffixIcon: _loadingClients
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _selectedClientId == null
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear selected client',
                                        onPressed: () => setState(() {
                                          _selectedClientId = null;
                                          _clientName.clear();
                                          _company.clear();
                                          _email.clear();
                                          _phone.clear();
                                          _address.clear();
                                          _clientTaxId.clear();
                                        }),
                                        icon: const Icon(Icons.close),
                                      ),
                          ),
                          validator: _required,
                          onChanged: (_) => setState(() {
                            _selectedClientId = null;
                            _showClientSuggestions = true;
                          }),
                          onTap: () => setState(() {
                            _showClientSuggestions =
                                _clientName.text.isNotEmpty;
                          }),
                        ),
                        if (_showClientSuggestions &&
                            _selectedClientId == null &&
                            _clientName.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (final client in _matchingClients)
                                  ListTile(
                                    dense: true,
                                    leading: const CircleAvatar(
                                      radius: 17,
                                      child:
                                          Icon(Icons.person_outline, size: 18),
                                    ),
                                    title: Text(
                                      client.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      [
                                        client.companyName,
                                        client.email,
                                        client.phone,
                                      ]
                                          .where((value) => value.isNotEmpty)
                                          .join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _applyClient(client),
                                  ),
                                if (_matchingClients.isEmpty)
                                  const ListTile(
                                    dense: true,
                                    leading: Icon(Icons.search_off_outlined),
                                    title: Text('No saved client matches yet'),
                                  ),
                                if (widget.clientRepository != null &&
                                    !_hasExactClientMatch)
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.person_add_alt_1,
                                      color: AppColors.blue,
                                    ),
                                    title: Text(
                                      'Save "${_clientName.text.trim()}" as a new client',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onTap: _createClientFromInvoice,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (_clientLoadError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _clientLoadError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _textField(
                      controller: _company,
                      label: 'Company',
                      isRequired: false,
                    ),
                    _textField(
                      controller: _email,
                      label: 'Email address',
                      isRequired: false,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isNotEmpty &&
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _textField(
                      controller: _phone,
                      label: 'Phone',
                      isRequired: false,
                      keyboardType: TextInputType.phone,
                    ),
                    _textField(
                      controller: _clientTaxId,
                      label: 'Client tax ID',
                      isRequired: false,
                    ),
                    _textField(
                      controller: _address,
                      label: 'Billing address',
                      isRequired: false,
                      maxLines: 2,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Line items',
              subtitle: 'Quantities, rates and optional line discounts',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openItemCustomizerDialog,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Item Settings', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Add item',
                    onPressed: () {
                      final isSecurity = _localSettings['industryPresetId'] == 'security' ||
                          _localSettings['showItemDuty'] == true;
                      setState(() => _items.add(_newLineItem(isSecurity)));
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        _loadingPreviousItems ? null : _copyPreviousItems,
                    icon: _loadingPreviousItems
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.history),
                    label: const Text('Use items from previous invoice'),
                  ),
                ),
                for (var index = 0; index < _items.length; index++) ...[
                  _LineItemEditor(
                    key: ValueKey(_items[index].id),
                    index: index,
                    item: _items[index],
                    currencySymbol: _currencySymbol.text,
                    localSettings: _localSettings,
                    showDescriptionField: _globalShowItemDescriptions ||
                        _items[index].itemDetails.isNotEmpty,
                    onToggleDescription: (open) {
                      setState(() => _globalShowItemDescriptions = open);
                    },
                    onChanged: (item) => _updateItem(index, item),
                    onRemove: () => _removeItem(index),
                  ),
                  if (index != _items.length - 1) const Divider(height: 28),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Invoice adjustments',
              subtitle: 'Tax and currency use your saved invoice defaults',
              children: [
                Text(
                  '${_taxLabel.text} ${_num(_value(_taxRate))}% · $_taxType'
                  '${_taxInclusive ? ' · tax included in prices' : ''}'
                  ' · ${_currencyCode.text}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                _ResponsiveFields(
                  children: [
                    _decimalField(
                      controller: _discountPercent,
                      label: 'Discount (%)',
                      min: 0,
                      max: 100,
                      onChanged: () => setState(() {}),
                    ),
                    _decimalField(
                      controller: _discountAmount,
                      label: 'Discount amount',
                      min: 0,
                      onChanged: () => setState(() {}),
                    ),
                    _decimalField(
                      controller: _shippingFee,
                      label: 'Shipping',
                      min: 0,
                      onChanged: () => setState(() {}),
                    ),
                    _decimalField(
                      controller: _additionalCharges,
                      label: 'Additional charges',
                      min: 0,
                      onChanged: () => setState(() {}),
                    ),
                    _decimalField(
                      controller: _roundOff,
                      label: 'Round off (+/−)',
                      min: -1000,
                      allowNegative: true,
                      onChanged: () => setState(() {}),
                    ),
                    _decimalField(
                      controller: _amountPaid,
                      label: 'Amount already paid',
                      min: 0,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TotalsPreview(invoice: draft),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Optional details',
              subtitle: 'Only add the sections needed for this invoice',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Notes & terms'),
                      selected: _showNotesSection,
                      onSelected: (value) =>
                          setState(() => _showNotesSection = value),
                    ),
                    FilterChip(
                      label: const Text('Delivery details'),
                      selected: _showShippingSection,
                      onSelected: (value) =>
                          setState(() => _showShippingSection = value),
                    ),
                    FilterChip(
                      label: const Text('Payment instructions'),
                      selected: _showPaymentSection,
                      onSelected: (value) =>
                          setState(() => _showPaymentSection = value),
                    ),
                  ],
                ),
                if (_showNotesSection) ...[
                  const SizedBox(height: 14),
                  _textField(
                    controller: _notes,
                    label: 'Notes to client',
                    isRequired: false,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: _terms,
                    label: 'Terms and conditions',
                    isRequired: false,
                    maxLines: 3,
                  ),
                ],
                if (_showShippingSection) ...[
                  const SizedBox(height: 12),
                  _textField(
                    controller: _shippingDetails,
                    label: 'Delivery / shipping details',
                    hintText: 'Address, delivery date, carrier or tracking',
                    isRequired: false,
                    maxLines: 3,
                  ),
                ],
                if (_showPaymentSection) ...[
                  const SizedBox(height: 12),
                  _textField(
                    controller: _paymentInstructions,
                    label: 'Payment instructions',
                    isRequired: false,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                  widget.invoice == null ? 'Create invoice' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

InvoiceItem _newLineItem([bool isSecurity = false]) => InvoiceItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      description: '',
      itemDetails: '',
      quantity: 1,
      dutyCount: isSecurity ? 26 : 0,
      unitPrice: 0,
      unit: isSecurity ? 'Duty' : 'pcs',
    );

class _ItemSuggestion {
  final String title;
  final String subtitle;
  final String defaultDetails;
  final double? defaultRate;
  final String? defaultUnit;
  final double? defaultDuty;
  final IconData icon;

  const _ItemSuggestion({
    required this.title,
    required this.subtitle,
    required this.defaultDetails,
    this.defaultRate,
    this.defaultUnit,
    this.defaultDuty,
    this.icon = Icons.shield_outlined,
  });
}

const _securitySuggestions = <_ItemSuggestion>[
  _ItemSuggestion(
    title: 'Security Guard (12 Hrs Shift)',
    subtitle: '12-Hour Shift • Unarmed Uniformed Guard',
    defaultDetails:
        'Deployment of uniformed security guard for 12 hours shift. Access control, gatekeeping, and premise surveillance.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 18500,
    icon: Icons.security,
  ),
  _ItemSuggestion(
    title: 'Security Guard (8 Hrs Shift)',
    subtitle: '8-Hour Shift • Commercial / Corporate Guard',
    defaultDetails:
        'Deployment of trained security guard for 8 hours shift. Visitor monitoring and perimeter patrolling.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 15000,
    icon: Icons.shield_outlined,
  ),
  _ItemSuggestion(
    title: 'Security Supervisor',
    subtitle: 'Post In-Charge • Shift Operations & Briefing',
    defaultDetails:
        'Overall supervision of security personnel, deployment management, incident escalation, and daily report log.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 24000,
    icon: Icons.local_police_outlined,
  ),
  _ItemSuggestion(
    title: 'Gunman / Armed Guard',
    subtitle: 'Armed Security • Vault & Cash Escort',
    defaultDetails:
        'Deployment of licensed armed gunman with weapon for high-security areas, cash transport, or executive protection.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 28000,
    icon: Icons.verified_user_outlined,
  ),
  _ItemSuggestion(
    title: 'Head Guard / Chief Guard',
    subtitle: 'Site Leadership • Shift Coordination',
    defaultDetails:
        'Site head guard responsible for main gate registers, key management, and shift roster execution.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 21000,
    icon: Icons.person_pin_outlined,
  ),
  _ItemSuggestion(
    title: 'Lady Security Guard',
    subtitle: 'Female Screening • Reception / Staff Gate',
    defaultDetails:
        'Deployment of female security guard for female staff/visitor frisking, reception assistance, and women safety.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 17500,
    icon: Icons.female_outlined,
  ),
  _ItemSuggestion(
    title: 'Bouncer / Event Security',
    subtitle: 'Physical Security • Crowd Control & VIP',
    defaultDetails:
        'Heavy physical security bouncer for crowd management, VIP escort, event access, and conflict mitigation.',
    defaultUnit: 'Duty',
    defaultDuty: 1,
    defaultRate: 2500,
    icon: Icons.sports_mma_outlined,
  ),
  _ItemSuggestion(
    title: 'Field Officer / Inspector',
    subtitle: 'Operations Officer • Night Patrol & Audit',
    defaultDetails:
        'Mobile inspection officer conducting surprise night rounds, guard muster verification, and client feedback.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 26000,
    icon: Icons.directions_walk_outlined,
  ),
  _ItemSuggestion(
    title: 'CCTV Operator / Control Room',
    subtitle: 'Surveillance Tech • Electronic Monitoring',
    defaultDetails:
        'Continuous monitoring of CCTV camera feeds, alarm acknowledgement, incident timestamping, and reporting.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 19500,
    icon: Icons.videocam_outlined,
  ),
  _ItemSuggestion(
    title: 'Housekeeping Staff / Janitor',
    subtitle: 'Facility Cleaning • Daily Upkeep',
    defaultDetails:
        'Daily cleaning of common areas, restroom hygiene, waste disposal, and maintenance of clean premises.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 12500,
    icon: Icons.cleaning_services_outlined,
  ),
];

const _generalSuggestions = <_ItemSuggestion>[
  _ItemSuggestion(
    title: 'Consulting Services',
    subtitle: 'Professional Advisory & Planning',
    defaultDetails:
        'Strategic consulting and expert advisory services per agreement scope.',
    defaultUnit: 'hrs',
    defaultRate: 120,
    icon: Icons.business_center_outlined,
  ),
  _ItemSuggestion(
    title: 'Maintenance & Support',
    subtitle: 'Monthly AMC & SLA Support',
    defaultDetails:
        'Ongoing maintenance, support services, and issue resolution under SLA.',
    defaultUnit: 'Month',
    defaultRate: 500,
    icon: Icons.build_outlined,
  ),
  _ItemSuggestion(
    title: 'Software Development',
    subtitle: 'Custom Software & Feature Engineering',
    defaultDetails:
        'Software design, feature coding, QA testing, and release delivery.',
    defaultUnit: 'hrs',
    defaultRate: 75,
    icon: Icons.code_outlined,
  ),
  _ItemSuggestion(
    title: 'UI/UX Design Services',
    subtitle: 'Interface Prototyping & Wireframing',
    defaultDetails:
        'User interface design, mobile/web mockups, design tokens, and prototypes.',
    defaultUnit: 'hrs',
    defaultRate: 60,
    icon: Icons.design_services_outlined,
  ),
  _ItemSuggestion(
    title: 'Digital Marketing & SEO',
    subtitle: 'Search Ranking & Campaign Strategy',
    defaultDetails:
        'Search engine optimization, targeted ad management, and monthly performance reporting.',
    defaultUnit: 'Month',
    defaultRate: 400,
    icon: Icons.campaign_outlined,
  ),
  _ItemSuggestion(
    title: 'Technical Audit & Inspection',
    subtitle: 'Infrastructure Review & Report',
    defaultDetails:
        'Full system security and operational compliance audit with detailed recommendation findings.',
    defaultUnit: 'pcs',
    defaultRate: 850,
    icon: Icons.checklist_outlined,
  ),
];

class _LineItemEditor extends StatefulWidget {
  const _LineItemEditor({
    required this.index,
    required this.item,
    required this.currencySymbol,
    required this.localSettings,
    required this.showDescriptionField,
    required this.onToggleDescription,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final InvoiceItem item;
  final String currencySymbol;
  final Map<String, Object?> localSettings;
  final bool showDescriptionField;
  final ValueChanged<bool> onToggleDescription;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<_LineItemEditor> {
  late final TextEditingController _description;
  late final TextEditingController _itemDetails;
  late final TextEditingController _quantity;
  late final TextEditingController _duty;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unit;
  late final TextEditingController _discount;
  bool _showSuggestions = false;
  bool? _isDescriptionCollapsed;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.item.description);
    _itemDetails = TextEditingController(text: widget.item.itemDetails);
    _quantity = TextEditingController(text: _num(widget.item.quantity));
    _duty = TextEditingController(
      text: widget.item.dutyCount > 0 ? _num(widget.item.dutyCount) : '',
    );
    _unitPrice = TextEditingController(text: _num(widget.item.unitPrice));
    _unit = TextEditingController(text: widget.item.unit);
    _discount = TextEditingController(text: _num(widget.item.discountRate));
  }

  @override
  void dispose() {
    _description.dispose();
    _itemDetails.dispose();
    _quantity.dispose();
    _duty.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(InvoiceItem(
      id: widget.item.id,
      description: _description.text,
      itemDetails: _itemDetails.text,
      quantity: double.tryParse(_quantity.text) ?? 0,
      dutyCount: double.tryParse(_duty.text) ?? 0,
      unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      taxRate: widget.item.taxRate,
      discountRate: double.tryParse(_discount.text) ?? 0,
    ));
  }

  void _applySuggestion(_ItemSuggestion s) {
    setState(() {
      _description.text = s.title;
      if (_itemDetails.text.trim().isEmpty) {
        _itemDetails.text = s.defaultDetails;
      }
      if (s.defaultUnit != null &&
          (_unit.text.trim().isEmpty || _unit.text == 'pcs')) {
        _unit.text = s.defaultUnit!;
      }
      if (s.defaultDuty != null &&
          (_duty.text.trim().isEmpty || _duty.text == '0')) {
        _duty.text = _num(s.defaultDuty!);
      }
      if (s.defaultRate != null &&
          (_unitPrice.text.trim().isEmpty || _unitPrice.text == '0')) {
        _unitPrice.text = _num(s.defaultRate!);
      }
      _showSuggestions = false;
    });
    _notify();
  }

  List<_ItemSuggestion> _matchingSuggestions(bool isSecurity) {
    final query = _description.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final pool = isSecurity
        ? _securitySuggestions
        : <_ItemSuggestion>[..._securitySuggestions, ..._generalSuggestions];
    return pool
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            s.subtitle.toLowerCase().contains(query) ||
            s.defaultDetails.toLowerCase().contains(query))
        .take(6)
        .toList(growable: false);
  }

  Widget _unitChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() => _unit.text = text);
        _notify();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ls = widget.localSettings;
    final itemLabel =
        ls['customItemHeader']?.toString().trim().isNotEmpty == true
            ? ls['customItemHeader']!.toString().trim()
            : 'Description';
    final qtyLabel =
        ls['customQtyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customQtyHeader']!.toString().trim()
            : 'Quantity';
    final dutyLabel =
        ls['customDutyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDutyHeader']!.toString().trim()
            : 'No. of Duty / Days';
    final unitLabel =
        ls['customUnitHeader']?.toString().trim().isNotEmpty == true
            ? ls['customUnitHeader']!.toString().trim()
            : 'Unit';
    final rateLabel =
        ls['customRateHeader']?.toString().trim().isNotEmpty == true
            ? ls['customRateHeader']!.toString().trim()
            : 'Unit price';
    final discountLabel =
        ls['customDiscountHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDiscountHeader']!.toString().trim()
            : 'Discount (%)';

    final isSecurityOrStaffing = ls['industryPresetId'] == 'security' ||
        ls['industryPresetId'] == 'hr_staffing' ||
        itemLabel.toLowerCase().contains('guard') ||
        itemLabel.toLowerCase().contains('designation');

    final showDuty = ls['showItemDuty'] == true ||
        isSecurityOrStaffing ||
        widget.item.dutyCount > 0;
    final showUnit = ls['showItemUnit'] != false;
    final showDiscount = ls['showItemDiscount'] == true;

    final qtyVal = double.tryParse(_quantity.text) ?? 0;
    final dutyVal = double.tryParse(_duty.text) ?? 0;
    final rateVal = double.tryParse(_unitPrice.text) ?? 0;
    final discVal = double.tryParse(_discount.text) ?? 0;

    final gross =
        dutyVal > 0 ? (qtyVal * dutyVal * rateVal) : (qtyVal * rateVal);
    final discAmt = gross * (discVal / 100);
    final lineTotal = gross - discAmt;

    final isDescOpen = _isDescriptionCollapsed != null
        ? !_isDescriptionCollapsed!
        : (widget.showDescriptionField || _itemDetails.text.trim().isNotEmpty);
    final suggestions = _matchingSuggestions(isSecurityOrStaffing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Item ${widget.index + 1}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Remove line item',
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        TextFormField(
          controller: _description,
          decoration: InputDecoration(
            labelText: itemLabel,
            hintText: isSecurityOrStaffing
                ? 'Type to search (e.g. Guard, Supervisor...)'
                : 'What are you billing for? (Type to search)',
            suffixIcon: _description.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _description.clear();
                        _showSuggestions = false;
                      });
                      _notify();
                    },
                  )
                : const Icon(Icons.search, size: 18),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Add a $itemLabel'
              : null,
          onTap: () {
            if (_description.text.trim().isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
          onChanged: (_) {
            setState(() => _showSuggestions = _description.text.trim().isNotEmpty);
            _notify();
          },
        ),
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested designations & services (${suggestions.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _showSuggestions = false),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  for (final s in suggestions)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(s.icon,
                            size: 16, color: const Color(0xFF2563EB)),
                      ),
                      title: Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        s.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _applySuggestion(s),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (!isDescOpen)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () {
                setState(() => _isDescriptionCollapsed = false);
                widget.onToggleDescription(true);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 15, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      _itemDetails.text.trim().isNotEmpty
                          ? '+ Description: "${_itemDetails.text.trim().split('\n').first}" (Expand)'
                          : '+ Description / Scope of Work',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    if (_itemDetails.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Clear description',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _itemDetails.clear();
                              _isDescriptionCollapsed = true;
                            });
                            _notify();
                          },
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description / Scope of Work',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _isDescriptionCollapsed = true);
                        widget.onToggleDescription(false);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.unfold_less, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Collapse',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _itemDetails,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        'Specifications, post location, shift hours, duties...',
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                    suffixIcon: _itemDetails.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear description',
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _itemDetails.clear();
                              _notify();
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _notify(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        _ResponsiveFields(
          children: [
            _itemNumberField(
              controller: _quantity,
              label: qtyLabel,
              min: 0.000001,
              onChanged: _notify,
            ),
            if (showDuty)
              _itemNumberField(
                controller: _duty,
                label: dutyLabel,
                min: 0,
                onChanged: _notify,
              ),
            _itemNumberField(
              controller: _unitPrice,
              label: '$rateLabel (${widget.currencySymbol})',
              min: 0,
              onChanged: _notify,
            ),
            if (showUnit)
              TextField(
                controller: _unit,
                decoration: InputDecoration(
                  labelText: unitLabel,
                  hintText: 'Duty, Days, Shift, hrs, pcs',
                ),
                onChanged: (_) => _notify(),
              ),
            if (showDiscount)
              _itemNumberField(
                controller: _discount,
                label: discountLabel,
                min: 0,
                max: 100,
                onChanged: _notify,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (showDuty) ...[
              _unitChip('Duty'),
              _unitChip('Shift'),
            ],
            _unitChip('Days'),
            _unitChip('Month'),
            _unitChip('hrs'),
            _unitChip('pcs'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dutyVal > 0
                      ? 'Auto Calculation: ${_num(qtyVal)} Staff × ${_num(dutyVal)} Duties × ${widget.currencySymbol}${_num(rateVal)}${discVal > 0 ? " (−$discVal%)" : ""}'
                      : 'Auto Calculation: ${_num(qtyVal)} × ${widget.currencySymbol}${_num(rateVal)}${discVal > 0 ? " (−$discVal%)" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${widget.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TotalLine(
              label: 'Subtotal',
              value: _money(invoice.subtotal, invoice.currencySymbol),
            ),
            _TotalLine(
              label: 'Discount',
              value:
                  '−${_money(invoice.totalDiscount, invoice.currencySymbol)}',
            ),
            _TotalLine(
              label:
                  '${invoice.taxLabel} (${_num(invoice.taxRate)}%${invoice.isTaxInclusive ? ', included' : ''})',
              value: _money(invoice.taxAmount, invoice.currencySymbol),
            ),
            _TotalLine(
              label: 'Shipping & additional charges',
              value: _money(
                invoice.shippingFee + invoice.additionalCharges,
                invoice.currencySymbol,
              ),
            ),
            const Divider(),
            _TotalLine(
              label: 'Total',
              value: _money(invoice.total, invoice.currencySymbol),
              emphasized: true,
            ),
            _TotalLine(
              label: 'Balance due',
              value: _money(invoice.balanceDue, invoice.currencySymbol),
              emphasized: true,
            ),
          ],
        ),
      );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: emphasized
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
            ),
            Text(
              value,
              style: emphasized
                  ? const TextStyle(fontWeight: FontWeight.w800)
                  : null,
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      );
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final responsiveColumns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          final gap = 12.0;
          final width = (constraints.maxWidth - (responsiveColumns - 1) * gap) /
              responsiveColumns;
          return Wrap(
            spacing: gap,
            runSpacing: 12,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

Widget _textField({
  required TextEditingController controller,
  required String label,
  bool isRequired = true,
  int maxLines = 1,
  String? hintText,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  String? Function(String?)? validator,
  ValueChanged<String>? onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: validator ?? (isRequired ? _required : null),
      onChanged: onChanged,
    );

Widget _decimalField({
  required TextEditingController controller,
  required String label,
  required double min,
  double? max,
  bool allowNegative = false,
  required VoidCallback onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'^-?\d*\.?\d{0,4}' : r'^\d*\.?\d{0,4}'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < min || (max != null && parsed > max)) {
          return max == null ? 'Must be at least $min' : 'Enter $min–$max';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );

Widget _itemNumberField({
  required TextEditingController controller,
  required String label,
  required double min,
  double? max,
  required VoidCallback onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < min || (max != null && parsed > max)) {
          return max == null ? 'Must be at least $min' : 'Enter $min–$max';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );

Widget _dateField({
  required String label,
  required String date,
  required VoidCallback onTap,
}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(date),
      ),
    );

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String _dateString(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int _paymentTermDays(String terms) {
  if (terms.toLowerCase().contains('receipt')) return 0;
  final days = RegExp(r'net\s*(\d+)', caseSensitive: false)
      .firstMatch(terms)
      ?.group(1);
  return int.tryParse(days ?? '') ?? 30;
}

String _num(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

String _money(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

double _settingNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _settingString(Object? value, String fallback) {
  final string = value?.toString().trim() ?? '';
  return string.isEmpty ? fallback : string;
}

String _currencySymbolFor(String currency) => switch (currency.toUpperCase()) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'INR' => '₹',
      'JPY' => '¥',
      'CAD' || 'AUD' || 'NZD' => r'$',
      _ => currency.toUpperCase(),
    };

String _readShippingDetails(String? value) {
  if (value == null || value.trim().isEmpty || value.trim() == '{}') return '';
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) return value;
    const labels = <String, String>{
      'shippingAddress': 'Shipping address',
      'deliveryAddress': 'Delivery address',
      'shippingMethod': 'Shipping method',
      'courier': 'Carrier',
      'trackingNumber': 'Tracking',
      'expectedDelivery': 'Expected delivery',
      'warehouse': 'Warehouse',
      'deliveryContact': 'Delivery contact',
      'vehicleNumber': 'Vehicle number',
      'dispatchDate': 'Dispatch date',
    };
    return labels.entries
        .where(
            (entry) => decoded[entry.key]?.toString().trim().isNotEmpty == true)
        .map((entry) => '${entry.value}: ${decoded[entry.key]}')
        .join('\n');
  } on FormatException {
    return value;
  }
}

String _serializeShippingDetails(String value) {
  if (value.trim().isEmpty) return '{}';
  const keys = <String, String>{
    'shipping address': 'shippingAddress',
    'delivery address': 'deliveryAddress',
    'shipping method': 'shippingMethod',
    'carrier': 'courier',
    'tracking': 'trackingNumber',
    'expected delivery': 'expectedDelivery',
    'warehouse': 'warehouse',
    'delivery contact': 'deliveryContact',
    'vehicle number': 'vehicleNumber',
    'dispatch date': 'dispatchDate',
  };
  final details = <String, Object?>{
    'isEnabled': true,
    'sameAsBilling': false,
    'sectionTitle': 'Shipping Details',
  };
  final unmatchedLines = <String>[];
  for (final line in value.split('\n')) {
    final separator = line.indexOf(':');
    final label =
        separator < 0 ? '' : line.substring(0, separator).trim().toLowerCase();
    final content =
        separator < 0 ? line.trim() : line.substring(separator + 1).trim();
    if (content.isEmpty) continue;
    final key = keys[label];
    if (key == null) {
      unmatchedLines.add(content);
    } else {
      details[key] = content;
    }
  }
  if (unmatchedLines.isNotEmpty && details['deliveryAddress'] == null) {
    details['deliveryAddress'] = unmatchedLines.join('\n');
  }
  return jsonEncode(details);
}
