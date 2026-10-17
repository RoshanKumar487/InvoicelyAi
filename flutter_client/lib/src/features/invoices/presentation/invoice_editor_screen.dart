import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../clients/data/client.dart';
import '../../clients/data/clients_repository.dart';
import '../../employees/data/employee.dart';
import '../../employees/data/employee_repository.dart';
import '../../templates/data/template_config.dart';
import '../../templates/presentation/widgets/formula_builder_popup.dart';
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
  late bool _isRcm;
  late List<InvoiceItem> _items;
  List<Client> _clients = const [];
  List<Employee> _employees = const [];
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
    _isRcm = invoice?.isRcm ??
        (_localSettings['isRcmApplicable'] == true);
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
    unawaited(_loadEmployees());
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

  Future<void> _loadEmployees() async {
    try {
      final repo = EmployeeRepository(apiClient: widget.repository.apiClient);
      final employees = await repo.list();
      if (!mounted) return;
      setState(() => _employees = employees);
    } catch (_) {
      // Optional autofetch source; ignore errors
    }
  }

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
        final clientCur = client.preferredCurrency.trim().toUpperCase();
        final defaultCurrency =
            _settingString(_localSettings['defaultCurrency'], 'INR');
        final defaultCurrencySymbol = _settingString(
          _localSettings['defaultCurrencySymbol'],
          _currencySymbolFor(defaultCurrency),
        );
        if (clientCur.isNotEmpty && clientCur != 'USD') {
          _currencyCode.text = clientCur;
          _currencySymbol.text = _currencySymbolFor(clientCur);
        } else if (_currencyCode.text.trim().isEmpty ||
            _currencyCode.text.trim().toUpperCase() == 'USD') {
          _currencyCode.text = defaultCurrency;
          _currencySymbol.text = defaultCurrencySymbol;
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
              ? 'INR'
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
        isRcm: _isRcm,
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

  void _autoRoundOff(Invoice currentDraft) {
    final subtotalBeforeRound = currentDraft.taxableAmount +
        (currentDraft.isTaxInclusive ? 0 : currentDraft.taxAmount) +
        currentDraft.shippingFee +
        currentDraft.additionalCharges;
    final rounded = subtotalBeforeRound.roundToDouble();
    final diff = rounded - subtotalBeforeRound;
    setState(() {
      _roundOff.text = diff == 0 ? '0' : diff.toStringAsFixed(2);
    });
  }

  Future<void> _openFormulaPopup() async {
    final currentFormulaKey =
        _localSettings['itemCalculationFormula']?.toString() ?? 'monthly_salary_30';
    final currentDays =
        double.tryParse(_localSettings['standardDutyDays']?.toString() ?? '30') ?? 30.0;
    final sym = _currencySymbol.text.trim().isEmpty ? '₹' : _currencySymbol.text.trim();

    final result = await FormulaBuilderPopup.show(
      context,
      targetTitle: 'Subtotal & Daily Wage Formula',
      initialFormulaCode: currentFormulaKey,
      initialExpression: '(Rate / 30) * Duty * Qty',
      initialStandardDays: currentDays,
      currencySymbol: sym,
    );

    if (result == null || !mounted) return;
    final parsedDate = DateTime.tryParse(_issueDate) ?? DateTime.now();
    final calendarDays = DateTime(parsedDate.year, parsedDate.month + 1, 0).day;
    final resolvedDays = (result.formulaCode == 'calendar_month' ||
            result.formulaCode == 'monthly_salary_calendar')
        ? calendarDays.toDouble()
        : result.standardDutyDays;

    setState(() {
      _localSettings = Map<String, Object?>.from(_localSettings)
        ..['itemCalculationFormula'] = result.formulaCode
        ..['standardDutyDays'] = resolvedDays
        ..['showItemDuty'] = true;
      _items = [
        for (final item in _items)
          item.copyWith(
            calculationFormula: result.formulaCode,
            standardDutyDays: resolvedDays,
            dutyCount: item.dutyCount <= 0 ? resolvedDays : item.dutyCount,
          ),
      ];
    });
    widget.onSaveLocalSettings?.call(_localSettings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily wage formula saved: ${result.formulaExpression}'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
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
          final formulaKey =
              applied['itemCalculationFormula']?.toString() ?? 'monthly_salary_30';
          final stdDays =
              double.tryParse(applied['standardDutyDays']?.toString() ?? '30') ?? 30.0;
          setState(() {
            _localSettings = applied;
            if (applied.containsKey('isRcmApplicable')) {
              _isRcm = applied['isRcmApplicable'] == true;
            }
            if (applied['industryPresetId'] == 'security' &&
                _items.isNotEmpty &&
                _items.first.description.trim().isEmpty) {
              _items[0] = InvoiceItem(
                id: _items[0].id,
                description: 'Security Guard (12 Hrs Shift)',
                itemDetails: '',
                quantity: 1,
                dutyCount: stdDays,
                unitPrice: 30000,
                unit: 'Duty',
                taxRate: _items[0].taxRate,
                discountRate: _items[0].discountRate,
                calculationFormula: formulaKey,
                standardDutyDays: stdDays,
              );
            } else {
              _items = [
                for (final item in _items)
                  item.copyWith(
                    calculationFormula: formulaKey,
                    standardDutyDays: stdDays,
                  ),
              ];
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

  void _duplicateItem(int index) {
    final source = _items[index];
    setState(() {
      _items.insert(
        index + 1,
        source.copyWith(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}-${_items.length}',
        ),
      );
    });
  }

  void _addQuickPresetItem(ItemSuggestion preset) {
    final isSecurity = _localSettings['industryPresetId'] == 'security' ||
        _localSettings['showItemDuty'] == true;
    final formulaKey =
        _localSettings['itemCalculationFormula']?.toString() ??
            (isSecurity ? 'monthly_salary_30' : 'standard');
    final stdDays =
        double.tryParse(_localSettings['standardDutyDays']?.toString() ?? '30') ?? 30.0;
    final newItem = InvoiceItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}-${_items.length}',
      description: preset.title,
      itemDetails: preset.defaultDetails,
      quantity: 1,
      dutyCount: preset.defaultDuty ?? (isSecurity ? stdDays : 0),
      unitPrice: preset.defaultRate ?? 0,
      unit: preset.defaultUnit ?? (isSecurity ? 'Duty' : 'pcs'),
      calculationFormula: formulaKey,
      standardDutyDays: stdDays,
    );
    setState(() {
      if (_items.length == 1 &&
          _items.first.description.trim().isEmpty &&
          _items.first.unitPrice == 0) {
        _items[0] = newItem;
      } else {
        _items.add(newItem);
      }
    });
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

  bool _show(String key, {bool fallback = true}) {
    final val = _localSettings[key];
    if (val is bool) return val;
    return fallback;
  }

  String _label(String key, String fallback) {
    final val = _localSettings[key]?.toString().trim();
    return (val != null && val.isNotEmpty) ? val : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final paymentTermOptions = <String>[
      'Due on Receipt',
      'Net 15',
      'Net 30',
      'Net 60',
      if (!const ['Due on Receipt', 'Net 15', 'Net 30', 'Net 60']
          .contains(_paymentTerms))
        _paymentTerms,
    ];
    final hasNotesOpt = _show('showNotesSection', fallback: true) ||
        _notes.text.isNotEmpty ||
        _terms.text.isNotEmpty;
    final hasShippingOpt = _show('showShippingSection', fallback: false) ||
        _shippingDetails.text.isNotEmpty;
    final hasPaymentOpt = _show('showPaymentInstructions', fallback: false) ||
        _paymentInstructions.text.isNotEmpty;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF1F5F9) : null,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _saving ? null : widget.onCancel,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            Text(widget.invoice == null ? 'Create invoice' : 'Edit invoice'),
            if (isDesktop) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_mosaic_rounded, size: 13, color: Color(0xFF2563EB)),
                    SizedBox(width: 5),
                    Text(
                      'Live Document Editor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isDesktop) ...[
            OutlinedButton.icon(
              onPressed: _openItemCustomizerDialog,
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Columns & Formula'),
            ),
            const SizedBox(width: 8),
            if (widget.onOpenInvoiceSettings != null) ...[
              OutlinedButton.icon(
                onPressed: widget.onOpenInvoiceSettings,
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Invoice Settings'),
              ),
              const SizedBox(width: 8),
            ],
          ],
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
              label: Text(_saving ? 'Saving' : 'Save Invoice'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isDesktop
            ? _buildDesktopDocumentEditor(
                context: context,
                draft: draft,
                paymentTermOptions: paymentTermOptions,
                hasNotesOpt: hasNotesOpt,
                hasShippingOpt: hasShippingOpt,
                hasPaymentOpt: hasPaymentOpt,
              )
            : _buildMobileForm(
                context: context,
                draft: draft,
                paymentTermOptions: paymentTermOptions,
                hasNotesOpt: hasNotesOpt,
                hasShippingOpt: hasShippingOpt,
                hasPaymentOpt: hasPaymentOpt,
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE FORM LAYOUT (Preserved intact!)
  // ---------------------------------------------------------------------------
  Widget _buildMobileForm({
    required BuildContext context,
    required Invoice draft,
    required List<String> paymentTermOptions,
    required bool hasNotesOpt,
    required bool hasShippingOpt,
    required bool hasPaymentOpt,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (_error != null) ...[
          _ErrorBanner(message: _error!),
          const SizedBox(height: 14),
        ],
        _SectionCard(
          title: _label('customTitle', 'Invoice details'),
          subtitle: 'Number, dates and payment terms',
          children: [
            _ResponsiveFields(
              children: [
                if (_show('showInvoiceNumber', fallback: true))
                  _textField(
                    controller: _number,
                    label: _label('customInvoiceNoLabel', 'Invoice number'),
                    validator: _required,
                  ),
                if (_show('showIssueDate', fallback: true))
                  _dateField(
                    label: _label('customDateLabel', 'Issue date'),
                    date: _issueDate,
                    onTap: () => _pickDate(issue: true),
                  ),
                if (_show('showDueDate', fallback: false))
                  _dateField(
                    label: _label('customDueDateLabel', 'Due date'),
                    date: _dueDate,
                    onTap: () => _pickDate(issue: false),
                  ),
                if (_show('showPaymentTerms', fallback: false))
                  DropdownButtonFormField<String>(
                    value: _paymentTerms,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _label('customTermsLabel', 'Payment terms'),
                    ),
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
                if (_show('showPoNumber', fallback: false))
                  _textField(
                    controller: _poNumber,
                    label: _label('customPoLabel', 'Purchase order number'),
                    isRequired: false,
                  ),
                _buildTemplateDropdown(),
              ],
            ),
          ],
        ),
        if (_show('showBillToSection', fallback: true)) ...[
          const SizedBox(height: 14),
          _buildClientBillingCard(),
        ],
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Line items',
          subtitle: 'Quantities, rates and optional line discounts',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Daily Wage & Subtotal Formula Setup',
                onPressed: _openFormulaPopup,
                icon: const Icon(
                  Icons.functions_rounded,
                  color: Color(0xFF4F46E5),
                ),
              ),
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
                onPressed: _loadingPreviousItems ? null : _copyPreviousItems,
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
                issueDate: _issueDate,
                forceDesktopRow: false,
                employees: _employees,
                onOpenFormulaSettings: _openFormulaPopup,
                showDescriptionField: _globalShowItemDescriptions ||
                    _items[index].itemDetails.isNotEmpty,
                onToggleDescription: (open) {
                  setState(() => _globalShowItemDescriptions = open);
                },
                onChanged: (item) => _updateItem(index, item),
                onDuplicate: () => _duplicateItem(index),
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
              '${_isRcm ? ' · RCM Applicable' : ''}'
              ' · ${_currencyCode.text}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text('Tax Inclusive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  selected: _taxInclusive,
                  onSelected: (val) => setState(() => _taxInclusive = val),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: const Text('RCM Applicable', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  selected: _isRcm,
                  onSelected: (val) => setState(() {
                    _isRcm = val;
                    _localSettings['isRcmApplicable'] = val;
                  }),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ResponsiveFields(
              children: _buildAdjustmentFields(draft),
            ),
            const SizedBox(height: 12),
            _TotalsPreview(
              invoice: draft,
              onAutoRound: () => _autoRoundOff(draft),
            ),
          ],
        ),
        if (hasNotesOpt || hasShippingOpt || hasPaymentOpt) ...[
          const SizedBox(height: 14),
          _buildOptionalDetailsCard(
            hasNotesOpt: hasNotesOpt,
            hasShippingOpt: hasShippingOpt,
            hasPaymentOpt: hasPaymentOpt,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(
              widget.invoice == null ? 'Create invoice' : 'Save changes'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LAPTOP / DESKTOP LIVE-PREVIEW DOCUMENT-STYLE EDITOR
  // ---------------------------------------------------------------------------
  Widget _buildDesktopDocumentEditor({
    required BuildContext context,
    required Invoice draft,
    required List<String> paymentTermOptions,
    required bool hasNotesOpt,
    required bool hasShippingOpt,
    required bool hasPaymentOpt,
  }) {
    final companyName =
        _localSettings['businessName']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessName']!.toString().trim()
            : (_localSettings['companyName']?.toString().trim().isNotEmpty == true
                ? _localSettings['companyName']!.toString().trim()
                : 'Your Company');
    final companyGstin = _localSettings['businessGstin']?.toString().trim() ?? '';
    final companyAddress = _localSettings['businessAddress']?.toString().trim() ?? '';
    final sym = _currencySymbol.text.trim().isEmpty ? '₹' : _currencySymbol.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 14),
              ],

              // Document Sheet Surface
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Document Top Brand & Live Status Header Band
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        companyName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    if (companyGstin.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'GSTIN: $companyGstin',
                                          style: const TextStyle(
                                            color: Color(0xFFBFDBFE),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  companyAddress.isNotEmpty
                                      ? companyAddress
                                      : 'Interactive Document Mode • Edit fields directly below',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Live Grand Total Pill in Document Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _label('customTitle', 'TAX INVOICE').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFBFDBFE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$sym${draft.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Document Body Padding
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Row A: 2-Column Side-by-Side Bill To (Left) & Invoice Metadata (Right)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_show('showBillToSection', fallback: true)) ...[
                                Expanded(
                                  flex: 6,
                                  child: _buildClientBillingCard(),
                                ),
                                const SizedBox(width: 18),
                              ],
                              Expanded(
                                flex: 5,
                                child: _SectionCard(
                                  title: _label('customTitle', 'Invoice Details & Dates'),
                                  subtitle: 'Document number, billing dates & template style',
                                  children: [
                                    Row(
                                      children: [
                                        if (_show('showInvoiceNumber', fallback: true))
                                          Expanded(
                                            child: _textField(
                                              controller: _number,
                                              label: _label('customInvoiceNoLabel', 'Invoice number'),
                                              validator: _required,
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        if (_show('showInvoiceNumber', fallback: true) &&
                                            _show('showIssueDate', fallback: true))
                                          const SizedBox(width: 12),
                                        if (_show('showIssueDate', fallback: true))
                                          Expanded(
                                            child: _dateField(
                                              label: _label('customDateLabel', 'Issue date'),
                                              date: _issueDate,
                                              onTap: () => _pickDate(issue: true),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _dateField(
                                            label: _label('customDueDateLabel', 'Due date'),
                                            date: _dueDate,
                                            onTap: () => _pickDate(issue: false),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _paymentTerms,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: _label('customTermsLabel', 'Payment terms'),
                                            ),
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
                                            onChanged: (value) =>
                                                setState(() => _paymentTerms = value ?? 'Net 30'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _textField(
                                            controller: _poNumber,
                                            label: _label('customPoLabel', 'PO / Work Order No.'),
                                            isRequired: false,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildTemplateDropdown()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Row B: Single-Line Tabular Line Items Editor Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A0F172A),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Quick-Add Preset Toolbar above Table Header
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A8A),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${_items.length} ${_items.length == 1 ? "ITEM" : "ITEMS"}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Quick Add Service:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          for (final preset in securitySuggestions.take(5))
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: ActionChip(
                                                avatar: Icon(preset.icon, size: 14, color: const Color(0xFF2563EB)),
                                                label: Text(
                                                  '+ ${preset.title.replaceAll("Security ", "")}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                                backgroundColor: const Color(0xFFEFF6FF),
                                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => _addQuickPresetItem(preset),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton.icon(
                                            onPressed: _loadingPreviousItems ? null : _copyPreviousItems,
                                            icon: _loadingPreviousItems
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.history_rounded, size: 16),
                                            label: const Text(
                                              'Copy Previous Invoice',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          OutlinedButton.icon(
                                            onPressed: _openFormulaPopup,
                                            icon: const Icon(Icons.functions_rounded, size: 15, color: Color(0xFF4F46E5)),
                                            label: const Text(
                                              'Daily Wage Formula',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4338CA),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              side: const BorderSide(color: Color(0xFFC7D2FE)),
                                              backgroundColor: const Color(0xFFEEF2FF),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          OutlinedButton.icon(
                                            onPressed: _openItemCustomizerDialog,
                                            icon: const Icon(Icons.tune_rounded, size: 15),
                                            label: const Text(
                                              'Item Columns & Formula',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Desktop Table Column Header Bar
                                DesktopLineItemsTableHeader(
                                  localSettings: _localSettings,
                                  currencySymbol: sym,
                                  forceShowDuty: _localSettings['showItemDuty'] == true ||
                                      _localSettings['industryPresetId'] == 'security' ||
                                      _localSettings['businessType'] == 'security' ||
                                      _localSettings['industryPresetId'] == 'hr_staffing' ||
                                      (_localSettings['customItemHeader']?.toString().toLowerCase().contains('guard') == true) ||
                                      _items.any((item) => item.dutyCount > 0),
                                ),

                                // Single-Line Item Rows
                                for (var index = 0; index < _items.length; index++)
                                  LineItemEditor(
                                    key: ValueKey(_items[index].id),
                                    index: index,
                                    item: _items[index],
                                    currencySymbol: sym,
                                    localSettings: _localSettings,
                                    issueDate: _issueDate,
                                    forceDesktopRow: true,
                                    forceShowDuty: _localSettings['showItemDuty'] == true ||
                                        _localSettings['industryPresetId'] == 'security' ||
                                        _localSettings['businessType'] == 'security' ||
                                        _localSettings['industryPresetId'] == 'hr_staffing' ||
                                        (_localSettings['customItemHeader']?.toString().toLowerCase().contains('guard') == true) ||
                                        _items.any((item) => item.dutyCount > 0),
                                    employees: _employees,
                                    onOpenFormulaSettings: _openFormulaPopup,
                                    showDescriptionField: _globalShowItemDescriptions ||
                                        _items[index].itemDetails.isNotEmpty,
                                    onToggleDescription: (open) {
                                      setState(() => _globalShowItemDescriptions = open);
                                    },
                                    onChanged: (item) => _updateItem(index, item),
                                    onDuplicate: () => _duplicateItem(index),
                                    onRemove: () => _removeItem(index),
                                  ),

                                // Table Bottom Bar: Add New Line Item Button + Live Subtotal
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final isSecurity =
                                              _localSettings['industryPresetId'] == 'security' ||
                                                  _localSettings['showItemDuty'] == true;
                                          setState(() => _items.add(_newLineItem(isSecurity)));
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x332563EB),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                                              SizedBox(width: 6),
                                              Text(
                                                'Add New Line Item',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: _openFormulaPopup,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              margin: const EdgeInsets.only(right: 10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFC7D2FE)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.functions_rounded, size: 14, color: Color(0xFF4F46E5)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Formula',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF4338CA),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            'Items Gross Subtotal:',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$sym${draft.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Row C: Bottom Split — Adjustments & Notes (Left, Flex 6) + Colored Total Section (Right, Flex 5)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _SectionCard(
                                      title: 'Tax, Discounts & Adjustments',
                                      subtitle:
                                          '${_taxLabel.text} ${_num(_value(_taxRate))}% ($_taxType) · ${_currencyCode.text}',
                                      trailing: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          FilterChip(
                                            label: const Text(
                                              'Tax Inclusive',
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                            ),
                                            selected: _taxInclusive,
                                            onSelected: (val) => setState(() => _taxInclusive = val),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          FilterChip(
                                            label: const Text(
                                              'RCM Applicable',
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                            ),
                                            selected: _isRcm,
                                            onSelected: (val) => setState(() {
                                              _isRcm = val;
                                              _localSettings['isRcmApplicable'] = val;
                                            }),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _decimalField(
                                                controller: _taxRate,
                                                label: '${_taxLabel.text} Rate (%)',
                                                min: 0,
                                                max: 100,
                                                onChanged: () => setState(() {}),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: const ['GST', 'IGST', 'VAT', 'TAX', 'NONE']
                                                        .contains(_taxType.toUpperCase())
                                                    ? _taxType.toUpperCase()
                                                    : 'GST',
                                                decoration: const InputDecoration(
                                                  labelText: 'Tax Type',
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'GST',
                                                    child: Text('GST (CGST + SGST)'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'IGST',
                                                    child: Text('IGST (Inter-State)'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'VAT',
                                                    child: Text('VAT / Sales Tax'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'NONE',
                                                    child: Text('No Tax (0%)'),
                                                  ),
                                                ],
                                                onChanged: (val) {
                                                  if (val == null) return;
                                                  setState(() {
                                                    _taxType = val;
                                                    if (val == 'NONE') {
                                                      _taxRate.text = '0';
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _ResponsiveFields(
                                          children: _buildAdjustmentFields(draft),
                                        ),
                                      ],
                                    ),
                                    if (hasNotesOpt || hasShippingOpt || hasPaymentOpt) ...[
                                      const SizedBox(height: 16),
                                      _buildOptionalDetailsCard(
                                        hasNotesOpt: hasNotesOpt,
                                        hasShippingOpt: hasShippingOpt,
                                        hasPaymentOpt: hasPaymentOpt,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _TotalsPreview(
                                      invoice: draft,
                                      onAutoRound: () => _autoRoundOff(draft),
                                    ),
                                    const SizedBox(height: 16),
                                    InkWell(
                                      onTap: _saving ? null : _save,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFF059669), Color(0xFF047857)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF6EE7B7).withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x38059669),
                                              blurRadius: 14,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              _saving
                                                  ? 'Saving Invoice...'
                                                  : (widget.invoice == null
                                                      ? 'Save & Generate Invoice'
                                                      : 'Save Invoice Changes'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDropdown() {
    return DropdownButtonFormField<String>(
      value: _template,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Invoice style'),
      items: [
        if (!templatePresets.any((item) => item.id == _template))
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
        ...templatePresets.map((template) => DropdownMenuItem<String>(
              value: template.id,
              child: Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      selectedItemBuilder: (context) => [
        if (!templatePresets.any((item) => item.id == _template))
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
      onChanged: (value) => setState(() => _template = value ?? 'modern'),
    );
  }

  Widget _buildClientBillingCard() {
    return ClientBillingCard(
      localSettings: _localSettings,
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
    );
  }

  List<Widget> _buildAdjustmentFields(Invoice draft) {
    return [
      if (_show('showDiscount', fallback: true)) ...[
        _decimalField(
          controller: _discountPercent,
          label: '${_label('customDiscountLabel', 'Discount')} (%)',
          min: 0,
          max: 100,
          onChanged: () => setState(() {}),
        ),
        _decimalField(
          controller: _discountAmount,
          label: '${_label('customDiscountLabel', 'Discount')} amount',
          min: 0,
          onChanged: () => setState(() {}),
        ),
      ],
      if (_show('showShippingFee', fallback: false) || _value(_shippingFee) > 0)
        _decimalField(
          controller: _shippingFee,
          label: _label('customShippingLabel', 'Shipping'),
          min: 0,
          onChanged: () => setState(() {}),
        ),
      if (_show('showAdditionalCharges', fallback: false) || _value(_additionalCharges) > 0)
        _decimalField(
          controller: _additionalCharges,
          label: _label('customAdjustmentsLabel', 'Additional charges'),
          min: 0,
          onChanged: () => setState(() {}),
        ),
      if (_show('showRoundOff', fallback: false) || _value(_roundOff) != 0)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _decimalField(
                controller: _roundOff,
                label: '${_label('customRoundOffLabel', 'Round off')} (+/−)',
                min: -1000,
                allowNegative: true,
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: OutlinedButton.icon(
                onPressed: () => _autoRoundOff(draft),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Auto Round'),
              ),
            ),
          ],
        ),
      if (_show('showAmountPaid', fallback: true))
        _decimalField(
          controller: _amountPaid,
          label: _label('customAmountPaidLabel', 'Amount already paid'),
          min: 0,
          onChanged: () => setState(() {}),
        ),
    ];
  }

  Widget _buildOptionalDetailsCard({
    required bool hasNotesOpt,
    required bool hasShippingOpt,
    required bool hasPaymentOpt,
  }) {
    return _SectionCard(
      title: 'Notes, Terms & Instructions',
      subtitle: 'Only include the sections needed for this invoice',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasNotesOpt)
              FilterChip(
                label: const Text('Notes & terms'),
                selected: _showNotesSection,
                onSelected: (value) => setState(() => _showNotesSection = value),
              ),
            if (hasShippingOpt)
              FilterChip(
                label: Text(_label('customShipToLabel', 'Delivery details')),
                selected: _showShippingSection,
                onSelected: (value) => setState(() => _showShippingSection = value),
              ),
            if (hasPaymentOpt)
              FilterChip(
                label: const Text('Payment instructions'),
                selected: _showPaymentSection,
                onSelected: (value) => setState(() => _showPaymentSection = value),
              ),
          ],
        ),
        if (_showNotesSection && hasNotesOpt) ...[
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
        if (_showShippingSection && hasShippingOpt) ...[
          const SizedBox(height: 12),
          _textField(
            controller: _shippingDetails,
            label: _label('customShipToLabel', 'Delivery / shipping details'),
            hintText: 'Address, delivery date, carrier or tracking',
            isRequired: false,
            maxLines: 3,
          ),
        ],
        if (_showPaymentSection && hasPaymentOpt) ...[
          const SizedBox(height: 12),
          _textField(
            controller: _paymentInstructions,
            label: 'Payment instructions',
            isRequired: false,
            maxLines: 3,
          ),
        ],
      ],
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
