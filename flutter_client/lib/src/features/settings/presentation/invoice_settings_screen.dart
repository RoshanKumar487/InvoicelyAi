import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/settings_repository.dart';
import 'widgets/invoice_settings_bank_tab.dart';
import 'widgets/invoice_settings_brand_terms_tab.dart';
import 'widgets/invoice_settings_general_tabs.dart';
import 'widgets/invoice_settings_line_items_tab.dart';

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
                        InvoiceSettingsDetailsTab(
                          fieldTileBuilder: _buildFieldTile,
                          customFieldsCardBuilder: _buildCustomFieldsCard,
                          onApplyPreset: _applyQuickPreset,
                          onSave: _save,
                        ),
                        InvoiceSettingsBillingTab(
                          fieldTileBuilder: _buildFieldTile,
                          customFieldsCardBuilder: _buildCustomFieldsCard,
                          onSave: _save,
                        ),
                        InvoiceSettingsLineItemsTab(
                          localSettings: _localSettings,
                          onChanged: () => setState(() {}),
                          onSave: _save,
                          onApplyPreset: _applyQuickPreset,
                          fieldTileBuilder: _buildFieldTile,
                          customFieldsCardBuilder: _buildCustomFieldsCard,
                        ),
                        InvoiceSettingsAdjustmentsTab(
                          fieldTileBuilder: _buildFieldTile,
                          customFieldsCardBuilder: _buildCustomFieldsCard,
                          onSave: _save,
                        ),
                        InvoiceSettingsBankTab(
                          profile: _profile,
                          localSettings: _localSettings,
                          onChanged: () => setState(() {}),
                          onSave: _save,
                        ),
                        InvoiceSettingsBrandTermsTab(
                          profile: _profile,
                          localSettings: _localSettings,
                          onChanged: () => setState(() {}),
                          onSave: _save,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
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
}
