import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../clients/data/client.dart';
import '../../clients/data/clients_repository.dart';
import '../../templates/data/template_config.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';
import 'widgets/client_billing_card.dart';
import 'widgets/invoice_editor_components.dart';
import 'widgets/item_customizer_modal.dart';
import 'widgets/line_item_editor.dart';

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
        _settingString(_localSettings['defaultCurrency'], 'INR');
    final defaultCurrencySymbol = _settingString(
      _localSettings['defaultCurrencySymbol'],
      _currencySymbolFor(defaultCurrency),
    );
    final hasExistingCustomCurrency = invoice != null &&
        invoice.currencyCode.isNotEmpty &&
        invoice.currencyCode != 'USD';
    _currencyCode = TextEditingController(
      text: hasExistingCustomCurrency ? invoice.currencyCode : defaultCurrency,
    );
    _currencySymbol = TextEditingController(
      text: (hasExistingCustomCurrency &&
              invoice.currencySymbol.isNotEmpty &&
              invoice.currencySymbol != r'$')
          ? invoice.currencySymbol
          : defaultCurrencySymbol,
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
            ? 'INR'
            : _currencyCode.text.trim().toUpperCase(),
        currencySymbol:
            _currencySymbol.text.trim().isEmpty ? '₹' : _currencySymbol.text,
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ItemCustomizerModal(
        initialSettings: _localSettings,
        onOpenInvoiceSettings: widget.onOpenInvoiceSettings,
        onApply: (applied) {
          setState(() {
            _localSettings = applied;
            if (applied['industryPresetId'] == 'security' &&
                _items.isNotEmpty &&
                _items.first.description.trim().isEmpty) {
              _items[0] = InvoiceItem(
                id: _items[0].id,
                description: 'Security Guard (12 Hrs Shift)',
                itemDetails: '',
                quantity: 1,
                dutyCount: 26,
                unitPrice: 18500,
                unit: 'Duty',
                taxRate: _items[0].taxRate,
                discountRate: _items[0].discountRate,
              );
            }
          });
          widget.onSaveLocalSettings?.call(applied);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item columns & template settings applied!')),
          );
        },
      ),
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
            ClientBillingCard(
              clientNameController: _clientName,
              companyController: _company,
              emailController: _email,
              phoneController: _phone,
              addressController: _address,
              taxIdController: _clientTaxId,
              selectedClientId: _selectedClientId,
              loadingClients: _loadingClients,
              showSuggestions: _showClientSuggestions,
              clientLoadError: _clientLoadError,
              matchingClients: _matchingClients,
              hasExactClientMatch: _hasExactClientMatch,
              canSaveClient: widget.clientRepository != null,
              onClearClient: () => setState(() {
                _selectedClientId = null;
                _clientName.clear();
                _company.clear();
                _email.clear();
                _phone.clear();
                _address.clear();
                _clientTaxId.clear();
              }),
              onApplyClient: _applyClient,
              onSaveClient: _createClientFromInvoice,
              onNameChanged: (_) => setState(() {
                _selectedClientId = null;
                _showClientSuggestions = true;
              }),
              onNameTap: () => setState(() {
                _showClientSuggestions = _clientName.text.isNotEmpty;
              }),
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
                  LineItemEditor(
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

InvoiceItem _newLineItem([bool isSecurity = false]) =>
    makeNewLineItem(isSecurity);

typedef _SectionCard = SectionCard;
typedef _ResponsiveFields = ResponsiveFields;
typedef _TotalsPreview = TotalsPreview;
typedef _ErrorBanner = ErrorBanner;

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
    appTextField(
      controller: controller,
      label: label,
      isRequired: isRequired,
      maxLines: maxLines,
      hintText: hintText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
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
    appDecimalField(
      controller: controller,
      label: label,
      min: min,
      max: max,
      allowNegative: allowNegative,
      onChanged: onChanged,
    );

Widget _dateField({
  required String label,
  required String date,
  required VoidCallback onTap,
}) =>
    appDateField(
      label: label,
      date: date,
      onTap: onTap,
    );

String? _required(String? value) => requiredValidator(value);
String _dateString(DateTime date) => formatDateString(date);
int _paymentTermDays(String terms) => parsePaymentTermDays(terms);
String _num(double value) => formatNum(value);
double _settingNumber(Object? value) => parseSettingNumber(value);
String _settingString(Object? value, String fallback) =>
    parseSettingString(value, fallback);
String _currencySymbolFor(String currency) => currencySymbolFor(currency);
String _readShippingDetails(String? value) => readShippingDetails(value);
String _serializeShippingDetails(String value) =>
    serializeShippingDetails(value);
