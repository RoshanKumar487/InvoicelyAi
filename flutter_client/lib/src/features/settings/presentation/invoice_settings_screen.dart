import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../templates/data/document_template_schema.dart';
import '../../templates/data/template_config.dart';
import '../../templates/data/template_layout_engine.dart';
import '../../templates/data/wysiwyg_pdf_exporter.dart';
import '../../templates/presentation/widgets/template_logo_studio.dart';
import '../../templates/presentation/widgets/template_presets_gallery.dart';
import '../../templates/presentation/widgets/wysiwyg_canvas_preview.dart';
import '../data/settings_repository.dart';
import 'widgets/invoice_settings_bank_tab.dart';
import 'widgets/invoice_settings_brand_terms_tab.dart';
import 'widgets/invoice_settings_general_tabs.dart';
import 'widgets/invoice_settings_line_items_tab.dart';

/// Unified Invoice Customization & WYSIWYG Template Studio.
/// Features a Word/Doc editor formatting toolbar, modular section box design,
/// duty/shift formulas, and live real-time border-boxed A4 canvas preview & PDF export.
class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({
    required this.apiClient,
    this.initialLocalSettings = const <String, Object?>{},
    this.initialConfig,
    this.onBack,
    this.onSaveLocalSettings,
    this.onSaveTemplate,
    super.key,
  });

  final ApiClient apiClient;
  final Map<String, Object?> initialLocalSettings;
  final TemplateConfig? initialConfig;
  final VoidCallback? onBack;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;
  final ValueChanged<TemplateConfig>? onSaveTemplate;

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final SettingsRepository _repository;
  Map<String, dynamic> _profile = <String, dynamic>{};
  late Map<String, Object?> _localSettings;
  late TemplateConfig _config;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Template gallery states
  String _presetId = 'gst_tax';
  String _selectedCategory = 'All';
  String _selectedStyle = 'All';

  // Doc/Word Editor formatting states
  double _baseFontSize = 10.5;
  String _tableDensity = 'normal'; // 'compact', 'normal', 'spacious'
  String _fontFamily = 'Inter';

  // Live WYSIWYG preview controls
  int _simulatedItemCount = 5;
  double _previewZoom = 0.82;
  bool _mobileShowPreview = false;
  late final ScrollController _previewScrollController;

  // JSON Schema Editor
  late final TextEditingController _jsonController;
  String? _jsonValidationError;

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

  static const _categories = [
    ('All', 'All Categories'),
    ('Security Agency', '🛡️ Security Agency'),
    ('HR & Staffing', '👥 HR & Staffing'),
    ('IT & Consulting', '💻 IT & Consulting'),
    ('Retail & GST', '🛍️ Retail & GST'),
    ('Corporate Suite', '🏢 Corporate Suite'),
  ];

  static const _styles = [
    'All',
    'Modern',
    'Classic',
    'Corporate',
    'Smart',
    'Minimal',
    'Industry',
  ];

  static const _colorSwatches = [
    {'name': 'Navy Blue', 'hex': '#1E3A8A'},
    {'name': 'Zoho Sky', 'hex': '#0284C7'},
    {'name': 'Emerald Teal', 'hex': '#0F766E'},
    {'name': 'Midnight Slate', 'hex': '#0F172A'},
    {'name': 'Indigo Blue', 'hex': '#6366F1'},
    {'name': 'Crimson Red', 'hex': '#B91C1C'},
    {'name': 'Amber Gold', 'hex': '#D97706'},
    {'name': 'Cool Charcoal', 'hex': '#334155'},
  ];

  String get _activeBusinessCategory {
    final bt = _profile['businessType']?.toString() ??
        _localSettings['businessType']?.toString() ??
        _localSettings['industryPresetId']?.toString() ??
        'security';
    switch (bt) {
      case 'security':
      case 'security_agency':
        return 'Security Agency';
      case 'it':
        return 'IT & Consulting';
      case 'retail':
        return 'Retail & GST';
      case 'wholesale':
        return 'Corporate Suite';
      case 'hr_staffing':
        return 'HR & Staffing';
      default:
        return 'Security Agency';
    }
  }

  List<(String, String)> get _availableCategories {
    final cat = _activeBusinessCategory;
    if (cat.isNotEmpty && cat != 'All') {
      return [
        (cat, cat == 'Security Agency' ? '🛡️ Security Agency (Business Mode)' : '🏢 $cat (Business Mode)'),
      ];
    }
    return _categories;
  }

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(apiClient: widget.apiClient);
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
    _previewScrollController = ScrollController();
    _jsonController = TextEditingController();

    // Default section visibility & line item configurations
    final isSecurityCategory = _activeBusinessCategory == 'Security Agency';
    final defaults = <String, Object?>{
      'showDocumentTitle': true,
      'showInvoiceNumber': true,
      'showIssueDate': true,
      'showDueDate': false,
      'showPoNumber': false,
      'showPaymentTerms': false,
      'showStatus': false,
      'showShippingSection': false, // STRICTLY DEFAULT OFF
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
      'showItemDescription': true,
      'showItemQty': true,
      'showItemDuty': isSecurityCategory,
      'showItemRate': true,
      'showItemAmount': true,
      'showItemUnit': !isSecurityCategory,
      'showItemTax': !isSecurityCategory,
      'showItemDiscount': false,
      'showItemNumber': false,
      'showDiscount': true,
      'showShippingFee': false,
      'showAdditionalCharges': false,
      'showRoundOff': false,
      'showAmountPaid': true,
      'showBalanceDue': true,
      'showBankDetails': true,
      'showQrCode': true,
      'brandColorHex': '#1E3A8A',
      'industryPresetId': isSecurityCategory ? 'security_agency' : 'general',
      'tableDensity': 'normal',
      'baseFontSize': 10.5,
      'fontFamily': 'Inter',
      'customTitle': 'TAX INVOICE',
      'customItemHeader': 'Particulars',
      'customQtyHeader': 'Qty.',
      'customDutyHeader': 'Duty',
      'customRateHeader': 'Rate',
      'customAmountHeader': 'Amount',
      'customBillToLabel': 'BILLED TO',
      'customShipToLabel': 'DISPATCH & SUPPLY DETAILS',
      'itemCalculationFormula': isSecurityCategory ? 'monthly_salary_26' : 'standard',
      'standardDutyDays': 26.0,
      'customColumns_items': <Map<String, dynamic>>[],
    };

    for (final entry in defaults.entries) {
      _localSettings.putIfAbsent(entry.key, () => entry.value);
    }

    _tableDensity = _localSettings['tableDensity']?.toString() ?? 'normal';
    _baseFontSize = (_localSettings['baseFontSize'] as num?)?.toDouble() ?? 10.5;
    _fontFamily = _localSettings['fontFamily']?.toString() ?? 'Inter';

    final activeCat = _activeBusinessCategory;
    _selectedCategory = activeCat;

    final catPresets = templatePresets.where((p) => p.businessCategory == activeCat).toList();
    if (widget.initialConfig != null &&
        (catPresets.isEmpty || catPresets.any((p) => p.id == widget.initialConfig!.id))) {
      _config = widget.initialConfig!;
      _presetId = _config.id;
    } else if (catPresets.isNotEmpty) {
      _config = catPresets.first;
      _presetId = catPresets.first.id;
    } else {
      _config = templatePresets.firstWhere((preset) => preset.id == 'gst_tax');
      _presetId = _config.id;
    }

    _load();
  }

  @override
  void dispose() {
    _previewScrollController.dispose();
    _jsonController.dispose();
    super.dispose();
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
        _selectedCategory = _activeBusinessCategory;

        if (profile['brandColorHex'] != null && profile['brandColorHex'].toString().isNotEmpty) {
          final hex = profile['brandColorHex'].toString();
          _localSettings['brandColorHex'] = hex;
          _config = _config.copyWith(color: hex);
        }
      });
      _syncJsonEditor();
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

  void _syncJsonEditor() {
    final schema = _buildSchemaFromSettings();
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(schema.toJson());
    _jsonValidationError = null;
  }

  // ---------------------------------------------------------------------------
  // TEMPLATE SELECTION & LOGO LOGIC
  // ---------------------------------------------------------------------------
  void _selectPreset(String? id) {
    if (id == null) return;
    final preset = templatePresets.firstWhere((template) => template.id == id);
    setState(() {
      _presetId = id;
      _config = preset.copyWith(
        showLogo: _config.showLogo,
        showBillFrom: _config.showBillFrom,
        showBillTo: _config.showBillTo,
        showBankDetails: _config.showBankDetails,
        showShipping: _localSettings['showShippingSection'] == true,
        showNotes: _config.showNotes,
        showTerms: _config.showTerms,
        showSignature: _config.showSignature,
        showTaxBreakdown: preset.showTaxBreakdown,
        showPaymentInstructions: preset.showPaymentInstructions,
      );
      _localSettings['brandColorHex'] = preset.color;
      _localSettings['secondaryColorHex'] = preset.secondaryColor;
      _localSettings['headerLayout'] = preset.headerLayout;
      _localSettings['tableStyle'] = preset.tableStyle;
    });
    _syncJsonEditor();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final updatedSettings = Map<String, Object?>.from(_localSettings)
        ..['invoiceLogo'] = base64
        ..['showLogo'] = true;
      setState(() {
        _localSettings = updatedSettings;
        _config = _config.copyWith(showLogo: true);
      });
      widget.onSaveLocalSettings?.call(updatedSettings);
      if (mounted) {
        _showFeedback('✓ Business logo uploaded & applied to template!');
      }
    } catch (e) {
      if (mounted) _showFeedback('Could not pick logo: $e');
    }
  }

  void _removeLogo() {
    final updatedSettings = Map<String, Object?>.from(_localSettings)..remove('invoiceLogo');
    setState(() {
      _localSettings = updatedSettings;
    });
    widget.onSaveLocalSettings?.call(updatedSettings);
    _showFeedback('Logo removed from template.');
  }

  Image? _getLogoImage({double height = 45}) {
    final encoded = _localSettings['invoiceLogo']?.toString() ?? '';
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

  // ---------------------------------------------------------------------------
  // CUSTOM FIELDS HELPERS
  // ---------------------------------------------------------------------------
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
    _syncJsonEditor();
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

  // ---------------------------------------------------------------------------
  // INDUSTRY PRESETS
  // ---------------------------------------------------------------------------
  void _applyQuickPreset(String type) {
    setState(() {
      switch (type) {
        case 'gst':
          _localSettings['customTitle'] = 'Tax Invoice';
          _localSettings['customBillToLabel'] = 'Billed To (Recipient)';
          _localSettings['customShipToLabel'] = 'Shipped To (Consignee)';
          _localSettings['showShippingSection'] = false; // Kept false by default
          _localSettings['customItemHeader'] = 'Description of Goods / Services';
          _localSettings['customQtyHeader'] = 'Qty';
          _localSettings['customRateHeader'] = 'Rate / Unit Price';
          _localSettings['customTaxHeader'] = 'GST (%)';
          _localSettings['customAmountHeader'] = 'Taxable Amount';
          _localSettings['brandColorHex'] = '#047857';
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
        case 'it':
          _localSettings['customTitle'] = 'Tax Invoice';
          _localSettings['customItemHeader'] = 'Services & Deliverables';
          _localSettings['customQtyHeader'] = 'Hours';
          _localSettings['customRateHeader'] = 'Hourly Rate';
          _localSettings['customAmountHeader'] = 'Amount';
          _localSettings['showItemUnit'] = true;
          _localSettings['brandColorHex'] = '#0284C7';
        case 'retail':
          _localSettings['customTitle'] = 'Retail Bill / Cash Memo';
          _localSettings['customItemHeader'] = 'Product Description';
          _localSettings['customQtyHeader'] = 'Qty';
          _localSettings['customRateHeader'] = 'Price';
          _localSettings['customAmountHeader'] = 'Total';
          _localSettings['showItemDiscount'] = true;
          _localSettings['showItemTax'] = true;
          _localSettings['brandColorHex'] = '#0F172A';
        case 'wholesale':
          _localSettings['customTitle'] = 'Commercial Invoice';
          _localSettings['customItemHeader'] = 'Particulars';
          _localSettings['customQtyHeader'] = 'Quantity';
          _localSettings['customRateHeader'] = 'Unit Price';
          _localSettings['customAmountHeader'] = 'Line Total';
          _localSettings['showShippingSection'] = true;
          _localSettings['showPoNumber'] = true;
          _localSettings['brandColorHex'] = '#1E3A8A';
        case 'security':
        case 'security_agency':
          _localSettings['industryPresetId'] = 'security_agency';
          _localSettings['customTitle'] = 'TAX INVOICE';
          _localSettings['customBillToLabel'] = 'BILLED TO';
          _localSettings['customShipToLabel'] = 'DISPATCH & SUPPLY DETAILS';
          _localSettings['showShippingSection'] = false; // Strictly OFF by default
          _localSettings['showDueDate'] = false; // Strictly OFF by default
          _localSettings['showPoNumber'] = false; // Strictly OFF by default
          _localSettings['showPaymentTerms'] = false; // Strictly OFF by default
          _localSettings['showStatus'] = false; // Strictly OFF by default
          _localSettings['customItemHeader'] = 'Particulars';
          _localSettings['customQtyHeader'] = 'Qty.';
          _localSettings['customDutyHeader'] = 'Duty';
          _localSettings['customRateHeader'] = 'Rate';
          _localSettings['customAmountHeader'] = 'Amount';
          _localSettings['showItemDescription'] = true;
          _localSettings['showItemQty'] = true;
          _localSettings['showItemDuty'] = true;
          _localSettings['showItemRate'] = true;
          _localSettings['showItemAmount'] = true;
          _localSettings['showItemUnit'] = false; // No redundant unit column
          _localSettings['showItemTax'] = false; // Tax is summarized in totals, not cluttering items table
          _localSettings['showItemDiscount'] = false;
          _localSettings['showItemNumber'] = false;
          _localSettings['itemCalculationFormula'] = 'monthly_salary_26';
          _localSettings['standardDutyDays'] = 26.0;
          _localSettings['isRcmApplicable'] = true;
          _localSettings['brandColorHex'] = '#1E3A8A';
          _localSettings['customColumns_items'] = <Map<String, dynamic>>[]; // CLEAR redundant custom columns
          _localSettings['defaultNotes'] =
              'Security attendance verified by client site supervisor. Statutory EPF & ESIC challans enclosed.';
          _localSettings['defaultTerms'] =
              'Payment due within 15 days of bill submission. RCM / GST compliance applicable.';
          _profile['defaultNotes'] = _localSettings['defaultNotes'];
          _profile['defaultTerms'] = _localSettings['defaultTerms'];
        case 'hr_staffing':
          _localSettings['industryPresetId'] = 'hr_staffing';
          _localSettings['customTitle'] = 'Staffing & Salary Reimbursement Invoice';
          _localSettings['customBillToLabel'] = 'Client Organization';
          _localSettings['customShipToLabel'] = 'Office / Branch Location';
          _localSettings['showShippingSection'] = false;
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
          _localSettings['brandColorHex'] = '#0F766E';
          _localSettings['defaultNotes'] =
              'Salary attendance muster roll attached. Net salaries disbursed to employee accounts.';
          _localSettings['defaultTerms'] =
              'Monthly reimbursement payable by 5th of every calendar month.';
          _profile['defaultNotes'] = _localSettings['defaultNotes'];
          _profile['defaultTerms'] = _localSettings['defaultTerms'];
        case 'freelance':
          _localSettings['customTitle'] = 'INVOICE';
          _localSettings['customItemHeader'] = 'Project Milestone / Task';
          _localSettings['customQtyHeader'] = 'Units';
          _localSettings['customRateHeader'] = 'Fee';
          _localSettings['customAmountHeader'] = 'Total';
          _localSettings['showSignature'] = true;
          _localSettings['brandColorHex'] = '#6366F1';
      }
    });
    _syncJsonEditor();
    _showFeedback('Applied $type preset. Review live A4 preview & tap Save to keep.');
  }

  // ---------------------------------------------------------------------------
  // DYNAMIC WYSIWYG SCHEMA & LAYOUT GENERATION
  // ---------------------------------------------------------------------------
  DocumentTemplateSchema _buildSchemaFromSettings() {
    final primaryHex = _localSettings['brandColorHex']?.toString().trim().isNotEmpty == true
        ? _localSettings['brandColorHex']!.toString().trim()
        : _config.color;
    final secondaryHex = _localSettings['secondaryColorHex']?.toString().trim().isNotEmpty == true
        ? _localSettings['secondaryColorHex']!.toString().trim()
        : _config.secondaryColor;

    final isClassicHeader = _config.headerLayout == 'classic' || _localSettings['headerLayout'] == 'classic';
    final tableStyle = _localSettings['tableStyle']?.toString() ?? _config.tableStyle;

    final baseFont = (_localSettings['baseFontSize'] as num?)?.toDouble() ?? _baseFontSize;
    final fontFamily = _localSettings['fontFamily']?.toString() ?? _fontFamily;
    final density = _localSettings['tableDensity']?.toString() ?? _tableDensity;
    final rowHeight = density == 'compact' ? 18.0 : (density == 'spacious' ? 28.0 : 22.0);

    // Build dynamic table columns based on user customization
    final cols = <TemplateColumnConfig>[];

    // Optional Row Number column
    if (_localSettings['showItemNumber'] == true) {
      cols.add(const TemplateColumnConfig(
        key: '#',
        label: '#',
        width: '32',
        priority: 1,
        align: 'center',
      ));
    }

    // 1. Item / Description Header (Particulars)
    final itemLabel = _localSettings['customItemHeader']?.toString().trim().isNotEmpty == true
        ? _localSettings['customItemHeader']!.toString().trim()
        : _config.itemHeader;
    cols.add(TemplateColumnConfig(
      key: 'item',
      label: itemLabel,
      width: 'flex',
      priority: 1,
      align: 'left',
    ));

    // 2. Quantity / Guards Column (Qty.)
    if (_localSettings['showItemQty'] != false) {
      final qtyLabel = _localSettings['customQtyHeader']?.toString().trim().isNotEmpty == true
          ? _localSettings['customQtyHeader']!.toString().trim()
          : _config.quantityHeader;
      cols.add(TemplateColumnConfig(
        key: 'qty',
        label: qtyLabel,
        width: '45',
        priority: 2,
        align: 'center',
      ));
    }

    // 3. Duty / Shift Days Column (Duty)
    final showDuty = _localSettings['showItemDuty'] == true || _config.showDuty;
    if (showDuty) {
      final dutyLabel = _localSettings['customDutyHeader']?.toString().trim().isNotEmpty == true
          ? _localSettings['customDutyHeader']!.toString().trim()
          : _config.dutyHeader;
      cols.add(TemplateColumnConfig(
        key: 'duty',
        label: dutyLabel,
        width: '65',
        priority: 2,
        align: 'center',
      ));
    }

    // 4. Custom Item Columns (if user explicitly added any)
    final customCols = _getCustomFields('customColumns_items');
    for (final c in customCols) {
      if (c['isVisible'] != false) {
        cols.add(TemplateColumnConfig(
          key: c['id']?.toString() ?? c['label']?.toString().toLowerCase() ?? 'custom',
          label: c['label']?.toString() ?? 'Field',
          width: '70',
          priority: 2,
          align: 'center',
        ));
      }
    }

    // 5. Unit of Measure (Optional, default hidden for security)
    if (_localSettings['showItemUnit'] == true) {
      final unitLabel = _localSettings['customUnitHeader']?.toString().trim().isNotEmpty == true
          ? _localSettings['customUnitHeader']!.toString().trim()
          : 'Unit';
      cols.add(TemplateColumnConfig(
        key: 'unit',
        label: unitLabel,
        width: '50',
        priority: 3,
        align: 'center',
      ));
    }

    // 6. HSN/SAC Code (Optional, default hidden for security)
    if (_localSettings['showItemTax'] == true &&
        !customCols.any((c) =>
            c['label']?.toString().toUpperCase() == 'HSN/SAC' ||
            c['label']?.toString().toUpperCase() == 'SAC CODE')) {
      cols.add(const TemplateColumnConfig(
        key: 'hsn',
        label: 'HSN/SAC',
        width: '65',
        priority: 3,
        align: 'center',
      ));
    }

    // 7. Rate / Unit Price Column (Rate)
    if (_localSettings['showItemRate'] != false) {
      final rateLabel = _localSettings['customRateHeader']?.toString().trim().isNotEmpty == true
          ? _localSettings['customRateHeader']!.toString().trim()
          : _config.rateHeader;
      cols.add(TemplateColumnConfig(
        key: 'rate',
        label: rateLabel,
        width: '85',
        priority: 2,
        align: 'right',
      ));
    }

    // 8. Item Discount (Optional)
    if (_localSettings['showItemDiscount'] == true) {
      cols.add(const TemplateColumnConfig(
        key: 'discount',
        label: 'Disc %',
        width: '50',
        priority: 3,
        align: 'center',
      ));
    }

    // 9. Amount / Total (Amount)
    final amountLabel = _localSettings['customAmountHeader']?.toString().trim().isNotEmpty == true
        ? _localSettings['customAmountHeader']!.toString().trim()
        : _config.amountHeader;
    cols.add(TemplateColumnConfig(
      key: 'amount',
      label: amountLabel,
      width: '95',
      priority: 1,
      align: 'right',
    ));

    // Pipeline sections with live toggle binding
    final sections = [
      TemplateSection(
        id: 'sec_header',
        type: 'header',
        isEnabled: _localSettings['showDocumentTitle'] != false,
        config: TemplateSectionConfig(
          logoMaxWidth: 140,
          logoMaxHeight: 65,
          companyBlockAlign: isClassicHeader ? 'center' : 'left',
        ),
      ),
      TemplateSection(
        id: 'sec_party',
        type: 'party_details',
        isEnabled: _localSettings['showBillFrom'] != false ||
            _localSettings['showBillTo'] != false ||
            _localSettings['showShippingSection'] == true,
      ),
      TemplateSection(
        id: 'sec_items',
        type: 'item_table',
        isEnabled: true,
        config: TemplateSectionConfig(
          columns: cols,
          rowMinHeight: rowHeight,
          stripedRows: tableStyle != 'clean',
          showBorders: tableStyle == 'boxed',
          repeatHeader: true,
        ),
      ),
      const TemplateSection(
        id: 'sec_totals',
        type: 'totals',
        isEnabled: true,
        config: TemplateSectionConfig(totalsAlign: 'right', keepWithPrevious: true),
      ),
      TemplateSection(
        id: 'sec_bank_qr',
        type: 'bank_qr',
        isEnabled: (_localSettings['showBankDetails'] != false && _config.showBankDetails) ||
            _localSettings['showQrCode'] != false,
        config: TemplateSectionConfig(
          showQr: _localSettings['showQrCode'] != false,
          qrSize: 85,
        ),
      ),
      TemplateSection(
        id: 'sec_notes',
        type: 'notes_terms',
        isEnabled: _localSettings['showNotes'] != false ||
            _localSettings['showTerms'] != false ||
            _localSettings['showPaymentInstructions'] != false,
      ),
      TemplateSection(
        id: 'sec_sign',
        type: 'signature',
        isEnabled: _localSettings['showSignature'] != false && _config.showSignature,
        config: TemplateSectionConfig(
          signatureMode: SignatureMode.fixedBottom,
          signatureHeight: 70,
          signatureLabel: _localSettings['signeeTitle']?.toString().trim().isNotEmpty == true
              ? _localSettings['signeeTitle']!.toString().trim()
              : (_profile['signeeTitle']?.toString().trim().isNotEmpty == true
                  ? _profile['signeeTitle']!.toString().trim()
                  : 'Authorized Signatory'),
        ),
      ),
      const TemplateSection(
        id: 'sec_footer',
        type: 'footer',
        isEnabled: true,
      ),
    ];

    return DocumentTemplateSchema(
      metadata: TemplateMetadata(
        id: _config.id,
        name: _config.name,
        category: _config.businessCategory,
        pageSize: TemplatePageSize.a4,
      ),
      style: TemplateStyle(
        fontFamily: fontFamily,
        baseSize: baseFont,
        primaryColor: primaryHex,
        secondaryColor: secondaryHex,
        accentColor: '#F59E0B',
        zebraColor: tableStyle == 'striped' ? '#F8FAFC' : '#FFFFFF',
        borderRadius: tableStyle == 'boxed' ? 4 : 6,
      ),
      sections: sections,
    );
  }

  List<LayoutLineItem> _generateSampleItems() {
    final list = <LayoutLineItem>[];
    final isSecurity = _localSettings['industryPresetId'] == 'security_agency' ||
        _config.businessCategory == 'Security Agency';
    final isHr = _localSettings['industryPresetId'] == 'hr_staffing' ||
        _config.businessCategory == 'HR & Staffing';
    final isIt = _localSettings['industryPresetId'] == 'it' ||
        _config.businessCategory == 'IT & Consulting';

    for (int i = 1; i <= _simulatedItemCount; i++) {
      if (isSecurity) {
        final roles = [
          ('Security Guard (12-hour shift)', 2.0, 26.0, 24500.0, 49000.0),
          ('Armed Guard (12-hour shift)', 4.0, 26.0, 21500.0, 86000.0),
          ('CCTV & Surveillance Operator (12-hour shift)', 2.0, 26.0, 19500.0, 39000.0),
        ];
        final role = roles[(i - 1) % roles.length];
        list.add(LayoutLineItem(
          name: role.$1,
          description: '',
          hsn: '998525',
          qty: role.$2,
          duty: role.$3,
          unitPrice: role.$4,
          amount: role.$5,
          unit: 'Days',
          customValues: const {},
        ));
      } else if (isHr) {
        final staffing = [
          ('Senior Cloud Architect', 'Enterprise AWS/GCP Kubernetes Orchestration', '998519', 1.0, 185000.0),
          ('Full Stack Engineer (Lead)', 'React Native & Microservices Architecture', '998519', 2.0, 135000.0),
          ('DevOps Automation Specialist', 'Terraform CI/CD Pipeline & Security Hardening', '998519', 1.0, 115000.0),
          ('QA Automation Engineer', 'Playwright & Regression Testing Suite', '998519', 2.0, 85000.0),
        ];
        final emp = staffing[(i - 1) % staffing.length];
        list.add(LayoutLineItem(
          name: '${emp.$1} (EMP-00$i)',
          description: emp.$2,
          hsn: emp.$3,
          qty: emp.$4,
          unitPrice: emp.$5,
          amount: emp.$4 * emp.$5,
          unit: 'Month',
          customValues: {
            'col_hr_sac': '998519',
            'col_hr_empid': 'EMP-10$i',
          },
        ));
      } else if (isIt) {
        final itServices = [
          ('Enterprise Cloud Architecture', 'Quarterly High-Availability Infrastructure Blueprint', '998313', 80.0, 1200.0),
          ('Security & SOC Compliance Audit', 'ISO 27001 & SOC-2 Type II Penetration Testing', '998314', 45.0, 1500.0),
          ('SLA Technical Support & Maintenance', '24x7 Tier-3 Production Monitoring', '998315', 1.0, 45000.0),
        ];
        final it = itServices[(i - 1) % itServices.length];
        list.add(LayoutLineItem(
          name: '${it.$1} #0$i',
          description: it.$2,
          hsn: it.$3,
          qty: it.$4,
          unitPrice: it.$5,
          amount: it.$4 * it.$5,
          unit: 'Hrs',
          customValues: {
            'det_proj': 'PRJ-2026-X',
          },
        ));
      } else {
        list.add(LayoutLineItem(
          name: 'Professional Business Deliverable Module #0$i',
          description: i.isEven ? 'Quarterly SLA maintenance and compliance review' : '',
          hsn: '998311',
          qty: (i % 3 + 1).toDouble(),
          unitPrice: 12500.0 + (i * 2000),
          amount: (12500.0 + (i * 2000)) * (i % 3 + 1),
          unit: 'Units',
        ));
      }
    }
    return list;
  }

  TemplateLayoutResult _computeCurrentLayout(DocumentTemplateSchema schema) {
    final items = _generateSampleItems();
    return TemplateLayoutEngine.computeLayout(
      schema: schema,
      items: items,
      pageWidth: schema.metadata.pageSize.previewWidth,
      pageHeight: schema.metadata.pageSize.previewHeight,
      hasBank: _localSettings['showBankDetails'] != false && _config.showBankDetails,
      hasNotes: _localSettings['showNotes'] != false || _config.showNotes,
    );
  }

  Future<void> _exportSamplePdf(DocumentTemplateSchema schema, TemplateLayoutResult layoutResult) async {
    try {
      final pdfBytes = await WysiwygPdfExporter.build(
        schema: schema,
        layoutResult: layoutResult,
        companyName: _localSettings['businessName']?.toString().isNotEmpty == true
            ? _localSettings['businessName']!.toString()
            : (_profile['businessName']?.toString().isNotEmpty == true
                ? _profile['businessName']!.toString()
                : 'Central Security Force'),
        companyAddress: _localSettings['businessAddress']?.toString() ??
            _profile['address']?.toString() ??
            '82-82-2772A, Hyderabad, Telangana, India -520007',
        companyGstin: _localSettings['businessGstin']?.toString() ?? _profile['gstin']?.toString() ?? 'TG72882828TGH818',
        companyPan: _localSettings['businessPan']?.toString() ?? _profile['panNumber']?.toString() ?? 'IC8188282J',
        clientName: 'Enterprise Client Corp',
        clientAddress: '42 Prestige Tech Park, Bangalore, KA 560103',
        clientGstin: '29ABCDE1234F1Z5',
        currencySymbol: 'Rs.',
        bankName: _profile['bankName']?.toString() ?? _localSettings['bankName']?.toString() ?? 'Axis Bank',
        accountNumber: _profile['accountNumber']?.toString() ?? _localSettings['accountNumber']?.toString() ?? '717272727727',
        ifsc: _profile['ifscCode']?.toString() ?? _localSettings['ifscCode']?.toString() ?? 'T7272GGF',
        upiId: _profile['upiId']?.toString() ?? _localSettings['upiId']?.toString() ?? 'csf7887@kotak',
        notes: _profile['defaultNotes']?.toString() ?? _localSettings['defaultNotes']?.toString() ?? '',
        terms: _profile['defaultTerms']?.toString() ??
            _localSettings['defaultTerms']?.toString() ??
            'Security attendance verified by client site supervisor. Statutory EPF & ESIC challans enclosed.\nPayment due within 15 days of bill submission. RCM / GST compliance applicable.',
        logoBase64: _localSettings['invoiceLogo']?.toString(),
        signatureBase64: _localSettings['digitalSignature']?.toString() ?? _profile['digitalSignature']?.toString(),
        showLogo: _localSettings['showLogo'] != false && _config.showLogo,
        showBillFrom: _localSettings['showBillFrom'] != false && _config.showBillFrom,
        showBillTo: _localSettings['showBillTo'] != false && _config.showBillTo,
        showShipping: _localSettings['showShippingSection'] == true, // STRICTLY RESPECTS USER TOGGLE
        showDueDate: _localSettings['showDueDate'] == true,
        showPoNumber: _localSettings['showPoNumber'] == true,
        showPaymentTerms: _localSettings['showPaymentTerms'] == true,
        showStatus: _localSettings['showStatus'] == true,
        showBankDetails: _localSettings['showBankDetails'] != false && _config.showBankDetails,
        showNotes: _localSettings['showNotes'] != false && _config.showNotes,
        showTerms: _localSettings['showTerms'] != false && _config.showTerms,
        showSignature: _localSettings['showSignature'] != false && _config.showSignature,
        customTitle: _localSettings['customTitle']?.toString() ?? _config.title,
        customBillToLabel: _localSettings['customBillToLabel']?.toString() ?? 'BILLED TO',
        customShipToLabel: _localSettings['customShipToLabel']?.toString() ?? 'DISPATCH & SUPPLY DETAILS',
        customInvoiceNoLabel: _localSettings['customInvoiceNoLabel']?.toString() ?? 'Invoice #',
        customDateLabel: _localSettings['customDateLabel']?.toString() ?? 'Issue Date',
        customDueDateLabel: _localSettings['customDueDateLabel']?.toString() ?? 'Due Date',
        customPoLabel: _localSettings['customPoLabel']?.toString() ?? 'PO Number',
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${schema.metadata.id}_preview.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Error generating sample PDF: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE IMPLEMENTATION
  // ---------------------------------------------------------------------------
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
          'preferredTemplateId': _config.id,
          'brandColorHex': _config.color,
          'secondaryColorHex': _config.secondaryColor,
          'headerLayout': _config.headerLayout,
          'tableStyle': _config.tableStyle,
          'tableDensity': _tableDensity,
          'baseFontSize': _baseFontSize,
          'fontFamily': _fontFamily,
          'showLogo': _config.showLogo,
          'showBillFrom': _config.showBillFrom,
          'showBillTo': _config.showBillTo,
          'showBankDetails': _config.showBankDetails,
          'showShippingSection': _localSettings['showShippingSection'] == true,
          'showNotes': _config.showNotes,
          'showTerms': _config.showTerms,
          'showSignature': _config.showSignature,
          'showTax': _config.showTaxBreakdown,
          'showPaymentInstructions': _config.showPaymentInstructions,
          'customTitle': _localSettings['customTitle'] ?? _config.title,
          'customItemHeader': _localSettings['customItemHeader'] ?? _config.itemHeader,
          'customQtyHeader': _localSettings['customQtyHeader'] ?? _config.quantityHeader,
          'customRateHeader': _localSettings['customRateHeader'] ?? _config.rateHeader,
          'customAmountHeader': _localSettings['customAmountHeader'] ?? _config.amountHeader,
          'customDutyHeader': _localSettings['customDutyHeader'] ?? _config.dutyHeader,
          'showItemDuty': _localSettings['showItemDuty'] ?? _config.showDuty,
          'defaultTaxRate': rate,
          'defaultTaxLabel': _profile['defaultTaxLabel']?.toString().trim().isNotEmpty == true
              ? _profile['defaultTaxLabel']
              : 'GST',
          'defaultCurrency': _profile['defaultCurrency'] ?? 'INR',
          'defaultCurrencySymbol': _profile['defaultCurrencySymbol'] ?? '₹',
          'defaultPaymentTerms': _profile['defaultPaymentTerms']?.toString().trim().isNotEmpty == true
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
          'showQrCode': _localSettings['showQrCode'] ?? true,
        });

      await widget.onSaveLocalSettings?.call(
        Map<String, Object?>.unmodifiable(localSettings),
      );
      widget.onSaveTemplate?.call(_config);

      setState(() => _localSettings = localSettings);

      final payload = <String, Object?>{
        for (final entry in _profile.entries)
          if (_supportedBackendFields.contains(entry.key)) entry.key: entry.value,
      };
      payload['brandColorHex'] = _config.color;

      final savedProfile = await _repository.saveProfile(payload);
      if (!mounted) return;
      setState(() => _profile = savedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text(
            '✓ All template styles, customizations, bank details & formulas saved! Applied across all previews & exports.',
          ),
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

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    final schema = _buildSchemaFromSettings();
    final layoutResult = _computeCurrentLayout(schema);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 22),
              const SizedBox(width: 8),
              const Text('Invoice & Template Studio'),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x1F00F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00F2FE), width: 1),
                ),
                child: const Text(
                  'WYSIWYG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00F2FE),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (!isDesktop)
              IconButton(
                tooltip: _mobileShowPreview ? 'Show Settings' : 'Show Live Preview',
                icon: Icon(
                  _mobileShowPreview ? Icons.tune_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF0284C7),
                ),
                onPressed: () => setState(() => _mobileShowPreview = !_mobileShowPreview),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              Tab(icon: Icon(Icons.palette_outlined), text: 'Template & Brand'),
              Tab(icon: Icon(Icons.description_outlined), text: 'Details & Billing'),
              Tab(icon: Icon(Icons.table_chart_outlined), text: 'Line Items & Duty'),
              Tab(icon: Icon(Icons.account_balance_outlined), text: 'Bank, Adjustments & Sign'),
              Tab(icon: Icon(Icons.data_object_outlined), text: 'JSON Studio'),
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
                              color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
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
                    child: isDesktop
                        ? _buildSplitLayout(schema, layoutResult)
                        : _buildMobileLayout(schema, layoutResult),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SPLIT SCREEN LAYOUT (DESKTOP)
  // ---------------------------------------------------------------------------
  Widget _buildSplitLayout(DocumentTemplateSchema schema, TemplateLayoutResult layoutResult) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Tab Bar Views with All Customization Settings
        Expanded(
          flex: 5,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _buildSettingsTabBarView(),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // Right Column: Live Real-Time WYSIWYG A4 Preview Canvas
        Expanded(
          flex: 6,
          child: _buildLivePreviewPanel(schema, layoutResult),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE RESPONSIVE LAYOUT
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(DocumentTemplateSchema schema, TemplateLayoutResult layoutResult) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Settings Controls'),
                      icon: Icon(Icons.tune_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Live A4 Preview'),
                      icon: Icon(Icons.auto_awesome, size: 16),
                    ),
                  ],
                  selected: {_mobileShowPreview},
                  onSelectionChanged: (set) => setState(() => _mobileShowPreview = set.first),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _mobileShowPreview
              ? _buildLivePreviewPanel(schema, layoutResult)
              : _buildSettingsTabBarView(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB BAR VIEW CONTAINER
  // ---------------------------------------------------------------------------
  Widget _buildSettingsTabBarView() {
    return TabBarView(
      children: [
        // 1. Template & Brand Customization Tab
        _buildTemplateBrandTab(),

        // 2. Details & Billing Tab
        InvoiceSettingsDetailsTab(
          fieldTileBuilder: _buildFieldTile,
          customFieldsCardBuilder: _buildCustomFieldsCard,
          onApplyPreset: _applyQuickPreset,
          onSave: _save,
        ),

        // 3. Line Items & Formulas Tab
        InvoiceSettingsLineItemsTab(
          localSettings: _localSettings,
          onChanged: () {
            setState(() {});
            _syncJsonEditor();
          },
          onSave: _save,
          onApplyPreset: _applyQuickPreset,
          fieldTileBuilder: _buildFieldTile,
          customFieldsCardBuilder: _buildCustomFieldsCard,
        ),

        // 4. Bank, Adjustments & Sign Tab
        _buildBankAndSignTab(),

        // 5. Declarative JSON Schema Studio Tab
        _buildJsonStudioTab(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: TEMPLATE & BRAND CUSTOMIZATION
  // ---------------------------------------------------------------------------
  Widget _buildTemplateBrandTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSettingsInfoBanner(
          'WYSIWYG Template & Brand Studio',
          'Choose industry presets, upload your business logo, customize primary brand colors, adjust table styling, and toggle template sections with instant live preview.',
        ),
        const SizedBox(height: 14),

        // Section 1: Template Presets Selector
        TemplatePresetsGallery(
          selectedPresetId: _presetId,
          selectedCategory: _selectedCategory,
          selectedStyle: _selectedStyle,
          categories: _availableCategories,
          styles: _styles,
          onSelectPreset: _selectPreset,
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
          onStyleChanged: (style) => setState(() => _selectedStyle = style),
        ),
        const SizedBox(height: 14),

        // Section 2: Template Logo Studio
        TemplateLogoStudioCard(
          logoWidget: _getLogoImage(height: 60),
          onPickGallery: () => _pickLogo(ImageSource.gallery),
          onPickCamera: () => _pickLogo(ImageSource.camera),
          onRemoveLogo: _removeLogo,
        ),
        const SizedBox(height: 14),

        // Section 3: Brand Colors & Typography
        _buildBrandColorsCard(),
        const SizedBox(height: 14),

        // Section 4: Layout & Table Styling
        _buildLayoutAndStylingCard(),
        const SizedBox(height: 14),

        // Section 5: Modular Section Boxes Designer Tool
        _buildSectionBoxDesignerCard(),
        const SizedBox(height: 14),

        // Section 6: Section Visibility Switches
        _buildSectionsVisibilityCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBrandColorsCard() {
    final activeHex = _localSettings['brandColorHex']?.toString().toUpperCase() ?? _config.color.toUpperCase();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Brand Accent Colors & Palette',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select brand colors for headers, table badges, totals highlight and borders.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorSwatches.map((swatch) {
              final hex = swatch['hex']!;
              final isSelected = activeHex == hex.toUpperCase();
              final c = _parseColor(hex);
              return InkWell(
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(color: hex);
                    _localSettings['brandColorHex'] = hex;
                  });
                  _syncJsonEditor();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? c.withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? c : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        swatch['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? c : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _config.color,
                  decoration: const InputDecoration(
                    labelText: 'Primary Brand Color (Hex)',
                    hintText: '#1E3A8A',
                    isDense: true,
                    prefixIcon: Icon(Icons.colorize_outlined, size: 18),
                  ),
                  onChanged: (val) {
                    final clean = val.trim();
                    if (clean.length >= 6) {
                      setState(() {
                        _config = _config.copyWith(color: clean);
                        _localSettings['brandColorHex'] = clean;
                      });
                      _syncJsonEditor();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _config.secondaryColor,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Accent (Hex)',
                    hintText: '#0D9488',
                    isDense: true,
                    prefixIcon: Icon(Icons.format_paint_outlined, size: 18),
                  ),
                  onChanged: (val) {
                    final clean = val.trim();
                    if (clean.length >= 6) {
                      setState(() {
                        _config = _config.copyWith(secondaryColor: clean);
                        _localSettings['secondaryColorHex'] = clean;
                      });
                      _syncJsonEditor();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutAndStylingCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Header & Table Layout Style', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Select how the header and items table are formatted on your WYSIWYG invoices.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          const Text('Header Alignment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'modern',
                label: Text('Modern Split'),
                icon: Icon(Icons.splitscreen_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'classic',
                label: Text('Centered Letterhead'),
                icon: Icon(Icons.align_horizontal_center, size: 16),
              ),
            ],
            selected: {_config.headerLayout},
            onSelectionChanged: (set) {
              setState(() {
                _config = _config.copyWith(headerLayout: set.first);
                _localSettings['headerLayout'] = set.first;
              });
              _syncJsonEditor();
            },
          ),
          const SizedBox(height: 16),
          const Text('Items Table Grid Style',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'boxed',
                label: Text('Boxed Grid'),
                icon: Icon(Icons.grid_on_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'striped',
                label: Text('Striped Rows'),
                icon: Icon(Icons.format_line_spacing, size: 16),
              ),
              ButtonSegment(
                value: 'clean',
                label: Text('Clean Minimal'),
                icon: Icon(Icons.table_rows_outlined, size: 16),
              ),
            ],
            selected: {_config.tableStyle},
            onSelectionChanged: (set) {
              setState(() {
                _config = _config.copyWith(tableStyle: set.first);
                _localSettings['tableStyle'] = set.first;
              });
              _syncJsonEditor();
            },
          ),
        ],
      ),
    );
  }

  /// Section Box Designer Card: Lets user visually manage, toggle, and view each section box
  Widget _buildSectionBoxDesignerCard() {
    final boxes = [
      ('Header & Letterhead Box', Icons.article_outlined, 'Company branding, title, invoice dates', _localSettings['showDocumentTitle'] != false, 'showDocumentTitle'),
      ('Due Date Field', Icons.event_busy_outlined, 'Payment deadline on invoice header (Default: Hidden)', _localSettings['showDueDate'] == true, 'showDueDate'),
      ('Purchase Order (PO #) Field', Icons.receipt_outlined, 'Client PO number for enterprise procurement (Default: Hidden)', _localSettings['showPoNumber'] == true, 'showPoNumber'),
      ('Payment Terms Field', Icons.schedule_outlined, 'Credit cycle e.g. Net 15, Net 30 (Default: Hidden)', _localSettings['showPaymentTerms'] == true, 'showPaymentTerms'),
      ('Status Badge', Icons.label_outline, 'Paid / Due stamp badge (Default: Hidden)', _localSettings['showStatus'] == true, 'showStatus'),
      ('Bill From Details Box', Icons.storefront_outlined, 'Your business name, address & tax ID', _localSettings['showBillFrom'] != false, 'showBillFrom'),
      ('Bill To (Client) Box', Icons.person_outline, 'Customer name, company & billing info', _localSettings['showBillTo'] != false, 'showBillTo'),
      ('Dispatch & Supply Box (Shipping)', Icons.local_shipping_outlined, 'Transport mode, consignee address, dispatch place (Default: Hidden)', _localSettings['showShippingSection'] == true, 'showShippingSection'),
      ('Items Table (Border-Boxed)', Icons.table_chart_outlined, 'Line items, descriptions, duty shifts, rates', true, null),
      ('Totals & Tax Summary Box', Icons.calculate_outlined, 'Taxable subtotal, CGST/SGST/IGST, total payable', true, null),
      ('Bank & Payment Routing Box', Icons.account_balance_outlined, 'Bank account number, IFSC, UPI ID for wire transfer', _localSettings['showBankDetails'] != false, 'showBankDetails'),
      ('UPI QR Code Box', Icons.qr_code_2_rounded, 'Instant scan-and-pay UPI QR block', _localSettings['showQrCode'] != false, 'showQrCode'),
      ('Notes & Client Message Box', Icons.notes_rounded, 'Thank you note & site supervisor instructions', _localSettings['showNotes'] != false, 'showNotes'),
      ('Terms & Conditions Box', Icons.gavel_rounded, 'Payment terms, warranty & cancellation policy', _localSettings['showTerms'] != false, 'showTerms'),
      ('Digital Signature & Stamp Box', Icons.draw_outlined, 'DocuHub digital signature pad & authorized signatory', _localSettings['showSignature'] != false, 'showSignature'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_quilt_rounded, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Modular Section Boxes Designer',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text('BOX ARCHITECTURE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Each component is wrapped in an aligned boxed text layout. Toggle any section to show or hide it immediately from both the live A4 preview and exported PDF.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          for (final box in boxes) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: box.$4 ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: box.$4 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                  width: box.$4 ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(box.$2, size: 18, color: box.$4 ? const Color(0xFF0284C7) : Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          box.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: box.$4 ? const Color(0xFF0F172A) : Colors.grey,
                          ),
                        ),
                        Text(
                          box.$3,
                          style: TextStyle(fontSize: 10.5, color: box.$4 ? const Color(0xFF64748B) : Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  if (box.$5 != null)
                    Switch(
                      value: box.$4,
                      onChanged: (val) {
                        setState(() {
                          _localSettings[box.$5!] = val;
                          if (box.$5 == 'showShippingSection') {
                            _config = _config.copyWith(showShipping: val);
                          }
                        });
                        _syncJsonEditor();
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('REQUIRED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionsVisibilityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Template Section Switches',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Individual section master switches. Any disabled section is completely hidden everywhere.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          _buildSectionSwitch(
            title: 'Bill From (Your Business Details)',
            subtitle: 'Show your business name, address, GSTIN/PAN, and contact info in header',
            value: _config.showBillFrom && _localSettings['showBillFrom'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showBillFrom: val);
                _localSettings['showBillFrom'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Business Logo in Header',
            subtitle: 'Display your company logo on the invoice',
            value: _config.showLogo && _localSettings['showLogo'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showLogo: val);
                _localSettings['showLogo'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Bill To (Client / Customer Info)',
            subtitle: 'Display client name, billing address, phone, email & tax ID',
            value: _config.showBillTo && _localSettings['showBillTo'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showBillTo: val);
                _localSettings['showBillTo'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Bank & Payment Details',
            subtitle: 'Display bank account number, IFSC, bank name & UPI ID for customer transfers',
            value: _config.showBankDetails && _localSettings['showBankDetails'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showBankDetails: val);
                _localSettings['showBankDetails'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Shipments & Dispatch Details',
            subtitle: 'Show courier/carrier, tracking number, and delivery shipping address (Default: Hidden)',
            value: _localSettings['showShippingSection'] == true,
            isDefault: false,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showShipping: val);
                _localSettings['showShippingSection'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Due Date in Header',
            subtitle: 'Display payment due date line next to invoice date (Default: Hidden)',
            value: _localSettings['showDueDate'] == true,
            isDefault: false,
            onChanged: (val) {
              setState(() => _localSettings['showDueDate'] = val);
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Purchase Order (PO #) in Header',
            subtitle: 'Display client purchase order tracking number (Default: Hidden)',
            value: _localSettings['showPoNumber'] == true,
            isDefault: false,
            onChanged: (val) {
              setState(() => _localSettings['showPoNumber'] = val);
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Payment Terms in Header',
            subtitle: 'Display payment credit terms (e.g. Net 30, Net 15) (Default: Hidden)',
            value: _localSettings['showPaymentTerms'] == true,
            isDefault: false,
            onChanged: (val) {
              setState(() => _localSettings['showPaymentTerms'] = val);
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Invoice Status Stamp Badge',
            subtitle: 'Display green/blue status pill stamp (PAID / DUE) (Default: Hidden)',
            value: _localSettings['showStatus'] == true,
            isDefault: false,
            onChanged: (val) {
              setState(() => _localSettings['showStatus'] = val);
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Tax Breakdown & Adjustments',
            subtitle: 'Display detailed tax percentages, discount rows, and charges breakdown',
            value: _config.showTaxBreakdown && _localSettings['showTax'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showTaxBreakdown: val);
                _localSettings['showTax'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'DocuHub Digital Signature & Stamp',
            subtitle: 'Include signature image, signee name, and official designation block',
            value: _config.showSignature && _localSettings['showSignature'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showSignature: val);
                _localSettings['showSignature'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Notes & Client Message',
            subtitle: 'Include personalized notes or thank-you message',
            value: _config.showNotes && _localSettings['showNotes'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showNotes: val);
                _localSettings['showNotes'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Terms and Conditions',
            subtitle: 'Display payment terms, warranty or cancellation policies',
            value: _config.showTerms && _localSettings['showTerms'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showTerms: val);
                _localSettings['showTerms'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Payment Instructions',
            subtitle: 'Display explicit instructions for check, wire, or cash payment',
            value: _config.showPaymentInstructions && _localSettings['showPaymentInstructions'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(showPaymentInstructions: val);
                _localSettings['showPaymentInstructions'] = val;
              });
              _syncJsonEditor();
            },
          ),
          const Divider(),
          _buildSectionSwitch(
            title: 'Payment UPI QR Code',
            subtitle: 'Display fast UPI/direct scan QR code for instant client payments',
            value: _localSettings['showQrCode'] != false,
            isDefault: true,
            onChanged: (val) {
              setState(() {
                _localSettings['showQrCode'] = val;
              });
              _syncJsonEditor();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDefault,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEFAULT ON',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: BANK, ADJUSTMENTS & SIGN
  // ---------------------------------------------------------------------------
  Widget _buildBankAndSignTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSettingsInfoBanner(
          'Bank Details, Adjustments & Signature',
          'Configure your bank settlement details, UPI ID, payment terms, tax adjustments, Reverse Charge Mechanism (RCM), and DocuHub digital signature.',
        ),
        const SizedBox(height: 14),
        InvoiceSettingsBankTab(
          profile: _profile,
          localSettings: _localSettings,
          onChanged: () {
            setState(() {});
            _syncJsonEditor();
          },
          onSave: _save,
        ),
        const SizedBox(height: 14),
        InvoiceSettingsAdjustmentsTab(
          fieldTileBuilder: _buildFieldTile,
          customFieldsCardBuilder: _buildCustomFieldsCard,
          onSave: _save,
          localSettings: _localSettings,
          onChanged: () {
            setState(() {});
            _syncJsonEditor();
          },
        ),
        const SizedBox(height: 14),
        InvoiceSettingsBrandTermsTab(
          profile: _profile,
          localSettings: _localSettings,
          onChanged: () {
            setState(() {});
            _syncJsonEditor();
          },
          onSave: _save,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: JSON SCHEMA STUDIO
  // ---------------------------------------------------------------------------
  Widget _buildJsonStudioTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.data_object_rounded, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Declarative WYSIWYG Template JSON Schema',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy JSON'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _jsonController.text));
                  _showFeedback('Template JSON copied to clipboard!');
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Apply JSON to Canvas'),
                onPressed: () {
                  try {
                    final decoded = jsonDecode(_jsonController.text) as Map<String, dynamic>;
                    final schema = DocumentTemplateSchema.fromJson(decoded);
                    final errors = TemplateSchemaValidator.validate(schema);
                    if (errors.isNotEmpty) {
                      setState(() => _jsonValidationError = errors.join('\n'));
                      return;
                    }
                    setState(() {
                      _jsonValidationError = null;
                      _config = _config.copyWith(
                        id: schema.metadata.id,
                        name: schema.metadata.name,
                        color: schema.style.primaryColor,
                        secondaryColor: schema.style.secondaryColor,
                      );
                      _localSettings['brandColorHex'] = schema.style.primaryColor;
                      _localSettings['secondaryColorHex'] = schema.style.secondaryColor;
                    });
                    _showFeedback('✓ JSON Schema applied successfully to live A4 canvas!');
                  } catch (e) {
                    setState(() => _jsonValidationError = 'Invalid JSON format: $e');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The entire invoice layout, column widths, padding, styles, and section flow are governed by this declarative schema.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (_jsonValidationError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                _jsonValidationError!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Color(0xFF38BDF8),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LIVE REAL-TIME WYSIWYG A4 PREVIEW PANEL WITH WORD/DOC EDITOR TOOLBAR
  // ---------------------------------------------------------------------------
  Widget _buildLivePreviewPanel(DocumentTemplateSchema schema, TemplateLayoutResult layoutResult) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          // Top Preview Toolbar with Pulsating Live Badge & Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Live status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF059669), size: 8),
                      SizedBox(width: 6),
                      Text(
                        'LIVE A4 CANVAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Simulated Item Count (Test Page Breaks & Pagination)
                const Text('Items:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(width: 6),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 5, label: Text('5')),
                    ButtonSegment(value: 12, label: Text('12 (Multi-page)')),
                  ],
                  selected: {_simulatedItemCount},
                  onSelectionChanged: (set) => setState(() => _simulatedItemCount = set.first),
                ),
                const Spacer(),

                // Zoom controls
                IconButton(
                  tooltip: 'Zoom Out',
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => setState(() => _previewZoom = (_previewZoom - 0.08).clamp(0.4, 1.5)),
                ),
                Text(
                  '${(_previewZoom * 100).round()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Zoom In',
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => setState(() => _previewZoom = (_previewZoom + 0.08).clamp(0.4, 1.5)),
                ),
                IconButton(
                  tooltip: 'Reset Zoom (82%)',
                  icon: const Icon(Icons.restart_alt, size: 18),
                  onPressed: () => setState(() => _previewZoom = 0.82),
                ),
                const SizedBox(width: 8),

                // Export Sample PDF
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Export PDF'),
                  onPressed: () => _exportSamplePdf(schema, layoutResult),
                ),
              ],
            ),
          ),

          // Word / Doc Editor Quick Formatting Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Font:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _fontFamily,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'Inter', child: Text('Inter (Modern Sans)')),
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto (Clean)')),
                      DropdownMenuItem(value: 'Merriweather', child: Text('Serif (Executive)')),
                      DropdownMenuItem(value: 'Courier', child: Text('Monospace (Technical)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _fontFamily = val;
                          _localSettings['fontFamily'] = val;
                        });
                        _syncJsonEditor();
                      }
                    },
                  ),
                  const SizedBox(width: 14),
                  const Text('Size:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.text_decrease, size: 16),
                    tooltip: 'Decrease font size',
                    onPressed: () {
                      setState(() {
                        _baseFontSize = (_baseFontSize - 0.5).clamp(8.0, 14.0);
                        _localSettings['baseFontSize'] = _baseFontSize;
                      });
                      _syncJsonEditor();
                    },
                  ),
                  Text('${_baseFontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.text_increase, size: 16),
                    tooltip: 'Increase font size',
                    onPressed: () {
                      setState(() {
                        _baseFontSize = (_baseFontSize + 0.5).clamp(8.0, 14.0);
                        _localSettings['baseFontSize'] = _baseFontSize;
                      });
                      _syncJsonEditor();
                    },
                  ),
                  const SizedBox(width: 14),
                  const Text('Density:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'compact', label: Text('Compact (Dense)')),
                      ButtonSegment(value: 'normal', label: Text('Normal')),
                      ButtonSegment(value: 'spacious', label: Text('Spacious')),
                    ],
                    selected: {_tableDensity},
                    onSelectionChanged: (set) {
                      setState(() {
                        _tableDensity = set.first;
                        _localSettings['tableDensity'] = set.first;
                      });
                      _syncJsonEditor();
                    },
                  ),
                  const SizedBox(width: 14),
                  const Text('Border Grid:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'boxed', label: Text('Boxed Grid'), icon: Icon(Icons.grid_on, size: 14)),
                      ButtonSegment(value: 'striped', label: Text('Striped'), icon: Icon(Icons.table_rows, size: 14)),
                      ButtonSegment(value: 'clean', label: Text('Minimal'), icon: Icon(Icons.crop_square, size: 14)),
                    ],
                    selected: {_config.tableStyle},
                    onSelectionChanged: (set) {
                      setState(() {
                        _config = _config.copyWith(tableStyle: set.first);
                        _localSettings['tableStyle'] = set.first;
                      });
                      _syncJsonEditor();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Canvas with Mouse Roller & Touch Pan
          Expanded(
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _previewScrollController.jumpTo(
                    (_previewScrollController.offset + event.scrollDelta.dy)
                        .clamp(0.0, _previewScrollController.position.maxScrollExtent),
                  );
                }
              },
              child: SingleChildScrollView(
                controller: _previewScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: WysiwygCanvasPreview(
                      schema: schema,
                      layoutResult: layoutResult,
                      scale: _previewZoom,
                      renderAllPagesStacked: true,
                      companyName: _localSettings['businessName']?.toString().isNotEmpty == true
                          ? _localSettings['businessName']!.toString()
                          : (_profile['businessName']?.toString().isNotEmpty == true
                              ? _profile['businessName']!.toString()
                              : 'Central Security Force'),
                      companyAddress: _localSettings['businessAddress']?.toString() ??
                          _profile['address']?.toString() ??
                          '82-82-2772A, Hyderabad, Telangana, India -520007',
                      companyGstin: _localSettings['businessGstin']?.toString() ??
                          _profile['gstin']?.toString() ??
                          'TG72882828TGH818',
                      companyPan: _localSettings['businessPan']?.toString() ??
                          _profile['panNumber']?.toString() ??
                          'IC8188282J',
                      clientName: 'Enterprise Client Corp',
                      clientAddress: '42 Prestige Tech Park, Bangalore, KA 560103',
                      clientGstin: '29ABCDE1234F1Z5',
                      currencySymbol: 'Rs.',
                      invoiceNumber: 'INV-2026-0881',
                      issueDate: '2026-10-15',
                      dueDate: '2026-10-30',
                      total: layoutResult.pages.expand((p) => p.items).fold<double>(
                            0.0,
                            (sum, item) => sum + item.amount,
                          ) * 1.18,
                      subtotal: layoutResult.pages.expand((p) => p.items).fold<double>(
                            0.0,
                            (sum, item) => sum + item.amount,
                          ),
                      tax: layoutResult.pages.expand((p) => p.items).fold<double>(
                            0.0,
                            (sum, item) => sum + item.amount,
                          ) * 0.18,
                      notes: _profile['defaultNotes']?.toString() ??
                          _localSettings['defaultNotes']?.toString() ??
                          'Thank you for your business! Please settle the bill within the agreed credit cycle.',
                      terms: _profile['defaultTerms']?.toString() ??
                          _localSettings['defaultTerms']?.toString() ??
                          'Security attendance verified by client site supervisor. Statutory EPF & ESIC challans enclosed.\nPayment due within 15 days of bill submission. RCM / GST compliance applicable.',
                      bankName: _profile['bankName']?.toString() ??
                          _localSettings['bankName']?.toString() ??
                          'Axis Bank',
                      accountNumber: _profile['accountNumber']?.toString() ??
                          _localSettings['accountNumber']?.toString() ??
                          '717272727727',
                      ifsc: _profile['ifscCode']?.toString() ??
                          _localSettings['ifscCode']?.toString() ??
                          'T7272GGF',
                      upiId: _profile['upiId']?.toString() ??
                          _localSettings['upiId']?.toString() ??
                          'csf7887@kotak',
                      logoWidget: _getLogoImage(height: 52),
                      showLogo: _localSettings['showLogo'] != false && _config.showLogo,
                      showBillFrom: _localSettings['showBillFrom'] != false && _config.showBillFrom,
                      showBillTo: _localSettings['showBillTo'] != false && _config.showBillTo,
                      showShipping: _localSettings['showShippingSection'] == true, // STRICTLY RESPECTS USER TOGGLE
                      showDueDate: _localSettings['showDueDate'] == true,
                      showPoNumber: _localSettings['showPoNumber'] == true,
                      showPaymentTerms: _localSettings['showPaymentTerms'] == true,
                      showStatus: _localSettings['showStatus'] == true,
                      showBankDetails:
                          _localSettings['showBankDetails'] != false && _config.showBankDetails,
                      showNotes: _localSettings['showNotes'] != false && _config.showNotes,
                      showTerms: _localSettings['showTerms'] != false && _config.showTerms,
                      showSignature:
                          _localSettings['showSignature'] != false && _config.showSignature,
                      signatureBase64: _localSettings['digitalSignature']?.toString() ??
                          _profile['digitalSignature']?.toString(),
                      customTitle: _localSettings['customTitle']?.toString() ?? _config.title,
                      customBillToLabel: _localSettings['customBillToLabel']?.toString() ?? 'BILLED TO',
                      customShipToLabel: _localSettings['customShipToLabel']?.toString() ?? 'DISPATCH & SUPPLY DETAILS',
                      customInvoiceNoLabel: _localSettings['customInvoiceNoLabel']?.toString() ?? 'Invoice #',
                      customDateLabel: _localSettings['customDateLabel']?.toString() ?? 'Issue Date',
                      customDueDateLabel: _localSettings['customDueDateLabel']?.toString() ?? 'Due Date',
                      customPoLabel: _localSettings['customPoLabel']?.toString() ?? 'PO Number',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE FIELD TILE WITH SWITCH & CUSTOM LABEL INPUT
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
    final isEnabled =
        _localSettings[toggleKey] != null ? _localSettings[toggleKey] == true : defaultToggle;
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
                _syncJsonEditor();
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
            _syncJsonEditor();
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE CUSTOM FIELDS CONTAINER
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
          onPressed: () => _editCustomFieldDialog(key, index, item, itemType),
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

  Color _parseColor(String hex) {
    try {
      final sanitized = hex.replaceAll('#', '').trim();
      return Color(int.parse('FF$sanitized', radix: 16));
    } catch (_) {
      return const Color(0xFF1E3A8A);
    }
  }
}
