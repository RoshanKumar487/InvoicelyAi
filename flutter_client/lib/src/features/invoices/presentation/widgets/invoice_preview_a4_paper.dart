import 'dart:convert';
import 'package:flutter/material.dart';

import '../../data/invoice.dart';
import '../../../../core/utils/amount_to_words.dart';
import '../../../../core/utils/gst_tax_calculator.dart';
import '../../../templates/data/company_letterhead.dart';
import '../../../templates/data/studio_section_model.dart';
import '../../../templates/data/template_config.dart';

const double a4PaperWidth = 760.0;
const double a4PaperMinHeight = 1075.0;

class InvoicePreviewA4Paper extends StatelessWidget {
  const InvoicePreviewA4Paper({
    required this.invoice,
    required this.template,
    required this.templateColor,
    required this.isMobile,
    required this.localSettings,
    required this.profile,
    this.onSignTap,
    super.key,
  });

  final Invoice invoice;
  final TemplateConfig? template;
  final Color templateColor;
  final bool isMobile;
  final Map<String, Object?> localSettings;
  final Map<String, Object?> profile;
  final VoidCallback? onSignTap;

  String get _activePreset {
    final preset = localSettings['studio_preset']?.toString().trim();
    if (preset != null && preset.isNotEmpty) return preset;
    final cat = (template?.category ?? '').toLowerCase();
    if (cat.contains('gst')) return 'gst_service';
    if (cat.contains('consult')) return 'consulting';
    if (cat.contains('retail')) return 'retail';
    return 'security_agency';
  }

  Color get _primaryColor {
    final savedHex = localSettings['studio_primary_color']?.toString().trim();
    if (savedHex != null && savedHex.isNotEmpty) {
      final parsed = int.tryParse(savedHex.replaceFirst('#', ''), radix: 16);
      if (parsed != null) return Color(0xFF000000 | parsed);
    }
    return templateColor;
  }

  Color get _tableHeaderTextColor {
    final savedHex =
        localSettings['studio_table_header_text_color']?.toString().trim();
    if (savedHex != null && savedHex.isNotEmpty) {
      final parsed = int.tryParse(savedHex.replaceFirst('#', ''), radix: 16);
      if (parsed != null) return Color(0xFF000000 | parsed);
    }
    return Colors.white;
  }

  String get _fontFamily {
    final saved = localSettings['studio_font_family']?.toString().trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final tplFont = template?.font.trim();
    if (tplFont != null && tplFont.isNotEmpty) return tplFont;
    return 'Inter';
  }

  double get _fontScale {
    final saved = localSettings['studio_font_scale']?.toString().trim();
    if (saved != null && saved.isNotEmpty) {
      final parsed = double.tryParse(saved);
      if (parsed != null && parsed > 0) return parsed.clamp(0.75, 1.35);
    }
    return 1.0;
  }

  bool get _uppercaseHeadings {
    final saved = localSettings['studio_uppercase_headings'];
    if (saved is bool) return saved;
    if (saved is String) return saved.toLowerCase() == 'true';
    return true;
  }

  String get _tableBorderStyle {
    final saved = localSettings['studio_table_border']?.toString().trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return 'boxed';
  }

  String get _layoutStyle {
    final saved = localSettings['studio_layout_style']?.toString().trim();
    if (saved != null && saved.isNotEmpty) return saved;
    final tplLayout = template?.layoutStyle.trim();
    if (tplLayout != null && tplLayout.isNotEmpty) return tplLayout;
    return 'modern_split';
  }

  String get _watermark {
    final saved = localSettings['studio_watermark']?.toString().trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return 'None';
  }

  EdgeInsets get _pagePadding {
    final margin = localSettings['studio_page_margin']?.toString().trim() ??
        'Standard (16mm)';
    return switch (margin) {
      'Compact (10mm)' => const EdgeInsets.all(20),
      'Spacious (24mm)' => const EdgeInsets.all(44),
      _ => const EdgeInsets.all(32),
    };
  }

  bool get _showQrCode {
    final saved = localSettings['showQrCode'];
    if (saved is bool) return saved;
    if (saved is String) return saved.toLowerCase() == 'true';
    return true;
  }

  String get _documentTitle {
    final custom = localSettings['customTitle']?.toString().trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final tplTitle = template?.title.trim();
    if (tplTitle != null &&
        tplTitle.isNotEmpty &&
        !tplTitle.contains('—')) {
      return tplTitle;
    }
    return 'TAX INVOICE';
  }

  String get _currencySymbol {
    final s = localSettings['defaultCurrencySymbol']?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
    final c = localSettings['defaultCurrency']?.toString().trim();
    if (c != null && c.isNotEmpty) return currencySymbolFor(c);
    if (invoice.currencySymbol.isNotEmpty && invoice.currencySymbol != r'$') {
      return invoice.currencySymbol;
    }
    return '₹';
  }

  List<StudioSection> get _sections {
    final raw = localSettings['studio_sections_json']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => StudioSection.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {}
    }
    return StudioSection.defaultSections(preset: _activePreset);
  }

  StudioSection _findSection(List<StudioSection> sections, String id) {
    return sections.firstWhere(
      (s) => s.id == id,
      orElse: () => StudioSection(
        id: id,
        title: id,
        subtitle: '',
        icon: Icons.view_module_rounded,
        enabled: true,
      ),
    );
  }

  bool _isFieldVisible(StudioSection section, String fieldId, {bool fallback = true}) {
    final idx = section.fields.indexWhere((f) => f.id == fieldId);
    if (idx == -1) return fallback;
    return section.fields[idx].isVisible;
  }

  StudioField? _findField(StudioSection section, String fieldId) {
    final idx = section.fields.indexWhere((f) => f.id == fieldId);
    if (idx == -1) return null;
    return section.fields[idx];
  }

  String _columnLabel(StudioSection section, String fieldId, String fallback) {
    final fld = _findField(section, fieldId);
    if (fld == null || fld.label.trim().isEmpty) return fallback;
    return fld.label.replaceFirst(RegExp(r'\s*Column$', caseSensitive: false), '');
  }

  List<StudioField> _customVisibleFields(
    StudioSection section,
    Set<String> builtInIds,
  ) {
    return section.fields
        .where((f) => f.isVisible && !builtInIds.contains(f.id))
        .toList();
  }

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

  String _formatNumber(double val) {
    final isNeg = val < 0;
    final absVal = val.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    if (intPart.length <= 3) {
      return '${isNeg ? '-' : ''}$intPart.$decPart';
    }
    final lastThree = intPart.substring(intPart.length - 3);
    final otherNumbers = intPart.substring(0, intPart.length - 3);
    final formattedOther = otherNumbers.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (_) => ',',
    );
    return '${isNeg ? '-' : ''}$formattedOther,$lastThree.$decPart';
  }

  String _formatAmount(double val) => '$_currencySymbol ${_formatNumber(val)}';

  Map<String, dynamic> _shippingMap() {
    final json = invoice.shippingDetailsJson;
    if (json.trim().isEmpty || json.trim() == '{}') return const {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final brandingSection = _findSection(sections, 'sec_branding');
    final identitySection = _findSection(sections, 'sec_identity');
    final clientSection = _findSection(sections, 'sec_client');
    final servicesSection = _findSection(sections, 'sec_services');
    final taxTotalsSection = _findSection(sections, 'sec_tax_totals');
    final bankSection = _findSection(sections, 'sec_bank');
    final termsSection = _findSection(sections, 'sec_terms');

    // Business details from profile / localSettings with clean fallbacks
    final companyLegalName = (profile['companyName']?.toString().trim().isNotEmpty == true)
        ? profile['companyName']!.toString().trim()
        : (localSettings['companyName']?.toString().trim().isNotEmpty == true
            ? localSettings['companyName']!.toString().trim()
            : (_findField(brandingSection, 'f_biz_name')?.defaultValue.trim().isNotEmpty == true
                ? _findField(brandingSection, 'f_biz_name')!.defaultValue.trim()
                : 'Northstar Security Services Ltd.'));

    // Derive Brand Headline & Subtitle from company name or preset
    final words = companyLegalName.split(RegExp(r'\s+'));
    final brandHeadline = words.isNotEmpty
        ? words.first
        : (_activePreset == 'security_agency' ? 'NORTHSTAR' : 'ENTERPRISE');
    final brandSubtitle = words.length > 1
        ? words.sublist(1).join(' ').replaceAll(RegExp(r'\b(Pvt\.?|Ltd\.?|LLP|Inc\.?)\b', caseSensitive: false), '').trim()
        : (_activePreset == 'security_agency' ? 'SECURITY SERVICES' : 'SOLUTIONS & SERVICES');

    final companyTagline = (profile['tagline']?.toString().trim().isNotEmpty == true)
        ? profile['tagline']!.toString().trim()
        : (localSettings['companyTagline']?.toString().trim().isNotEmpty == true
            ? localSettings['companyTagline']!.toString().trim()
            : (_findField(brandingSection, 'f_biz_tagline')?.defaultValue.trim().isNotEmpty == true
                ? _findField(brandingSection, 'f_biz_tagline')!.defaultValue.trim()
                : 'Safe People  |  Secure Tomorrow'));

    final companyAddress = (profile['companyAddress']?.toString().trim().isNotEmpty == true)
        ? profile['companyAddress']!.toString().trim()
        : (localSettings['companyAddress']?.toString().trim().isNotEmpty == true
            ? localSettings['companyAddress']!.toString().trim()
            : '#12, 3rd Floor, Green Park, Bengaluru,\nKarnataka - 560076');

    final companyGstin = (profile['taxId']?.toString().trim().isNotEmpty == true)
        ? profile['taxId']!.toString().trim()
        : (localSettings['companyGstin']?.toString().trim().isNotEmpty == true
            ? localSettings['companyGstin']!.toString().trim()
            : (_findField(brandingSection, 'f_biz_gstin')?.defaultValue.trim().isNotEmpty == true
                ? _findField(brandingSection, 'f_biz_gstin')!.defaultValue.trim()
                : '29ABCDE1234F1Z5'));

    final companyPan = (profile['panNumber']?.toString().trim().isNotEmpty == true)
        ? profile['panNumber']!.toString().trim()
        : (localSettings['companyPan']?.toString().trim().isNotEmpty == true
            ? localSettings['companyPan']!.toString().trim()
            : (_findField(brandingSection, 'f_biz_pan')?.defaultValue.trim().isNotEmpty == true
                ? _findField(brandingSection, 'f_biz_pan')!.defaultValue.trim()
                : (companyGstin.length >= 12 ? companyGstin.substring(2, 12) : 'ABCDE1234F')));

    final companyPhone = (profile['companyPhone']?.toString().trim().isNotEmpty == true)
        ? profile['companyPhone']!.toString().trim()
        : (localSettings['companyPhone']?.toString().trim().isNotEmpty == true
            ? localSettings['companyPhone']!.toString().trim()
            : '+91 98765 43210');

    final companyEmail = (profile['companyEmail']?.toString().trim().isNotEmpty == true)
        ? profile['companyEmail']!.toString().trim()
        : (localSettings['companyEmail']?.toString().trim().isNotEmpty == true
            ? localSettings['companyEmail']!.toString().trim()
            : 'info@northstarsecurity.in');

    final logoBase64 = localSettings['invoiceLogo']?.toString().trim();
    final stampBase64 = localSettings['invoiceStamp']?.toString().trim();
    final signatureBase64 = localSettings['invoiceSignature']?.toString().trim();
    final signeeTitle = (localSettings['signeeTitle']?.toString().trim().isNotEmpty == true)
        ? localSettings['signeeTitle']!.toString().trim()
        : (_findField(termsSection, 'f_trm_title')?.defaultValue.trim().isNotEmpty == true
            ? _findField(termsSection, 'f_trm_title')!.defaultValue.trim()
            : 'Authorized Signatory');

    // Client details
    final clientDisplayName = invoice.clientCompany.trim().isNotEmpty
        ? invoice.clientCompany.trim()
        : (invoice.clientName.trim().isNotEmpty
            ? invoice.clientName.trim()
            : 'ABC Industries Pvt. Ltd.');
    final clientContactPerson =
        (invoice.clientCompany.trim().isNotEmpty &&
                invoice.clientName.trim().isNotEmpty &&
                invoice.clientName.trim() != invoice.clientCompany.trim())
            ? invoice.clientName.trim()
            : (_findField(clientSection, 'f_cli_contact')?.defaultValue.trim() ?? '');
    final clientAddr = invoice.clientAddress.trim().isNotEmpty
        ? invoice.clientAddress.trim()
        : '101, Business Tower, MG Road,\nBengaluru, Karnataka - 560001';
    final clientGstin = invoice.clientTaxId.trim().isNotEmpty
        ? invoice.clientTaxId.trim()
        : '29AABCA1234B1Z2';
    final clientPhone = invoice.clientPhone.trim().isNotEmpty
        ? invoice.clientPhone.trim()
        : '+91 98800 11223';

    // Service Location & Billing Period
    final shipping = _shippingMap();
    final serviceLocation = (shipping['shippingAddress']?.toString().trim().isNotEmpty == true)
        ? shipping['shippingAddress']!.toString().trim()
        : ((shipping['deliveryAddress']?.toString().trim().isNotEmpty == true)
            ? shipping['deliveryAddress']!.toString().trim()
            : (_findField(servicesSection, 'f_srv_loc')?.defaultValue.trim().isNotEmpty == true
                ? _findField(servicesSection, 'f_srv_loc')!.defaultValue.trim()
                : (invoice.clientAddress.trim().isNotEmpty
                    ? invoice.clientAddress.trim()
                    : 'Tech Park, Whitefield\nBengaluru, Karnataka - 560066')));

    final billingPeriod = (_findField(servicesSection, 'f_srv_period')?.defaultValue.trim().isNotEmpty == true)
        ? _findField(servicesSection, 'f_srv_period')!.defaultValue.trim()
        : '${invoice.issueDate.isNotEmpty ? invoice.issueDate : '01 Apr 2025'} - ${invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025'}';

    // Tax & Totals calculation
    final gstBreakdown = GstTaxCalculator.calculate(
      taxableAmount: invoice.taxableAmount,
      taxRate: invoice.taxRate,
      taxLabel: invoice.taxLabel,
      taxType: invoice.taxType,
      isRcm: invoice.isRcm,
      supplierPlaceOfSupply: companyAddress,
      clientPlaceOfSupply: invoice.clientAddress,
    );

    // Bank details
    final bankName = (profile['bankName']?.toString().trim().isNotEmpty == true)
        ? profile['bankName']!.toString().trim()
        : (localSettings['bankName']?.toString().trim().isNotEmpty == true
            ? localSettings['bankName']!.toString().trim()
            : (_findField(bankSection, 'f_bnk_name')?.defaultValue.trim().isNotEmpty == true
                ? _findField(bankSection, 'f_bnk_name')!.defaultValue.trim()
                : 'HDFC Bank'));
    final bankAccount = (profile['accountNumber']?.toString().trim().isNotEmpty == true)
        ? profile['accountNumber']!.toString().trim()
        : (localSettings['accountNumber']?.toString().trim().isNotEmpty == true
            ? localSettings['accountNumber']!.toString().trim()
            : (_findField(bankSection, 'f_bnk_ac')?.defaultValue.trim().isNotEmpty == true
                ? _findField(bankSection, 'f_bnk_ac')!.defaultValue.trim()
                : '50200012345678'));
    final bankIfsc = (profile['ifscCode']?.toString().trim().isNotEmpty == true)
        ? profile['ifscCode']!.toString().trim()
        : (localSettings['ifscCode']?.toString().trim().isNotEmpty == true
            ? localSettings['ifscCode']!.toString().trim()
            : (_findField(bankSection, 'f_bnk_ifsc')?.defaultValue.trim().isNotEmpty == true
                ? _findField(bankSection, 'f_bnk_ifsc')!.defaultValue.trim()
                : 'HDFC0001234'));
    final bankUpi = (profile['upiId']?.toString().trim().isNotEmpty == true)
        ? profile['upiId']!.toString().trim()
        : (localSettings['upiId']?.toString().trim().isNotEmpty == true
            ? localSettings['upiId']!.toString().trim()
            : (_findField(bankSection, 'f_bnk_upi')?.defaultValue.trim().isNotEmpty == true
                ? _findField(bankSection, 'f_bnk_upi')!.defaultValue.trim()
                : 'northstar@hdfcbank'));

    // Terms lines
    final termsLines = <String>[];
    if (invoice.terms.trim().isNotEmpty) {
      termsLines.addAll(
        invoice.terms
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty),
      );
    }
    if (invoice.notes.trim().isNotEmpty) {
      termsLines.addAll(
        invoice.notes
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty),
      );
    }
    if (termsLines.isEmpty) {
      final defaultTrm = _findField(termsSection, 'f_trm_lines')?.defaultValue.trim() ?? '';
      if (defaultTrm.isNotEmpty) {
        termsLines.addAll(
          defaultTrm.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty),
        );
      } else {
        termsLines.addAll(const [
          '1. Payment due within 15 days from the date of invoice.',
          '2. Late payment attracts 18% annual interest.',
          '3. Security personnel are deployed as per the agreed schedule.',
          '4. Any dispute must be reported within 7 days of service completion.',
        ]);
      }
    }

    final letterheadConfig = CompanyLetterheadConfig.fromSettings(
      localSettings: localSettings,
      profile: profile,
      fallbackCompanyName: companyLegalName,
      fallbackAddress: companyAddress.replaceAll('\n', ', '),
      fallbackPhone: companyPhone,
      fallbackEmail: companyEmail,
      fallbackGstin: companyGstin,
      fallbackPan: companyPan,
      fallbackLogoBase64: logoBase64,
    );

    return Container(
      width: a4PaperWidth,
      constraints: const BoxConstraints(minHeight: a4PaperMinHeight),
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
      padding: _pagePadding,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A. Header (Company Letterhead Banner or Classic Business Branding)
              if (brandingSection.enabled) ...[
                if (letterheadConfig.isLetterheadActive)
                  CompanyLetterheadWidgets.buildHeaderBanner(
                    config: letterheadConfig,
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
                      // Left: Logo & Brand Name
                      Expanded(
                        flex: 6,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isFieldVisible(brandingSection, 'f_biz_logo')) ...[
                              Container(
                                width: 46 * _fontScale,
                                height: 52 * _fontScale,
                                decoration: BoxDecoration(
                                  color: (logoBase64 != null && logoBase64.isNotEmpty)
                                      ? Colors.transparent
                                      : _primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: (logoBase64 != null && logoBase64.isNotEmpty)
                                      ? _safeBase64Image(
                                          logoBase64,
                                          width: 46 * _fontScale,
                                          height: 52 * _fontScale,
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isFieldVisible(brandingSection, 'f_biz_name'))
                                    Text(
                                      _uppercaseHeadings
                                          ? brandHeadline.toUpperCase()
                                          : brandHeadline,
                                      style: _docStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  if (brandSubtitle.isNotEmpty)
                                    Text(
                                      _uppercaseHeadings
                                          ? brandSubtitle.toUpperCase()
                                          : brandSubtitle,
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
                                      companyTagline,
                                      style: _docStyle(
                                        fontSize: 9.5,
                                        color: const Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right: Company Metadata
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_isFieldVisible(brandingSection, 'f_biz_name'))
                              Text(
                                companyLegalName,
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            const SizedBox(height: 1),
                            if (_isFieldVisible(brandingSection, 'f_biz_addr'))
                              for (final line in companyAddress.split('\n'))
                                if (line.trim().isNotEmpty)
                                  Text(
                                    line.trim(),
                                    textAlign: TextAlign.right,
                                    style: _docStyle(
                                      fontSize: 9.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                            if (_isFieldVisible(brandingSection, 'f_biz_gstin') &&
                                companyGstin.isNotEmpty)
                              Text(
                                'GSTIN: $companyGstin',
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            if (_isFieldVisible(brandingSection, 'f_biz_pan') &&
                                companyPan.isNotEmpty)
                              Text(
                                'PAN: $companyPan',
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            const SizedBox(height: 2),
                            if (companyPhone.isNotEmpty)
                              Text(
                                '📞 $companyPhone',
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            if (companyEmail.isNotEmpty)
                              Text(
                                '✉ $companyEmail',
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            for (final cf in _customVisibleFields(
                              brandingSection,
                              const {
                                'f_biz_logo',
                                'f_biz_name',
                                'f_biz_tagline',
                                'f_biz_addr',
                                'f_biz_gstin',
                                'f_biz_pan',
                              },
                            ))
                              Text(
                                '${cf.label}: ${cf.defaultValue.isNotEmpty ? cf.defaultValue : '—'}',
                                textAlign: TextAlign.right,
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: _primaryColor, thickness: 1.5),
                  const SizedBox(height: 16),
                ],
              ],

              // B & C. Identity, Document Details & Client Sections by Selected Layout Structure
              _buildIdentityAndClientByLayout(
                identitySection: identitySection,
                clientSection: clientSection,
                servicesSection: servicesSection,
                clientDisplayName: clientDisplayName,
                clientContactPerson: clientContactPerson,
                clientAddr: clientAddr,
                clientGstin: clientGstin,
                clientPhone: clientPhone,
                serviceLocation: serviceLocation,
                billingPeriod: billingPeriod,
                companyLegalName: companyLegalName,
                companyAddress: companyAddress,
                companyGstin: companyGstin,
                companyPan: companyPan,
              ),

              // D. Duty & Line Items Table
              if (servicesSection.enabled) ...[
                _buildDynamicLineItemsTable(servicesSection),
                const SizedBox(height: 16),
              ],

              // E. Financial Summary & Totals Box
              if (taxTotalsSection.enabled) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Amount in Words
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uppercaseHeadings
                                  ? 'AMOUNT IN WORDS'
                                  : 'Amount in Words',
                              style: _docStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AmountToWords.convert(
                                invoice.total,
                                currency: invoice.currencyCode,
                              ),
                              style: _docStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right: Summary Rows & Grand Total Box
                    SizedBox(
                      width: 270,
                      child: Column(
                        children: [
                          if (_isFieldVisible(taxTotalsSection, 'f_tot_sub'))
                            _buildSummaryRow(
                              'Subtotal',
                              _formatAmount(invoice.subtotal),
                            ),
                          if (_isFieldVisible(taxTotalsSection, 'f_tot_disc') &&
                              (invoice.totalDiscount > 0 ||
                                  _isFieldVisible(taxTotalsSection, 'f_tot_disc')))
                            _buildSummaryRow(
                              'Discount',
                              '(-) ${_formatAmount(invoice.totalDiscount)}',
                            ),
                          if (_isFieldVisible(taxTotalsSection, 'f_tot_taxable'))
                            _buildSummaryRow(
                              'Taxable Amount',
                              _formatAmount(invoice.taxableAmount),
                              isBold: true,
                            ),
                          if (invoice.isRcm) ...[
                            _buildSummaryRow(
                              'Reverse Charge (RCM)',
                              'Tax Payable by Recipient',
                              isBold: true,
                            ),
                          ] else if (invoice.taxRate > 0) ...[
                            if (!gstBreakdown.isInterState) ...[
                              if (_isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                                _buildSummaryRow(
                                  'CGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%)',
                                  _formatAmount(invoice.taxAmount / 2),
                                ),
                              if (_isFieldVisible(taxTotalsSection, 'f_tot_sgst'))
                                _buildSummaryRow(
                                  'SGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%)',
                                  _formatAmount(invoice.taxAmount / 2),
                                ),
                            ] else ...[
                              if (_isFieldVisible(taxTotalsSection, 'f_tot_igst', fallback: true) ||
                                  _isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                                _buildSummaryRow(
                                  'IGST (${invoice.taxRate.toStringAsFixed(invoice.taxRate % 1 == 0 ? 0 : 1)}%)',
                                  _formatAmount(invoice.taxAmount),
                                ),
                            ],
                          ],
                          if (invoice.shippingFee > 0)
                            _buildSummaryRow(
                              'Shipping & Handling',
                              _formatAmount(invoice.shippingFee),
                            ),
                          if (invoice.additionalCharges > 0)
                            _buildSummaryRow(
                              'Additional Charges',
                              _formatAmount(invoice.additionalCharges),
                            ),
                          if (invoice.roundOff != 0)
                            _buildSummaryRow(
                              'Round Off',
                              _formatAmount(invoice.roundOff),
                            ),
                          if (_isFieldVisible(taxTotalsSection, 'f_tot_grand')) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _uppercaseHeadings
                                        ? 'GRAND TOTAL'
                                        : 'Grand Total',
                                    style: _docStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _formatAmount(invoice.total),
                                      textAlign: TextAlign.right,
                                      style: _docStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (invoice.amountPaid > 0) ...[
                            const SizedBox(height: 4),
                            _buildSummaryRow(
                              'Amount Paid',
                              '(-) ${_formatAmount(invoice.amountPaid)}',
                            ),
                            _buildSummaryRow(
                              'Balance Due',
                              _formatAmount(invoice.balanceDue),
                              isBold: true,
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
                              _uppercaseHeadings
                                  ? 'PAYMENT DETAILS'
                                  : 'Payment Details',
                              style: _docStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_isFieldVisible(bankSection, 'f_bnk_name'))
                              Text(
                                'Bank Name : $bankName',
                                style: _docStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            if (_isFieldVisible(bankSection, 'f_bnk_ac'))
                              Text(
                                'A/C No.      : $bankAccount',
                                style: _docStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            if (_isFieldVisible(bankSection, 'f_bnk_ifsc'))
                              Text(
                                'IFSC           : $bankIfsc',
                                style: _docStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            if (_isFieldVisible(bankSection, 'f_bnk_upi'))
                              Text(
                                'UPI             : $bankUpi',
                                style: _docStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            if (invoice.paymentInstructions.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                invoice.paymentInstructions.trim(),
                                style: _docStyle(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
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
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 48 * _fontScale,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Scan to Pay',
                              style: _docStyle(
                                fontSize: 8.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
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
                            _uppercaseHeadings
                                ? 'TERMS & CONDITIONS'
                                : 'Terms & Conditions',
                            style: _docStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_isFieldVisible(termsSection, 'f_trm_lines'))
                            for (int i = 0; i < termsLines.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1.5),
                                child: Text(
                                  RegExp(r'^\d+\.').hasMatch(termsLines[i])
                                      ? termsLines[i]
                                      : '${i + 1}. ${termsLines[i]}',
                                  style: _docStyle(
                                    fontSize: 8.5,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
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
                            Text(
                              'For $companyLegalName',
                              textAlign: TextAlign.right,
                              style: _docStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Render Signature and Stamp (with tap-to-sign support)
                          InkWell(
                            onTap: onSignTap,
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (stampBase64 != null && stampBase64.isNotEmpty)
                                  Container(
                                    width: 38 * _fontScale,
                                    height: 38 * _fontScale,
                                    margin: const EdgeInsets.only(right: 6),
                                    child: _safeBase64Image(
                                      stampBase64,
                                      width: 38 * _fontScale,
                                      height: 38 * _fontScale,
                                    ),
                                  ),
                                if (signatureBase64 != null &&
                                    signatureBase64.isNotEmpty)
                                  Container(
                                    height: 34 * _fontScale,
                                    constraints: const BoxConstraints(maxWidth: 120),
                                    child: _safeBase64Image(
                                      signatureBase64,
                                      height: 34 * _fontScale,
                                    ),
                                  )
                                else if (onSignTap != null)
                                  Container(
                                    height: 28 * _fontScale,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.draw_rounded,
                                          size: 11 * _fontScale,
                                          color: _primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to Sign',
                                          style: _docStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  SizedBox(height: 26 * _fontScale),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 110,
                            height: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 3),
                          if (_isFieldVisible(termsSection, 'f_trm_title'))
                            Text(
                              signeeTitle,
                              textAlign: TextAlign.right,
                              style: _docStyle(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          if (_isFieldVisible(termsSection, 'f_trm_auto_stamp'))
                            Text(
                              '(This is a system generated invoice)',
                              textAlign: TextAlign.right,
                              style: _docStyle(
                                fontSize: 7.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // H. Custom Sections added by user in Template Studio
              for (final customSec in sections.where(
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
                if (customSec.enabled &&
                    customSec.fields.any((f) => f.isVisible)) ...[
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
                          _uppercaseHeadings
                              ? customSec.title.toUpperCase()
                              : customSec.title,
                          style: _docStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (customSec.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            customSec.subtitle,
                            style: _docStyle(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: customSec.fields
                              .where((f) => f.isVisible)
                              .map((f) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${f.label}: ',
                                  style: _docStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  f.defaultValue.isNotEmpty
                                      ? f.defaultValue
                                      : '—',
                                  style: _docStyle(
                                    fontSize: 9.5,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

              // I. Document Footer (Company Letterhead Footer or Classic Footer)
              if (letterheadConfig.isLetterheadActive)
                CompanyLetterheadWidgets.buildFooterBanner(
                  config: letterheadConfig,
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
                    Text(
                      'Thank you for your business!',
                      style: _docStyle(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'Page 1 of 1',
                      style: _docStyle(
                        fontSize: 8.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLineItemsTable(StudioSection section) {
    final isBoxed = _tableBorderStyle == 'boxed';
    final isStriped = _tableBorderStyle == 'striped';

    final String defaultCol0;
    final String defaultCol1;
    final String defaultCol2;
    final String defaultCol3;
    final String defaultCol4;

    if (_activePreset == 'gst_service') {
      defaultCol0 = 'Service Description & Scope';
      defaultCol1 = 'SAC Code';
      defaultCol2 = 'Qty / Hrs';
      defaultCol3 = 'Rate ($_currencySymbol)';
      defaultCol4 = 'Amount ($_currencySymbol)';
    } else if (_activePreset == 'consulting') {
      defaultCol0 = 'Scope & Deliverables';
      defaultCol1 = 'Lead Consultant';
      defaultCol2 = 'Hours / Days';
      defaultCol3 = 'Rate ($_currencySymbol)';
      defaultCol4 = 'Amount ($_currencySymbol)';
    } else if (_activePreset == 'retail') {
      defaultCol0 = 'Item Description';
      defaultCol1 = 'SKU / HSN';
      defaultCol2 = 'Qty';
      defaultCol3 = 'MRP ($_currencySymbol)';
      defaultCol4 = 'Net Total ($_currencySymbol)';
    } else {
      defaultCol0 = 'Particulars';
      defaultCol1 = 'Guards';
      defaultCol2 = 'Duty Days';
      defaultCol3 = 'Rate ($_currencySymbol)';
      defaultCol4 = 'Amount ($_currencySymbol)';
    }

    final allColumns = <({String fieldId, String label, int flex, TextAlign align})>[
      (
        fieldId: 'f_col_particulars',
        label: _columnLabel(section, 'f_col_particulars', defaultCol0),
        flex: 5,
        align: TextAlign.left,
      ),
      (
        fieldId: 'f_col_guards',
        label: _columnLabel(section, 'f_col_guards', defaultCol1),
        flex: 2,
        align: TextAlign.center,
      ),
      (
        fieldId: 'f_col_duty',
        label: _columnLabel(section, 'f_col_duty', defaultCol2),
        flex: 2,
        align: TextAlign.center,
      ),
      (
        fieldId: 'f_col_rate',
        label: _columnLabel(section, 'f_col_rate', defaultCol3),
        flex: 3,
        align: TextAlign.right,
      ),
      (
        fieldId: 'f_col_amount',
        label: _columnLabel(section, 'f_col_amount', defaultCol4),
        flex: 3,
        align: TextAlign.right,
      ),
    ];

    final allRows = <List<String>>[];
    if (invoice.items.isNotEmpty) {
      for (final item in invoice.items) {
        final desc = item.itemDetails.trim().isNotEmpty
            ? '${item.description}\n${item.itemDetails.trim()}'
            : item.description;
        final qtyStr = item.quantity % 1 == 0
            ? item.quantity.toInt().toString()
            : item.quantity.toStringAsFixed(2);
        final dutyStr = item.dutyCount > 0
            ? (item.dutyCount % 1 == 0
                ? item.dutyCount.toInt().toString()
                : item.dutyCount.toStringAsFixed(1))
            : (item.standardDutyDays > 0
                ? item.standardDutyDays.toInt().toString()
                : '26');
        final rateStr = _formatNumber(item.unitPrice);
        final amtStr = _formatNumber(item.total);
        allRows.add([desc, qtyStr, dutyStr, rateStr, amtStr]);
      }
    } else {
      allRows.add([
        'Security Guard (12-hour shift)',
        '4',
        '26',
        '2,150.00',
        '2,23,600.00',
      ]);
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: isBoxed && c < columns.length - 1
                            ? const Border(
                                right: BorderSide(
                                  color: Color(0x33FFFFFF),
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        _uppercaseHeadings
                            ? columns[c].label.toUpperCase()
                            : columns[c].label,
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
              color: isStriped && r.isOdd
                  ? const Color(0xFFF8FAFC)
                  : Colors.white,
              decoration: isBoxed && r < rows.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    )
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < rows[r].length; c++)
                    Expanded(
                      flex: columns[c].flex,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          border: isBoxed && c < rows[r].length - 1
                              ? const Border(
                                  right: BorderSide(color: Color(0xFFCBD5E1)),
                                )
                              : null,
                        ),
                        child: Text(
                          rows[r][c],
                          textAlign: columns[c].align,
                          style: _docStyle(
                            fontSize: 10,
                            fontWeight: c == 0
                                ? FontWeight.w600
                                : (c == rows[r].length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                            color: c == rows[r].length - 1
                                ? const Color(0xFF0F172A)
                                : (c == 0
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF475569)),
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

  Widget _buildIdentityAndClientByLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientContactPerson,
    required String clientAddr,
    required String clientGstin,
    required String clientPhone,
    required String serviceLocation,
    required String billingPeriod,
    required String companyLegalName,
    required String companyAddress,
    required String companyGstin,
    required String companyPan,
  }) {
    switch (_layoutStyle) {
      case 'executive_banner':
        return _buildExecutiveBannerLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientContactPerson: clientContactPerson,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          clientPhone: clientPhone,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
        );
      case 'compact_grid':
        return _buildCompactGridLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
          companyLegalName: companyLegalName,
          companyAddress: companyAddress,
          companyGstin: companyGstin,
          companyPan: companyPan,
        );
      case 'minimal_asymmetric':
        return _buildMinimalAsymmetricLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
        );
      case 'sidebar_accent':
        return _buildSidebarAccentLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
        );
      case 'classic_bordered':
        return _buildClassicBorderedLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
        );
      case 'modern_split':
      default:
        return _buildModernSplitLayout(
          identitySection: identitySection,
          clientSection: clientSection,
          servicesSection: servicesSection,
          clientDisplayName: clientDisplayName,
          clientContactPerson: clientContactPerson,
          clientAddr: clientAddr,
          clientGstin: clientGstin,
          clientPhone: clientPhone,
          serviceLocation: serviceLocation,
          billingPeriod: billingPeriod,
        );
    }
  }

  Widget _buildModernSplitLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientContactPerson,
    required String clientAddr,
    required String clientGstin,
    required String clientPhone,
    required String serviceLocation,
    required String billingPeriod,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identitySection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _uppercaseHeadings
                      ? _documentTitle.toUpperCase()
                      : _documentTitle,
                  style: _docStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  if (_isFieldVisible(identitySection, 'f_doc_number'))
                    _metaRow(
                      'Invoice No.',
                      invoice.invoiceNumber.isNotEmpty
                          ? invoice.invoiceNumber
                          : 'INV-2025-0148',
                    ),
                  if (_isFieldVisible(identitySection, 'f_doc_issue'))
                    _metaRow(
                      'Issue Date',
                      invoice.issueDate.isNotEmpty
                          ? invoice.issueDate
                          : '15 Apr 2025',
                    ),
                  if (_isFieldVisible(identitySection, 'f_doc_due'))
                    _metaRow(
                      'Due Date',
                      invoice.dueDate.isNotEmpty
                          ? invoice.dueDate
                          : '30 Apr 2025',
                    ),
                  if (_isFieldVisible(identitySection, 'f_doc_po'))
                    _metaRow(
                      'PO No.',
                      invoice.poNumber.trim().isNotEmpty
                          ? invoice.poNumber.trim()
                          : (_findField(identitySection, 'f_doc_po')
                                      ?.defaultValue
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? _findField(identitySection, 'f_doc_po')!
                                  .defaultValue
                                  .trim()
                              : 'PO-4587/2025'),
                    ),
                  for (final cf in _customVisibleFields(
                    identitySection,
                    const {
                      'f_doc_number',
                      'f_doc_issue',
                      'f_doc_due',
                      'f_doc_po',
                    },
                  ))
                    _metaRow(
                      cf.label,
                      cf.defaultValue.isNotEmpty ? cf.defaultValue : '—',
                    ),
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
                        style: _docStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isFieldVisible(clientSection, 'f_cli_name'))
                        Text(
                          clientDisplayName,
                          style: _docStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_addr'))
                        for (final line in clientAddr.split('\n'))
                          if (line.trim().isNotEmpty)
                            Text(
                              line.trim(),
                              style: _docStyle(
                                fontSize: 10,
                                color: const Color(0xFF475569),
                              ),
                            ),
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_gstin') &&
                          clientGstin.isNotEmpty)
                        Text(
                          'GSTIN: $clientGstin',
                          style: _docStyle(
                            fontSize: 10,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      if (_isFieldVisible(clientSection, 'f_cli_contact') &&
                          clientContactPerson.isNotEmpty)
                        Text(
                          'Contact: $clientContactPerson',
                          style: _docStyle(
                            fontSize: 10,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      if (_isFieldVisible(clientSection, 'f_cli_phone') &&
                          clientPhone.isNotEmpty)
                        Text(
                          'Phone: $clientPhone',
                          style: _docStyle(
                            fontSize: 10,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      for (final cf in _customVisibleFields(
                        clientSection,
                        const {
                          'f_cli_name',
                          'f_cli_addr',
                          'f_cli_gstin',
                          'f_cli_contact',
                          'f_cli_phone',
                        },
                      ))
                        Text(
                          '${cf.label}: ${cf.defaultValue.isNotEmpty ? cf.defaultValue : '—'}',
                          style: _docStyle(
                            fontSize: 10,
                            color: const Color(0xFF475569),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isFieldVisible(servicesSection, 'f_srv_loc') ||
                  _isFieldVisible(servicesSection, 'f_srv_period')) ...[
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
                        if (_isFieldVisible(servicesSection, 'f_srv_loc')) ...[
                          Text(
                            _uppercaseHeadings
                                ? 'SERVICE LOCATION'
                                : 'Service Location',
                            style: _docStyle(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...() {
                            final locLines = serviceLocation
                                .split('\n')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            return [
                              if (locLines.isNotEmpty)
                                Text(
                                  locLines.first,
                                  style: _docStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              for (final sub in locLines.skip(1))
                                Text(
                                  sub,
                                  style: _docStyle(
                                    fontSize: 10,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                            ];
                          }(),
                          if (_isFieldVisible(servicesSection, 'f_srv_period'))
                            const SizedBox(height: 8),
                        ],
                        if (_isFieldVisible(servicesSection, 'f_srv_period')) ...[
                          Text(
                            _uppercaseHeadings
                                ? 'BILLING PERIOD'
                                : 'Billing Period',
                            style: _docStyle(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            billingPeriod,
                            style: _docStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '(${invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Monthly Billing'})',
                            style: _docStyle(
                              fontSize: 9.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
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

  Widget _buildExecutiveBannerLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientContactPerson,
    required String clientAddr,
    required String clientGstin,
    required String clientPhone,
    required String serviceLocation,
    required String billingPeriod,
  }) {
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
    final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
    final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';
    final poNum = invoice.poNumber.trim().isNotEmpty ? invoice.poNumber.trim() : 'PO-4587/2025';

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
                    _heroPill(Icons.tag_rounded, 'Inv: $invNum'),
                    _heroPill(Icons.calendar_today_rounded, 'Issued: $issueDate'),
                    _heroPill(Icons.event_available_rounded, 'Due: $dueDate'),
                    _heroPill(Icons.receipt_long_rounded, 'PO Ref: $poNum'),
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
                            Text(clientDisplayName, style: _docStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            for (final line in clientAddr.split('\n'))
                              if (line.trim().isNotEmpty)
                                Text(line.trim(), style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                            if (clientGstin.isNotEmpty)
                              Text('GSTIN: $clientGstin', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                            if (clientPhone.isNotEmpty)
                              Text('Phone: $clientPhone', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
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
                            for (final line in serviceLocation.split('\n'))
                              if (line.trim().isNotEmpty)
                                Text(line.trim(), style: _docStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('Billing Period: $billingPeriod', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                            Text('Terms: ${invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Standard Net 15'}', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
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

  Widget _buildCompactGridLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientAddr,
    required String clientGstin,
    required String serviceLocation,
    required String billingPeriod,
    required String companyLegalName,
    required String companyAddress,
    required String companyGstin,
    required String companyPan,
  }) {
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
    final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
    final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';
    final poNum = invoice.poNumber.trim().isNotEmpty ? invoice.poNumber.trim() : 'PO-4587/2025';

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
                          Text(companyLegalName, style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          for (final line in companyAddress.split('\n'))
                            if (line.trim().isNotEmpty)
                              Text(line.trim(), style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          Text('GSTIN: $companyGstin · PAN: $companyPan', style: _docStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
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
                          _ledgerRow('Invoice No.', invNum),
                          _ledgerRow('Date', issueDate),
                          _ledgerRow('Due Date', dueDate),
                          _ledgerRow('PO Ref', poNum),
                          _ledgerRow('Terms', invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Net 15 Days'),
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
                          Text(clientDisplayName, style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          for (final line in clientAddr.split('\n'))
                            if (line.trim().isNotEmpty)
                              Text(line.trim(), style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                          if (clientGstin.isNotEmpty)
                            Text('GSTIN: $clientGstin', style: _docStyle(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
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
                          for (final line in serviceLocation.split('\n'))
                            if (line.trim().isNotEmpty)
                              Text(line.trim(), style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('Period: $billingPeriod', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
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

  Widget _buildMinimalAsymmetricLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientAddr,
    required String clientGstin,
    required String serviceLocation,
    required String billingPeriod,
  }) {
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
    final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
    final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';
    final poNum = invoice.poNumber.trim().isNotEmpty ? invoice.poNumber.trim() : 'PO-4587/2025';

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
              '//  $invNum',
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
              child: Text('ISSUED: ${issueDate.toUpperCase()}', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
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
                  Text(clientDisplayName, style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  for (final line in clientAddr.split('\n'))
                    if (line.trim().isNotEmpty)
                      Text(line.trim(), style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
                  if (clientGstin.isNotEmpty)
                    Text('GST: $clientGstin', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
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
                  for (final line in serviceLocation.split('\n'))
                    if (line.trim().isNotEmpty)
                      Text(line.trim(), style: _docStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  Text('Period: $billingPeriod', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
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
                  Text(invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Net 15 Days', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  Text('Due: $dueDate\nPO: $poNum', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSidebarAccentLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientAddr,
    required String clientGstin,
    required String serviceLocation,
    required String billingPeriod,
  }) {
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
    final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
    final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';
    final poNum = invoice.poNumber.trim().isNotEmpty ? invoice.poNumber.trim() : 'PO-4587/2025';

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
                _heroPill(Icons.confirmation_number_outlined, invNum),
                const SizedBox(width: 6),
                _heroPill(Icons.event_outlined, issueDate),
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
                    Text(clientDisplayName, style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    for (final line in clientAddr.split('\n'))
                      if (line.trim().isNotEmpty)
                        Text(line.trim(), style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                    if (clientGstin.isNotEmpty)
                      Text('GSTIN: $clientGstin', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
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
                    for (final line in serviceLocation.split('\n'))
                      if (line.trim().isNotEmpty)
                        Text(line.trim(), style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text('Period: $billingPeriod', style: _docStyle(fontSize: 9.5, color: const Color(0xFF475569))),
                    Text('PO: $poNum · Due: $dueDate', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
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

  Widget _buildClassicBorderedLayout({
    required StudioSection identitySection,
    required StudioSection clientSection,
    required StudioSection servicesSection,
    required String clientDisplayName,
    required String clientAddr,
    required String clientGstin,
    required String serviceLocation,
    required String billingPeriod,
  }) {
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
    final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
    final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';

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
                    Text(clientDisplayName, style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    for (final line in clientAddr.split('\n'))
                      if (line.trim().isNotEmpty)
                        Text(line.trim(), style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                    if (clientGstin.isNotEmpty)
                      Text('GSTIN: $clientGstin', style: _docStyle(fontSize: 9, color: const Color(0xFF475569))),
                  ],
                ),
              ),
              Container(width: 1, height: 56, color: const Color(0xFFCBD5E1), margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ledgerRow('Invoice No.', invNum),
                    _ledgerRow('Dated', issueDate),
                    _ledgerRow('Payment Due', dueDate),
                    _ledgerRow('Site / Place', serviceLocation.split('\n').first),
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

  TableRow _metaRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(
            label,
            style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(
            ':',
            style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(
            value,
            style: _docStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
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
          Flexible(
            child: Text(
              label,
              style: _docStyle(
                fontSize: 10,
                color: const Color(0xFF64748B),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: _docStyle(
              fontSize: 10,
              color: const Color(0xFF1E293B),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safeBase64Image(
    String encoded, {
    double? width,
    double? height,
  }) {
    try {
      return Image.memory(
        base64Decode(encoded),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
