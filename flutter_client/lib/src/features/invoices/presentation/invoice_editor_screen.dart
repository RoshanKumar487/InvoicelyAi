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
    super.key,
  });

  final InvoiceRepository repository;
  final Invoice? invoice;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> initialLocalSettings;
  final ClientsRepository? clientRepository;
  final VoidCallback onCancel;
  final ValueChanged<Invoice> onSaved;

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
  late final Map<String, Object?> _localSettings;
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
      _items.add(_newLineItem());
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

  void _updateItem(int index, InvoiceItem item) {
    setState(() => _items[index] = item);
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      setState(() => _items[index] = _newLineItem());
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
              trailing: IconButton(
                tooltip: 'Add item',
                onPressed: () => setState(() => _items.add(_newLineItem())),
                icon: const Icon(Icons.add_circle_outline),
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

InvoiceItem _newLineItem() => InvoiceItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      description: '',
      quantity: 1,
      unitPrice: 0,
    );

class _LineItemEditor extends StatefulWidget {
  const _LineItemEditor({
    required this.index,
    required this.item,
    required this.currencySymbol,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final InvoiceItem item;
  final String currencySymbol;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<_LineItemEditor> {
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unit;
  late final TextEditingController _discount;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.item.description);
    _quantity = TextEditingController(text: _num(widget.item.quantity));
    _unitPrice = TextEditingController(text: _num(widget.item.unitPrice));
    _unit = TextEditingController(text: widget.item.unit);
    _discount = TextEditingController(text: _num(widget.item.discountRate));
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(InvoiceItem(
      id: widget.item.id,
      description: _description.text,
      quantity: double.tryParse(_quantity.text) ?? 0,
      unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      taxRate: widget.item.taxRate,
      discountRate: double.tryParse(_discount.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) => Column(
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
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What are you billing for?',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Add a description'
                : null,
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 10),
          _ResponsiveFields(
            children: [
              _itemNumberField(
                controller: _quantity,
                label: 'Quantity',
                min: 0.000001,
                onChanged: _notify,
              ),
              _itemNumberField(
                controller: _unitPrice,
                label: 'Unit price (${widget.currencySymbol})',
                min: 0,
                onChanged: _notify,
              ),
              TextField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'pcs, hrs, days',
                ),
                onChanged: (_) => _notify(),
              ),
              _itemNumberField(
                controller: _discount,
                label: 'Discount (%)',
                min: 0,
                max: 100,
                onChanged: _notify,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total: ${widget.currencySymbol}${widget.item.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      );
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
