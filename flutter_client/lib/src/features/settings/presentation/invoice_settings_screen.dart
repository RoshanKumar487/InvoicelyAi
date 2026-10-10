import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../data/settings_repository.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({
    required this.apiClient,
    this.initialLocalSettings = const <String, Object?>{},
    this.onBack,
    this.onSaveLocalSettings,
    super.key,
  });

  final ApiClient apiClient;
  final Map<String, Object?> initialLocalSettings;
  final VoidCallback? onBack;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final SettingsRepository _repository;
  Map<String, dynamic> _profile = <String, dynamic>{};
  late Map<String, Object?> _localSettings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _supportedBackendFields = <String>{
    'id',
    'companyId',
    'businessName',
    'legalName',
    'email',
    'phone',
    'website',
    'address',
    'taxId',
    'gstin',
    'panNumber',
    'placeOfSupply',
    'upiId',
    'bankName',
    'accountHolder',
    'accountNumber',
    'ifscCode',
    'routingNumber',
    'swiftBic',
    'paymentLink',
    'defaultCurrency',
    'defaultCurrencySymbol',
    'defaultCurrencyFormat',
    'defaultTaxRate',
    'defaultTaxLabel',
    'defaultPaymentTerms',
    'defaultNotes',
    'defaultTerms',
    'signeeName',
    'signeeTitle',
    'brandColorHex',
  };

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(apiClient: widget.apiClient);
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);

    // Apply strict defaults based on requirements:
    // Invoice details section: default only invoice num, creation date, invoice style.
    const defaults = <String, Object?>{
      'showDocumentTitle': true,
      'showInvoiceNumber': true,
      'showIssueDate': true,
      'showDueDate': false,
      'showPoNumber': false,
      'showPaymentTerms': false,
      'showStatus': false,
      'showShippingSection': false,
      'showNotesSection': true,
      'showPaymentInstructions': true,
      'showTerms': true,
      'showNotes': true,
      'showSignature': true,
      'showLogo': true,
      'showClientCompany': true,
      'showClientEmail': true,
      'showClientPhone': true,
      'showClientAddress': true,
      'showClientTaxId': true,
      'showItemUnit': true,
      'showItemQty': true,
      'showItemRate': true,
      'showItemDiscount': false,
      'showItemTax': true,
      'showDiscount': true,
      'showShippingFee': false,
      'showAdditionalCharges': false,
      'showRoundOff': false,
      'showAmountPaid': true,
      'showBalanceDue': true,
    };

    for (final entry in defaults.entries) {
      _localSettings.putIfAbsent(entry.key, () => entry.value);
    }
    _localSettings.putIfAbsent('industryPresetId', () => 'general');
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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
        _error = 'Could not load invoice settings: $error';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCustomFields(String key) {
    final raw = _localSettings[key];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return <Map<String, dynamic>>[];
  }

  void _saveCustomFields(String key, List<Map<String, dynamic>> list) {
    setState(() {
      _localSettings[key] = list;
    });
  }

  void _addCustomFieldDialog(String key, {required String title, required String itemType}) {
    final labelCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New $itemType to $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '$itemType Name / Label *',
                hintText: itemType == 'Column' ? 'e.g. HSN/SAC, Unit' : 'e.g. Order ID, PAN No.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(
                labelText: 'Default / Sample Value (Optional)',
                hintText: 'e.g. 998311, ORD-1001',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final current = _getCustomFields(key);
              current.add({
                'id': '${key}_${DateTime.now().millisecondsSinceEpoch}',
                'label': label,
                'value': valueCtrl.text.trim(),
                'isVisible': true,
              });
              _saveCustomFields(key, current);
              Navigator.pop(ctx);
              _showFeedback('Added "$label" to $title');
            },
            child: const Text('Add Field'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _localSettings['invoiceLogo'] = base64Encode(bytes);
        _localSettings['showLogo'] = true;
      });
      _showFeedback('Logo captured. Tap Save to apply everywhere.');
    } catch (e) {
      _showFeedback('Could not load logo: $e');
    }
  }

  Future<void> _openDocuHubSigner() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: _localSettings['signeeName']?.toString() ??
          _profile['signeeName']?.toString(),
      initialSigneeTitle: _localSettings['signeeTitle']?.toString() ??
          _profile['signeeTitle']?.toString(),
    );
    if (result == null) return;
    setState(() {
      _localSettings['invoiceSignature'] = result.base64Png;
      _localSettings['showSignature'] = true;
      if (result.signeeName != null) {
        _localSettings['signeeName'] = result.signeeName;
        _profile['signeeName'] = result.signeeName;
      }
      if (result.signeeTitle != null) {
        _localSettings['signeeTitle'] = result.signeeTitle;
        _profile['signeeTitle'] = result.signeeTitle;
      }
    });
    _showFeedback('Signature captured via DocuHub Studio! Tap Save to apply.');
  }

  void _applyQuickPreset(String type) {
    setState(() {
      switch (type) {
        case 'gst':
          _localSettings['customTitle'] = 'Tax Invoice';
          _localSettings['customBillToLabel'] = 'Billed To (Recipient)';
          _localSettings['customShipToLabel'] = 'Shipped To (Consignee)';
          _localSettings['showShippingSection'] = true;
          _localSettings['customItemHeader'] = 'Description of Goods / Services';
          _localSettings['customQtyHeader'] = 'Qty';
          _localSettings['customRateHeader'] = 'Rate / Unit Price';
          _localSettings['customTaxHeader'] = 'GST (%)';
          _localSettings['customAmountHeader'] = 'Taxable Amount';
          final existingCols = _getCustomFields('customColumns_items');
          if (!existingCols.any((c) => c['label'] == 'HSN/SAC')) {
            existingCols.add({
              'id': 'col_hsn',
              'label': 'HSN/SAC',
              'value': '998311',
              'isVisible': true,
            });
            _localSettings['customColumns_items'] = existingCols;
          }
          final existingBills = _getCustomFields('customFields_billing');
          if (!existingBills.any((b) => b['label'] == 'Place of Supply')) {
            existingBills.add({
              'id': 'bill_pos',
              'label': 'Place of Supply',
              'value': '27 - Maharashtra',
              'isVisible': true,
            });
            _localSettings['customFields_billing'] = existingBills;
          }
        case 'it':
          _localSettings['customTitle'] = 'Tax Invoice';
          _localSettings['customItemHeader'] = 'Services & Deliverables';
          _localSettings['customQtyHeader'] = 'Hours';
          _localSettings['customRateHeader'] = 'Hourly Rate';
          _localSettings['customAmountHeader'] = 'Amount';
          _localSettings['showItemUnit'] = true;
          final details = _getCustomFields('customFields_details');
          if (!details.any((d) => d['label'] == 'Project Code')) {
            details.add({
              'id': 'det_proj',
              'label': 'Project Code',
              'value': 'PRJ-2026-X',
              'isVisible': true,
            });
            _localSettings['customFields_details'] = details;
          }
        case 'retail':
          _localSettings['customTitle'] = 'Retail Bill / Cash Memo';
          _localSettings['customItemHeader'] = 'Product Description';
          _localSettings['customQtyHeader'] = 'Qty';
          _localSettings['customRateHeader'] = 'Price';
          _localSettings['customAmountHeader'] = 'Total';
          _localSettings['showItemDiscount'] = true;
          _localSettings['showItemTax'] = true;
        case 'wholesale':
          _localSettings['customTitle'] = 'Commercial Invoice';
          _localSettings['customItemHeader'] = 'Particulars';
          _localSettings['customQtyHeader'] = 'Quantity';
          _localSettings['customRateHeader'] = 'Unit Price';
          _localSettings['customAmountHeader'] = 'Line Total';
          _localSettings['showShippingSection'] = true;
          _localSettings['showPoNumber'] = true;
        case 'security':
          _localSettings['industryPresetId'] = 'security_agency';
          _localSettings['customTitle'] = 'Security Services Tax Invoice';
          _localSettings['customBillToLabel'] = 'Client / Principal Employer';
          _localSettings['customShipToLabel'] = 'Deployment Site / Unit Location';
          _localSettings['showShippingSection'] = true;
          _localSettings['customItemHeader'] = 'Designation / Deployment (Supervisor, Guard, etc.)';
          _localSettings['customQtyHeader'] = 'No. of Guards / Staff';
          _localSettings['customDutyHeader'] = 'No. of Duty';
          _localSettings['customUnitHeader'] = 'Duty / Days';
          _localSettings['customRateHeader'] = 'Rate / Salary per Month';
          _localSettings['customTaxHeader'] = 'GST (18%)';
          _localSettings['customAmountHeader'] = 'Total Amount';
          _localSettings['showItemDuty'] = true;
          _localSettings['showItemUnit'] = true;
          _localSettings['showItemQty'] = true;
          _localSettings['showItemRate'] = true;
          _localSettings['showItemTax'] = true;
          _localSettings['defaultNotes'] = 'Security attendance verified by client site supervisor. Statutory EPF & ESIC challans enclosed.';
          _localSettings['defaultTerms'] = 'Payment due within 15 days of bill submission. RCM / GST compliance applicable.';
          _profile['defaultNotes'] = _localSettings['defaultNotes'];
          _profile['defaultTerms'] = _localSettings['defaultTerms'];
          final secCols = _getCustomFields('customColumns_items');
          if (!secCols.any((c) => c['label'] == 'SAC Code')) {
            secCols.add({
              'id': 'col_sec_sac',
              'label': 'SAC Code',
              'value': '998525',
              'isVisible': true,
            });
          }
          if (!secCols.any((c) => c['label'] == 'Shift / Hours')) {
            secCols.add({
              'id': 'col_sec_shift',
              'label': 'Shift / Hours',
              'value': '12 Hrs Shift',
              'isVisible': true,
            });
          }
          if (!secCols.any((c) => c['label'] == 'Duty Days')) {
            secCols.add({
              'id': 'col_sec_duty',
              'label': 'Duty Days',
              'value': '26 / 30 Days',
              'isVisible': true,
            });
          }
          _localSettings['customColumns_items'] = secCols;
        case 'hr_staffing':
          _localSettings['industryPresetId'] = 'hr_staffing';
          _localSettings['customTitle'] = 'Staffing & Salary Reimbursement Invoice';
          _localSettings['customBillToLabel'] = 'Client Organization';
          _localSettings['customShipToLabel'] = 'Office / Branch Location';
          _localSettings['showShippingSection'] = true;
          _localSettings['customItemHeader'] = 'Employee Name / Designation';
          _localSettings['customQtyHeader'] = 'Staff Count';
          _localSettings['customUnitHeader'] = 'Days Worked';
          _localSettings['customRateHeader'] = 'Monthly Salary / Rate';
          _localSettings['customTaxHeader'] = 'GST (18%)';
          _localSettings['customAmountHeader'] = 'Total Salary Due';
          _localSettings['showItemUnit'] = true;
          _localSettings['showItemQty'] = true;
          _localSettings['showItemRate'] = true;
          _localSettings['showItemTax'] = true;
          _localSettings['defaultNotes'] = 'Salary attendance muster roll attached. Net salaries disbursed to employee accounts.';
          _localSettings['defaultTerms'] = 'Monthly reimbursement payable by 5th of every calendar month.';
          _profile['defaultNotes'] = _localSettings['defaultNotes'];
          _profile['defaultTerms'] = _localSettings['defaultTerms'];
          final hrCols = _getCustomFields('customColumns_items');
          if (!hrCols.any((c) => c['label'] == 'SAC Code')) {
            hrCols.add({
              'id': 'col_hr_sac',
              'label': 'SAC Code',
              'value': '998519',
              'isVisible': true,
            });
          }
          if (!hrCols.any((c) => c['label'] == 'Emp ID')) {
            hrCols.add({
              'id': 'col_hr_empid',
              'label': 'Emp ID',
              'value': 'EMP-101',
              'isVisible': true,
            });
          }
          _localSettings['customColumns_items'] = hrCols;
        case 'freelance':
          _localSettings['customTitle'] = 'INVOICE';
          _localSettings['customItemHeader'] = 'Project Milestone / Task';
          _localSettings['customQtyHeader'] = 'Units';
          _localSettings['customRateHeader'] = 'Fee';
          _localSettings['customAmountHeader'] = 'Total';
          _localSettings['showSignature'] = true;
      }
    });
    _showFeedback('Applied $type preset. Review & tap Save to keep.');
  }

  Widget _presetChip(String id, String label, String subtitle) {
    final currentId = _localSettings['industryPresetId']?.toString();
    final isSelected = currentId == id ||
        (id == 'security' && (currentId == 'security_agency' || _localSettings['customItemHeader']?.toString().contains('Guards') == true)) ||
        (id == 'hr_staffing' && (currentId == 'hr_staffing' || _localSettings['customItemHeader']?.toString().contains('Employee') == true)) ||
        (id == 'gst' && (_localSettings['customTaxHeader']?.toString().contains('GST') == true && currentId != 'security' && currentId != 'security_agency')) ||
        (id == 'it' && _localSettings['customQtyHeader']?.toString() == 'Hours') ||
        (id == 'freelance' && _localSettings['customRateHeader']?.toString() == 'Fee');
    return InkWell(
      onTap: () => _applyQuickPreset(id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF2563EB)),
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

  Future<void> _save() async {
    final rate = double.tryParse(_profile['defaultTaxRate']?.toString() ?? '18') ?? 18.0;
    if (rate < 0 || rate > 100) {
      _showFeedback('Enter a default tax rate from 0 to 100.');
      return;
    }
    setState(() => _saving = true);
    try {
      final localSettings = Map<String, Object?>.from(_localSettings)
        ..addAll({
          'defaultTaxRate': rate,
          'defaultTaxLabel':
              _profile['defaultTaxLabel']?.toString().trim().isNotEmpty == true
                  ? _profile['defaultTaxLabel']
                  : 'Tax',
          'defaultCurrency': _profile['defaultCurrency'] ?? 'INR',
          'defaultCurrencySymbol': _profile['defaultCurrencySymbol'] ?? '₹',
          'defaultPaymentTerms':
              _profile['defaultPaymentTerms']?.toString().trim().isNotEmpty == true
                  ? _profile['defaultPaymentTerms']
                  : 'Net 30',
          'bankName': _profile['bankName'] ?? _localSettings['bankName'] ?? '',
          'accountHolder': _profile['accountHolder'] ?? _localSettings['accountHolder'] ?? '',
          'accountNumber': _profile['accountNumber'] ?? _localSettings['accountNumber'] ?? '',
          'ifscCode': _profile['ifscCode'] ?? _localSettings['ifscCode'] ?? '',
          'swiftBic': _profile['swiftBic'] ?? _localSettings['swiftBic'] ?? '',
          'upiId': _profile['upiId'] ?? _localSettings['upiId'] ?? '',
          'paymentLink': _profile['paymentLink'] ?? _localSettings['paymentLink'] ?? '',
          'defaultNotes': _profile['defaultNotes'] ?? _localSettings['defaultNotes'] ?? '',
          'defaultTerms': _profile['defaultTerms'] ?? _localSettings['defaultTerms'] ?? '',
          'defaultPaymentInstructions': _localSettings['defaultPaymentInstructions'] ?? '',
          'defaultShippingDetails': _localSettings['defaultShippingDetails'] ?? '',
          'showBankDetails': _localSettings['showBankDetails'] ?? true,
          'showQrCode': _localSettings['showQrCode'] ?? true,
        });
      await widget.onSaveLocalSettings?.call(
        Map<String, Object?>.unmodifiable(localSettings),
      );
      setState(() => _localSettings = localSettings);
      final payload = <String, Object?>{
        for (final entry in _profile.entries)
          if (_supportedBackendFields.contains(entry.key))
            entry.key: entry.value,
      };
      final savedProfile = await _repository.saveProfile(payload);
      if (!mounted) return;
      setState(() => _profile = savedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ All customizations, bank details & defaults saved!'),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showFeedback(error.message);
    } catch (error) {
      if (mounted) _showFeedback('Could not save invoice settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Image? _getBrandImage(String key, {double height = 50}) {
    final encoded = _localSettings[key]?.toString() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return Image.memory(
        base64Decode(encoded),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Invoice Customization Studio'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save All'),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.description_outlined), text: 'Details & Style'),
              Tab(icon: Icon(Icons.person_pin_outlined), text: 'Bills & Client'),
              Tab(icon: Icon(Icons.table_chart_outlined), text: 'Line Items'),
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Adjustments'),
              Tab(icon: Icon(Icons.account_balance_outlined), text: 'Bank & UPI'),
              Tab(icon: Icon(Icons.draw_outlined), text: 'Brand & Terms'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.errorContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _error = null),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(),
                        _buildBillingTab(),
                        _buildLineItemsTab(),
                        _buildAdjustmentsTab(),
                        _buildBankTab(),
                        _buildBrandingAndTermsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DETAILS & STYLE
  // ---------------------------------------------------------------------------
  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Invoice Details Section',
          'Configure document title, invoice number, creation dates, and add custom metadata like Order ID or Project Code.',
        ),
        const SizedBox(height: 12),

        // Quick Presets
        _buildPresetsCard(),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Style & Core Fields',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'By default, only Invoice Number, Creation Date, and Invoice Style are shown on your invoice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),

              // Title / Style
              _buildFieldTile(
                title: 'Invoice Style / Title',
                description: 'Main letterhead document title',
                toggleKey: 'showDocumentTitle',
                defaultToggle: true,
                labelKey: 'customTitle',
                fallbackLabel: 'Tax Invoice',
                hint: 'e.g. Tax Invoice, Bill of Supply',
              ),
              const Divider(height: 24),

              // Invoice Number
              _buildFieldTile(
                title: 'Invoice Number',
                description: 'Unique invoice identifier',
                toggleKey: 'showInvoiceNumber',
                defaultToggle: true,
                labelKey: 'customInvoiceNoLabel',
                fallbackLabel: 'Invoice #',
                hint: 'e.g. Bill No., Ref #',
              ),
              const Divider(height: 24),

              // Creation Date
              _buildFieldTile(
                title: 'Creation Date (Issue Date)',
                description: 'Date invoice was created',
                toggleKey: 'showIssueDate',
                defaultToggle: true,
                labelKey: 'customDateLabel',
                fallbackLabel: 'Creation Date',
                hint: 'e.g. Invoice Date, Date',
              ),
              const Divider(height: 24),

              // Due Date (Default Hidden)
              _buildFieldTile(
                title: 'Due Date',
                description: 'Payment due deadline (Default: Hidden)',
                toggleKey: 'showDueDate',
                defaultToggle: false,
                labelKey: 'customDueDateLabel',
                fallbackLabel: 'Due Date',
                hint: 'e.g. Payment Due',
              ),
              const Divider(height: 24),

              // PO Number (Default Hidden)
              _buildFieldTile(
                title: 'Purchase Order (PO) Number',
                description: 'Client purchase order reference (Default: Hidden)',
                toggleKey: 'showPoNumber',
                defaultToggle: false,
                labelKey: 'customPoLabel',
                fallbackLabel: 'PO Number',
                hint: 'e.g. Customer PO #',
              ),
              const Divider(height: 24),

              // Payment Terms (Default Hidden)
              _buildFieldTile(
                title: 'Payment Terms',
                description: 'e.g. Net 30, Due on Receipt (Default: Hidden)',
                toggleKey: 'showPaymentTerms',
                defaultToggle: false,
                labelKey: 'customTermsLabel',
                fallbackLabel: 'Payment Terms',
                hint: 'e.g. Terms',
              ),
              const Divider(height: 24),

              // Status Badge (Default Hidden)
              _buildFieldTile(
                title: 'Invoice Status Badge',
                description: 'Paid, Sent, Draft pill (Default: Hidden)',
                toggleKey: 'showStatus',
                defaultToggle: false,
                labelKey: 'customStatusLabel',
                fallbackLabel: 'Status',
                hint: 'e.g. State',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM FIELDS IN DETAILS
        _buildCustomFieldsCard(
          key: 'customFields_details',
          title: 'Invoice Details',
          itemType: 'Field',
          hintText: 'e.g. Order ID, Project Name, Delivery Challan #, Sales Rep',
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: BILLS & CLIENT
  // ---------------------------------------------------------------------------
  Widget _buildBillingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Bills & Client Section',
          'Rename billing headers, toggle client details, shipping sections, and add custom fields like PAN Number or Place of Supply.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing & Shipping Section Labels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              // Bill To Header
              _buildFieldTile(
                title: 'Bill To Section Header',
                description: 'Section heading above customer address',
                toggleKey: 'showBillToSection',
                defaultToggle: true,
                labelKey: 'customBillToLabel',
                fallbackLabel: 'BILL TO',
                hint: 'e.g. Invoiced To, Customer Details',
              ),
              const Divider(height: 24),

              // Ship To Header (Default Hidden)
              _buildFieldTile(
                title: 'Ship To / Delivery Section',
                description: 'Separate shipping recipient details (Default: Hidden)',
                toggleKey: 'showShippingSection',
                defaultToggle: false,
                labelKey: 'customShipToLabel',
                fallbackLabel: 'SHIPPING DETAILS',
                hint: 'e.g. Shipped To, Delivery Address',
              ),
              const Divider(height: 24),

              // Client Name
              _buildFieldTile(
                title: 'Client / Customer Name',
                description: 'Primary customer name line',
                toggleKey: 'showClientName',
                defaultToggle: true,
                labelKey: 'customClientNameLabel',
                fallbackLabel: 'Client Name',
                hint: 'e.g. Customer Name, M/s',
              ),
              const Divider(height: 24),

              // Company Name
              _buildFieldTile(
                title: 'Company Name',
                description: 'Customer company or legal entity',
                toggleKey: 'showClientCompany',
                defaultToggle: true,
                labelKey: 'customClientCompanyLabel',
                fallbackLabel: 'Company Name',
                hint: 'e.g. Business Name',
              ),
              const Divider(height: 24),

              // Email Address
              _buildFieldTile(
                title: 'Email Address',
                description: 'Billing email line',
                toggleKey: 'showClientEmail',
                defaultToggle: true,
                labelKey: 'customClientEmailLabel',
                fallbackLabel: 'Email',
                hint: 'e.g. Billing Email',
              ),
              const Divider(height: 24),

              // Phone Number
              _buildFieldTile(
                title: 'Phone Number',
                description: 'Contact phone line',
                toggleKey: 'showClientPhone',
                defaultToggle: true,
                labelKey: 'customClientPhoneLabel',
                fallbackLabel: 'Phone',
                hint: 'e.g. Mobile, Contact',
              ),
              const Divider(height: 24),

              // Billing Address
              _buildFieldTile(
                title: 'Billing Address',
                description: 'Street, city, postal code',
                toggleKey: 'showClientAddress',
                defaultToggle: true,
                labelKey: 'customClientAddressLabel',
                fallbackLabel: 'Billing Address',
                hint: 'e.g. Address',
              ),
              const Divider(height: 24),

              // GSTIN / Tax ID
              _buildFieldTile(
                title: 'Tax ID / GSTIN',
                description: 'Customer tax registration',
                toggleKey: 'showClientTaxId',
                defaultToggle: true,
                labelKey: 'customClientTaxIdLabel',
                fallbackLabel: 'GSTIN / Tax ID',
                hint: 'e.g. GSTIN, VAT No., Tax ID',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM FIELDS IN BILLING
        _buildCustomFieldsCard(
          key: 'customFields_billing',
          title: 'Bills & Client',
          itemType: 'Field',
          hintText: 'e.g. PAN Number, Place of Supply, Customer Code, State Code',
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: LINE ITEMS
  // ---------------------------------------------------------------------------
  Widget _buildLineItemsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Line Items & Table Columns',
          'Rename all column headers, show/hide optional columns (tax, discount, units), and add brand new custom columns like HSN/SAC Code or SKU.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_center_outlined, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Business Industry Presets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your business category to instantly set the right column labels, duty/salary formulas, and SAC codes:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip('security', '🛡️ Security Agency & Guards', 'Supervisor, Guard, Days, Rate/Salary'),
                  _presetChip('hr_staffing', '👤 HR Staffing & Payroll', 'Staff, Days Worked, Monthly Salary'),
                  _presetChip('gst', '⚖️ GST Tax Invoice', 'Goods / Services, HSN/SAC, Qty, Rate'),
                  _presetChip('it', '💻 IT & Software Consulting', 'Deliverables, Hours, Hourly Rate'),
                  _presetChip('retail', '🛍️ Retail & Wholesale', 'Product, Qty, Price, Discount'),
                  _presetChip('freelance', '🎨 Freelance Services', 'Tasks, Milestones, Units, Fee'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Line Items Column Headers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              // Description Column
              _buildFieldTile(
                title: 'Item Description Column',
                description: 'Primary product or service name',
                toggleKey: 'showItemDescription',
                defaultToggle: true,
                labelKey: 'customItemHeader',
                fallbackLabel: 'Description',
                hint: 'e.g. Particulars, Items, Services',
              ),
              const Divider(height: 24),

              // Quantity Column
              _buildFieldTile(
                title: 'Quantity / Staff Column',
                description: 'Number of units purchased or guards deployed',
                toggleKey: 'showItemQty',
                defaultToggle: true,
                labelKey: 'customQtyHeader',
                fallbackLabel: 'Qty',
                hint: 'e.g. Units, No. of Staff, Guards',
              ),
              const Divider(height: 24),

              // Duty Column
              _buildFieldTile(
                title: 'No. of Duty / Days Column',
                description: 'Duties, shifts, or days worked per staff (multiplies Staff × Duty × Rate)',
                toggleKey: 'showItemDuty',
                defaultToggle: false,
                labelKey: 'customDutyHeader',
                fallbackLabel: 'No. of Duty',
                hint: 'e.g. No. of Duty, Duty Days, Shifts',
              ),
              const Divider(height: 24),

              // Unit of Measure
              _buildFieldTile(
                title: 'Unit Measurement Badge',
                description: 'e.g. hrs, pcs, kg, days',
                toggleKey: 'showItemUnit',
                defaultToggle: true,
                labelKey: 'customUnitHeader',
                fallbackLabel: 'Unit',
                hint: 'e.g. UOM, Unit',
              ),
              const Divider(height: 24),

              // Rate / Unit Price
              _buildFieldTile(
                title: 'Rate / Price Column',
                description: 'Unit cost per item',
                toggleKey: 'showItemRate',
                defaultToggle: true,
                labelKey: 'customRateHeader',
                fallbackLabel: 'Rate',
                hint: 'e.g. Unit Price, Price, Fee',
              ),
              const Divider(height: 24),

              // Discount Column
              _buildFieldTile(
                title: 'Item Discount Column',
                description: 'Per-item discount rate (%)',
                toggleKey: 'showItemDiscount',
                defaultToggle: false,
                labelKey: 'customDiscountHeader',
                fallbackLabel: 'Discount',
                hint: 'e.g. Disc %, Rebate',
              ),
              const Divider(height: 24),

              // Item Tax Column
              _buildFieldTile(
                title: 'Item Tax Column',
                description: 'Per-item tax rate (%)',
                toggleKey: 'showItemTax',
                defaultToggle: true,
                labelKey: 'customTaxHeader',
                fallbackLabel: 'Tax (%)',
                hint: 'e.g. GST %, VAT %',
              ),
              const Divider(height: 24),

              // Line Amount / Total Column
              _buildFieldTile(
                title: 'Amount / Total Column',
                description: 'Total line amount calculation',
                toggleKey: 'showItemAmount',
                defaultToggle: true,
                labelKey: 'customAmountHeader',
                fallbackLabel: 'Amount',
                hint: 'e.g. Total, Net Amount',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM COLUMNS IN LINE ITEMS
        _buildCustomFieldsCard(
          key: 'customColumns_items',
          title: 'Line Items Table',
          itemType: 'Column',
          hintText: 'e.g. HSN/SAC Code, SKU / Barcode, Part #, Batch No.',
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: ADJUSTMENTS & TOTALS
  // ---------------------------------------------------------------------------
  Widget _buildAdjustmentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Invoice Adjustments & Summary Totals',
          'Rename calculation rows, show/hide discounts, shipping fees, round offs, and add custom adjustment charges like Packaging & Handling.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Summary Labels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              // Subtotal
              _buildFieldTile(
                title: 'Subtotal Row',
                description: 'Gross sum of all line items',
                toggleKey: 'showSubtotal',
                defaultToggle: true,
                labelKey: 'customSubtotalLabel',
                fallbackLabel: 'Subtotal',
                hint: 'e.g. Gross Total',
              ),
              const Divider(height: 24),

              // Discount
              _buildFieldTile(
                title: 'Discount Adjustment',
                description: 'Invoice-level or item discount deduction',
                toggleKey: 'showDiscount',
                defaultToggle: true,
                labelKey: 'customDiscountLabel',
                fallbackLabel: 'Discount',
                hint: 'e.g. Special Discount, Promo',
              ),
              const Divider(height: 24),

              // Tax / GST
              _buildFieldTile(
                title: 'Tax Breakdown Row',
                description: 'Tax rate & total calculated tax',
                toggleKey: 'showTax',
                defaultToggle: true,
                labelKey: 'customTaxLabel',
                fallbackLabel: 'Tax',
                hint: 'e.g. GST, VAT, Sales Tax',
              ),
              const Divider(height: 24),

              // Shipping Fee (Default Hidden)
              _buildFieldTile(
                title: 'Shipping & Delivery Fee',
                description: 'Freight / courier charge (Default: Hidden)',
                toggleKey: 'showShippingFee',
                defaultToggle: false,
                labelKey: 'customShippingLabel',
                fallbackLabel: 'Shipping',
                hint: 'e.g. Delivery & Handling, Freight',
              ),
              const Divider(height: 24),

              // Additional Charges (Default Hidden)
              _buildFieldTile(
                title: 'Additional Charges / Adjustments',
                description: 'Misc adjustments (Default: Hidden)',
                toggleKey: 'showAdditionalCharges',
                defaultToggle: false,
                labelKey: 'customAdjustmentsLabel',
                fallbackLabel: 'Adjustments',
                hint: 'e.g. Other Charges, Surcharge',
              ),
              const Divider(height: 24),

              // Round Off (Default Hidden)
              _buildFieldTile(
                title: 'Round Off',
                description: 'Decimal rounding adjustment (Default: Hidden)',
                toggleKey: 'showRoundOff',
                defaultToggle: false,
                labelKey: 'customRoundOffLabel',
                fallbackLabel: 'Round off',
                hint: 'e.g. Rounding (+/-)',
              ),
              const Divider(height: 24),

              // Total Amount
              _buildFieldTile(
                title: 'Total Amount Row',
                description: 'Final payable invoice balance',
                toggleKey: 'showTotal',
                defaultToggle: true,
                labelKey: 'customTotalLabel',
                fallbackLabel: 'Total',
                hint: 'e.g. Grand Total, Invoice Total',
              ),
              const Divider(height: 24),

              // Amount Paid
              _buildFieldTile(
                title: 'Amount Paid Row',
                description: 'Advance or payments received',
                toggleKey: 'showAmountPaid',
                defaultToggle: true,
                labelKey: 'customAmountPaidLabel',
                fallbackLabel: 'Amount paid',
                hint: 'e.g. Paid, Advance Received',
              ),
              const Divider(height: 24),

              // Balance Due
              _buildFieldTile(
                title: 'Balance Due Row',
                description: 'Remaining outstanding amount',
                toggleKey: 'showBalanceDue',
                defaultToggle: true,
                labelKey: 'customBalanceDueLabel',
                fallbackLabel: 'Balance due',
                hint: 'e.g. Net Payable, Amount Due',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM ADJUSTMENT FIELDS
        _buildCustomFieldsCard(
          key: 'customFields_adjustments',
          title: 'Invoice Adjustments',
          itemType: 'Fee / Charge',
          hintText: 'e.g. Packaging Fee, Insurance, Cess, Service Fee',
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: BANK & DIGITAL PAYMENT (UPI)
  // ---------------------------------------------------------------------------
  Widget _buildBankTab() {
    final bankName = _profile['bankName']?.toString() ??
        _localSettings['bankName']?.toString() ??
        '';
    final accHolder = _profile['accountHolder']?.toString() ??
        _localSettings['accountHolder']?.toString() ??
        '';
    final accNo = _profile['accountNumber']?.toString() ??
        _localSettings['accountNumber']?.toString() ??
        '';
    final ifsc = _profile['ifscCode']?.toString() ??
        _localSettings['ifscCode']?.toString() ??
        '';
    final swift = _profile['swiftBic']?.toString() ??
        _localSettings['swiftBic']?.toString() ??
        '';
    final upi = _profile['upiId']?.toString() ??
        _localSettings['upiId']?.toString() ??
        '';
    final payLink = _profile['paymentLink']?.toString() ??
        _localSettings['paymentLink']?.toString() ??
        '';

    final showBank = _localSettings['showBankDetails'] != false;
    final showQr = _localSettings['showQrCode'] != false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Bank & Digital Payment Configuration',
          'Configure your company bank account and optional UPI ID. When UPI ID or payment link is provided, a Scan-to-Pay QR code will be generated on invoices.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Options',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Bank & Payment Details on Invoices',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Displays account number, IFSC code, and beneficiary details on invoices',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showBank,
                onChanged: (val) =>
                    setState(() => _localSettings['showBankDetails'] = val),
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Scan-to-Pay QR Code (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Strictly optional: generated only if UPI ID or payment link is provided below. If left blank, QR code is hidden.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showQr,
                onChanged: (val) =>
                    setState(() => _localSettings['showQrCode'] = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bank Account Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: bankName,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g. HDFC Bank, State Bank of India, ICICI Bank',
                  prefixIcon: Icon(Icons.business_outlined, size: 18),
                ),
                onChanged: (val) {
                  _profile['bankName'] = val.trim();
                  _localSettings['bankName'] = val.trim();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: accHolder,
                decoration: const InputDecoration(
                  labelText: 'Account Holder / Beneficiary Name',
                  hintText: 'e.g. Acme Security Services Pvt Ltd',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
                onChanged: (val) {
                  _profile['accountHolder'] = val.trim();
                  _localSettings['accountHolder'] = val.trim();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      initialValue: accNo,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        hintText: 'e.g. 50200012345678',
                        prefixIcon: Icon(Icons.credit_card_outlined, size: 18),
                      ),
                      onChanged: (val) {
                        _profile['accountNumber'] = val.trim();
                        _localSettings['accountNumber'] = val.trim();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      initialValue: ifsc,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code',
                        hintText: 'e.g. HDFC0001234',
                        prefixIcon: Icon(Icons.pin_outlined, size: 18),
                      ),
                      onChanged: (val) {
                        _profile['ifscCode'] = val.trim().toUpperCase();
                        _localSettings['ifscCode'] = val.trim().toUpperCase();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: swift,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'SWIFT / BIC (Optional for international)',
                  hintText: 'e.g. HDFCINBBXXX',
                  prefixIcon: Icon(Icons.language_outlined, size: 18),
                ),
                onChanged: (val) {
                  _profile['swiftBic'] = val.trim().toUpperCase();
                  _localSettings['swiftBic'] = val.trim().toUpperCase();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_2, color: Color(0xFF047857), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Instant Digital Payment & UPI (Optional)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Customers can scan the QR code using Google Pay, PhonePe, Paytm, BHIM, or any UPI app to pay invoice balance directly.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: upi,
                decoration: const InputDecoration(
                  labelText: 'UPI ID / VPA (Optional)',
                  hintText: 'e.g. yourbusiness@okhdfcbank, 9876543210@paytm',
                  prefixIcon: Icon(Icons.flash_on_outlined, size: 18, color: Color(0xFF047857)),
                  helperText: 'Creates dynamic Scan-to-Pay QR code on invoice',
                ),
                onChanged: (val) {
                  _profile['upiId'] = val.trim();
                  _localSettings['upiId'] = val.trim();
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: payLink,
                decoration: const InputDecoration(
                  labelText: 'Payment Gateway Link (Optional)',
                  hintText: 'e.g. https://rzp.io/l/yourlink or https://stripe.com/...',
                  prefixIcon: Icon(Icons.link_outlined, size: 18),
                  helperText: 'Shown as clickable payment link on invoice & PDF',
                ),
                onChanged: (val) {
                  _profile['paymentLink'] = val.trim();
                  _localSettings['paymentLink'] = val.trim();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 6: BRANDING, NOTES & TERMS
  // ---------------------------------------------------------------------------
  Widget _buildBrandingAndTermsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Branding, Terms & DocuHub Signature',
          'Upload your company logo (enabled by default), capture your digital signature via DocuHub, and customize footer terms and bank payment instructions.',
        ),
        const SizedBox(height: 14),

        // LOGO CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Company Logo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: _localSettings['showLogo'] != false,
                    onChanged: (val) => setState(() => _localSettings['showLogo'] = val),
                  ),
                ],
              ),
              const Text(
                'Displayed at the top of all templates (Enabled by default)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _getBrandImage('invoiceLogo', height: 60) ??
                        const Center(
                          child: Icon(Icons.business_outlined, color: Colors.grey, size: 32),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickLogo(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Gallery'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _pickLogo(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Camera'),
                            ),
                          ],
                        ),
                        if (_localSettings['invoiceLogo'] != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _localSettings.remove('invoiceLogo')),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
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

        // DOCUHUB SIGNATURE CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DocuHub Digital Signature',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: _localSettings['showSignature'] != false,
                    onChanged: (val) => setState(() => _localSettings['showSignature'] = val),
                  ),
                ],
              ),
              const Text(
                'Draw with smooth Bezier ink, type in cursive, or photograph ink on paper',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 130,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _getBrandImage('invoiceSignature', height: 60) ??
                        const Center(
                          child: Icon(Icons.draw_outlined, color: Colors.grey, size: 30),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _openDocuHubSigner,
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: Text(
                            _localSettings['invoiceSignature'] != null
                                ? 'Edit Signature'
                                : 'Capture Signature',
                          ),
                        ),
                        if (_localSettings['invoiceSignature'] != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _localSettings.remove('invoiceSignature')),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _localSettings['signeeTitle']?.toString() ??
                          _profile['signeeTitle']?.toString() ??
                          'Authorized Signatory',
                      decoration: const InputDecoration(
                        labelText: 'Signatory Title',
                        isDense: true,
                        hintText: 'e.g. Managing Director, Founder',
                      ),
                      onChanged: (val) {
                        _localSettings['signeeTitle'] = val;
                        _profile['signeeTitle'] = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: _localSettings['signeeName']?.toString() ??
                          _profile['signeeName']?.toString() ??
                          '',
                      decoration: const InputDecoration(
                        labelText: 'Signatory Name',
                        isDense: true,
                        hintText: 'e.g. John Doe',
                      ),
                      onChanged: (val) {
                        _localSettings['signeeName'] = val;
                        _profile['signeeName'] = val;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // DEFAULT INVOICE CONTENT (PRE-FILLED ON EVERY NEW INVOICE)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.feed_outlined, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Default Invoice Content & Defaults',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'These texts are automatically pre-filled into all new invoices, saving you repetitive typing:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _profile['defaultNotes']?.toString() ??
                    _localSettings['defaultNotes']?.toString() ??
                    '',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Default Notes & Remarks',
                  hintText:
                      'e.g. Thank you for your business. Security attendance verified by site supervisor.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                ),
                onChanged: (val) {
                  _profile['defaultNotes'] = val;
                  _localSettings['defaultNotes'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _profile['defaultTerms']?.toString() ??
                    _localSettings['defaultTerms']?.toString() ??
                    '',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Default Terms & Conditions',
                  hintText:
                      'e.g. Payment due within 15 days of bill submission. Interest @ 18% p.a. on overdue bills.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.gavel_rounded, size: 18),
                ),
                onChanged: (val) {
                  _profile['defaultTerms'] = val;
                  _localSettings['defaultTerms'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _localSettings['defaultPaymentInstructions']?.toString() ?? '',
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Default Payment Instructions',
                  hintText:
                      'e.g. Please mention Invoice # in NEFT narration. Cheques payable to Acme Security.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.payment_rounded, size: 18),
                ),
                onChanged: (val) {
                  _localSettings['defaultPaymentInstructions'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _localSettings['defaultShippingDetails']?.toString() ?? '',
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Default Delivery / Site Shipping Details',
                  hintText:
                      'e.g. Unit deployment post, gate supervisor contact, delivery terms.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.local_shipping_outlined, size: 18),
                ),
                onChanged: (val) {
                  _localSettings['defaultShippingDetails'] = val;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // TERMS, NOTES & INSTRUCTIONS
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Footer Notes, Terms & Instructions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              // Payment Instructions
              _buildFieldTile(
                title: 'Payment Instructions Header',
                description: 'Bank account, UPI, transfer instructions',
                toggleKey: 'showPaymentInstructions',
                defaultToggle: true,
                labelKey: 'customPaymentInstructionsLabel',
                fallbackLabel: 'PAYMENT INSTRUCTIONS',
                hint: 'e.g. Bank Account / Transfer Info',
              ),
              const Divider(height: 24),

              // Notes Header
              _buildFieldTile(
                title: 'Notes & Remarks Header',
                description: 'Special client notes or thank you messages',
                toggleKey: 'showNotes',
                defaultToggle: true,
                labelKey: 'customNotesLabel',
                fallbackLabel: 'Notes',
                hint: 'e.g. Remarks, Thank you note',
              ),
              const Divider(height: 24),

              // Terms Header
              _buildFieldTile(
                title: 'Terms & Conditions Header',
                description: 'Legal terms, jurisdiction, warranty clauses',
                toggleKey: 'showTerms',
                defaultToggle: true,
                labelKey: 'customTermsLabel',
                fallbackLabel: 'Terms & Conditions',
                hint: 'e.g. Terms of Service, Legal Clauses',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM FOOTER FIELDS
        _buildCustomFieldsCard(
          key: 'customFields_footer',
          title: 'Footer & Terms',
          itemType: 'Field',
          hintText: 'e.g. Bank IFSC, SWIFT BIC, Declaration, UPI ID',
        ),

        const SizedBox(height: 24),
        _buildBottomSaveButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE FIELD TILE WITH TOGGLE AND CUSTOM LABEL INPUT
  // ---------------------------------------------------------------------------
  Widget _buildFieldTile({
    required String title,
    required String description,
    required String toggleKey,
    required bool defaultToggle,
    required String labelKey,
    required String fallbackLabel,
    required String hint,
  }) {
    final isEnabled = _localSettings[toggleKey] != null
        ? _localSettings[toggleKey] == true
        : defaultToggle;
    final currentCustomLabel = _localSettings[labelKey]?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isEnabled ? null : Colors.grey[600],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (val) {
                setState(() => _localSettings[toggleKey] = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: currentCustomLabel.isNotEmpty ? currentCustomLabel : '',
          enabled: isEnabled,
          decoration: InputDecoration(
            labelText: 'Custom Label for "$title"',
            hintText: currentCustomLabel.isNotEmpty ? currentCustomLabel : fallbackLabel,
            isDense: true,
            prefixIcon: const Icon(Icons.edit_outlined, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() {
              if (value.trim().isEmpty) {
                _localSettings.remove(labelKey);
              } else {
                _localSettings[labelKey] = value.trim();
              }
            });
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOM FIELDS SECTION FOR ANY CATEGORY
  // ---------------------------------------------------------------------------
  Widget _buildCustomFieldsCard({
    required String key,
    required String title,
    required String itemType,
    required String hintText,
  }) {
    final customList = _getCustomFields(key);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom $itemType' 's ($title)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      hintText,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _addCustomFieldDialog(key, title: title, itemType: itemType),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add $itemType'),
              ),
            ],
          ),
          if (customList.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No custom $itemType added yet. Tap "+ Add $itemType" to add custom fields to this section.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (int i = 0; i < customList.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              _buildCustomFieldRow(key, i, customList[i], itemType),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomFieldRow(
    String key,
    int index,
    Map<String, dynamic> item,
    String itemType,
  ) {
    final isVisible = item['isVisible'] != false;
    final label = item['label']?.toString() ?? 'Custom $itemType';
    final value = item['value']?.toString() ?? '';

    return Row(
      children: [
        Switch(
          value: isVisible,
          onChanged: (val) {
            final list = _getCustomFields(key);
            list[index]['isVisible'] = val;
            _saveCustomFields(key, list);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isVisible ? null : Colors.grey,
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  'Default: $value',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Edit Field',
          onPressed: () {
            _editCustomFieldDialog(key, index, item, itemType);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          tooltip: 'Delete Field',
          onPressed: () {
            final list = _getCustomFields(key);
            list.removeAt(index);
            _saveCustomFields(key, list);
            _showFeedback('Removed "$label"');
          },
        ),
      ],
    );
  }

  void _editCustomFieldDialog(
    String key,
    int index,
    Map<String, dynamic> item,
    String itemType,
  ) {
    final labelCtrl = TextEditingController(text: item['label']?.toString() ?? '');
    final valCtrl = TextEditingController(text: item['value']?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $itemType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(labelText: '$itemType Label *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valCtrl,
              decoration: const InputDecoration(labelText: 'Default Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newLabel = labelCtrl.text.trim();
              if (newLabel.isEmpty) return;
              final list = _getCustomFields(key);
              list[index]['label'] = newLabel;
              list[index]['value'] = valCtrl.text.trim();
              _saveCustomFields(key, list);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRESETS & INFO BANNER
  // ---------------------------------------------------------------------------
  Widget _buildInfoBanner(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1-Click Industry Presets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Instantly populate standard labels & columns for your trade',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Indian GST Bill'),
                onPressed: () => _applyQuickPreset('gst'),
              ),
              ActionChip(
                avatar: const Icon(Icons.code, size: 16),
                label: const Text('IT & Consulting'),
                onPressed: () => _applyQuickPreset('it'),
              ),
              ActionChip(
                avatar: const Icon(Icons.storefront, size: 16),
                label: const Text('Retail Store'),
                onPressed: () => _applyQuickPreset('retail'),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_shipping, size: 16),
                label: const Text('Wholesale & Logistics'),
                onPressed: () => _applyQuickPreset('wholesale'),
              ),
              ActionChip(
                avatar: const Icon(Icons.palette, size: 16),
                label: const Text('Freelancer / Creative'),
                onPressed: () => _applyQuickPreset('freelance'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveButton() {
    return FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: const Icon(Icons.check_circle_outline),
      label: Text(_saving ? 'Saving...' : 'Save All Invoice Customizations'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
