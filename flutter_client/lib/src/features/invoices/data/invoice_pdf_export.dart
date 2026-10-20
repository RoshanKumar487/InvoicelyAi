import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/amount_to_words.dart';
import '../../../core/utils/gst_tax_calculator.dart';
import '../../templates/data/company_letterhead.dart';
import '../../templates/data/studio_section_model.dart';
import '../../templates/data/template_config.dart';
import 'invoice.dart';

class InvoicePdfExport {
  InvoicePdfExport._();

  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2B50}-\u{2B55}\u{200D}\u{FE0F}]',
    unicode: true,
  );

  static String _cleanText(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input.replaceAll(_emojiRegex, '');
    text = text
        .replaceAll('₹', 'Rs. ')
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
    return text.replaceAll(RegExp(r'Rs\.\s+Rs\.'), 'Rs.').trim();
  }

  static PdfColor _parsePdfColor(String? hex, PdfColor fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final clean = hex.trim().replaceFirst('#', '');
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed == null) return fallback;
    return PdfColor.fromInt(0xFF000000 | parsed);
  }

  static PdfColor _tintColor(PdfColor base, double opacity) {
    final r = base.red + (1.0 - base.red) * (1.0 - opacity);
    final g = base.green + (1.0 - base.green) * (1.0 - opacity);
    final b = base.blue + (1.0 - base.blue) * (1.0 - opacity);
    return PdfColor(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0));
  }

  static pw.MemoryImage? _memoryImage(Object? raw) {
    final encoded = raw?.toString().trim() ?? '';
    if (encoded.isEmpty) return null;
    try {
      final clean = encoded.contains(',') ? encoded.split(',').last : encoded;
      final bytes = base64Decode(clean);
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _formatNumber(double val) {
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

  static Future<Uint8List> build(
    Invoice invoice, {
    TemplateConfig? template,
    Map<String, Object?> localSettings = const <String, Object?>{},
    Map<String, dynamic> businessProfile = const <String, dynamic>{},
  }) async {
    // 1. Resolve Studio Preset, Sections & Style Settings
    final presetStr = localSettings['studio_preset']?.toString().trim();
    final activePreset = (presetStr != null && presetStr.isNotEmpty)
        ? presetStr
        : () {
            final cat = (template?.category ?? '').toLowerCase();
            final id = (template?.id ?? '').toLowerCase();
            if (id.contains('creative') || cat.contains('creative')) return 'creative_vibrant';
            if (id.contains('construction') || cat.contains('construction')) return 'construction_contractor';
            if (id.contains('healthcare') || cat.contains('healthcare')) return 'healthcare_clinic';
            if (id.contains('logistics') || cat.contains('logistics')) return 'logistics_freight';
            if (id.contains('legal') || cat.contains('legal')) return 'legal_counsel';
            if (id.contains('hospitality') || cat.contains('hospitality')) return 'hospitality_catering';
            if (cat.contains('gst')) return 'gst_service';
            if (cat.contains('consult')) return 'consulting';
            if (cat.contains('retail')) return 'retail';
            return 'security_agency';
          }();

    List<StudioSection> sections =
        StudioSection.defaultSections(preset: activePreset);
    final rawSections = localSettings['studio_sections_json']?.toString().trim();
    if (rawSections != null && rawSections.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSections);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => StudioSection.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (parsed.isNotEmpty) {
            sections = parsed;
          }
        }
      } catch (_) {}
    }

    StudioSection findSection(String id) {
      return sections.firstWhere(
        (s) => s.id == id,
        orElse: () => StudioSection(
          id: id,
          title: id,
          subtitle: '',
          icon: StudioFieldType.text.icon,
          enabled: true,
        ),
      );
    }

    bool isFieldVisible(StudioSection section, String fieldId,
        {bool fallback = true}) {
      final idx = section.fields.indexWhere((f) => f.id == fieldId);
      if (idx == -1) return fallback;
      return section.fields[idx].isVisible;
    }

    StudioField? findField(StudioSection section, String fieldId) {
      final idx = section.fields.indexWhere((f) => f.id == fieldId);
      if (idx == -1) return null;
      return section.fields[idx];
    }

    String columnLabel(StudioSection section, String fieldId, String fallback) {
      final fld = findField(section, fieldId);
      if (fld == null || fld.label.trim().isEmpty) return fallback;
      return _cleanText(
        fld.label.replaceFirst(RegExp(r'\s*Column$', caseSensitive: false), ''),
      );
    }

    List<StudioField> customVisibleFields(
      StudioSection section,
      Set<String> builtInIds,
    ) {
      return section.fields
          .where((f) => f.isVisible && !builtInIds.contains(f.id))
          .toList();
    }

    final brandingSection = findSection('sec_branding');
    final identitySection = findSection('sec_identity');
    final clientSection = findSection('sec_client');
    final servicesSection = findSection('sec_services');
    final taxTotalsSection = findSection('sec_tax_totals');
    final bankSection = findSection('sec_bank');
    final termsSection = findSection('sec_terms');

    // Colors & Typography
    final primaryHex = localSettings['studio_primary_color']?.toString().trim();
    final primaryColor = _parsePdfColor(
      (primaryHex != null && primaryHex.isNotEmpty)
          ? primaryHex
          : template?.color,
      PdfColor.fromInt(0xFF1E3A8A),
    );
    final headerTextHex =
        localSettings['studio_table_header_text_color']?.toString().trim();
    final tableHeaderTextColor = _parsePdfColor(
      headerTextHex,
      PdfColors.white,
    );

    final fontScale = () {
      final s = localSettings['studio_font_scale']?.toString().trim();
      if (s != null && s.isNotEmpty) {
        final parsed = double.tryParse(s);
        if (parsed != null && parsed > 0) return parsed.clamp(0.75, 1.35);
      }
      return 1.0;
    }();

    final uppercaseHeadings = () {
      final u = localSettings['studio_uppercase_headings'];
      if (u is bool) return u;
      if (u is String) return u.toLowerCase() == 'true';
      return true;
    }();

    final tableBorderStyle =
        localSettings['studio_table_border']?.toString().trim() ?? 'boxed';
    final isBoxed = tableBorderStyle == 'boxed';
    final isStriped = tableBorderStyle == 'striped';

    final watermark =
        localSettings['studio_watermark']?.toString().trim() ?? 'None';

    final marginStr =
        localSettings['studio_page_margin']?.toString().trim() ??
            'Standard (16mm)';
    final pageMarginPt = switch (marginStr) {
      'Compact (10mm)' => 22.0,
      'Spacious (24mm)' => 44.0,
      _ => 32.0,
    };

    final showQrCode = () {
      final q = localSettings['showQrCode'];
      if (q is bool) return q;
      if (q is String) return q.toLowerCase() == 'true';
      return true;
    }();

    final documentTitle = () {
      final custom = localSettings['customTitle']?.toString().trim();
      if (custom != null && custom.isNotEmpty) return _cleanText(custom);
      final tplTitle = template?.title.trim();
      if (tplTitle != null && tplTitle.isNotEmpty && !tplTitle.contains('—')) {
        return _cleanText(tplTitle);
      }
      return 'TAX INVOICE';
    }();

    final layoutStyle = () {
      final s = localSettings['studio_layout_style']?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
      final tplLayout = template?.layoutStyle.trim();
      if (tplLayout != null && tplLayout.isNotEmpty) return tplLayout;
      return 'modern_split';
    }();

    // Font family selection
    final fontFamilyStr =
        (localSettings['studio_font_family']?.toString() ??
                template?.font ??
                'Inter')
            .toLowerCase();
    late final pw.Font baseFont;
    late final pw.Font boldFont;
    late final pw.Font italicFont;
    late final pw.Font boldItalicFont;
    if (fontFamilyStr.contains('merriweather') ||
        fontFamilyStr.contains('times')) {
      baseFont = pw.Font.times();
      boldFont = pw.Font.timesBold();
      italicFont = pw.Font.timesItalic();
      boldItalicFont = pw.Font.timesBoldItalic();
    } else if (fontFamilyStr.contains('courier') ||
        fontFamilyStr.contains('consolas')) {
      baseFont = pw.Font.courier();
      boldFont = pw.Font.courierBold();
      italicFont = pw.Font.courierOblique();
      boldItalicFont = pw.Font.courierBoldOblique();
    } else {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
      boldItalicFont = pw.Font.helveticaBoldOblique();
    }

    pw.TextStyle docStyle({
      double fontSize = 9.5,
      bool bold = false,
      bool italic = false,
      PdfColor color = const PdfColor.fromInt(0xFF1E293B),
      double? letterSpacing,
    }) {
      final font = bold && italic
          ? boldItalicFont
          : (bold ? boldFont : (italic ? italicFont : baseFont));
      return pw.TextStyle(
        font: font,
        fontSize: fontSize * fontScale,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    // Currency symbol (Latin-1 safe for built-in PDF fonts)
    final rawCurrency =
        localSettings['defaultCurrencySymbol']?.toString().trim().isNotEmpty ==
                true
            ? localSettings['defaultCurrencySymbol'].toString().trim()
            : (localSettings['defaultCurrency']?.toString().trim().isNotEmpty ==
                    true
                ? localSettings['defaultCurrency'].toString().trim()
                : (invoice.currencySymbol.trim().isNotEmpty &&
                        invoice.currencySymbol.trim() != r'$'
                    ? invoice.currencySymbol.trim()
                    : 'INR'));
    final currencySymbol =
        (rawCurrency == '₹' || rawCurrency.toUpperCase() == 'INR')
            ? 'Rs.'
            : _cleanText(rawCurrency);

    String formatAmount(double val) => '$currencySymbol ${_formatNumber(val)}';

    // Business Profile resolution (supports both company* and business* keys)
    String pickSetting(List<String> keys, String fallback) {
      for (final k in keys) {
        final pVal = businessProfile[k]?.toString().trim();
        if (pVal != null && pVal.isNotEmpty) return _cleanText(pVal);
        final lVal = localSettings[k]?.toString().trim();
        if (lVal != null && lVal.isNotEmpty) return _cleanText(lVal);
      }
      return _cleanText(fallback);
    }

    final companyLegalName = pickSetting(
      ['companyName', 'businessName', 'legalName'],
      findField(brandingSection, 'f_biz_name')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(brandingSection, 'f_biz_name')!.defaultValue.trim()
          : 'Northstar Security Services Ltd.',
    );



    final companyAddress = pickSetting(
      ['companyAddress', 'address', 'businessAddress'],
      '#12, 3rd Floor, Green Park, Bengaluru,\nKarnataka - 560076',
    );

    final companyGstin = pickSetting(
      ['taxId', 'gstin', 'companyGstin', 'businessGstin'],
      findField(brandingSection, 'f_biz_gstin')
                  ?.defaultValue
                  .trim()
                  .isNotEmpty ==
              true
          ? findField(brandingSection, 'f_biz_gstin')!.defaultValue.trim()
          : '29ABCDE1234F1Z5',
    );

    final companyPan = pickSetting(
      ['panNumber', 'companyPan', 'businessPan'],
      findField(brandingSection, 'f_biz_pan')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(brandingSection, 'f_biz_pan')!.defaultValue.trim()
          : (companyGstin.length >= 12
              ? companyGstin.substring(2, 12)
              : 'ABCDE1234F'),
    );

    final companyPhone = pickSetting(
      ['companyPhone', 'phone', 'businessPhone'],
      '+91 98765 43210',
    );

    final companyEmail = pickSetting(
      ['companyEmail', 'email', 'businessEmail'],
      'info@northstarsecurity.in',
    );

    // Client details
    final clientDisplayName = _cleanText(
      invoice.clientCompany.trim().isNotEmpty
          ? invoice.clientCompany.trim()
          : (invoice.clientName.trim().isNotEmpty
              ? invoice.clientName.trim()
              : 'ABC Industries Pvt. Ltd.'),
    );
    final clientContactPerson = _cleanText(
      (invoice.clientCompany.trim().isNotEmpty &&
              invoice.clientName.trim().isNotEmpty &&
              invoice.clientName.trim() != invoice.clientCompany.trim())
          ? invoice.clientName.trim()
          : (findField(clientSection, 'f_cli_contact')?.defaultValue.trim() ??
              ''),
    );
    final clientAddr = _cleanText(
      invoice.clientAddress.trim().isNotEmpty
          ? invoice.clientAddress.trim()
          : '101, Business Tower, MG Road,\nBengaluru, Karnataka - 560001',
    );
    final clientGstin = _cleanText(
      invoice.clientTaxId.trim().isNotEmpty
          ? invoice.clientTaxId.trim()
          : '29AABCA1234B1Z2',
    );
    final clientPhone = _cleanText(
      invoice.clientPhone.trim().isNotEmpty
          ? invoice.clientPhone.trim()
          : '+91 98800 11223',
    );

    // Service Location & Billing Period
    Map<String, dynamic> shippingMap = const {};
    if (invoice.shippingDetailsJson.trim().isNotEmpty &&
        invoice.shippingDetailsJson.trim() != '{}') {
      try {
        final decoded = jsonDecode(invoice.shippingDetailsJson);
        if (decoded is Map<String, dynamic>) shippingMap = decoded;
      } catch (_) {}
    }

    final serviceLocation = _cleanText(
      (shippingMap['shippingAddress']?.toString().trim().isNotEmpty == true)
          ? shippingMap['shippingAddress']!.toString().trim()
          : ((shippingMap['deliveryAddress']?.toString().trim().isNotEmpty ==
                  true)
              ? shippingMap['deliveryAddress']!.toString().trim()
              : (findField(servicesSection, 'f_srv_loc')
                          ?.defaultValue
                          .trim()
                          .isNotEmpty ==
                      true
                  ? findField(servicesSection, 'f_srv_loc')!.defaultValue.trim()
                  : (invoice.clientAddress.trim().isNotEmpty
                      ? invoice.clientAddress.trim()
                      : 'Tech Park, Whitefield\nBengaluru, Karnataka - 560066'))),
    );

    final billingPeriod = _cleanText(
      (findField(servicesSection, 'f_srv_period')
                  ?.defaultValue
                  .trim()
                  .isNotEmpty ==
              true)
          ? findField(servicesSection, 'f_srv_period')!.defaultValue.trim()
          : '${invoice.issueDate.isNotEmpty ? invoice.issueDate : '01 Apr 2025'} - ${invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025'}',
    );

    // Tax & Totals
    final gstBreakdown = GstTaxCalculator.calculate(
      taxableAmount: invoice.taxableAmount,
      taxRate: invoice.taxRate,
      taxLabel: invoice.taxLabel,
      taxType: invoice.taxType,
      isRcm: invoice.isRcm,
      supplierPlaceOfSupply: companyAddress,
      clientPlaceOfSupply: invoice.clientAddress,
    );

    // Bank & UPI QR
    final bankName = pickSetting(
      ['bankName'],
      findField(bankSection, 'f_bnk_name')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(bankSection, 'f_bnk_name')!.defaultValue.trim()
          : 'HDFC Bank',
    );
    final bankAccount = pickSetting(
      ['accountNumber'],
      findField(bankSection, 'f_bnk_ac')?.defaultValue.trim().isNotEmpty == true
          ? findField(bankSection, 'f_bnk_ac')!.defaultValue.trim()
          : '50200012345678',
    );
    final bankIfsc = pickSetting(
      ['ifscCode'],
      findField(bankSection, 'f_bnk_ifsc')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(bankSection, 'f_bnk_ifsc')!.defaultValue.trim()
          : 'HDFC0001234',
    );
    final bankUpi = pickSetting(
      ['upiId'],
      findField(bankSection, 'f_bnk_upi')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(bankSection, 'f_bnk_upi')!.defaultValue.trim()
          : 'northstar@hdfcbank',
    );
    final qrPayload =
        'upi://pay?pa=$bankUpi&pn=${Uri.encodeComponent(companyLegalName)}&am=${(invoice.balanceDue > 0 ? invoice.balanceDue : invoice.total).toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Invoice ${invoice.invoiceNumber}")}';

    // Terms & Signatory
    final termsLines = <String>[];
    if (invoice.terms.trim().isNotEmpty) {
      termsLines.addAll(
        invoice.terms
            .split('\n')
            .map((l) => _cleanText(l))
            .where((l) => l.isNotEmpty),
      );
    }
    if (invoice.notes.trim().isNotEmpty) {
      termsLines.addAll(
        invoice.notes
            .split('\n')
            .map((l) => _cleanText(l))
            .where((l) => l.isNotEmpty),
      );
    }
    if (termsLines.isEmpty) {
      final defaultTrm =
          findField(termsSection, 'f_trm_lines')?.defaultValue.trim() ?? '';
      if (defaultTrm.isNotEmpty) {
        termsLines.addAll(
          defaultTrm
              .split('\n')
              .map((l) => _cleanText(l))
              .where((l) => l.isNotEmpty),
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

    final signeeTitle = pickSetting(
      ['signeeTitle'],
      findField(termsSection, 'f_trm_title')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(termsSection, 'f_trm_title')!.defaultValue.trim()
          : 'Authorized Signatory',
    );

    final stampImage = _memoryImage(localSettings['invoiceStamp']);
    final signatureImage = _memoryImage(localSettings['invoiceSignature']);

    // Line items table columns & rows
    final String defaultCol0;
    final String defaultCol1;
    final String defaultCol2;
    final String defaultCol3;
    final String defaultCol4;

    if (activePreset == 'gst_service') {
      defaultCol0 = 'Service Description & Scope';
      defaultCol1 = 'SAC Code';
      defaultCol2 = 'Qty / Hrs';
      defaultCol3 = 'Rate ($currencySymbol)';
      defaultCol4 = 'Amount ($currencySymbol)';
    } else if (activePreset == 'consulting') {
      defaultCol0 = 'Scope & Deliverables';
      defaultCol1 = 'Lead Consultant';
      defaultCol2 = 'Hours / Days';
      defaultCol3 = 'Rate ($currencySymbol)';
      defaultCol4 = 'Amount ($currencySymbol)';
    } else if (activePreset == 'retail') {
      defaultCol0 = 'Item Description';
      defaultCol1 = 'SKU / HSN';
      defaultCol2 = 'Qty';
      defaultCol3 = 'MRP ($currencySymbol)';
      defaultCol4 = 'Net Total ($currencySymbol)';
    } else {
      defaultCol0 = 'Particulars';
      defaultCol1 = 'Guards';
      defaultCol2 = 'Duty Days';
      defaultCol3 = 'Rate ($currencySymbol)';
      defaultCol4 = 'Amount ($currencySymbol)';
    }

    final allColumns = <({
      String fieldId,
      String label,
      int flex,
      pw.TextAlign align,
    })>[
      (
        fieldId: 'f_col_particulars',
        label: columnLabel(servicesSection, 'f_col_particulars', defaultCol0),
        flex: 5,
        align: pw.TextAlign.left,
      ),
      (
        fieldId: 'f_col_guards',
        label: columnLabel(servicesSection, 'f_col_guards', defaultCol1),
        flex: 2,
        align: pw.TextAlign.center,
      ),
      (
        fieldId: 'f_col_duty',
        label: columnLabel(servicesSection, 'f_col_duty', defaultCol2),
        flex: 2,
        align: pw.TextAlign.center,
      ),
      (
        fieldId: 'f_col_rate',
        label: columnLabel(servicesSection, 'f_col_rate', defaultCol3),
        flex: 3,
        align: pw.TextAlign.right,
      ),
      (
        fieldId: 'f_col_amount',
        label: columnLabel(servicesSection, 'f_col_amount', defaultCol4),
        flex: 3,
        align: pw.TextAlign.right,
      ),
    ];

    final allRows = <List<String>>[];
    if (invoice.items.isNotEmpty) {
      for (final item in invoice.items) {
        final desc = item.itemDetails.trim().isNotEmpty
            ? '${_cleanText(item.description)}\n${_cleanText(item.itemDetails)}'
            : _cleanText(item.description);
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
      if (isFieldVisible(servicesSection, allColumns[i].fieldId)) {
        visibleIndices.add(i);
      }
    }
    if (visibleIndices.isEmpty) visibleIndices.add(0);

    final columns = [for (final idx in visibleIndices) allColumns[idx]];
    final rows = [
      for (final row in allRows)
        [for (final idx in visibleIndices) row[idx]],
    ];

    pw.TableRow metaRow(String label, String value) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
            child: pw.Text(
              _cleanText(label),
              style: docStyle(
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF64748B),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Text(
              ':',
              style: docStyle(
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF64748B),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
            child: pw.Text(
              _cleanText(value),
              style: docStyle(
                fontSize: 9,
                bold: true,
                color: const PdfColor.fromInt(0xFF1E293B),
              ),
            ),
          ),
        ],
      );
    }

    pw.Widget pdfHeroPill(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: pw.BoxDecoration(
          color: const PdfColor(1, 1, 1, 0.2),
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: const PdfColor(1, 1, 1, 0.35)),
        ),
        child: pw.Text(
          _cleanText(text),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8.5 * fontScale,
            color: PdfColors.white,
          ),
        ),
      );
    }

    pw.Widget pdfLedgerRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 70,
              child: pw.Text(
                '${_cleanText(label)}:',
                style: docStyle(
                  fontSize: 8.5,
                  bold: true,
                  color: const PdfColor.fromInt(0xFF64748B),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                _cleanText(value),
                style: docStyle(
                  fontSize: 8.5,
                  bold: true,
                  color: const PdfColor.fromInt(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget summaryRow(String label, String value, {bool isBold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _cleanText(label),
              style: docStyle(
                fontSize: 9.5,
                bold: isBold,
                color: const PdfColor.fromInt(0xFF64748B),
              ),
            ),
            pw.Text(
              _cleanText(value),
              style: docStyle(
                fontSize: 9.5,
                bold: true,
                color: const PdfColor.fromInt(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    }

    final letterheadConfig = CompanyLetterheadConfig.fromSettings(
      localSettings: localSettings,
      profile: businessProfile,
      fallbackCompanyName: companyLegalName,
      fallbackAddress: companyAddress.replaceAll('\n', ', '),
      fallbackPhone: companyPhone,
      fallbackEmail: companyEmail,
      fallbackGstin: companyGstin,
      fallbackPan: companyPan,
      fallbackLogoBase64: localSettings['invoiceLogo']?.toString(),
    );

    final document = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: companyLegalName,
      subject: '$documentTitle ${invoice.invoiceNumber}',
    );

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(pageMarginPt),
      buildBackground: watermark != 'None'
          ? (pw.Context ctx) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.35,
                    child: pw.Text(
                      _cleanText(watermark),
                      style: docStyle(
                        fontSize: 52,
                        bold: true,
                        color: const PdfColor(0.06, 0.09, 0.16, 0.06),
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
              )
          : (letterheadConfig.isLetterheadActive &&
                  letterheadConfig.styleId == 'royal_security_crest')
              ? (pw.Context ctx) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Center(
                      child: CompanyLetterheadPdf.buildPdfWatermark(config: letterheadConfig),
                    ),
                  )
              : null,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (pw.Context ctx) => letterheadConfig.isLetterheadActive
            ? CompanyLetterheadPdf.buildPdfFooter(
                config: letterheadConfig,
                overridePrimary: primaryColor,
                scale: fontScale,
                pageLabel: 'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              )
            : pw.SizedBox(height: 30 * fontScale),
        build: (pw.Context context) => [
          // A. Header (Company Letterhead Banner or Classic Business Branding)
          if (brandingSection.enabled) ...[
            if (letterheadConfig.isLetterheadActive)
              CompanyLetterheadPdf.buildPdfHeader(
                config: letterheadConfig,
                overridePrimary: primaryColor,
                scale: fontScale,
                showGstBadges: isFieldVisible(brandingSection, 'f_biz_gstin') ||
                    isFieldVisible(brandingSection, 'f_biz_pan'),
              )
            else
              // Pre-printed stationery paper mode: letterhead is unselected,
              // so leave blank top space for company's pre-printed physical letterhead paper
              // and do NOT print "Billed From" company details.
              pw.SizedBox(height: 90 * fontScale),
          ],

          // B & C. Identity, Document Details & Client Sections by Selected Layout Structure
          ...() {
            final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148';
            final issueDate = invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025';
            final dueDate = invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025';
            final poNum = invoice.poNumber.trim().isNotEmpty ? invoice.poNumber.trim() : 'PO-4587/2025';

            if (layoutStyle == 'executive_banner') {
              return [
                if (identitySection.enabled) ...[
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 14),
                    padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              uppercaseHeadings ? documentTitle.toUpperCase() : documentTitle,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 18 * fontScale,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor(1, 1, 1, 0.25),
                                borderRadius: pw.BorderRadius.circular(10),
                                border: pw.Border.all(color: const PdfColor(1, 1, 1, 0.4)),
                              ),
                              child: pw.Text(
                                'ORIGINAL BILL',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8 * fontScale,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pdfHeroPill('Inv: $invNum'),
                            pw.SizedBox(width: 6),
                            pdfHeroPill('Issued: $issueDate'),
                            pw.SizedBox(width: 6),
                            pdfHeroPill('Due: $dueDate'),
                            pw.SizedBox(width: 6),
                            pdfHeroPill('PO: $poNum'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (clientSection.enabled) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                height: 3.5,
                                decoration: pw.BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(10),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      uppercaseHeadings ? 'BILLED TO (CLIENT)' : 'Billed To (Client)',
                                      style: docStyle(fontSize: 8.8, bold: true, color: primaryColor),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(clientDisplayName, style: docStyle(fontSize: 10.5, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                                    pw.SizedBox(height: 2),
                                    for (final line in clientAddr.split('\n'))
                                      if (line.trim().isNotEmpty)
                                        pw.Text(line.trim(), style: docStyle(fontSize: 8.8, color: const PdfColor.fromInt(0xFF475569))),
                                    if (clientGstin.isNotEmpty)
                                      pw.Text('GSTIN: $clientGstin', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF475569))),
                                    if (clientPhone.isNotEmpty)
                                      pw.Text('Phone: $clientPhone', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF475569))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                height: 3.5,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFF0D9488),
                                  borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(10),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      uppercaseHeadings ? 'SERVICE LOCATION & PERIOD' : 'Service Location & Period',
                                      style: docStyle(fontSize: 8.8, bold: true, color: const PdfColor.fromInt(0xFF0D9488)),
                                    ),
                                    pw.SizedBox(height: 4),
                                    for (final line in serviceLocation.split('\n'))
                                      if (line.trim().isNotEmpty)
                                        pw.Text(line.trim(), style: docStyle(fontSize: 9.5, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                                    pw.SizedBox(height: 2),
                                    pw.Text('Billing Period: $billingPeriod', style: docStyle(fontSize: 8.8, color: const PdfColor.fromInt(0xFF475569))),
                                    pw.Text('Terms: ${_cleanText(invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Net 15 Days')}', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                ],
              ];
            }

            if (layoutStyle == 'compact_grid') {
              return [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF0F172A), width: 1),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 6,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(color: PdfColor.fromInt(0xFF0F172A), width: 1),
                                  bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0F172A), width: 1),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('1. SUPPLIER / CONSIGNOR DETAILS', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF475569))),
                                  pw.SizedBox(height: 2),
                                  pw.Text(companyLegalName, style: docStyle(fontSize: 10, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                                  for (final line in companyAddress.split('\n'))
                                    if (line.trim().isNotEmpty)
                                      pw.Text(line.trim(), style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                                  pw.Text('GSTIN: $companyGstin · PAN: $companyPan', style: docStyle(fontSize: 8.2, bold: true, color: const PdfColor.fromInt(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0F172A), width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('TAX INVOICE & DISPATCH REF', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF475569))),
                                  pw.SizedBox(height: 2),
                                  pdfLedgerRow('Invoice No.', invNum),
                                  pdfLedgerRow('Date', issueDate),
                                  pdfLedgerRow('Due Date', dueDate),
                                  pdfLedgerRow('PO Ref', poNum),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 6,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(color: PdfColor.fromInt(0xFF0F172A), width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('2. BUYER / BILLED TO', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF475569))),
                                  pw.SizedBox(height: 2),
                                  pw.Text(clientDisplayName, style: docStyle(fontSize: 10, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                                  for (final line in clientAddr.split('\n'))
                                    if (line.trim().isNotEmpty)
                                      pw.Text(line.trim(), style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                                  if (clientGstin.isNotEmpty)
                                    pw.Text('GSTIN: $clientGstin', style: docStyle(fontSize: 8.2, bold: true, color: const PdfColor.fromInt(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('3. CONSIGNEE / SHIPPED TO', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF475569))),
                                  pw.SizedBox(height: 2),
                                  for (final line in serviceLocation.split('\n'))
                                    if (line.trim().isNotEmpty)
                                      pw.Text(line.trim(), style: docStyle(fontSize: 8.8, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                                  pw.Text('Period: $billingPeriod', style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
              ];
            }

            if (layoutStyle == 'minimal_asymmetric') {
              return [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      uppercaseHeadings ? 'INVOICE' : 'Invoice',
                      style: docStyle(fontSize: 24, bold: true, color: const PdfColor.fromInt(0xFF0F172A)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      '//  $invNum',
                      style: docStyle(fontSize: 14, color: const PdfColor.fromInt(0xFF64748B)),
                    ),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFEFF6FF),
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
                      ),
                      child: pw.Text('ISSUED: ${issueDate.toUpperCase()}', style: docStyle(fontSize: 8.5, bold: true, color: const PdfColor.fromInt(0xFF1E40AF))),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(height: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILLED TO', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF94A3B8))),
                          pw.SizedBox(height: 3),
                          pw.Text(clientDisplayName, style: docStyle(fontSize: 10, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                          for (final line in clientAddr.split('\n'))
                            if (line.trim().isNotEmpty)
                              pw.Text(line.trim(), style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B))),
                          if (clientGstin.isNotEmpty)
                            pw.Text('GST: $clientGstin', style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF64748B))),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 50, color: const PdfColor.fromInt(0xFFE2E8F0), margin: const pw.EdgeInsets.symmetric(horizontal: 10)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SERVICE SCOPE', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF94A3B8))),
                          pw.SizedBox(height: 3),
                          for (final line in serviceLocation.split('\n'))
                            if (line.trim().isNotEmpty)
                              pw.Text(line.trim(), style: docStyle(fontSize: 9.2, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                          pw.Text('Period: $billingPeriod', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B))),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 50, color: const PdfColor.fromInt(0xFFE2E8F0), margin: const pw.EdgeInsets.symmetric(horizontal: 10)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PAYMENT TERMS', style: docStyle(fontSize: 8, bold: true, color: const PdfColor.fromInt(0xFF94A3B8))),
                          pw.SizedBox(height: 3),
                          pw.Text(_cleanText(invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Net 15 Days'), style: docStyle(fontSize: 9.5, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                          pw.Text('Due: $dueDate\nPO: $poNum', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
              ];
            }

            if (layoutStyle == 'sidebar_accent') {
              return [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(width: 4, height: 20, color: primaryColor),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          uppercaseHeadings ? documentTitle.toUpperCase() : documentTitle,
                          style: docStyle(fontSize: 18, bold: true, color: const PdfColor.fromInt(0xFF0F172A)),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pdfHeroPill(invNum),
                        pw.SizedBox(width: 6),
                        pdfHeroPill(issueDate),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(5),
                          border: pw.Border(
                            left: pw.BorderSide(color: primaryColor, width: 3.5),
                            top: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
                            right: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
                            bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('CLIENT & BILLING ADDRESS', style: docStyle(fontSize: 8.8, bold: true, color: primaryColor)),
                            pw.SizedBox(height: 3),
                            pw.Text(clientDisplayName, style: docStyle(fontSize: 10, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                            for (final line in clientAddr.split('\n'))
                              if (line.trim().isNotEmpty)
                                pw.Text(line.trim(), style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF475569))),
                            if (clientGstin.isNotEmpty)
                              pw.Text('GSTIN: $clientGstin', style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(5),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('SERVICE DEPLOYMENT & PERIOD', style: docStyle(fontSize: 8.8, bold: true, color: const PdfColor.fromInt(0xFF475569))),
                            pw.SizedBox(height: 3),
                            for (final line in serviceLocation.split('\n'))
                              if (line.trim().isNotEmpty)
                                pw.Text(line.trim(), style: docStyle(fontSize: 9.5, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                            pw.Text('Period: $billingPeriod', style: docStyle(fontSize: 8.5, color: const PdfColor.fromInt(0xFF475569))),
                            pw.Text('PO: $poNum · Due: $dueDate', style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
              ];
            }

            if (layoutStyle == 'classic_bordered') {
              return [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '- ✦ ${uppercaseHeadings ? documentTitle.toUpperCase() : documentTitle} ✦ -',
                        style: docStyle(fontSize: 16, bold: true, color: const PdfColor.fromInt(0xFF0F172A)),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Issued under Goods & Services Tax Act · Duplicate for Transporter',
                        style: docStyle(fontSize: 7.5, italic: true, color: const PdfColor.fromInt(0xFF64748B)),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(9),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF334155), width: 1),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BILLED TO (RECIPIENT):', style: docStyle(fontSize: 8.8, bold: true, color: const PdfColor.fromInt(0xFF1E293B))),
                            pw.SizedBox(height: 2),
                            pw.Text(clientDisplayName, style: docStyle(fontSize: 10, bold: true, color: const PdfColor.fromInt(0xFF0F172A))),
                            for (final line in clientAddr.split('\n'))
                              if (line.trim().isNotEmpty)
                                pw.Text(line.trim(), style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                            if (clientGstin.isNotEmpty)
                              pw.Text('GSTIN: $clientGstin', style: docStyle(fontSize: 8.2, color: const PdfColor.fromInt(0xFF475569))),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 48, color: const PdfColor.fromInt(0xFFCBD5E1), margin: const pw.EdgeInsets.symmetric(horizontal: 8)),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pdfLedgerRow('Invoice No.', invNum),
                            pdfLedgerRow('Dated', issueDate),
                            pdfLedgerRow('Payment Due', dueDate),
                            pdfLedgerRow('Site / Place', serviceLocation.split('\n').first),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ];
            }

            // Default modern_split layout
            return [
              if (identitySection.enabled) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        uppercaseHeadings
                            ? documentTitle.toUpperCase()
                            : documentTitle,
                        style: docStyle(
                          fontSize: 19,
                          bold: true,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Table(
                      defaultColumnWidth: const pw.IntrinsicColumnWidth(),
                      children: [
                        if (isFieldVisible(identitySection, 'f_doc_number'))
                          metaRow(
                            'Invoice No.',
                            invoice.invoiceNumber.isNotEmpty
                                ? invoice.invoiceNumber
                                : 'INV-2025-0148',
                          ),
                        if (isFieldVisible(identitySection, 'f_doc_issue'))
                          metaRow(
                            'Issue Date',
                            invoice.issueDate.isNotEmpty
                                ? invoice.issueDate
                                : '15 Apr 2025',
                          ),
                        if (isFieldVisible(identitySection, 'f_doc_due'))
                          metaRow(
                            'Due Date',
                            invoice.dueDate.isNotEmpty
                                ? invoice.dueDate
                                : '30 Apr 2025',
                          ),
                        if (isFieldVisible(identitySection, 'f_doc_po') &&
                            (invoice.poNumber.trim().isNotEmpty ||
                                findField(identitySection, 'f_doc_po')
                                        ?.defaultValue
                                        .trim()
                                        .isNotEmpty ==
                                    true))
                          metaRow(
                            'PO No.',
                            invoice.poNumber.trim().isNotEmpty
                                ? invoice.poNumber.trim()
                                : findField(identitySection, 'f_doc_po')!
                                    .defaultValue
                                    .trim(),
                          ),
                        for (final cf in customVisibleFields(
                          identitySection,
                          const {
                            'f_doc_number',
                            'f_doc_issue',
                            'f_doc_due',
                            'f_doc_po',
                          },
                        ))
                          metaRow(
                            cf.label,
                            cf.defaultValue.isNotEmpty ? cf.defaultValue : '-',
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
              ],

              if (clientSection.enabled) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(5),
                          border: pw.Border.all(
                            color: const PdfColor.fromInt(0xFFE2E8F0),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              uppercaseHeadings ? 'BILL TO' : 'Bill To',
                              style: docStyle(
                                fontSize: 9.5,
                                bold: true,
                                color: const PdfColor.fromInt(0xFF475569),
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            if (isFieldVisible(clientSection, 'f_cli_name'))
                              pw.Text(
                                clientDisplayName,
                                style: docStyle(
                                  fontSize: 10.5,
                                  bold: true,
                                  color: const PdfColor.fromInt(0xFF0F172A),
                                ),
                              ),
                            pw.SizedBox(height: 2),
                            if (isFieldVisible(clientSection, 'f_cli_addr'))
                              for (final line in clientAddr.split('\n'))
                                if (line.trim().isNotEmpty)
                                  pw.Text(
                                    line.trim(),
                                    style: docStyle(
                                      fontSize: 9,
                                      color: const PdfColor.fromInt(0xFF475569),
                                    ),
                                  ),
                            pw.SizedBox(height: 2),
                            if (isFieldVisible(clientSection, 'f_cli_gstin') &&
                                clientGstin.isNotEmpty)
                              pw.Text(
                                'GSTIN: $clientGstin',
                                style: docStyle(
                                  fontSize: 9,
                                  color: const PdfColor.fromInt(0xFF475569),
                                ),
                              ),
                            if (isFieldVisible(clientSection, 'f_cli_contact') &&
                                clientContactPerson.isNotEmpty)
                              pw.Text(
                                'Contact: $clientContactPerson',
                                style: docStyle(
                                  fontSize: 9,
                                  color: const PdfColor.fromInt(0xFF475569),
                                ),
                              ),
                            if (isFieldVisible(clientSection, 'f_cli_phone') &&
                                clientPhone.isNotEmpty)
                              pw.Text(
                                'Phone: $clientPhone',
                                style: docStyle(
                                  fontSize: 9,
                                  color: const PdfColor.fromInt(0xFF475569),
                                ),
                              ),
                            for (final cf in customVisibleFields(
                              clientSection,
                              const {
                                'f_cli_name',
                                'f_cli_addr',
                                'f_cli_gstin',
                                'f_cli_contact',
                                'f_cli_phone',
                              },
                            ))
                              pw.Text(
                                '${_cleanText(cf.label)}: ${_cleanText(cf.defaultValue.isNotEmpty ? cf.defaultValue : '-')}',
                                style: docStyle(
                                  fontSize: 9,
                                  color: const PdfColor.fromInt(0xFF475569),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isFieldVisible(servicesSection, 'f_srv_loc') ||
                        isFieldVisible(servicesSection, 'f_srv_period')) ...[
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF8FAFC),
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFFE2E8F0),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (isFieldVisible(servicesSection, 'f_srv_loc')) ...[
                                pw.Text(
                                  uppercaseHeadings
                                      ? 'SERVICE LOCATION'
                                      : 'Service Location',
                                  style: docStyle(
                                    fontSize: 9,
                                    color: const PdfColor.fromInt(0xFF64748B),
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                ...() {
                                  final locLines = serviceLocation
                                      .split('\n')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                  return [
                                    if (locLines.isNotEmpty)
                                      pw.Text(
                                        locLines.first,
                                        style: docStyle(
                                          fontSize: 9.5,
                                          bold: true,
                                          color: const PdfColor.fromInt(0xFF1E293B),
                                        ),
                                      ),
                                    for (final sub in locLines.skip(1))
                                      pw.Text(
                                        sub,
                                        style: docStyle(
                                          fontSize: 9,
                                          color: const PdfColor.fromInt(0xFF475569),
                                        ),
                                      ),
                                  ];
                                }(),
                                if (isFieldVisible(servicesSection, 'f_srv_period'))
                                  pw.SizedBox(height: 6),
                              ],
                              if (isFieldVisible(servicesSection, 'f_srv_period')) ...[
                                pw.Text(
                                  uppercaseHeadings
                                      ? 'BILLING PERIOD'
                                      : 'Billing Period',
                                  style: docStyle(
                                    fontSize: 9,
                                    color: const PdfColor.fromInt(0xFF64748B),
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  billingPeriod,
                                  style: docStyle(
                                    fontSize: 9.5,
                                    bold: true,
                                    color: const PdfColor.fromInt(0xFF1E293B),
                                  ),
                                ),
                                pw.Text(
                                  '(${_cleanText(invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Monthly Billing')})',
                                  style: docStyle(
                                    fontSize: 8.5,
                                    color: const PdfColor.fromInt(0xFF64748B),
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
                pw.SizedBox(height: 14),
              ],
            ];
          }(),

          // D. Line Items & Duty Table
          if (servicesSection.enabled) ...[
            pw.Container(
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFCBD5E1),
                ),
              ),
              child: pw.Column(
                children: [
                  // Header Row
                  pw.Container(
                    color: primaryColor,
                    child: pw.Row(
                      children: [
                        for (int c = 0; c < columns.length; c++)
                          pw.Expanded(
                            flex: columns[c].flex,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration: pw.BoxDecoration(
                                border: isBoxed && c < columns.length - 1
                                    ? const pw.Border(
                                        right: pw.BorderSide(
                                          color: PdfColor(1, 1, 1, 0.25),
                                          width: 0.8,
                                        ),
                                      )
                                    : null,
                              ),
                              child: pw.Text(
                                uppercaseHeadings
                                    ? columns[c].label.toUpperCase()
                                    : columns[c].label,
                                textAlign: columns[c].align,
                                style: docStyle(
                                  fontSize: 9,
                                  bold: true,
                                  color: tableHeaderTextColor,
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
                      pw.Divider(
                        height: 1,
                        thickness: 0.7,
                        color: const PdfColor.fromInt(0xFFE2E8F0),
                      ),
                    pw.Container(
                      color: isStriped && r.isOdd
                          ? const PdfColor.fromInt(0xFFF8FAFC)
                          : PdfColors.white,
                      decoration: isBoxed && r < rows.length - 1
                          ? const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: PdfColor.fromInt(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                            )
                          : null,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (int c = 0; c < rows[r].length; c++)
                            pw.Expanded(
                              flex: columns[c].flex,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: pw.BoxDecoration(
                                  border: isBoxed && c < rows[r].length - 1
                                      ? const pw.Border(
                                          right: pw.BorderSide(
                                            color: PdfColor.fromInt(0xFFCBD5E1),
                                            width: 0.8,
                                          ),
                                        )
                                      : null,
                                ),
                                child: pw.Text(
                                  rows[r][c],
                                  textAlign: columns[c].align,
                                  style: docStyle(
                                    fontSize: 9,
                                    bold: c == 0 || c == rows[r].length - 1,
                                    color: c == rows[r].length - 1
                                        ? const PdfColor.fromInt(0xFF0F172A)
                                        : (c == 0
                                            ? const PdfColor.fromInt(0xFF1E293B)
                                            : const PdfColor.fromInt(0xFF475569)),
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
            ),
            pw.SizedBox(height: 14),
          ],

          // E. Financial Summary & Totals Box
          if (taxTotalsSection.enabled) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 14, top: 4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          uppercaseHeadings
                              ? 'AMOUNT IN WORDS'
                              : 'Amount in Words',
                          style: docStyle(
                            fontSize: 8.5,
                            bold: true,
                            color: const PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          _cleanText(
                            AmountToWords.convert(
                              invoice.total,
                              currency: invoice.currencyCode,
                            ),
                          ),
                          style: docStyle(
                            fontSize: 9,
                            bold: true,
                            italic: true,
                            color: const PdfColor.fromInt(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Container(
                  width: 235,
                  child: pw.Column(
                    children: [
                      if (isFieldVisible(taxTotalsSection, 'f_tot_sub'))
                        summaryRow('Subtotal', formatAmount(invoice.subtotal)),
                      if (isFieldVisible(taxTotalsSection, 'f_tot_disc'))
                        summaryRow(
                          'Discount',
                          '(-) ${formatAmount(invoice.totalDiscount)}',
                        ),
                      if (isFieldVisible(taxTotalsSection, 'f_tot_taxable'))
                        summaryRow(
                          'Taxable Amount',
                          formatAmount(invoice.taxableAmount),
                          isBold: true,
                        ),
                      if (!invoice.isRcm && invoice.taxRate > 0) ...[
                        if (!gstBreakdown.isInterState) ...[
                          if (isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                            summaryRow(
                              'CGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%)',
                              formatAmount(invoice.taxAmount / 2),
                            ),
                          if (isFieldVisible(taxTotalsSection, 'f_tot_sgst'))
                            summaryRow(
                              'SGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%)',
                              formatAmount(invoice.taxAmount / 2),
                            ),
                        ] else ...[
                          if (isFieldVisible(taxTotalsSection, 'f_tot_igst',
                                  fallback: true) ||
                              isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                            summaryRow(
                              'IGST (${invoice.taxRate.toStringAsFixed(invoice.taxRate % 1 == 0 ? 0 : 1)}%)',
                              formatAmount(invoice.taxAmount),
                            ),
                        ],
                      ],
                      if (invoice.shippingFee > 0)
                        summaryRow(
                          'Shipping & Handling',
                          formatAmount(invoice.shippingFee),
                        ),
                      if (invoice.additionalCharges > 0)
                        summaryRow(
                          'Additional Charges',
                          formatAmount(invoice.additionalCharges),
                        ),
                      if (invoice.roundOff != 0)
                        summaryRow(
                          'Round Off',
                          formatAmount(invoice.roundOff),
                        ),
                      if (isFieldVisible(taxTotalsSection, 'f_tot_grand')) ...[
                        pw.SizedBox(height: 5),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _tintColor(primaryColor, 0.12),
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(
                              color: _tintColor(primaryColor, 0.35),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                uppercaseHeadings
                                    ? 'GRAND TOTAL'
                                    : 'Grand Total',
                                style: docStyle(
                                  fontSize: 10.5,
                                  bold: true,
                                  color: primaryColor,
                                ),
                              ),
                              pw.Text(
                                formatAmount(invoice.total),
                                style: docStyle(
                                  fontSize: 10.5,
                                  bold: true,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (invoice.amountPaid > 0) ...[
                        pw.SizedBox(height: 3),
                        summaryRow(
                          'Amount Paid',
                          '(-) ${formatAmount(invoice.amountPaid)}',
                        ),
                        summaryRow(
                          'Balance Due',
                          formatAmount(invoice.balanceDue),
                          isBold: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // F. Payment Details & UPI QR Code
          if (bankSection.enabled) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFE2E8F0),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          uppercaseHeadings
                              ? 'PAYMENT DETAILS'
                              : 'Payment Details',
                          style: docStyle(
                            fontSize: 10,
                            bold: true,
                            color: const PdfColor.fromInt(0xFF0F172A),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        if (isFieldVisible(bankSection, 'f_bnk_name'))
                          pw.Text(
                            'Bank Name : $bankName',
                            style: docStyle(
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFF475569),
                            ),
                          ),
                        if (isFieldVisible(bankSection, 'f_bnk_ac'))
                          pw.Text(
                            'A/C No.      : $bankAccount',
                            style: docStyle(
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFF475569),
                            ),
                          ),
                        if (isFieldVisible(bankSection, 'f_bnk_ifsc'))
                          pw.Text(
                            'IFSC           : $bankIfsc',
                            style: docStyle(
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFF475569),
                            ),
                          ),
                        if (isFieldVisible(bankSection, 'f_bnk_upi'))
                          pw.Text(
                            'UPI             : $bankUpi',
                            style: docStyle(
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFF475569),
                            ),
                          ),
                        if (invoice.paymentInstructions.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            _cleanText(invoice.paymentInstructions),
                            style: docStyle(
                              fontSize: 8.5,
                              color: const PdfColor.fromInt(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showQrCode && isFieldVisible(bankSection, 'f_bnk_qr'))
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 50 * fontScale,
                          height: 50 * fontScale,
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFFCBD5E1),
                            ),
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrPayload,
                            drawText: false,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Scan to Pay',
                          style: docStyle(
                            fontSize: 7.5,
                            color: const PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // G. Terms & Conditions and Signature
          if (termsSection.enabled) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        uppercaseHeadings
                            ? 'TERMS & CONDITIONS'
                            : 'Terms & Conditions',
                        style: docStyle(
                          fontSize: 9.5,
                          bold: true,
                          color: const PdfColor.fromInt(0xFF0F172A),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      if (isFieldVisible(termsSection, 'f_trm_lines'))
                        for (int i = 0; i < termsLines.length; i++)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 1.5),
                            child: pw.Text(
                              RegExp(r'^\d+\.').hasMatch(termsLines[i])
                                  ? termsLines[i]
                                  : '${i + 1}. ${termsLines[i]}',
                              style: docStyle(
                                fontSize: 8,
                                color: const PdfColor.fromInt(0xFF475569),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (isFieldVisible(termsSection, 'f_trm_company'))
                        pw.Text(
                          'For $companyLegalName',
                          textAlign: pw.TextAlign.right,
                          style: docStyle(
                            fontSize: 9,
                            bold: true,
                            color: const PdfColor.fromInt(0xFF1E293B),
                          ),
                        ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          if (stampImage != null)
                            pw.Container(
                              width: 56 * fontScale,
                              height: 56 * fontScale,
                              margin: const pw.EdgeInsets.only(right: 8),
                              child: pw.Image(
                                stampImage,
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          if (signatureImage != null)
                            pw.Container(
                              height: 44 * fontScale,
                              width: 130 * fontScale,
                              child: pw.Image(
                                signatureImage,
                                fit: pw.BoxFit.contain,
                              ),
                            )
                          else
                            pw.SizedBox(height: 36 * fontScale),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        width: 130,
                        height: 0.8,
                        color: const PdfColor.fromInt(0xFFCBD5E1),
                      ),
                      pw.SizedBox(height: 3),
                      if (isFieldVisible(termsSection, 'f_trm_title'))
                        pw.Text(
                          signeeTitle,
                          textAlign: pw.TextAlign.right,
                          style: docStyle(
                            fontSize: 8.5,
                            color: const PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      if (isFieldVisible(termsSection, 'f_trm_auto_stamp'))
                        pw.Text(
                          '(This is a system generated invoice)',
                          textAlign: pw.TextAlign.right,
                          style: docStyle(
                            fontSize: 7,
                            color: const PdfColor.fromInt(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
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
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.circular(5),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFCBD5E1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _cleanText(
                        uppercaseHeadings
                            ? customSec.title.toUpperCase()
                            : customSec.title,
                      ),
                      style: docStyle(
                        fontSize: 9.5,
                        bold: true,
                        color: const PdfColor.fromInt(0xFF0F172A),
                      ),
                    ),
                    if (customSec.subtitle.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _cleanText(customSec.subtitle),
                        style: docStyle(
                          fontSize: 8.5,
                          color: const PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 6),
                    pw.Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: customSec.fields
                          .where((f) => f.isVisible)
                          .map((f) {
                        return pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              '${_cleanText(f.label)}: ',
                              style: docStyle(
                                fontSize: 8.5,
                                bold: true,
                                color: const PdfColor.fromInt(0xFF475569),
                              ),
                            ),
                            pw.Text(
                              _cleanText(
                                f.defaultValue.isNotEmpty
                                    ? f.defaultValue
                                    : '-',
                              ),
                              style: docStyle(
                                fontSize: 8.5,
                                color: const PdfColor.fromInt(0xFF1E293B),
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
        ],
      ),
    );

    return document.save();
  }
}
