import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/utils/file_download_helper.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../invoices/data/invoice.dart';
import '../../invoices/data/invoice_docx_export.dart';
import '../../invoices/data/invoice_pdf_export.dart';
import '../data/company_letterhead.dart';
import '../data/studio_section_model.dart';
import '../data/template_config.dart';
import 'widgets/company_letterhead_studio_card.dart';
import 'widgets/formula_builder_popup.dart';
import 'widgets/invoice_section_accordion.dart';
import 'widgets/studio_field_dialogs.dart';
import 'widgets/studio_style_dialogs.dart';
import 'widgets/studio_template_selector_dialog.dart';

class InvoiceTemplateStudioScreen extends StatefulWidget {
  const InvoiceTemplateStudioScreen({
    required this.apiClient,
    this.initialConfig,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onSaveTemplate,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final TemplateConfig? initialConfig;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
  final ValueChanged<TemplateConfig>? onSaveTemplate;
  final VoidCallback? onBack;

  @override
  State<InvoiceTemplateStudioScreen> createState() =>
      _InvoiceTemplateStudioScreenState();
}

class _InvoiceTemplateStudioScreenState
    extends State<InvoiceTemplateStudioScreen> {
  // Top Header State
  String _templateName = 'Security Services — GST Invoice';
  String _templateStatus = 'Draft';
  bool _isEditingName = false;
  late final TextEditingController _nameController;

  // Active Top Navigation Tab
  int _activeTopTabIndex = 0;
  final List<String> _topTabs = const [
    'Template & Branding',
    'Invoice Details & Billing',
    'Line Items & Duty',
    'Tax & Totals',
    'Bank, Adjustments & Signature',
    'Advanced',
  ];

  // Industry Presets & Templates List
  String _activePreset = 'security_agency';
  String _selectedTemplateId = 'security_gst';
  String _companyDefaultTemplateId = 'security_gst';

  final List<StudioTemplateOption> _availableTemplates = const [
    StudioTemplateOption(
      id: 'security_gst',
      name: 'Security Services — GST Invoice',
      presetKey: 'security_agency',
      description: 'Optimized for security agencies: Guard counts, Duty days, shifts & GST.',
      primaryColor: Color(0xFF1E3A8A),
      layoutStyle: 'modern_split',
    ),
    StudioTemplateOption(
      id: 'gst_service',
      name: 'Professional GST Service Invoice',
      presetKey: 'gst_service',
      description: 'SAC codes, professional service billing, CGST/SGST/IGST breakdown.',
      primaryColor: Color(0xFF2563EB),
      layoutStyle: 'modern_split',
    ),
    StudioTemplateOption(
      id: 'creative_agency',
      name: 'Creative & Digital Agency Studio',
      presetKey: 'creative_vibrant',
      description: 'Design studios, advertising, campaign milestones, media deliverables & licensing.',
      primaryColor: Color(0xFF7C3AED),
      layoutStyle: 'minimal_asymmetric',
    ),
    StudioTemplateOption(
      id: 'construction',
      name: 'Contractor & Civil Engineering RA Bill',
      presetKey: 'construction_contractor',
      description: 'Material supply, BOQ measurement units, labor shifts, site addresses & retainage.',
      primaryColor: Color(0xFFEA580C),
      layoutStyle: 'compact_grid',
    ),
    StudioTemplateOption(
      id: 'healthcare',
      name: 'Healthcare Clinic & Diagnostic Bill',
      presetKey: 'healthcare_clinic',
      description: 'Doctor consultations, medical diagnostics, hospital treatments & pharmacy billing.',
      primaryColor: Color(0xFF059669),
      layoutStyle: 'executive_banner',
    ),
    StudioTemplateOption(
      id: 'logistics',
      name: 'Logistics, Cargo & Freight Consignment',
      presetKey: 'logistics_freight',
      description: 'Consignment (LR) numbers, origin-destination routes, cargo tonnage & freight charges.',
      primaryColor: Color(0xFF1E40AF),
      layoutStyle: 'compact_grid',
    ),
    StudioTemplateOption(
      id: 'legal',
      name: 'Legal Counsel & CA Advisory Statement',
      presetKey: 'legal_counsel',
      description: 'Chartered accountants, legal retainers, court appearances & advisory scopes.',
      primaryColor: Color(0xFF451A03),
      layoutStyle: 'classic_bordered',
    ),
    StudioTemplateOption(
      id: 'hospitality',
      name: 'Hospitality, Banquets & Catering',
      presetKey: 'hospitality_catering',
      description: 'Events, banquets, guest pax counts, menu packages & hospitality service.',
      primaryColor: Color(0xFFBE185D),
      layoutStyle: 'executive_banner',
    ),
    StudioTemplateOption(
      id: 'consulting',
      name: 'Corporate Consulting Invoice',
      presetKey: 'consulting',
      description: 'Deliverables, retainer fees, advisory hours and professional disbursements.',
      primaryColor: Color(0xFF0F172A),
      layoutStyle: 'sidebar_accent',
    ),
    StudioTemplateOption(
      id: 'retail',
      name: 'Standard Retail Store Invoice',
      presetKey: 'retail',
      description: 'Inventory items, SKU numbers, MRP, discounts and counter checkout.',
      primaryColor: Color(0xFF0D9488),
      layoutStyle: 'compact_grid',
    ),
    StudioTemplateOption(
      id: 'modern',
      name: 'Executive Modern Clean Invoice',
      presetKey: 'modern',
      description: 'Minimalist high-contrast layout for executive billing and tech contractors.',
      primaryColor: Color(0xFF4F46E5),
      layoutStyle: 'minimal_asymmetric',
    ),
    StudioTemplateOption(
      id: 'executive_enterprise_hero',
      name: 'Executive Enterprise Hero Banner',
      presetKey: 'gst_service',
      description: 'Full-bleed executive hero band with embedded document pills & dual corporate cards.',
      primaryColor: Color(0xFF0F172A),
      layoutStyle: 'executive_banner',
    ),
    StudioTemplateOption(
      id: 'civil_matrix_ledger',
      name: 'Heavy Civil & Material Matrix Ledger',
      presetKey: 'construction_contractor',
      description: '4-Quadrant formal matrix grid with HSN, unit dispatch notes & ledger borders.',
      primaryColor: Color(0xFFC2410C),
      layoutStyle: 'compact_grid',
    ),
    StudioTemplateOption(
      id: 'nordic_sidebar_pro',
      name: 'Nordic Executive Dual-Column Sidebar',
      presetKey: 'consulting',
      description: 'Dedicated left vertical panel for invoice metadata, bank QR and stamp.',
      primaryColor: Color(0xFF0284C7),
      layoutStyle: 'sidebar_accent',
    ),
    StudioTemplateOption(
      id: 'legal_chamber_bordered',
      name: 'Chamber Legal & CA Classical Bordered',
      presetKey: 'legal_counsel',
      description: 'Classical perimeter frame, centered decorative heading & formal bilateral declaration.',
      primaryColor: Color(0xFF3B0764),
      layoutStyle: 'classic_bordered',
    ),
    StudioTemplateOption(
      id: 'vanguard_tech_asym',
      name: 'Vanguard Modernist Asymmetric Clean',
      presetKey: 'creative_vibrant',
      description: 'Modern asymmetrical aesthetic with electric accent dot, 3-column metadata & borderless rows.',
      primaryColor: Color(0xFF4338CA),
      layoutStyle: 'minimal_asymmetric',
    ),
  ];

  // Typography & Styling State
  String _fontFamily = 'Inter';
  double _fontScale = 1.0;
  bool _uppercaseHeadings = true;
  String _documentTitle = 'TAX INVOICE';
  Color _primaryColor = const Color(0xFF1E3A8A);
  Color _tableHeaderTextColor = Colors.white;
  String _tableBorderStyle = 'boxed'; // 'boxed', 'lines', 'striped'
  String _layoutStyle = 'modern_split'; // 'modern_split', 'executive_banner', 'compact_grid', 'minimal_asymmetric', 'sidebar_accent', 'classic_bordered'
  bool _showQrCode = true;
  String _watermark = 'None';
  String _pageMargin = 'Standard (16mm)';

  // Visual Branding & Authorized Signature State (DocuHub Signer)
  String? _logoBase64;
  String? _stampBase64;
  String? _signatureBase64;
  String? _signeeName;
  String? _signeeTitle;

  // Official Company Letterhead State (Default for All Documents: Invoice, Biodata, etc.)
  bool _letterheadEnabled = true;
  String _letterheadStyleId = 'modern_ribbon';
  String _letterheadCompanyName = 'Northstar Security Services Pvt. Ltd.';
  String _letterheadTagline = 'Smart Solutions for a Better Tomorrow';
  String _letterheadPhone = '+91 98765 43210';
  String _letterheadEmail = 'info@northstarsecurity.in';
  String _letterheadWebsite = 'www.northstarsecurity.in';
  String _letterheadAddress = '#12, 3rd Floor, Green Park, Bengaluru, Karnataka - 560076';
  String _letterheadGstin = '29ABCDE1234F1Z5';
  String _letterheadPan = 'ABCDE1234F';
  String _letterheadCin = 'PSARA/KA/2021/889';

  // Automatic Daily Wage & Formula Calculation State
  String _itemCalculationFormula = 'monthly_salary_30';
  double _standardDutyDays = 30.0;
  bool _isRcmApplicable = false;

  // Organization & Audit Metadata (Backend Persistence)
  String _orgCode = '';
  String _createdBy = '';
  String _updatedBy = '';

  // Sections Model List
  late List<StudioSection> _sections;

  // Preview Workspace State
  double _zoomLevel = 1.0;
  final String _paperFormat = 'A4';
  final int _currentPage = 1;
  final int _totalPages = 1;
  String _sampleDataset = 'Security Agency (Northstar)';
  bool _previewOnlyOnMobile = false;
  bool _saving = false;
  String _saveMessage = 'Changes saved';

  // Local storage cache
  late final LocalPreferences _localPreferences;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _templateName);
    _localPreferences = LocalPreferences(scope: 'template_studio');
    _sections = StudioSection.defaultSections(preset: _activePreset);

    // Explicitly collapse all sections by default
    for (final s in _sections) {
      s.isExpanded = false;
    }

    // Apply initial settings if provided
    _initFromInitialSettings();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static String? _stripDataPrefix(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('data:')) {
      final idx = trimmed.indexOf(',');
      if (idx != -1) return trimmed.substring(idx + 1);
    }
    return trimmed;
  }

  Future<void> _loadSavedSettings() async {
    try {
      final defId = await _localPreferences.readString('company_default_template_id');
      if (defId != null && defId.isNotEmpty && mounted) {
        setState(() => _companyDefaultTemplateId = defId);
      }
      final savedPreset = await _localPreferences.readString('studio_preset');
      if (savedPreset != null && savedPreset.isNotEmpty && mounted) {
        setState(() => _activePreset = savedPreset);
      }
      final savedTplName = await _localPreferences.readString('studio_template_name');
      if (savedTplName != null && savedTplName.isNotEmpty && mounted) {
        setState(() {
          _templateName = savedTplName;
          _nameController.text = savedTplName;
        });
      }
      final savedPrimaryHex = await _localPreferences.readString('studio_primary_color');
      if (savedPrimaryHex != null && savedPrimaryHex.isNotEmpty && mounted) {
        final parsed = int.tryParse(savedPrimaryHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          setState(() => _primaryColor = Color(0xFF000000 | parsed));
        }
      }
      final savedHeaderTextHex = await _localPreferences.readString('studio_table_header_text_color');
      if (savedHeaderTextHex != null && savedHeaderTextHex.isNotEmpty && mounted) {
        final parsed = int.tryParse(savedHeaderTextHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          setState(() => _tableHeaderTextColor = Color(0xFF000000 | parsed));
        }
      }
      final savedFont = await _localPreferences.readString('studio_font_family');
      if (savedFont != null && savedFont.isNotEmpty && mounted) {
        setState(() => _fontFamily = savedFont);
      }
      final savedScale = await _localPreferences.readString('studio_font_scale');
      if (savedScale != null && savedScale.isNotEmpty && mounted) {
        final parsed = double.tryParse(savedScale);
        if (parsed != null && parsed > 0) {
          setState(() => _fontScale = parsed);
        }
      }
      final savedBorder = await _localPreferences.readString('studio_table_border');
      if (savedBorder != null && savedBorder.isNotEmpty && mounted) {
        setState(() => _tableBorderStyle = savedBorder);
      }
      final savedLayout = await _localPreferences.readString('studio_layout_style');
      if (savedLayout != null && savedLayout.isNotEmpty && mounted) {
        setState(() => _layoutStyle = savedLayout);
      }
      final savedTitle = await _localPreferences.readString('studio_doc_title');
      if (savedTitle != null && savedTitle.isNotEmpty && mounted) {
        setState(() => _documentTitle = savedTitle);
      }
      final savedUppercase = await _localPreferences.readString('studio_uppercase_headings');
      if (savedUppercase != null && mounted) {
        setState(() => _uppercaseHeadings = savedUppercase == 'true');
      }
      final savedWatermark = await _localPreferences.readString('studio_watermark');
      if (savedWatermark != null && savedWatermark.isNotEmpty && mounted) {
        setState(() => _watermark = savedWatermark);
      }
      final savedMargin = await _localPreferences.readString('studio_page_margin');
      if (savedMargin != null && savedMargin.isNotEmpty && mounted) {
        setState(() => _pageMargin = savedMargin);
      }
      final savedShowQr = await _localPreferences.readString('studio_show_qr');
      if (savedShowQr != null && mounted) {
        setState(() => _showQrCode = savedShowQr == 'true');
      }
      final savedFormula = await _localPreferences.readString('itemCalculationFormula');
      if (savedFormula != null && savedFormula.isNotEmpty && mounted) {
        setState(() => _itemCalculationFormula = savedFormula);
      }
      final savedDays = await _localPreferences.readString('standardDutyDays');
      if (savedDays != null && savedDays.isNotEmpty && mounted) {
        final parsedDays = double.tryParse(savedDays);
        if (parsedDays != null && parsedDays > 0) {
          setState(() => _standardDutyDays = parsedDays);
        }
      }
      final savedLogo = await _localPreferences.readString('invoiceLogo');
      if (savedLogo != null && savedLogo.isNotEmpty && mounted) {
        setState(() => _logoBase64 ??= savedLogo);
      }
      final savedStamp = await _localPreferences.readString('invoiceStamp');
      if (savedStamp != null && savedStamp.isNotEmpty && mounted) {
        setState(() => _stampBase64 ??= savedStamp);
      }
      final savedSig = await _localPreferences.readString('invoiceSignature');
      if (savedSig != null && savedSig.isNotEmpty && mounted) {
        setState(() => _signatureBase64 ??= savedSig);
      }
      final savedName = await _localPreferences.readString('signeeName');
      if (savedName != null && savedName.isNotEmpty && mounted) {
        setState(() => _signeeName ??= savedName);
      }
      final savedTitleSig = await _localPreferences.readString('signeeTitle');
      if (savedTitleSig != null && savedTitleSig.isNotEmpty && mounted) {
        setState(() => _signeeTitle ??= savedTitleSig);
      }
      final savedLhEnabled = await _localPreferences.readString('letterhead_enabled');
      if (savedLhEnabled != null && mounted) {
        setState(() => _letterheadEnabled = savedLhEnabled == 'true');
      }
      final savedLhStyle = await _localPreferences.readString('letterhead_style_id');
      if (savedLhStyle != null && savedLhStyle.isNotEmpty && mounted) {
        setState(() => _letterheadStyleId = savedLhStyle);
      }
      final savedLhName = await _localPreferences.readString('letterhead_company_name');
      if (savedLhName != null &&
          savedLhName.isNotEmpty &&
          savedLhName != 'Northstar Security Services Pvt. Ltd.' &&
          mounted) {
        setState(() => _letterheadCompanyName = savedLhName);
      }
      final savedLhTagline = await _localPreferences.readString('letterhead_tagline');
      if (savedLhTagline != null && savedLhTagline.isNotEmpty && mounted) {
        setState(() => _letterheadTagline = savedLhTagline);
      }
      final savedLhPhone = await _localPreferences.readString('letterhead_phone');
      if (savedLhPhone != null && savedLhPhone.isNotEmpty && mounted) {
        setState(() => _letterheadPhone = savedLhPhone);
      }
      final savedLhEmail = await _localPreferences.readString('letterhead_email');
      if (savedLhEmail != null && savedLhEmail.isNotEmpty && mounted) {
        setState(() => _letterheadEmail = savedLhEmail);
      }
      final savedLhWeb = await _localPreferences.readString('letterhead_website');
      if (savedLhWeb != null && savedLhWeb.isNotEmpty && mounted) {
        setState(() => _letterheadWebsite = savedLhWeb);
      }
      final savedLhAddr = await _localPreferences.readString('letterhead_address');
      if (savedLhAddr != null && savedLhAddr.isNotEmpty && mounted) {
        setState(() => _letterheadAddress = savedLhAddr);
      }
      final savedLhGstin = await _localPreferences.readString('letterhead_gstin');
      if (savedLhGstin != null && savedLhGstin.isNotEmpty && mounted) {
        setState(() => _letterheadGstin = savedLhGstin);
      }
      final savedLhPan = await _localPreferences.readString('letterhead_pan');
      if (savedLhPan != null && savedLhPan.isNotEmpty && mounted) {
        setState(() => _letterheadPan = savedLhPan);
      }
      final savedLhCin = await _localPreferences.readString('letterhead_cin');
      if (savedLhCin != null && savedLhCin.isNotEmpty && mounted) {
        setState(() => _letterheadCin = savedLhCin);
      }
      final savedSectionsCache = await _localPreferences.readString('sections_cache');
      if (savedSectionsCache != null &&
          savedSectionsCache.isNotEmpty &&
          (widget.initialLocalSettings['studio_sections_json'] == null ||
              widget.initialLocalSettings['studio_sections_json'].toString().isEmpty)) {
        try {
          final decoded = jsonDecode(savedSectionsCache) as List<dynamic>;
          final parsed = decoded
              .map((e) => StudioSection.fromJson(e as Map<String, dynamic>))
              .toList();
          if (parsed.isNotEmpty && mounted) {
            for (final s in parsed) {
              s.isExpanded = false;
            }
            setState(() => _sections = parsed);
          }
        } catch (_) {}
      }

      // Fetch organization-scoped template settings & section booleans from backend
      await _fetchBackendTemplateSettings();
    } catch (_) {}
  }

  Future<void> _fetchBackendTemplateSettings() async {
    try {
      final response = await widget.apiClient.getJson('api/v1/templates/settings');
      final rawData = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      if (rawData.isEmpty || !mounted) return;

      setState(() {
        final org = rawData['orgCode']?.toString();
        if (org != null && org.isNotEmpty) _orgCode = org;
        final created = rawData['createdBy']?.toString();
        if (created != null && created.isNotEmpty) _createdBy = created;
        final updated = rawData['updatedBy']?.toString();
        if (updated != null && updated.isNotEmpty) _updatedBy = updated;

        final settingsJsonStr = rawData['settingsJson']?.toString();
        if (settingsJsonStr != null && settingsJsonStr.isNotEmpty) {
          try {
            final decodedMap = jsonDecode(settingsJsonStr);
            if (decodedMap is Map<String, dynamic>) {
              _applySettingsMap(decodedMap);
            }
          } catch (_) {}
        }

        final configJsonStr = rawData['configurationJson']?.toString();
        if (configJsonStr != null && configJsonStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(configJsonStr);
            if (decoded is List<dynamic>) {
              final parsed = decoded
                  .whereType<Map<String, dynamic>>()
                  .map(StudioSection.fromJson)
                  .toList();
              if (parsed.isNotEmpty) {
                for (final s in parsed) {
                  s.isExpanded = false;
                }
                _sections = parsed;
              }
            } else if (decoded is Map<String, dynamic>) {
              _applySettingsMap(decoded);
            }
          } catch (_) {}
        }

        // Apply explicit boolean flags saved on the backend entity
        _applyExplicitSectionBooleans(rawData);
      });
    } catch (_) {}
  }

  void _applySettingsMap(Map<String, dynamic> map) {
    final preset = map['studio_preset']?.toString() ?? map['industryPreset']?.toString();
    if (preset != null && preset.isNotEmpty && preset != 'SECURITY_SERVICES') {
      _activePreset = preset;
    }
    final tplName = map['studio_template_name']?.toString() ?? map['templateName']?.toString();
    if (tplName != null && tplName.isNotEmpty && tplName != 'Organization Default Template') {
      _templateName = tplName;
      _nameController.text = tplName;
    }
    final primaryHex = map['studio_primary_color']?.toString();
    if (primaryHex != null && primaryHex.isNotEmpty) {
      final parsed = int.tryParse(primaryHex.replaceFirst('#', ''), radix: 16);
      if (parsed != null) _primaryColor = Color(0xFF000000 | parsed);
    }
    final headerHex = map['studio_table_header_text_color']?.toString();
    if (headerHex != null && headerHex.isNotEmpty) {
      final parsed = int.tryParse(headerHex.replaceFirst('#', ''), radix: 16);
      if (parsed != null) _tableHeaderTextColor = Color(0xFF000000 | parsed);
    }
    final font = map['studio_font_family']?.toString();
    if (font != null && font.isNotEmpty) _fontFamily = font;
    final scale = double.tryParse(map['studio_font_scale']?.toString() ?? '');
    if (scale != null && scale > 0) _fontScale = scale;
    final border = map['studio_table_border']?.toString();
    if (border != null && border.isNotEmpty) _tableBorderStyle = border;
    final docTitle = map['customTitle']?.toString() ?? map['studio_doc_title']?.toString();
    if (docTitle != null && docTitle.isNotEmpty) _documentTitle = docTitle;
    if (map['studio_uppercase_headings'] is bool) {
      _uppercaseHeadings = map['studio_uppercase_headings'] as bool;
    }
    if (map['showQrCode'] is bool) {
      _showQrCode = map['showQrCode'] as bool;
    }
    if (map['letterhead_enabled'] is bool) {
      _letterheadEnabled = map['letterhead_enabled'] as bool;
    }
    final lhStyle = map['letterhead_style_id']?.toString();
    if (lhStyle != null && lhStyle.isNotEmpty) _letterheadStyleId = lhStyle;
    final formula = map['itemCalculationFormula']?.toString();
    if (formula != null && formula.isNotEmpty) _itemCalculationFormula = formula;
    final stdDays = double.tryParse(map['standardDutyDays']?.toString() ?? '');
    if (stdDays != null && stdDays > 0) _standardDutyDays = stdDays;
    if (map['isRcmApplicable'] != null) _isRcmApplicable = map['isRcmApplicable'] == true;

    final sectionsRaw = map['studio_sections_json'];
    if (sectionsRaw is String && sectionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(sectionsRaw) as List<dynamic>;
        final parsed = decoded
            .whereType<Map<String, dynamic>>()
            .map(StudioSection.fromJson)
            .toList();
        if (parsed.isNotEmpty) {
          for (final s in parsed) {
            s.isExpanded = false;
          }
          _sections = parsed;
        }
      } catch (_) {}
    } else if (map['sections'] is List<dynamic>) {
      final parsed = (map['sections'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(StudioSection.fromJson)
          .toList();
      if (parsed.isNotEmpty) {
        for (final s in parsed) {
          s.isExpanded = false;
        }
        _sections = parsed;
      }
    }
    _applyExplicitSectionBooleans(map);
  }

  void _applyExplicitSectionBooleans(Map<String, dynamic> source) {
    final boolLookup = <String, String>{
      'sec_branding': 'secBrandingEnabled',
      'sec_invoice_details': 'secInvoiceDetailsEnabled',
      'sec_bill_to': 'secBillToEnabled',
      'sec_ship_to': 'secShipToEnabled',
      'sec_services': 'secServicesEnabled',
      'sec_tax_totals': 'secTaxTotalsEnabled',
      'sec_bank_payment': 'secBankPaymentEnabled',
      'sec_adjustments': 'secAdjustmentsEnabled',
      'sec_terms_notes': 'secTermsNotesEnabled',
      'sec_signature': 'secSignatureEnabled',
    };
    final nestedBooleans = source['sectionBooleans'] is Map
        ? Map<String, dynamic>.from(source['sectionBooleans'] as Map)
        : const <String, dynamic>{};

    for (final sec in _sections) {
      final camelKey = boolLookup[sec.id];
      final rawVal = nestedBooleans[sec.id] ??
          source[sec.id] ??
          (camelKey != null ? source[camelKey] : null);
      if (rawVal is bool) {
        sec.enabled = rawVal;
      }
    }
    if (source['letterheadEnabled'] is bool) {
      _letterheadEnabled = source['letterheadEnabled'] as bool;
    }
    if (source['showQrCode'] is bool) {
      _showQrCode = source['showQrCode'] as bool;
    }
  }

  void _initFromInitialSettings() {
    if (widget.initialLocalSettings.isNotEmpty) {
      final preset = widget.initialLocalSettings['studio_preset']?.toString();
      if (preset != null && preset.isNotEmpty) {
        _activePreset = preset;
      }
      final name = widget.initialLocalSettings['studio_template_name']?.toString();
      if (name != null && name.isNotEmpty) {
        _templateName = name;
        _nameController.text = name;
      }
      final defaultTpl = widget.initialLocalSettings['preferredTemplateId']?.toString() ??
          widget.initialLocalSettings['company_default_template_id']?.toString();
      if (defaultTpl != null && defaultTpl.isNotEmpty) {
        _companyDefaultTemplateId = defaultTpl;
        _selectedTemplateId = defaultTpl;
      }
      final primaryHex = widget.initialLocalSettings['studio_primary_color']?.toString();
      if (primaryHex != null && primaryHex.isNotEmpty) {
        final parsed = int.tryParse(primaryHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          _primaryColor = Color(0xFF000000 | parsed);
        }
      }
      final headerTextHex = widget.initialLocalSettings['studio_table_header_text_color']?.toString();
      if (headerTextHex != null && headerTextHex.isNotEmpty) {
        final parsed = int.tryParse(headerTextHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          _tableHeaderTextColor = Color(0xFF000000 | parsed);
        }
      }
      final font = widget.initialLocalSettings['studio_font_family']?.toString();
      if (font != null && font.isNotEmpty) {
        _fontFamily = font;
      }
      final scaleStr = widget.initialLocalSettings['studio_font_scale']?.toString();
      if (scaleStr != null && scaleStr.isNotEmpty) {
        final parsed = double.tryParse(scaleStr);
        if (parsed != null && parsed > 0) {
          _fontScale = parsed;
        }
      }
      final border = widget.initialLocalSettings['studio_table_border']?.toString();
      if (border != null && border.isNotEmpty) {
        _tableBorderStyle = border;
      }
      final docTitle = widget.initialLocalSettings['customTitle']?.toString();
      if (docTitle != null && docTitle.isNotEmpty) {
        _documentTitle = docTitle;
      }
      if (widget.initialLocalSettings['studio_uppercase_headings'] is bool) {
        _uppercaseHeadings = widget.initialLocalSettings['studio_uppercase_headings'] as bool;
      }
      final watermark = widget.initialLocalSettings['studio_watermark']?.toString();
      if (watermark != null && watermark.isNotEmpty) {
        _watermark = watermark;
      }
      final margin = widget.initialLocalSettings['studio_page_margin']?.toString();
      if (margin != null && margin.isNotEmpty) {
        _pageMargin = margin;
      }
      if (widget.initialLocalSettings['showQrCode'] is bool) {
        _showQrCode = widget.initialLocalSettings['showQrCode'] as bool;
      }
      final formula = widget.initialLocalSettings['itemCalculationFormula']?.toString();
      if (formula != null && formula.isNotEmpty) {
        _itemCalculationFormula = formula;
      }
      final stdDays = double.tryParse(widget.initialLocalSettings['standardDutyDays']?.toString() ?? '');
      if (stdDays != null && stdDays > 0) {
        _standardDutyDays = stdDays;
      }

      // Sync organization branding assets & Business Profile company details
      _logoBase64 = widget.initialLocalSettings['invoiceLogo']?.toString() ??
          _stripDataPrefix(widget.initialLocalSettings['logoUrl']?.toString());
      _stampBase64 = widget.initialLocalSettings['invoiceStamp']?.toString() ??
          _stripDataPrefix(widget.initialLocalSettings['stampUrl']?.toString());
      _signatureBase64 = widget.initialLocalSettings['invoiceSignature']?.toString() ??
          _stripDataPrefix(widget.initialLocalSettings['signatureUrl']?.toString());
      _signeeName = widget.initialLocalSettings['signeeName']?.toString();
      _signeeTitle = widget.initialLocalSettings['signeeTitle']?.toString();

      final orgName = widget.initialLocalSettings['businessName']?.toString().trim() ??
          widget.initialLocalSettings['companyName']?.toString().trim();
      if (orgName != null &&
          orgName.isNotEmpty &&
          orgName != 'Northstar Security Services Pvt. Ltd.' &&
          orgName != 'Apex Nova Dynamics') {
        _letterheadCompanyName = orgName;
      }
      final orgAddr = widget.initialLocalSettings['businessAddress']?.toString().trim();
      if (orgAddr != null && orgAddr.isNotEmpty) {
        _letterheadAddress = orgAddr;
      }
      final orgGstin = widget.initialLocalSettings['businessGstin']?.toString().trim();
      if (orgGstin != null && orgGstin.isNotEmpty) {
        _letterheadGstin = orgGstin;
      }
      final orgPan = widget.initialLocalSettings['businessPan']?.toString().trim();
      if (orgPan != null && orgPan.isNotEmpty) {
        _letterheadPan = orgPan;
      }
      final orgPhone = widget.initialLocalSettings['businessPhone']?.toString().trim();
      if (orgPhone != null && orgPhone.isNotEmpty) {
        _letterheadPhone = orgPhone;
      }
      final orgEmail = widget.initialLocalSettings['businessEmail']?.toString().trim();
      if (orgEmail != null && orgEmail.isNotEmpty) {
        _letterheadEmail = orgEmail;
      }

      final savedSectionsJson =
          widget.initialLocalSettings['studio_sections_json']?.toString();
      if (savedSectionsJson != null && savedSectionsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedSectionsJson) as List<dynamic>;
          final parsed = decoded
              .map((e) => StudioSection.fromJson(e as Map<String, dynamic>))
              .toList();
          if (parsed.isNotEmpty) {
            _sections = parsed;
          }
        } catch (_) {}
      }
    }
    // Ensure all loaded sections remain collapsed by default
    for (final s in _sections) {
      s.isExpanded = false;
    }
  }

  void _switchPreset(String presetKey) {
    setState(() {
      _activePreset = presetKey;
      final matched = _availableTemplates.firstWhere(
        (t) => t.presetKey == presetKey,
        orElse: () => _availableTemplates.first,
      );
      _selectedTemplateId = matched.id;
      _templateName = matched.name;
      _nameController.text = _templateName;
      _primaryColor = matched.primaryColor;
      _layoutStyle = matched.layoutStyle;

      if (presetKey == 'security_agency') {
        _tableBorderStyle = 'boxed';
        _sampleDataset = 'Security Agency (Northstar)';
      } else if (presetKey == 'gst_service') {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'GST Service Tech';
      } else if (presetKey == 'creative_vibrant') {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'Creative Studio';
      } else if (presetKey == 'construction_contractor') {
        _tableBorderStyle = 'boxed';
        _sampleDataset = 'Civil Infrastructure';
      } else if (presetKey == 'healthcare_clinic') {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'MediCare Clinic';
      } else if (presetKey == 'logistics_freight') {
        _tableBorderStyle = 'boxed';
        _sampleDataset = 'Express Logistics';
      } else if (presetKey == 'legal_counsel') {
        _tableBorderStyle = 'boxed';
        _sampleDataset = 'Apex Legal & Advisory';
      } else if (presetKey == 'hospitality_catering') {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'Grand Banquet';
      } else if (presetKey == 'consulting') {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'Apex Consulting';
      } else {
        _tableBorderStyle = 'lines';
        _sampleDataset = 'Retail Mart';
      }

      _sections = StudioSection.defaultSections(preset: presetKey);
      // Ensure all sections are collapsed by default
      for (final s in _sections) {
        s.isExpanded = false;
      }
      _markSaved();
    });
  }

  void _selectTemplate(StudioTemplateOption t) {
    setState(() {
      _selectedTemplateId = t.id;
      _layoutStyle = t.layoutStyle;
    });
    _switchPreset(t.presetKey);
  }

  Future<void> _setAsCompanyDefault() async {
    setState(() {
      _companyDefaultTemplateId = _selectedTemplateId;
      _saveMessage = 'Set as Default';
    });
    await _localPreferences.writeString('company_default_template_id', _selectedTemplateId);
    await _localPreferences.writeString('preferredTemplateId', _selectedTemplateId);
    await _localPreferences.writeString('company_default_template_name', _templateName);
    await _autoSaveLocal();

    widget.onSaveTemplate?.call(
      TemplateConfig(
        id: _selectedTemplateId,
        name: _templateName,
        title: _documentTitle.isNotEmpty ? _documentTitle : _templateName,
        category: _activePreset,
        color: '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        font: _fontFamily,
        itemHeader: _activePreset == 'security_agency' ? 'Particulars' : 'Description',
        businessCategory: _activePreset == 'security_agency' ? 'Security Agency' : 'Corporate Suite',
        dutyHeader: 'Duty Days',
        showDuty: true,
        quantityHeader: _activePreset == 'security_agency' ? 'Guards' : 'Qty',
        rateHeader: 'Rate (₹)',
        amountHeader: 'Amount (₹)',
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('★ "$_templateName" set as your company default invoice template!'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _logoBase64 = base64Str);
      _markSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Company Logo uploaded & updated in live preview!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload logo: $e')),
        );
      }
    }
  }

  void _removeLogo() {
    setState(() => _logoBase64 = null);
    _localPreferences.remove('invoiceLogo');
    _markSaved();
  }

  Future<void> _pickStamp() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _stampBase64 = base64Str);
      _markSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Official Company Stamp uploaded & updated in live preview!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload stamp: $e')),
        );
      }
    }
  }

  void _removeStamp() {
    setState(() => _stampBase64 = null);
    _localPreferences.remove('invoiceStamp');
    _markSaved();
  }

  Future<void> _captureSignatureInStudio() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: _signeeName,
      initialSigneeTitle: _signeeTitle,
    );
    if (result == null) return;
    setState(() {
      _signatureBase64 = result.base64Png;
      if (result.signeeName != null && result.signeeName!.isNotEmpty) {
        _signeeName = result.signeeName;
      }
      if (result.signeeTitle != null && result.signeeTitle!.isNotEmpty) {
        _signeeTitle = result.signeeTitle;
      }
    });
    _markSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Digital Signature captured via DocuHub Signer!'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
    }
  }

  void _removeSignature() {
    setState(() => _signatureBase64 = null);
    _localPreferences.remove('invoiceSignature');
    _markSaved();
  }

  void _onSectionEnabledChanged(StudioSection section, bool enabled) {
    setState(() {
      section.enabled = enabled;
      _markSaved();
    });
  }

  void _onSectionExpansionChanged(StudioSection section, bool isExpanded) {
    setState(() {
      section.isExpanded = isExpanded;
    });
  }

  void _onFieldVisibilityChanged(StudioSection section, StudioField field, bool isVisible) {
    setState(() {
      field.isVisible = isVisible;
      _markSaved();
    });
  }

  void _markSaved() {
    _saveMessage = 'Changes saved';
    _autoSaveLocal();
  }

  Map<String, bool> _buildSectionBooleanMap() {
    final map = <String, bool>{
      'sec_branding': true,
      'sec_invoice_details': true,
      'sec_bill_to': true,
      'sec_ship_to': true,
      'sec_services': true,
      'sec_tax_totals': true,
      'sec_bank_payment': true,
      'sec_adjustments': true,
      'sec_terms_notes': true,
      'sec_signature': true,
      'letterhead_enabled': _letterheadEnabled,
      'showQrCode': _showQrCode,
    };
    for (final sec in _sections) {
      map[sec.id] = sec.enabled;
    }
    return map;
  }

  Future<void> _autoSaveLocal({String statusOverride = 'PUBLISHED'}) async {
    final sectionsList = _sections.map((s) => s.toJson()).toList();
    final sectionsJson = jsonEncode(sectionsList);
    final sectionBooleans = _buildSectionBooleanMap();
    final primaryHex =
        '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final headerTextHex =
        '#${_tableHeaderTextColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final orgCodeVal = _orgCode.isNotEmpty
        ? _orgCode
        : (widget.initialLocalSettings['companyCode']?.toString() ??
            widget.initialLocalSettings['orgCode']?.toString() ??
            '');
    final data = <String, Object?>{
      ...widget.initialLocalSettings,
      'orgCode': orgCodeVal,
      if (_createdBy.isNotEmpty) 'createdBy': _createdBy,
      if (_updatedBy.isNotEmpty) 'updatedBy': _updatedBy,
      'studio_template_name': _templateName,
      'templateName': _templateName,
      'studio_preset': _activePreset,
      'industryPreset': _activePreset,
      'studio_sections_json': sectionsJson,
      'sections': sectionsList,
      'sectionBooleans': sectionBooleans,
      'secBrandingEnabled': sectionBooleans['sec_branding'] ?? true,
      'secInvoiceDetailsEnabled': sectionBooleans['sec_invoice_details'] ?? true,
      'secBillToEnabled': sectionBooleans['sec_bill_to'] ?? true,
      'secShipToEnabled': sectionBooleans['sec_ship_to'] ?? true,
      'secServicesEnabled': sectionBooleans['sec_services'] ?? true,
      'secTaxTotalsEnabled': sectionBooleans['sec_tax_totals'] ?? true,
      'secBankPaymentEnabled': sectionBooleans['sec_bank_payment'] ?? true,
      'secAdjustmentsEnabled': sectionBooleans['sec_adjustments'] ?? true,
      'secTermsNotesEnabled': sectionBooleans['sec_terms_notes'] ?? true,
      'secSignatureEnabled': sectionBooleans['sec_signature'] ?? true,
      'letterheadEnabled': _letterheadEnabled,
      'studio_primary_color': primaryHex,
      'studio_table_header_text_color': headerTextHex,
      'studio_font_family': _fontFamily,
      'studio_font_scale': _fontScale.toString(),
      'studio_table_border': _tableBorderStyle,
      'studio_layout_style': _layoutStyle,
      'studio_uppercase_headings': _uppercaseHeadings,
      'studio_watermark': _watermark,
      'studio_page_margin': _pageMargin,
      'showQrCode': _showQrCode,
      'businessCategory': _activePreset == 'security_agency' ? 'Security Agency' : 'Corporate Suite',
      'dutyHeader': 'Duty Days',
      'showDuty': true,
      'preferredTemplateId': _selectedTemplateId,
      'company_default_template_id': _companyDefaultTemplateId,
      'templateId': _selectedTemplateId,
      'customTitle': _documentTitle,
      'invoiceLogo': _logoBase64,
      'invoiceStamp': _stampBase64,
      'invoiceSignature': _signatureBase64,
      'signeeName': _signeeName,
      'signeeTitle': _signeeTitle,
      'showLogo': _logoBase64 != null && _logoBase64!.isNotEmpty,
      'showStamp': _stampBase64 != null && _stampBase64!.isNotEmpty,
      'showSignature': _signatureBase64 != null && _signatureBase64!.isNotEmpty,
      'letterhead_enabled': _letterheadEnabled,
      'letterhead_style_id': _letterheadStyleId,
      'letterhead_company_name': _letterheadCompanyName,
      'letterhead_tagline': _letterheadTagline,
      'letterhead_phone': _letterheadPhone,
      'letterhead_email': _letterheadEmail,
      'letterhead_website': _letterheadWebsite,
      'letterhead_address': _letterheadAddress,
      'letterhead_gstin': _letterheadGstin,
      'letterhead_pan': _letterheadPan,
      'letterhead_cin': _letterheadCin,
      'itemCalculationFormula': _itemCalculationFormula,
      'standardDutyDays': _standardDutyDays.toString(),
      'isRcmApplicable': _isRcmApplicable,
    };
    widget.onSaveLocalSettings?.call(data);
    await _localPreferences.writeString('sections_cache', sectionsJson);
    await _localPreferences.writeString('studio_preset', _activePreset);
    await _localPreferences.writeString('studio_template_name', _templateName);
    await _localPreferences.writeString('studio_primary_color', primaryHex);
    await _localPreferences.writeString('studio_table_header_text_color', headerTextHex);
    await _localPreferences.writeString('studio_font_family', _fontFamily);
    await _localPreferences.writeString('studio_font_scale', _fontScale.toString());
    await _localPreferences.writeString('studio_table_border', _tableBorderStyle);
    await _localPreferences.writeString('studio_layout_style', _layoutStyle);
    await _localPreferences.writeString('studio_doc_title', _documentTitle);
    await _localPreferences.writeString('studio_uppercase_headings', _uppercaseHeadings.toString());
    await _localPreferences.writeString('studio_watermark', _watermark);
    await _localPreferences.writeString('studio_page_margin', _pageMargin);
    await _localPreferences.writeString('studio_show_qr', _showQrCode.toString());
    await _localPreferences.writeString('itemCalculationFormula', _itemCalculationFormula);
    await _localPreferences.writeString('standardDutyDays', _standardDutyDays.toString());
    await _localPreferences.writeString('letterhead_enabled', _letterheadEnabled.toString());
    await _localPreferences.writeString('letterhead_style_id', _letterheadStyleId);
    await _localPreferences.writeString('letterhead_company_name', _letterheadCompanyName);
    await _localPreferences.writeString('letterhead_tagline', _letterheadTagline);
    await _localPreferences.writeString('letterhead_phone', _letterheadPhone);
    await _localPreferences.writeString('letterhead_email', _letterheadEmail);
    await _localPreferences.writeString('letterhead_website', _letterheadWebsite);
    await _localPreferences.writeString('letterhead_address', _letterheadAddress);
    await _localPreferences.writeString('letterhead_gstin', _letterheadGstin);
    await _localPreferences.writeString('letterhead_pan', _letterheadPan);
    await _localPreferences.writeString('letterhead_cin', _letterheadCin);
    if (_logoBase64 != null) {
      await _localPreferences.writeString('invoiceLogo', _logoBase64!);
    }
    if (_stampBase64 != null) {
      await _localPreferences.writeString('invoiceStamp', _stampBase64!);
    }
    if (_signatureBase64 != null) {
      await _localPreferences.writeString('invoiceSignature', _signatureBase64!);
    }
    if (_signeeName != null) {
      await _localPreferences.writeString('signeeName', _signeeName!);
    }
    if (_signeeTitle != null) {
      await _localPreferences.writeString('signeeTitle', _signeeTitle!);
    }

    // Persist customized settings JSON + section boolean flags to backend (excluding raw docx template documents)
    try {
      final backendPayload = <String, Object?>{
        ...data,
        'status': statusOverride,
        'configurationJson': sectionsJson,
        'settingsJson': jsonEncode(data),
      };
      final response = await widget.apiClient.putJson('api/v1/templates/settings', backendPayload);
      final savedMap = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      if (mounted && savedMap.isNotEmpty) {
        setState(() {
          final org = savedMap['orgCode']?.toString();
          if (org != null && org.isNotEmpty) _orgCode = org;
          final created = savedMap['createdBy']?.toString();
          if (created != null && created.isNotEmpty) _createdBy = created;
          final updated = savedMap['updatedBy']?.toString();
          if (updated != null && updated.isNotEmpty) _updatedBy = updated;
        });
      }
    } catch (_) {
      // Offline / local fallback handled seamlessly
    }
  }

  Future<void> _openSectionFormulaPopup(StudioSection section) async {
    final result = await FormulaBuilderPopup.show(
      context,
      targetTitle: '${section.title} — Automatic Subtotal & Daily Wage',
      initialFormulaCode: _itemCalculationFormula,
      initialExpression: '',
      initialStandardDays: _standardDutyDays,
    );
    if (result == null || !mounted) return;
    setState(() {
      _itemCalculationFormula = result.formulaCode;
      _standardDutyDays = result.standardDutyDays;
      for (final f in section.fields) {
        if (f.id == 'f_tot_sub' || f.id == 'f_col_amount') {
          f.formula = result.formulaExpression;
        }
      }
      _markSaved();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Formula saved: ${result.formulaExpression} (Base: ${result.standardDutyDays.toStringAsFixed(0)} days)',
        ),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openFieldFormulaPopup(StudioSection section, StudioField field) async {
    final result = await FormulaBuilderPopup.show(
      context,
      targetTitle: '${field.label} (${section.title})',
      initialFormulaCode: _itemCalculationFormula,
      initialExpression: field.formula,
      initialStandardDays: _standardDutyDays,
    );
    if (result == null || !mounted) return;
    setState(() {
      field.formula = result.formulaExpression;
      if (section.id == 'sec_services' ||
          section.id == 'sec_tax_totals' ||
          field.id == 'f_tot_sub' ||
          field.id == 'f_col_amount' ||
          field.id == 'f_col_rate') {
        _itemCalculationFormula = result.formulaCode;
        _standardDutyDays = result.standardDutyDays;
      }
      _markSaved();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Formula saved for "${field.label}": ${result.formulaExpression}'),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await _autoSaveLocal(statusOverride: 'DRAFT');
      setState(() {
        _templateStatus = 'Draft';
        _saveMessage = 'Draft saved to server';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Template draft & section settings saved to backend!'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishTemplate() async {
    setState(() => _saving = true);
    try {
      await _autoSaveLocal(statusOverride: 'PUBLISHED');

      // Notify parent template config
      widget.onSaveTemplate?.call(
        TemplateConfig(
          id: 'tpl_$_activePreset',
          name: _templateName,
          title: _templateName,
          category: _activePreset,
          color: '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
          font: _fontFamily,
          itemHeader: 'Particulars',
          businessCategory: _activePreset == 'security_agency' ? 'Security' : 'Corporate',
          dutyHeader: 'Duty Days',
          showDuty: true,
          quantityHeader: 'Guards',
          rateHeader: 'Rate (₹)',
          amountHeader: 'Amount (₹)',
        ),
      );

      setState(() {
        _templateStatus = 'Published';
        _saveMessage = 'Published & Active';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Template published and saved to backend for your organization!'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAddFieldDialog(StudioSection section) {
    StudioAddFieldDialog.show(
      context,
      section: section,
      initialFormulaCode: _itemCalculationFormula,
      initialStandardDays: _standardDutyDays,
      onFieldAdded: (newField) {
        setState(() {
          section.fields.add(newField);
          _markSaved();
        });
      },
    );
  }

  void _showEditFieldDialog(StudioSection section, StudioField field) {
    StudioEditFieldDialog.show(
      context,
      field: field,
      initialFormulaCode: _itemCalculationFormula,
      initialStandardDays: _standardDutyDays,
      onSaveField: (updatedField) {
        setState(() {
          _markSaved();
        });
      },
    );
  }

  void _duplicateField(StudioSection section, StudioField field) {
    setState(() {
      final copy = field.copyWith(
        id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
        label: '${field.label} (Copy)',
      );
      final idx = section.fields.indexOf(field);
      if (idx != -1) {
        section.fields.insert(idx + 1, copy);
      } else {
        section.fields.add(copy);
      }
      _markSaved();
    });
  }

  void _deleteField(StudioSection section, StudioField field) {
    if (field.isRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove required field "${field.label}"'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      section.fields.remove(field);
      _markSaved();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Field "${field.label}" removed from template'),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF93C5FD),
          onPressed: () {
            setState(() {
              section.fields.add(field);
              _markSaved();
            });
          },
        ),
      ),
    );
  }

  void _showStyleDialog() {
    StudioStyleDialog.show(
      context,
      initialConfig: StudioStyleConfig(
        fontFamily: _fontFamily,
        fontScale: _fontScale,
        uppercaseHeadings: _uppercaseHeadings,
        documentTitle: _documentTitle,
        primaryColor: _primaryColor,
        tableHeaderTextColor: _tableHeaderTextColor,
        tableBorderStyle: _tableBorderStyle,
      ),
      onApplyStyle: (updated) {
        setState(() {
          _fontFamily = updated.fontFamily;
          _fontScale = updated.fontScale;
          _uppercaseHeadings = updated.uppercaseHeadings;
          _documentTitle = updated.documentTitle;
          _primaryColor = updated.primaryColor;
          _tableHeaderTextColor = updated.tableHeaderTextColor;
          _tableBorderStyle = updated.tableBorderStyle;
          _markSaved();
        });
        _localPreferences.writeString('studio_font_family', _fontFamily);
        _localPreferences.writeString('studio_font_scale', _fontScale.toString());
        _localPreferences.writeString('studio_table_border', _tableBorderStyle);
        _localPreferences.writeString('studio_doc_title', _documentTitle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ“ Style applied to invoice template!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showPageSettingsDialog() {
    StudioPageSettingsDialog.show(
      context,
      showQrCode: _showQrCode,
      watermark: _watermark,
      pageMargin: _pageMargin,
      onSaveSettings: (tempQr, tempWatermark, tempMargin) {
        setState(() {
          _showQrCode = tempQr;
          _watermark = tempWatermark;
          _pageMargin = tempMargin;
          _markSaved();
        });
      },
    );
  }

  void _showTemplateSelectorDialog() {
    StudioTemplateSelectorDialog.show(
      context,
      availableTemplates: _availableTemplates,
      activePreset: _activePreset,
      companyDefaultTemplateId: _companyDefaultTemplateId,
      onSelectTemplate: _selectTemplate,
      onSetAsCompanyDefault: (t) => _setAsCompanyDefault(),
    );
  }

  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.library_add_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Add Custom Section', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Section Title *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Compliance & Approvals',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Subtitle / Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: subtitleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Regulatory compliance and statutory details',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              setState(() {
                _sections.add(
                  StudioSection(
                    id: 'sec_${DateTime.now().microsecondsSinceEpoch}',
                    title: title,
                    subtitle: subtitleCtrl.text.trim(),
                    icon: Icons.layers_outlined,
                    enabled: true,
                    isExpanded: true,
                    fields: [
                      StudioField(
                        id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
                        label: 'Reference ID',
                        type: StudioFieldType.text,
                        isRequired: false,
                        isVisible: true,
                      ),
                    ],
                  ),
                );
                _markSaved();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Create Section'),
          ),
        ],
      ),
    );
  }

  Map<String, Object?> _currentStudioSettingsMap() {
    final sectionsJson =
        jsonEncode(_sections.map((s) => s.toJson()).toList());
    final primaryHex =
        '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final headerTextHex =
        '#${_tableHeaderTextColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return <String, Object?>{
      ...widget.initialLocalSettings,
      'studio_template_name': _templateName,
      'studio_preset': _activePreset,
      'studio_sections_json': sectionsJson,
      'studio_primary_color': primaryHex,
      'studio_table_header_text_color': headerTextHex,
      'studio_font_family': _fontFamily,
      'studio_font_scale': _fontScale.toString(),
      'studio_table_border': _tableBorderStyle,
      'studio_uppercase_headings': _uppercaseHeadings,
      'studio_watermark': _watermark,
      'studio_page_margin': _pageMargin,
      'showQrCode': _showQrCode,
      'customTitle': _documentTitle,
      'invoiceLogo': _logoBase64,
      'invoiceStamp': _stampBase64,
      'invoiceSignature': _signatureBase64,
      'signeeName': _signeeName,
      'signeeTitle': _signeeTitle,
      'letterhead_enabled': _letterheadEnabled,
      'letterhead_style_id': _letterheadStyleId,
      'letterhead_company_name': _letterheadCompanyName,
      'letterhead_tagline': _letterheadTagline,
      'letterhead_phone': _letterheadPhone,
      'letterhead_email': _letterheadEmail,
      'letterhead_website': _letterheadWebsite,
      'letterhead_address': _letterheadAddress,
      'letterhead_gstin': _letterheadGstin,
      'letterhead_pan': _letterheadPan,
      'letterhead_cin': _letterheadCin,
    };
  }

  Invoice _samplePreviewInvoice() {
    return const Invoice(
      invoiceNumber: 'INV-2025-0148',
      clientName: 'Mr. Rahul Sharma',
      clientCompany: 'ABC Industries Pvt. Ltd.',
      clientAddress: '101, Business Tower, MG Road,\nBengaluru, Karnataka - 560001',
      clientTaxId: '29AABCA1234B1Z2',
      clientPhone: '+91 98800 11223',
      issueDate: '15 Apr 2025',
      dueDate: '30 Apr 2025',
      poNumber: 'PO-4587/2025',
      paymentTerms: '30 Days',
      currencyCode: 'INR',
      currencySymbol: '₹',
      taxRate: 18,
      taxLabel: 'GST',
      taxType: 'GST',
      discountAmount: 5000,
      items: [
        InvoiceItem(
          description: 'Security Guard (12-hour shift)',
          quantity: 4,
          dutyCount: 26,
          standardDutyDays: 26,
          unitPrice: 55900,
          calculationFormula: 'monthly_salary_26',
        ),
        InvoiceItem(
          description: 'Armed Guard (12-hour shift)',
          quantity: 2,
          dutyCount: 26,
          standardDutyDays: 26,
          unitPrice: 74100,
          calculationFormula: 'monthly_salary_26',
        ),
      ],
    );
  }

  Future<void> _exportPdfDocument() async {
    await _autoSaveLocal();
    final settings = _currentStudioSettingsMap();
    final sampleInv = _samplePreviewInvoice();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => InvoicePdfExport.build(
        sampleInv,
        localSettings: settings,
      ),
      name: '${_templateName.replaceAll(RegExp(r'\s+'), '_')}.pdf',
    );
  }

  Future<void> _exportDocxDocument() async {
    await _autoSaveLocal();
    final settings = _currentStudioSettingsMap();
    final sampleInv = _samplePreviewInvoice();
    final Uint8List bytes = InvoiceDocxExport.build(
      sampleInv,
      localSettings: settings,
    );
    final filename = '${_templateName.replaceAll(RegExp(r'\s+'), '_')}.docx';
    await FileDownloadHelper.downloadFile(
      bytes: bytes,
      filename: filename,
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved $filename to Downloads'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Studio Bar
            _buildTopStudioBar(),

            // 2. Sub-Header Navigation Tabs
            _buildTopSubHeaderTabs(),

            // 3. Main Split Content Area
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane: Accordion Studio
                        SizedBox(
                          width: 490,
                          child: _buildLeftAccordionEditor(),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFFD5DCE6)),

                        // Right Pane: A4 Document Canvas Workspace
                        Expanded(
                          child: _buildRightPreviewWorkspace(),
                        ),
                      ],
                    )
                  : _buildMobileView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return Column(
      children: [
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: AppTheme.neuRecessedDecoration(radius: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _previewOnlyOnMobile = false),
                    borderRadius: BorderRadius.circular(13),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: !_previewOnlyOnMobile
                          ? AppTheme.neuPillDecoration(radius: 13, isActive: true, activeColor: const Color(0xFFE2E8F0))
                          : null,
                      child: Center(
                        child: Text(
                          'Accordion Studio',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: !_previewOnlyOnMobile ? FontWeight.w800 : FontWeight.w600,
                            color: !_previewOnlyOnMobile ? const Color(0xFF0F172A) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _previewOnlyOnMobile = true),
                    borderRadius: BorderRadius.circular(13),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: _previewOnlyOnMobile
                          ? AppTheme.neuPillDecoration(radius: 13, isActive: true, activeColor: const Color(0xFFE2E8F0))
                          : null,
                      child: Center(
                        child: Text(
                          'A4 Preview',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _previewOnlyOnMobile ? FontWeight.w800 : FontWeight.w600,
                            color: _previewOnlyOnMobile ? const Color(0xFF0F172A) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _previewOnlyOnMobile
              ? _buildRightPreviewWorkspace()
              : _buildLeftAccordionEditor(),
        ),
      ],
    );
  }

  // 1. Top Studio Bar
  Widget _buildTopStudioBar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neuSurface,
        border: const Border(bottom: BorderSide(color: Color(0xFFD5DCE6))),
        boxShadow: [
          BoxShadow(
            color: AppColors.neuShadowDark.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          if (isCompact) {
            // Mobile-optimized 2-tier Top Studio Bar:
            // Tier 1: Back button, Full-width Template selector with dropdown arrow, and More menu
            // Tier 2: Status pill ('Draft'/'Published'), Save status message, Save Draft button, and Publish button
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      InkWell(
                        onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: AppTheme.neuOrbDecoration(),
                          child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Template Selector Pill (takes available space)
                      Expanded(
                        child: InkWell(
                          onTap: _showTemplateSelectorDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: AppTheme.neuPillDecoration(radius: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.style_outlined,
                                  size: 15,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _templateName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // More Menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val == 'reset') {
                            setState(() => _sections = StudioSection.defaultSections(preset: _activePreset));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sections reset to default')));
                          } else if (val == 'export') {
                            _exportPdfDocument();
                          } else if (val == 'rename') {
                            setState(() => _isEditingName = true);
                          } else if (val == 'default') {
                            _setAsCompanyDefault();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'export', child: Text('Export PDF Document')),
                          const PopupMenuItem(value: 'rename', child: Text('Rename Template')),
                          const PopupMenuItem(value: 'default', child: Text('Set as Company Default')),
                          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Template')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset to Preset Defaults')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _templateStatus == 'Published' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _templateStatus == 'Published' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          _templateStatus,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _templateStatus == 'Published' ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Cloud Sync Indicator
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _saveMessage,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Compact Save Draft Button
                      OutlinedButton.icon(
                        icon: _saving
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                            : const Icon(Icons.save_outlined, size: 14, color: Color(0xFF2563EB)),
                        label: const Text('Save Draft', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        onPressed: _saving ? null : _saveDraft,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Compact Publish Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.rocket_launch_rounded, size: 13, color: Colors.white),
                        label: const Text('Publish', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neuActiveDark,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _saving ? null : _publishTemplate,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Desktop Top Studio Bar
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Button in Neumorphic Orb
                      InkWell(
                        onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: AppTheme.neuOrbDecoration(),
                          child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Studio Badge Icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: AppTheme.neuOrbDecoration(
                          isActive: true,
                          activeColor: const Color(0xFF2563EB),
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome_mosaic_rounded, size: 17, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title
                      const Text(
                        'Invoice Template Studio',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Separator Pipe
                      Container(width: 1.5, height: 18, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 12),

                      // Template Selector Dropdown Pill
                      if (_isEditingName)
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _nameController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onSubmitted: (val) {
                              setState(() {
                                _templateName = val.trim().isNotEmpty ? val.trim() : _templateName;
                                _isEditingName = false;
                                _markSaved();
                              });
                            },
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _showTemplateSelectorDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                decoration: AppTheme.neuPillDecoration(radius: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.style_outlined,
                                      size: 15,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 7),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 230),
                                      child: Text(
                                        _templateName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                              tooltip: 'Rename Template',
                              onPressed: () => setState(() => _isEditingName = true),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),

                      // Default Template Pill or "Set Default" Action
                      if (_companyDefaultTemplateId == _selectedTemplateId)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                              SizedBox(width: 3),
                              Text(
                                'Default',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          icon: const Icon(Icons.star_border_rounded, size: 13, color: Color(0xFFD97706)),
                          label: const Text('Set Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            backgroundColor: const Color(0xFFFFFBEB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _setAsCompanyDefault,
                        ),
                      const SizedBox(width: 8),

                      // Organization Code & Audit Badge
                      if (_orgCode.isNotEmpty) ...[
                        Tooltip(
                          message: _updatedBy.isNotEmpty
                              ? 'Org: $_orgCode • Last updated by $_updatedBy'
                              : 'Org: $_orgCode',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: AppTheme.neuRecessedDecoration(radius: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  _orgCode,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Draft / Published Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _templateStatus == 'Published' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _templateStatus == 'Published' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          _templateStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _templateStatus == 'Published' ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Save status indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            _saveMessage,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Right Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF334155)),
                        label: const Text('Preview', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() => _previewOnlyOnMobile = true);
                        },
                      ),
                      const SizedBox(width: 8),

                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saving ? null : _saveDraft,
                        child: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Draft', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                      ),
                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.rocket_launch_rounded, size: 15, color: Colors.white),
                        label: const Text('Publish', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neuActiveDark,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _saving ? null : _publishTemplate,
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val == 'reset') {
                            setState(() => _sections = StudioSection.defaultSections(preset: _activePreset));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sections reset to default')));
                          } else if (val == 'export') {
                            _exportPdfDocument();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'export', child: Text('Export PDF Document')),
                          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Template')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset to Preset Defaults')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Sub-Header Navigation Tabs
  Widget _buildTopSubHeaderTabs() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.neuSurface,
        border: Border(bottom: BorderSide(color: Color(0xFFD5DCE6))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _topTabs.length; i++)
              _buildTopTabItem(
                title: _topTabs[i],
                isSelected: _activeTopTabIndex == i,
                onTap: () {
                  setState(() => _activeTopTabIndex = i);
                  _onTabSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData icon = switch (title) {
      'Template & Branding' => Icons.view_quilt_outlined,
      'Invoice Details & Billing' => Icons.description_outlined,
      'Line Items & Duty' => Icons.format_list_bulleted_rounded,
      'Tax & Totals' => Icons.percent_rounded,
      'Bank, Adjustments & Signature' => Icons.account_balance_outlined,
      _ => Icons.tune_outlined,
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    // Expand matching sections in the accordion
    final targetSectionIds = switch (index) {
      0 => ['sec_branding'],
      1 => ['sec_identity', 'sec_client'],
      2 => ['sec_services'],
      3 => ['sec_tax_totals'],
      4 => ['sec_bank', 'sec_terms'],
      _ => <String>[],
    };

    if (targetSectionIds.isNotEmpty) {
      setState(() {
        for (final s in _sections) {
          if (targetSectionIds.contains(s.id)) {
            s.isExpanded = true;
          }
        }
      });
    }
  }

  Widget _buildBrandingAssetsCustomContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Branding Assets (Company Logo & Official Stamp)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Live Sync',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your official company logo and round/oval seal for live A4 document branding and PDF generation.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              // Logo Block
              _buildBrandingAssetRow(
                isNarrow: isNarrow,
                previewWidget: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: _logoBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.memory(
                            base64Decode(_logoBase64!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Icon(Icons.business_outlined, color: Color(0xFF94A3B8), size: 24),
                ),
                title: 'Company Logo',
                subtitle: _logoBase64 != null ? 'Logo uploaded & active on invoices' : 'No logo uploaded (using preset icon)',
                isUploaded: _logoBase64 != null,
                onPick: _pickLogo,
                onRemove: _removeLogo,
                pickLabel: 'Upload Logo',
                replaceLabel: 'Replace',
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              // Stamp Block
              _buildBrandingAssetRow(
                isNarrow: isNarrow,
                previewWidget: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: _stampBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_stampBase64!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Icon(Icons.verified_outlined, color: Color(0xFF94A3B8), size: 24),
                ),
                title: 'Official Company Stamp / Seal',
                subtitle: _stampBase64 != null ? 'Stamp uploaded & applied to signature block' : 'No stamp uploaded',
                isUploaded: _stampBase64 != null,
                onPick: _pickStamp,
                onRemove: _removeStamp,
                pickLabel: 'Upload Stamp',
                replaceLabel: 'Replace',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandingAssetRow({
    required bool isNarrow,
    required Widget previewWidget,
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required String pickLabel,
    required String replaceLabel,
  }) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              previewWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: isUploaded ? const Color(0xFF059669) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: Icon(isUploaded ? Icons.edit_outlined : Icons.upload_outlined, size: 14),
                label: Text(isUploaded ? replaceLabel : pickLabel, style: const TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
                onPressed: onPick,
              ),
              if (isUploaded) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        previewWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: isUploaded ? const Color(0xFF059669) : const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          icon: Icon(isUploaded ? Icons.edit_outlined : Icons.upload_outlined, size: 14),
          label: Text(isUploaded ? replaceLabel : pickLabel, style: const TextStyle(fontSize: 11.5)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            side: const BorderSide(color: Color(0xFF93C5FD)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          ),
          onPressed: onPick,
        ),
        if (isUploaded) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            tooltip: 'Remove',
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildBankCustomContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_outlined, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Account & Payment QR',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Bank transfer details & UPI QR codes automatically display in payment box.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.draw_rounded, size: 14),
                      label: const Text('Capture Signature', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _captureSignatureInStudio,
                    ),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.draw_rounded, size: 14),
                    label: const Text('Capture Signature', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: _captureSignatureInStudio,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignatureCustomContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.draw_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Authorized Digital Signature (DocuHub Signer)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'Legal Signatory',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Draw ink signature or create styled typography to sign generated invoices and PDF documents.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              // Signature Preview & Capture Action (Responsive for narrow screens)
              if (isNarrow) ...[
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: _signatureBase64 != null
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.memory(
                              base64Decode(_signatureBase64!),
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'No Signature Saved',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.draw_outlined, size: 15),
                        label: Text(
                          _signatureBase64 != null ? 'Redraw Signature' : 'Capture Signature',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _captureSignatureInStudio,
                      ),
                    ),
                    if (_signatureBase64 != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        tooltip: 'Clear Signature',
                        onPressed: _removeSignature,
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 140,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: _signatureBase64 != null
                          ? Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.memory(
                                base64Decode(_signatureBase64!),
                                fit: BoxFit.contain,
                              ),
                            )
                          : const Center(
                              child: Text(
                                'No Signature Saved',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.draw_outlined, size: 15),
                            label: Text(
                              _signatureBase64 != null ? 'Redraw / Edit Signature' : 'Capture / Draw Signature',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _captureSignatureInStudio,
                          ),
                          if (_signatureBase64 != null) ...[
                            const SizedBox(height: 4),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                              label: const Text('Clear Signature', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _removeSignature,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Metadata Fields: Signatory Name & Title (Responsive for narrow screens)
              if (isNarrow) ...[
                TextFormField(
                  initialValue: _signeeName ?? '',
                  decoration: InputDecoration(
                    labelText: 'Signatory Name',
                    hintText: 'e.g. R. K. Sharma',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    _signeeName = val;
                    _markSaved();
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _signeeTitle ?? 'Authorized Signatory',
                  decoration: InputDecoration(
                    labelText: 'Signatory Title',
                    hintText: 'e.g. Director / Partner',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    _signeeTitle = val;
                    _markSaved();
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _signeeName ?? '',
                        decoration: InputDecoration(
                          labelText: 'Signatory Name',
                          hintText: 'e.g. R. K. Sharma',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          _signeeName = val;
                          _markSaved();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _signeeTitle ?? 'Authorized Signatory',
                        decoration: InputDecoration(
                          labelText: 'Signatory Title',
                          hintText: 'e.g. Director / Partner',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          _signeeTitle = val;
                          _markSaved();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxTotalsCustomContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Taxation & Reverse Charge (RCM) Configuration',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure default taxation mode and Reverse Charge Mechanism (RCM) for invoices generated with this template.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: SwitchListTile(
              dense: true,
              value: _isRcmApplicable,
              activeThumbColor: const Color(0xFF2563EB),
              title: const Text(
                'Enable Reverse Charge Mechanism (RCM) by Default',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              subtitle: const Text(
                'When enabled, invoices show "Tax Payable on Reverse Charge Basis by Recipient" and grand total excludes supplier tax collection.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              onChanged: (val) {
                setState(() {
                  _isRcmApplicable = val;
                  _markSaved();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  CompanyLetterheadConfig _currentLetterheadConfig() {
    final primaryHex =
        '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return CompanyLetterheadConfig(
      enabledForAllDocuments: _letterheadEnabled,
      styleId: _letterheadStyleId,
      companyName: _letterheadCompanyName,
      tagline: _letterheadTagline,
      phone: _letterheadPhone,
      email: _letterheadEmail,
      website: _letterheadWebsite,
      address: _letterheadAddress,
      gstin: _letterheadGstin,
      pan: _letterheadPan,
      cinOrLicense: _letterheadCin,
      logoBase64: _logoBase64,
      primaryColorHex: primaryHex,
    );
  }

  Widget _buildCompanyLetterheadStudioCard() {
    return CompanyLetterheadStudioCard(
      config: _currentLetterheadConfig(),
      letterheadEnabled: _letterheadEnabled,
      letterheadStyleId: _letterheadStyleId,
      primaryColor: _primaryColor,
      letterheadCompanyName: _letterheadCompanyName,
      letterheadTagline: _letterheadTagline,
      letterheadPhone: _letterheadPhone,
      letterheadEmail: _letterheadEmail,
      letterheadWebsite: _letterheadWebsite,
      letterheadAddress: _letterheadAddress,
      onEnabledChanged: (val) {
        setState(() {
          _letterheadEnabled = val;
          _markSaved();
        });
      },
      onStyleChanged: (styleId, enabled) {
        setState(() {
          _letterheadStyleId = styleId;
          _letterheadEnabled = enabled;
          _markSaved();
        });
      },
      onCompanyNameChanged: (v) {
        setState(() {
          _letterheadCompanyName = v;
          _markSaved();
        });
      },
      onTaglineChanged: (v) {
        setState(() {
          _letterheadTagline = v;
          _markSaved();
        });
      },
      onPhoneChanged: (v) {
        setState(() {
          _letterheadPhone = v;
          _markSaved();
        });
      },
      onEmailChanged: (v) {
        setState(() {
          _letterheadEmail = v;
          _markSaved();
        });
      },
      onWebsiteChanged: (v) {
        setState(() {
          _letterheadWebsite = v;
          _markSaved();
        });
      },
      onAddressChanged: (v) {
        setState(() {
          _letterheadAddress = v;
          _markSaved();
        });
      },
    );
  }
  // 3. Left Column: Accordion Section Editor
  Widget _buildLeftAccordionEditor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          color: const Color(0xFFF8FAFC),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 18, vertical: isMobile ? 12 : 18),
            children: [
              // Industry Preset Block
              _buildIndustryPresetsHeader(),
              const SizedBox(height: 14),

          // Official Company Letterhead Studio Card (Default for All Documents)
          _buildCompanyLetterheadStudioCard(),

          // Accordion Section Cards
          for (final section in _sections)
            InvoiceSectionAccordion(
              section: section,
              customContent: switch (section.id) {
                'sec_branding' => _buildBrandingAssetsCustomContent(),
                'sec_bank' => _buildBankCustomContent(),
                'sec_terms' => _buildSignatureCustomContent(),
                'sec_tax_totals' => _buildTaxTotalsCustomContent(),
                _ => null,
              },
              onEnabledChanged: (val) => _onSectionEnabledChanged(section, val),
              onExpansionChanged: (val) => _onSectionExpansionChanged(section, val),
              onFieldVisibilityChanged: (field, isVis) =>
                  _onFieldVisibilityChanged(section, field, isVis),
              onAddField: () => _showAddFieldDialog(section),
              onFieldFormula: (field) => _openFieldFormulaPopup(section, field),
              onSectionFormula: (section.id == 'sec_tax_totals' || section.id == 'sec_services')
                  ? () => _openSectionFormulaPopup(section)
                  : null,
              onEditField: (field) => _showEditFieldDialog(section, field),
              onDuplicateField: (field) => _duplicateField(section, field),
              onDeleteField: (field) => _deleteField(section, field),
              onDeleteSection: section.isLocked ? null : () {
                setState(() {
                  _sections.remove(section);
                  _markSaved();
                });
              },
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
      },
    );
  }

  Widget _buildIndustryPresetsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Industry Preset',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose a preset to get started quickly or customize from scratch.',
          style: TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Industry Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip('security_agency', 'Security Agency', Icons.security_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('gst_service', 'GST Service', Icons.apartment_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('creative_vibrant', 'Creative Agency', Icons.palette_outlined),
              const SizedBox(width: 8),
              _buildPresetChip('construction_contractor', 'Contractor RA', Icons.construction_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('healthcare_clinic', 'Healthcare', Icons.medical_services_outlined),
              const SizedBox(width: 8),
              _buildPresetChip('logistics_freight', 'Logistics', Icons.local_shipping_outlined),
              const SizedBox(width: 8),
              _buildPresetChip('legal_counsel', 'Legal & CA', Icons.gavel_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('hospitality_catering', 'Hospitality', Icons.restaurant_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('consulting', 'Consulting', Icons.person_outline_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('retail', 'Retail', Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              _buildPresetChip('modern', 'Modern Clean', Icons.auto_awesome_rounded),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                label: const Text(
                  'Add Section',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white,
                ),
                onPressed: _showAddSectionDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Invoice Layout Structure Picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_outlined, size: 14, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Invoice Layout Structure (Design):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLayoutChip('modern_split', 'Modern Split Cards', Icons.splitscreen_rounded),
                    const SizedBox(width: 6),
                    _buildLayoutChip('executive_banner', 'Executive Hero Banner', Icons.view_headline_rounded),
                    const SizedBox(width: 6),
                    _buildLayoutChip('compact_grid', 'Compact Matrix Ledger', Icons.grid_view_rounded),
                    const SizedBox(width: 6),
                    _buildLayoutChip('minimal_asymmetric', 'Creative Minimalist', Icons.auto_awesome_mosaic_rounded),
                    const SizedBox(width: 6),
                    _buildLayoutChip('sidebar_accent', 'Nordic Left Sidebar', Icons.view_sidebar_rounded),
                    const SizedBox(width: 6),
                    _buildLayoutChip('classic_bordered', 'Classic Chamber Frame', Icons.crop_square_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutChip(String key, String label, IconData icon) {
    final isSelected = _layoutStyle == key;
    return InkWell(
      onTap: () {
        setState(() => _layoutStyle = key);
        _markSaved();
        _autoSaveLocal();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String key, String label, IconData icon) {
    final isSelected = _activePreset == key;
    return InkWell(
      onTap: () => _switchPreset(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Right Column: Document Preview Workspace
  Widget _buildRightPreviewWorkspace() {
    final pagePadding = switch (_pageMargin) {
      'Compact (10mm)' => const EdgeInsets.all(20),
      'Spacious (24mm)' => const EdgeInsets.all(44),
      _ => const EdgeInsets.all(32),
    };

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          // Preview Top Toolbar
          _buildWorkspaceToolbar(),

          // Preview Canvas Scroll Container
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = (constraints.maxWidth - 32).clamp(240.0, 2400.0);
                final isNarrow = availableWidth < 760;
                final fitScale = isNarrow ? (availableWidth / 760.0) : 1.0;
                final effectiveScale = (fitScale * _zoomLevel).clamp(0.3, 2.0);
                final renderedWidth = 760.0 * effectiveScale;

                final paperCard = Container(
                  width: 760,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: pagePadding,
                  child: Stack(
                    children: [
                      if (_watermark != 'None')
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.35,
                                child: Text(
                                  _watermark,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 60 * _fontScale,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                    letterSpacing: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      _buildA4DocumentContent(),
                    ],
                  ),
                );

                final scaledCanvas = SizedBox(
                  width: renderedWidth,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: paperCard,
                  ),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.all(isNarrow ? 12 : 24),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: availableWidth),
                      child: Center(child: scaledCanvas),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left mode tabs
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFF2563EB), width: 2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _showPageSettingsDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text('Page settings', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _showStyleDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text('Style', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sample Data Pill Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sampleDataset,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            items: const [
                              DropdownMenuItem(value: 'Security Agency (Northstar)', child: Text('📋 Security Agency Sample')),
                              DropdownMenuItem(value: 'WASM Security & Tech', child: Text('📋 WASM Boxed Sample')),
                              DropdownMenuItem(value: 'GST Service Tech', child: Text('📋 GST Service Data')),
                              DropdownMenuItem(value: 'Apex Consulting', child: Text('📋 Consulting Data')),
                              DropdownMenuItem(value: 'Retail Mart', child: Text('📋 Retail Data')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sampleDataset = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Zoom Controls
                      IconButton(
                        icon: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          if (_zoomLevel > 0.6) setState(() => _zoomLevel -= 0.1);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      ),
                      Text('${(_zoomLevel * 100).round()}%',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      IconButton(
                        icon: const Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
                        tooltip: 'Zoom In',
                        onPressed: () {
                          if (_zoomLevel < 1.4) setState(() => _zoomLevel += 0.1);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      ),
                      const SizedBox(width: 8),

                      // Page indicator
                      Text('$_currentPage/$_totalPages ▾',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      const SizedBox(width: 12),

                      // Format
                      Text('$_paperFormat ▾',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(width: 12),

                      // Download PDF Action
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFFDC2626)),
                        tooltip: 'Export / Download PDF',
                        onPressed: _exportPdfDocument,
                      ),

                      // Export Word DOCX Action
                      IconButton(
                        icon: const Icon(Icons.description_rounded, size: 18, color: Color(0xFF2563EB)),
                        tooltip: 'Export Word (.docx)',
                        onPressed: _exportDocxDocument,
                      ),

                      // Print Action
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF475569)),
                        tooltip: 'Print Invoice',
                        onPressed: _exportPdfDocument,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. Rendered A4 Document Matching Screenshot & Settings
  TextStyle _docStyle({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF1E293B),
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize * _fontScale,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  Widget _buildA4DocumentContent() {
    final brandingSection = _sections.firstWhere((s) => s.id == 'sec_branding', orElse: () => _sections.first);
    final identitySection = _sections.firstWhere((s) => s.id == 'sec_identity', orElse: () => _sections.first);
    final clientSection = _sections.firstWhere((s) => s.id == 'sec_client', orElse: () => _sections.first);
    final servicesSection = _sections.firstWhere((s) => s.id == 'sec_services', orElse: () => _sections.first);
    final taxTotalsSection = _sections.firstWhere((s) => s.id == 'sec_tax_totals', orElse: () => _sections.first);
    final bankSection = _sections.firstWhere((s) => s.id == 'sec_bank', orElse: () => _sections.first);
    final termsSection = _sections.firstWhere((s) => s.id == 'sec_terms', orElse: () => _sections.first);

    final lhConfig = _currentLetterheadConfig();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Header (Company Letterhead Banner or Classic Business Branding)
        if (brandingSection.enabled) ...[
          if (lhConfig.isLetterheadActive)
            CompanyLetterheadWidgets.buildHeaderBanner(
              config: lhConfig,
              overridePrimaryColor: _primaryColor,
              fontScale: _fontScale,
              fontFamily: _fontFamily,
              showGstBadges: _isFieldVisible(brandingSection, 'f_biz_gstin') ||
                  _isFieldVisible(brandingSection, 'f_biz_pan'),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo & Brand Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isFieldVisible(brandingSection, 'f_biz_logo')) ...[
                      Container(
                        width: 46 * _fontScale,
                        height: 52 * _fontScale,
                        decoration: BoxDecoration(
                          color: _logoBase64 != null ? Colors.transparent : _primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: _logoBase64 != null
                              ? Image.memory(
                                  base64Decode(_logoBase64!),
                                  width: 46 * _fontScale,
                                  height: 52 * _fontScale,
                                  fit: BoxFit.contain,
                                )
                              : Icon(
                                  _activePreset == 'security_agency'
                                      ? Icons.shield_rounded
                                      : Icons.business_rounded,
                                  size: 28 * _fontScale,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isFieldVisible(brandingSection, 'f_biz_name'))
                          Text(
                            _activePreset == 'security_agency'
                                ? (_uppercaseHeadings ? 'NORTHSTAR' : 'Northstar')
                                : (_uppercaseHeadings ? 'ENTERPRISE TECH' : 'Enterprise Tech'),
                            style: _docStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: _primaryColor,
                            ),
                          ),
                        Text(
                          _activePreset == 'security_agency'
                              ? (_uppercaseHeadings ? 'SECURITY SERVICES' : 'Security Services')
                              : (_uppercaseHeadings ? 'SOLUTIONS & SERVICES' : 'Solutions & Services'),
                          style: _docStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: _primaryColor,
                          ),
                        ),
                        if (_isFieldVisible(brandingSection, 'f_biz_tagline')) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Safe People  |  Secure Tomorrow',
                            style: _docStyle(
                              fontSize: 9.5,
                              color: const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Company Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isFieldVisible(brandingSection, 'f_biz_name'))
                      Text(
                        'Northstar Security Services Ltd.',
                        style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                    const SizedBox(height: 1),
                    if (_isFieldVisible(brandingSection, 'f_biz_addr')) ...[
                      Text('#12, 3rd Floor, Green Park, Bengaluru,', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                      Text('Karnataka - 560076', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                    ],
                    if (_isFieldVisible(brandingSection, 'f_biz_gstin'))
                      Text('GSTIN: 29ABCDE1234F1Z5', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                    if (_isFieldVisible(brandingSection, 'f_biz_pan'))
                      Text('PAN: ABCDE1234F', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text('📞 +91 98765 43210', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                    Text('✉ info@northstarsecurity.in', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: _primaryColor, thickness: 1.5),
            const SizedBox(height: 16),
          ],
        ],

        // B & C. Document Identity & Client/Service Boxes (Layout Structure Driven)
        _buildIdentityAndClientByLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
        ),

        // D. Duty & Line Items Table (Dynamic Presets & Boxed Layout)
        if (servicesSection.enabled) ...[
          _buildDynamicLineItemsTable(servicesSection),
          const SizedBox(height: 16),
        ],

        // E. Financial Summary & Totals Box
        if (taxTotalsSection.enabled) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_sub'))
                      _buildSummaryRow('Subtotal', '₹ 3,71,800.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_disc'))
                      _buildSummaryRow('Discount', '(-) ₹ 5,000.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_taxable'))
                      _buildSummaryRow('Taxable Amount', '₹ 3,66,800.00', isBold: true),
                    if (_isRcmApplicable) ...[
                      _buildSummaryRow('Reverse Charge (RCM)', 'Tax Payable by Recipient', isBold: true),
                    ] else ...[
                      if (_isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                        _buildSummaryRow('CGST (9%)', '₹ 33,012.00'),
                      if (_isFieldVisible(taxTotalsSection, 'f_tot_sgst'))
                        _buildSummaryRow('SGST (9%)', '₹ 33,012.00'),
                    ],
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_grand')) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _uppercaseHeadings ? 'GRAND TOTAL' : 'Grand Total',
                              style: _docStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                            ),
                            Text(
                              _isRcmApplicable ? '₹ 3,66,800.00' : '₹ 4,32,824.00',
                              style: _docStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // F. Payment Details & UPI QR Code
        if (bankSection.enabled) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uppercaseHeadings ? 'PAYMENT DETAILS' : 'Payment Details',
                        style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      if (_isFieldVisible(bankSection, 'f_bnk_name'))
                        Text('Bank Name : INDFC Bank', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_ac'))
                        Text('A/C No.      : 50200012345678', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_ifsc'))
                        Text('IFSC           : HDFC0001234', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_upi'))
                        Text('UPI             : northstar@hdfcbank', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                    ],
                  ),
                ),
                if (_showQrCode && _isFieldVisible(bankSection, 'f_bnk_qr'))
                  Column(
                    children: [
                      Container(
                        width: 56 * _fontScale,
                        height: 56 * _fontScale,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 48 * _fontScale, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Scan to Pay', style: _docStyle(fontSize: 8.5, color: const Color(0xFF64748B))),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // G. Terms & Conditions and Signature
        if (termsSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uppercaseHeadings ? 'TERMS & CONDITIONS' : 'Terms & Conditions',
                      style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    if (_isFieldVisible(termsSection, 'f_trm_lines')) ...[
                      Text('1. Payment due within 15 days from the date of invoice.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('2. Late payment attracts 18% annual interest.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('3. Security personnel are deployed as per the agreed schedule.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('4. Any dispute must be reported within 7 days of service completion.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isFieldVisible(termsSection, 'f_trm_company'))
                      Text('For Northstar Security Services Ltd.', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    // Render Signature and Stamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_stampBase64 != null) ...[
                          Container(
                            width: 36 * _fontScale,
                            height: 36 * _fontScale,
                            margin: const EdgeInsets.only(right: 6),
                            child: Image.memory(
                              base64Decode(_stampBase64!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                        if (_signatureBase64 != null) ...[
                          Container(
                            height: 32 * _fontScale,
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Image.memory(
                              base64Decode(_signatureBase64!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 26 * _fontScale),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(width: 110, height: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 3),
                    if (_isFieldVisible(termsSection, 'f_trm_title'))
                      Text(_signeeTitle ?? 'Authorized Signatory', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                    if (_isFieldVisible(termsSection, 'f_trm_auto_stamp'))
                      Text('(This is a system generated invoice)', style: _docStyle(fontSize: 7.5, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // H. Custom Sections added by user
        for (final customSec in _sections.where(
          (s) => !const {
            'sec_branding',
            'sec_identity',
            'sec_client',
            'sec_services',
            'sec_tax_totals',
            'sec_bank',
            'sec_terms',
          }.contains(s.id),
        ))
          if (customSec.enabled && customSec.fields.any((f) => f.isVisible)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uppercaseHeadings ? customSec.title.toUpperCase() : customSec.title,
                    style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  if (customSec.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(customSec.subtitle, style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: customSec.fields.where((f) => f.isVisible).map((f) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${f.label}: ', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                          Text(f.defaultValue.isNotEmpty ? f.defaultValue : '—', style: _docStyle(fontSize: 9.5, color: const Color(0xFF1E293B))),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

        // I. Document Footer (Company Letterhead Footer or Classic Footer)
        if (lhConfig.isLetterheadActive)
          CompanyLetterheadWidgets.buildFooterBanner(
            config: lhConfig,
            overridePrimaryColor: _primaryColor,
            fontScale: _fontScale,
            fontFamily: _fontFamily,
            pageLabel: 'Page 1 of 1',
          )
        else ...[
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thank you for your business!', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B), fontStyle: FontStyle.italic)),
              Text('Page 1 of 1', style: _docStyle(fontSize: 8.5, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIdentityAndClientByLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
  }) {
    switch (_layoutStyle) {
      case 'executive_banner':
        return _buildExecutiveBannerLayout(identitySection, clientSection, servicesSection);
      case 'compact_grid':
        return _buildCompactGridLayout(identitySection, clientSection, servicesSection);
      case 'minimal_asymmetric':
        return _buildMinimalAsymmetricLayout(identitySection, clientSection, servicesSection);
      case 'sidebar_accent':
        return _buildSidebarAccentLayout(identitySection, clientSection, servicesSection);
      case 'classic_bordered':
        return _buildClassicBorderedLayout(identitySection, clientSection, servicesSection);
      case 'modern_split':
      default:
        return _buildModernSplitLayout(identitySection, clientSection, servicesSection);
    }
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _ledgerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: _docStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSplitLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identitySection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _uppercaseHeadings ? _documentTitle.toUpperCase() : _documentTitle,
                style: _docStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  if (_isFieldVisible(identitySection, 'f_doc_number'))
                    _metaRow('Invoice No.', 'INV-2025-0148'),
                  if (_isFieldVisible(identitySection, 'f_doc_issue'))
                    _metaRow('Issue Date', '15 Apr 2025'),
                  if (_isFieldVisible(identitySection, 'f_doc_due'))
                    _metaRow('Due Date', '30 Apr 2025'),
                  if (_isFieldVisible(identitySection, 'f_doc_po'))
                    _metaRow('PO No.', 'PO-4587/2025'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (clientSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uppercaseHeadings ? 'BILL TO' : 'Bill To',
                        style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      if (_isFieldVisible(clientSection, 'f_cli_name'))
                        Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_addr')) ...[
                        Text('101, Business Tower, MG Road,', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                        Text('Bengaluru, Karnataka - 560001', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      ],
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_gstin'))
                        Text('GSTIN: 29AABCA1234B1Z2', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(clientSection, 'f_cli_contact'))
                        Text('Contact: Mr. Rahul Sharma', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(clientSection, 'f_cli_phone'))
                        Text('Phone: +91 98800 11223', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              if (_isFieldVisible(servicesSection, 'f_srv_loc') || _isFieldVisible(servicesSection, 'f_srv_period')) ...[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isFieldVisible(servicesSection, 'f_srv_loc')) ...[
                          Text(_uppercaseHeadings ? 'SERVICE LOCATION' : 'Service Location', style: _docStyle(fontSize: 10, color: const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('Tech Park, Whitefield', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          Text('Bengaluru, Karnataka - 560066', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                        ],
                        if (_isFieldVisible(servicesSection, 'f_srv_period')) ...[
                          Text(_uppercaseHeadings ? 'BILLING PERIOD' : 'Billing Period', style: _docStyle(fontSize: 10, color: const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('01 Apr 2025 - 30 Apr 2025', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          Text('(30 Days)', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildExecutiveBannerLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identitySection.enabled) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _uppercaseHeadings ? _documentTitle.toUpperCase() : _documentTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('ORIGINAL BILL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroPill(Icons.tag_rounded, 'Inv: INV-2025-0148'),
                    _heroPill(Icons.calendar_today_rounded, 'Issued: 15 Apr 2025'),
                    _heroPill(Icons.event_available_rounded, 'Due: 30 Apr 2025'),
                    _heroPill(Icons.receipt_long_rounded, 'PO Ref: PO-4587/2025'),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (clientSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uppercaseHeadings ? 'BILLED TO (CLIENT)' : 'Billed To (Client)',
                              style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: _primaryColor, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 5),
                            Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('101, Business Tower, MG Road, Bengaluru - 560001', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                            Text('GSTIN: 29AABCA1234B1Z2 · Phone: +91 98800 11223', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uppercaseHeadings ? 'SERVICE LOCATION & PERIOD' : 'Service Location & Period',
                              style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF0D9488), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 5),
                            Text('Tech Park, Whitefield, Bengaluru - 560066', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('Billing Period: 01 Apr 2025 - 30 Apr 2025 (30 Days)', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                            Text('PSARA Verified Deployment Schedule', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCompactGridLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                          bottom: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. SUPPLIER / CONSIGNOR DETAILS', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 3),
                          Text('Northstar Security Services Ltd.', style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('#12, 3rd Floor, Green Park, Bengaluru - 560076', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          Text('GSTIN: 29ABCDE1234F1Z5 · PAN: ABCDE1234F', style: _docStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF0F172A), width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAX INVOICE & DISPATCH REF', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 3),
                          _ledgerRow('Invoice No.', 'INV-2025-0148'),
                          _ledgerRow('Date', '15 Apr 2025'),
                          _ledgerRow('Due Date', '30 Apr 2025'),
                          _ledgerRow('PO Ref', 'PO-4587/2025'),
                          _ledgerRow('State Code', '29 (Karnataka)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFF0F172A), width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2. BUYER / BILLED TO', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 3),
                          Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('101, Business Tower, MG Road, Bengaluru - 560001', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          Text('GSTIN: 29AABCA1234B1Z2 · State: 29', style: _docStyle(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('3. CONSIGNEE / SHIPPED TO', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 3),
                          Text('Tech Park, Whitefield', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('Bengaluru - 560066', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          Text('Period: 01 Apr - 30 Apr 2025', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalAsymmetricLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _uppercaseHeadings ? 'INVOICE' : 'Invoice',
              style: _docStyle(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Text(
              '//  INV-2025-0148',
              style: _docStyle(fontSize: 16, fontWeight: FontWeight.w300, color: const Color(0xFF64748B)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text('ISSUED: 15 APR 2025', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILLED TO', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text('101, Business Tower, MG Road\nBengaluru - 560001', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
                  Text('GST: 29AABCA1234B1Z2', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SERVICE SCOPE', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('Tech Park, Whitefield', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  Text('Period: 01 Apr - 30 Apr 2025\n30 Operating Days', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAYMENT TERMS', style: _docStyle(fontSize: 8.8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('Net 15 Days', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  Text('Due: 30 Apr 2025\nPO: PO-4587/2025', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSidebarAccentLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 4, height: 24, color: _primaryColor),
                const SizedBox(width: 8),
                Text(
                  _uppercaseHeadings ? _documentTitle.toUpperCase() : _documentTitle,
                  style: _docStyle(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            Row(
              children: [
                _heroPill(Icons.confirmation_number_outlined, 'INV-2025-0148'),
                const SizedBox(width: 6),
                _heroPill(Icons.event_outlined, '15 Apr 2025'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(color: _primaryColor, width: 4),
                    top: const BorderSide(color: Color(0xFFE2E8F0)),
                    right: const BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLIENT & BILLING ADDRESS', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: _primaryColor)),
                    const SizedBox(height: 4),
                    Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('101, Business Tower, MG Road, Bengaluru - 560001', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                    Text('GSTIN: 29AABCA1234B1Z2', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SERVICE DEPLOYMENT & PERIOD', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text('Tech Park, Whitefield, Bengaluru - 560066', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('Period: 01 Apr 2025 - 30 Apr 2025 (30 Days)', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                    Text('PO: PO-4587/2025 · Due: 30 Apr 2025', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildClassicBorderedLayout(
    StudioSection identitySection,
    StudioSection clientSection,
    StudioSection servicesSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '—  ✦  ${_uppercaseHeadings ? _documentTitle.toUpperCase() : _documentTitle}  ✦  —',
                style: _docStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Issued under Goods & Services Tax Act · Duplicate for Transporter',
                style: _docStyle(fontSize: 8.5, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF334155), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILLED TO (RECIPIENT):', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 3),
                    Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('101, Business Tower, MG Road, Bengaluru - 560001', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                    Text('GSTIN: 29AABCA1234B1Z2 · State: 29', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                  ],
                ),
              ),
              Container(width: 1, height: 56, color: const Color(0xFFCBD5E1), margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ledgerRow('Invoice No.', 'INV-2025-0148'),
                    _ledgerRow('Dated', '15 Apr 2025'),
                    _ledgerRow('Payment Due', '30 Apr 2025'),
                    _ledgerRow('Site / Place', 'Tech Park, Whitefield (560066)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _columnLabel(StudioSection section, String fieldId, String fallback) {
    final fld = section.fields.firstWhere(
      (f) => f.id == fieldId,
      orElse: () => StudioField(id: '', label: fallback),
    );
    if (fld.id.isEmpty || fld.label.trim().isEmpty) return fallback;
    return fld.label.replaceFirst(RegExp(r'\s*Column$', caseSensitive: false), '');
  }

  Widget _buildDynamicLineItemsTable(StudioSection section) {
    final isBoxed = _tableBorderStyle == 'boxed';
    final isStriped = _tableBorderStyle == 'striped';

    // Determine full columns based on preset with field IDs
    final List<({String fieldId, String label, int flex, TextAlign align})> allColumns;
    final List<List<String>> allRows;

    if (_activePreset == 'gst_service') {
      allColumns = [
        (fieldId: 'f_col_particulars', label: _columnLabel(section, 'f_col_particulars', 'Service Description & Scope'), flex: 5, align: TextAlign.left),
        (fieldId: 'f_col_guards', label: _columnLabel(section, 'f_col_guards', 'SAC Code'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_duty', label: _columnLabel(section, 'f_col_duty', 'Qty / Hrs'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_rate', label: _columnLabel(section, 'f_col_rate', 'Rate (₹)'), flex: 3, align: TextAlign.right),
        (fieldId: 'f_col_amount', label: _columnLabel(section, 'f_col_amount', 'Amount (₹)'), flex: 3, align: TextAlign.right),
      ];
      allRows = [
        ['Enterprise Cloud & Security Architecture', '998313', '160 Hrs', '1,500.00', '2,40,000.00'],
        ['Cybersecurity Audit & Penetration Testing', '998314', '1 Audit', '1,25,000.00', '1,25,000.00'],
      ];
    } else if (_activePreset == 'consulting') {
      allColumns = [
        (fieldId: 'f_col_particulars', label: _columnLabel(section, 'f_col_particulars', 'Scope & Deliverables'), flex: 5, align: TextAlign.left),
        (fieldId: 'f_col_guards', label: _columnLabel(section, 'f_col_guards', 'Lead Consultant'), flex: 3, align: TextAlign.center),
        (fieldId: 'f_col_duty', label: _columnLabel(section, 'f_col_duty', 'Hours / Days'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_rate', label: _columnLabel(section, 'f_col_rate', 'Rate (₹)'), flex: 3, align: TextAlign.right),
        (fieldId: 'f_col_amount', label: _columnLabel(section, 'f_col_amount', 'Amount (₹)'), flex: 3, align: TextAlign.right),
      ];
      allRows = [
        ['Strategic IT Security Advisory - Phase 1', 'Principal Advisor', '40 Hrs', '5,500.00', '2,20,000.00'],
        ['Compliance Certification Preparation', 'Senior Specialist', '20 Hrs', '4,200.00', '84,000.00'],
      ];
    } else if (_activePreset == 'retail') {
      allColumns = [
        (fieldId: 'f_col_particulars', label: _columnLabel(section, 'f_col_particulars', 'Item Description'), flex: 5, align: TextAlign.left),
        (fieldId: 'f_col_guards', label: _columnLabel(section, 'f_col_guards', 'SKU / HSN'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_duty', label: _columnLabel(section, 'f_col_duty', 'Qty'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_rate', label: _columnLabel(section, 'f_col_rate', 'MRP (₹)'), flex: 3, align: TextAlign.right),
        (fieldId: 'f_col_amount', label: _columnLabel(section, 'f_col_amount', 'Net Total (₹)'), flex: 3, align: TextAlign.right),
      ];
      allRows = [
        ['Smart Biometric Access Terminal Pro', 'BIO-901', '5', '18,500.00', '92,500.00'],
        ['HD Night-Vision CCTV Camera 4K', 'CAM-402', '12', '4,200.00', '50,400.00'],
      ];
    } else {
      // security_agency and default
      allColumns = [
        (fieldId: 'f_col_particulars', label: _columnLabel(section, 'f_col_particulars', 'Particulars'), flex: 5, align: TextAlign.left),
        (fieldId: 'f_col_guards', label: _columnLabel(section, 'f_col_guards', 'Guards'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_duty', label: _columnLabel(section, 'f_col_duty', 'Duty Days'), flex: 2, align: TextAlign.center),
        (fieldId: 'f_col_rate', label: _columnLabel(section, 'f_col_rate', 'Rate (₹)'), flex: 3, align: TextAlign.right),
        (fieldId: 'f_col_amount', label: _columnLabel(section, 'f_col_amount', 'Amount (₹)'), flex: 3, align: TextAlign.right),
      ];
      allRows = [
        ['Security Guard (12-hour shift)', '4', '26', '2,150.00', '2,23,600.00'],
        ['Armed Guard (12-hour shift)', '2', '26', '2,850.00', '1,48,200.00'],
      ];
    }

    final visibleIndices = <int>[];
    for (int i = 0; i < allColumns.length; i++) {
      if (_isFieldVisible(section, allColumns[i].fieldId)) {
        visibleIndices.add(i);
      }
    }
    if (visibleIndices.isEmpty) {
      visibleIndices.add(0);
    }

    final columns = [for (final idx in visibleIndices) allColumns[idx]];
    final rows = [
      for (final row in allRows)
        [for (final idx in visibleIndices) row[idx]],
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row
          Container(
            color: _primaryColor,
            child: Row(
              children: [
                for (int c = 0; c < columns.length; c++)
                  Expanded(
                    flex: columns[c].flex,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: isBoxed && c < columns.length - 1
                            ? const Border(right: BorderSide(color: Color(0x33FFFFFF), width: 1))
                            : null,
                      ),
                      child: Text(
                        _uppercaseHeadings ? columns[c].label.toUpperCase() : columns[c].label,
                        textAlign: columns[c].align,
                        style: _docStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _tableHeaderTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Rows
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0 && !isBoxed)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Container(
              color: isStriped && r.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
              decoration: isBoxed
                  ? const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                    )
                  : null,
              child: Row(
                children: [
                  for (int c = 0; c < rows[r].length; c++)
                    Expanded(
                      flex: columns[c].flex,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          border: isBoxed && c < rows[r].length - 1
                              ? const Border(right: BorderSide(color: Color(0xFFCBD5E1)))
                              : null,
                        ),
                        child: Text(
                          rows[r][c],
                          textAlign: columns[c].align,
                          style: _docStyle(
                            fontSize: 10,
                            fontWeight: c == 0
                                ? FontWeight.w600
                                : (c == rows[r].length - 1 ? FontWeight.bold : FontWeight.normal),
                            color: c == rows[r].length - 1
                                ? const Color(0xFF0F172A)
                                : (c == 0 ? const Color(0xFF1E293B) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TableRow _metaRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(label, style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(':', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(value, style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _docStyle(fontSize: 10, color: const Color(0xFF64748B), fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: _docStyle(fontSize: 10, color: const Color(0xFF1E293B), fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  bool _isFieldVisible(StudioSection section, String fieldId) {
    final fld = section.fields.firstWhere((f) => f.id == fieldId, orElse: () => StudioField(id: '', label: ''));
    return fld.id.isNotEmpty && fld.isVisible;
  }
}
