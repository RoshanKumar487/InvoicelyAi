import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/utils/amount_to_words.dart';
import '../../../core/utils/gst_tax_calculator.dart';
import '../../templates/data/studio_section_model.dart';
import '../../templates/data/template_config.dart';
import 'invoice.dart';

class InvoiceDocxExport {
  InvoiceDocxExport._();

  static String _cleanHex(String? hex, String fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final clean = hex.trim().replaceFirst('#', '').toUpperCase();
    return clean.length == 6 ? clean : fallback;
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

  static Uint8List build(
    Invoice invoice, {
    TemplateConfig? template,
    Map<String, Object?> localSettings = const <String, Object?>{},
    Map<String, dynamic> businessProfile = const <String, dynamic>{},
  }) {
    final presetStr = localSettings['studio_preset']?.toString().trim();
    final activePreset = (presetStr != null && presetStr.isNotEmpty)
        ? presetStr
        : () {
            final cat = (template?.category ?? '').toLowerCase();
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
      return fld.label
          .replaceFirst(RegExp(r'\s*Column$', caseSensitive: false), '')
          .trim();
    }

    final brandingSection = findSection('sec_branding');
    final identitySection = findSection('sec_identity');
    final clientSection = findSection('sec_client');
    final servicesSection = findSection('sec_services');
    final taxTotalsSection = findSection('sec_tax_totals');
    final bankSection = findSection('sec_bank');
    final termsSection = findSection('sec_terms');

    final primaryHex = _cleanHex(
      localSettings['studio_primary_color']?.toString() ?? template?.color,
      '1E3A8A',
    );
    final headerTextHex = _cleanHex(
      localSettings['studio_table_header_text_color']?.toString(),
      'FFFFFF',
    );
    final uppercaseHeadings = () {
      final u = localSettings['studio_uppercase_headings'];
      if (u is bool) return u;
      if (u is String) return u.toLowerCase() == 'true';
      return true;
    }();

    final documentTitle = () {
      final custom = localSettings['customTitle']?.toString().trim();
      if (custom != null && custom.isNotEmpty) return custom;
      final tplTitle = template?.title.trim();
      if (tplTitle != null && tplTitle.isNotEmpty && !tplTitle.contains('—')) {
        return tplTitle;
      }
      return 'TAX INVOICE';
    }();

    final currencySymbol =
        localSettings['defaultCurrencySymbol']?.toString().trim().isNotEmpty ==
                true
            ? localSettings['defaultCurrencySymbol']!.toString().trim()
            : (invoice.currencySymbol.trim().isNotEmpty &&
                    invoice.currencySymbol.trim() != r'$'
                ? invoice.currencySymbol.trim()
                : '₹');

    String formatAmount(double val) => '$currencySymbol ${_formatNumber(val)}';

    String pickSetting(List<String> keys, String fallback) {
      for (final k in keys) {
        final pVal = businessProfile[k]?.toString().trim();
        if (pVal != null && pVal.isNotEmpty) return pVal;
        final lVal = localSettings[k]?.toString().trim();
        if (lVal != null && lVal.isNotEmpty) return lVal;
      }
      return fallback;
    }

    final companyLegalName = pickSetting(
      ['companyName', 'businessName', 'legalName'],
      findField(brandingSection, 'f_biz_name')?.defaultValue.trim().isNotEmpty ==
              true
          ? findField(brandingSection, 'f_biz_name')!.defaultValue.trim()
          : 'Northstar Security Services Ltd.',
    );

    final words = companyLegalName.split(RegExp(r'\s+'));
    final brandHeadline = words.isNotEmpty
        ? words.first
        : (activePreset == 'security_agency' ? 'NORTHSTAR' : 'ENTERPRISE');
    final brandSubtitle = words.length > 1
        ? words
            .sublist(1)
            .join(' ')
            .replaceAll(
              RegExp(r'\b(Pvt\.?|Ltd\.?|LLP|Inc\.?)\b', caseSensitive: false),
              '',
            )
            .trim()
        : (activePreset == 'security_agency'
            ? 'SECURITY SERVICES'
            : 'SOLUTIONS & SERVICES');

    final companyTagline = pickSetting(
      ['tagline', 'companyTagline', 'businessTagline'],
      findField(brandingSection, 'f_biz_tagline')
                  ?.defaultValue
                  .trim()
                  .isNotEmpty ==
              true
          ? findField(brandingSection, 'f_biz_tagline')!.defaultValue.trim()
          : 'Safe People  |  Secure Tomorrow',
    );
    final companyAddress = pickSetting(
      ['companyAddress', 'address', 'businessAddress'],
      '#12, 3rd Floor, Green Park, Bengaluru, Karnataka - 560076',
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
            : (findField(clientSection, 'f_cli_contact')?.defaultValue.trim() ??
                '');
    final clientAddr = invoice.clientAddress.trim().isNotEmpty
        ? invoice.clientAddress.trim()
        : '101, Business Tower, MG Road, Bengaluru, Karnataka - 560001';
    final clientGstin = invoice.clientTaxId.trim().isNotEmpty
        ? invoice.clientTaxId.trim()
        : '29AABCA1234B1Z2';
    final clientPhone = invoice.clientPhone.trim().isNotEmpty
        ? invoice.clientPhone.trim()
        : '+91 98800 11223';

    Map<String, dynamic> shippingMap = const {};
    if (invoice.shippingDetailsJson.trim().isNotEmpty &&
        invoice.shippingDetailsJson.trim() != '{}') {
      try {
        final decoded = jsonDecode(invoice.shippingDetailsJson);
        if (decoded is Map<String, dynamic>) shippingMap = decoded;
      } catch (_) {}
    }

    final serviceLocation =
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
                    ? findField(servicesSection, 'f_srv_loc')!
                        .defaultValue
                        .trim()
                    : (invoice.clientAddress.trim().isNotEmpty
                        ? invoice.clientAddress.trim()
                        : 'Tech Park, Whitefield, Bengaluru - 560066')));

    final billingPeriod =
        (findField(servicesSection, 'f_srv_period')
                    ?.defaultValue
                    .trim()
                    .isNotEmpty ==
                true)
            ? findField(servicesSection, 'f_srv_period')!.defaultValue.trim()
            : '${invoice.issueDate.isNotEmpty ? invoice.issueDate : '01 Apr 2025'} - ${invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025'}';

    final gstBreakdown = GstTaxCalculator.calculate(
      taxableAmount: invoice.taxableAmount,
      taxRate: invoice.taxRate,
      taxLabel: invoice.taxLabel,
      taxType: invoice.taxType,
      isRcm: invoice.isRcm,
      supplierPlaceOfSupply: companyAddress,
      clientPlaceOfSupply: invoice.clientAddress,
    );

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
      final defaultTrm =
          findField(termsSection, 'f_trm_lines')?.defaultValue.trim() ?? '';
      if (defaultTrm.isNotEmpty) {
        termsLines.addAll(
          defaultTrm
              .split('\n')
              .map((l) => l.trim())
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

    final body = StringBuffer();

    // A. Header Table (Brand Headline on Left, Company Details on Right)
    if (brandingSection.enabled) {
      final leftParas = <String>[
        if (isFieldVisible(brandingSection, 'f_biz_name'))
          _paragraph(
            uppercaseHeadings ? brandHeadline.toUpperCase() : brandHeadline,
            bold: true,
            size: 34,
            color: primaryHex,
          ),
        if (brandSubtitle.isNotEmpty)
          _paragraph(
            uppercaseHeadings ? brandSubtitle.toUpperCase() : brandSubtitle,
            bold: true,
            size: 20,
            color: primaryHex,
          ),
        if (isFieldVisible(brandingSection, 'f_biz_tagline'))
          _paragraph(
            companyTagline,
            italic: true,
            size: 18,
            color: '64748B',
          ),
      ];

      final rightParas = <String>[
        if (isFieldVisible(brandingSection, 'f_biz_name'))
          _paragraph(
            companyLegalName,
            bold: true,
            size: 20,
            color: '1E293B',
            align: 'right',
          ),
        if (isFieldVisible(brandingSection, 'f_biz_addr'))
          for (final l in companyAddress.split('\n'))
            if (l.trim().isNotEmpty)
              _paragraph(l.trim(), size: 18, color: '64748B', align: 'right'),
        if (isFieldVisible(brandingSection, 'f_biz_gstin') &&
            companyGstin.isNotEmpty)
          _paragraph(
            'GSTIN: $companyGstin',
            size: 18,
            color: '64748B',
            align: 'right',
          ),
        if (isFieldVisible(brandingSection, 'f_biz_pan') &&
            companyPan.isNotEmpty)
          _paragraph(
            'PAN: $companyPan',
            size: 18,
            color: '64748B',
            align: 'right',
          ),
        if (companyPhone.isNotEmpty)
          _paragraph(
            'Tel: $companyPhone',
            size: 18,
            color: '64748B',
            align: 'right',
          ),
        if (companyEmail.isNotEmpty)
          _paragraph(
            companyEmail,
            size: 18,
            color: '64748B',
            align: 'right',
          ),
      ];

      body
        ..write(_twoColumnLayoutTable(leftParas, rightParas))
        ..write(_dividerParagraph(primaryHex));
    }

    // B. Document Identity (Title on Left, Invoice Meta on Right)
    if (identitySection.enabled) {
      final leftParas = <String>[
        _paragraph(
          uppercaseHeadings ? documentTitle.toUpperCase() : documentTitle,
          bold: true,
          size: 38,
          color: '0F172A',
        ),
      ];
      final rightParas = <String>[
        if (isFieldVisible(identitySection, 'f_doc_number'))
          _paragraph(
            'Invoice No. : ${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'INV-2025-0148'}',
            bold: true,
            size: 19,
            color: '1E293B',
            align: 'right',
          ),
        if (isFieldVisible(identitySection, 'f_doc_issue'))
          _paragraph(
            'Issue Date  : ${invoice.issueDate.isNotEmpty ? invoice.issueDate : '15 Apr 2025'}',
            size: 19,
            color: '475569',
            align: 'right',
          ),
        if (isFieldVisible(identitySection, 'f_doc_due'))
          _paragraph(
            'Due Date    : ${invoice.dueDate.isNotEmpty ? invoice.dueDate : '30 Apr 2025'}',
            size: 19,
            color: '475569',
            align: 'right',
          ),
        if (isFieldVisible(identitySection, 'f_doc_po') &&
            invoice.poNumber.trim().isNotEmpty)
          _paragraph(
            'PO No.      : ${invoice.poNumber.trim()}',
            size: 19,
            color: '475569',
            align: 'right',
          ),
      ];
      body
        ..write(_twoColumnLayoutTable(leftParas, rightParas))
        ..write(_paragraph('', size: 10));
    }

    // C. Bill To & Service Location Cards
    if (clientSection.enabled) {
      final billToParas = <String>[
        _paragraph(
          uppercaseHeadings ? 'BILL TO' : 'Bill To',
          bold: true,
          size: 19,
          color: '475569',
        ),
        if (isFieldVisible(clientSection, 'f_cli_name'))
          _paragraph(
            clientDisplayName,
            bold: true,
            size: 22,
            color: '0F172A',
          ),
        if (isFieldVisible(clientSection, 'f_cli_addr'))
          for (final l in clientAddr.split('\n'))
            if (l.trim().isNotEmpty)
              _paragraph(l.trim(), size: 18, color: '475569'),
        if (isFieldVisible(clientSection, 'f_cli_gstin') &&
            clientGstin.isNotEmpty)
          _paragraph('GSTIN: $clientGstin', size: 18, color: '475569'),
        if (isFieldVisible(clientSection, 'f_cli_contact') &&
            clientContactPerson.isNotEmpty)
          _paragraph('Contact: $clientContactPerson', size: 18, color: '475569'),
        if (isFieldVisible(clientSection, 'f_cli_phone') &&
            clientPhone.isNotEmpty)
          _paragraph('Phone: $clientPhone', size: 18, color: '475569'),
      ];

      final srvParas = <String>[
        if (isFieldVisible(servicesSection, 'f_srv_loc')) ...[
          _paragraph(
            uppercaseHeadings ? 'SERVICE LOCATION' : 'Service Location',
            bold: true,
            size: 18,
            color: '64748B',
          ),
          for (final l in serviceLocation.split('\n'))
            if (l.trim().isNotEmpty)
              _paragraph(l.trim(), bold: true, size: 19, color: '1E293B'),
        ],
        if (isFieldVisible(servicesSection, 'f_srv_period')) ...[
          _paragraph(
            uppercaseHeadings ? 'BILLING PERIOD' : 'Billing Period',
            bold: true,
            size: 18,
            color: '64748B',
          ),
          _paragraph(billingPeriod, bold: true, size: 19, color: '1E293B'),
          _paragraph(
            '(${invoice.paymentTerms.isNotEmpty ? invoice.paymentTerms : 'Monthly Billing'})',
            size: 17,
            color: '64748B',
          ),
        ],
      ];

      body
        ..write(
          _twoColumnLayoutTable(
            billToParas,
            srvParas.isNotEmpty ? srvParas : [_paragraph('')],
            shaded: true,
          ),
        )
        ..write(_paragraph('', size: 12));
    }

    // D. Line Items Table
    if (servicesSection.enabled) {
      final allColumns = <({String fieldId, String label, String align})>[
        (
          fieldId: 'f_col_particulars',
          label: columnLabel(servicesSection, 'f_col_particulars', 'Particulars'),
          align: 'left',
        ),
        (
          fieldId: 'f_col_guards',
          label: columnLabel(servicesSection, 'f_col_guards', 'Guards'),
          align: 'center',
        ),
        (
          fieldId: 'f_col_duty',
          label: columnLabel(servicesSection, 'f_col_duty', 'Duty Days'),
          align: 'center',
        ),
        (
          fieldId: 'f_col_rate',
          label: columnLabel(
            servicesSection,
            'f_col_rate',
            'Rate ($currencySymbol)',
          ),
          align: 'right',
        ),
        (
          fieldId: 'f_col_amount',
          label: columnLabel(
            servicesSection,
            'f_col_amount',
            'Amount ($currencySymbol)',
          ),
          align: 'right',
        ),
      ];

      final allRows = <List<String>>[];
      if (invoice.items.isNotEmpty) {
        for (final item in invoice.items) {
          final desc = item.itemDetails.trim().isNotEmpty
              ? '${item.description} (${item.itemDetails.trim()})'
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
        if (isFieldVisible(servicesSection, allColumns[i].fieldId)) {
          visibleIndices.add(i);
        }
      }
      if (visibleIndices.isEmpty) visibleIndices.add(0);

      final cols = [for (final idx in visibleIndices) allColumns[idx]];
      final rows = [
        for (final r in allRows)
          [for (final idx in visibleIndices) r[idx]],
      ];

      final tbl = StringBuffer(
        '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>'
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
        '<w:left w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
        '<w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
        '<w:right w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        '</w:tblBorders></w:tblPr>',
      );

      // Header Row
      tbl.write('<w:tr>');
      for (final col in cols) {
        final hdrText =
            uppercaseHeadings ? col.label.toUpperCase() : col.label;
        tbl.write(
          '<w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$primaryHex"/></w:tcPr>'
          '${_paragraph(hdrText, bold: true, size: 19, color: headerTextHex, align: col.align)}'
          '</w:tc>',
        );
      }
      tbl.write('</w:tr>');

      // Body Rows
      for (final row in rows) {
        tbl.write('<w:tr>');
        for (int c = 0; c < row.length; c++) {
          tbl.write(
            '<w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="FFFFFF"/></w:tcPr>'
            '${_paragraph(row[c], bold: c == 0 || c == row.length - 1, size: 19, color: '1E293B', align: cols[c].align)}'
            '</w:tc>',
          );
        }
        tbl.write('</w:tr>');
      }
      tbl.write('</w:tbl>');
      body
        ..write(tbl.toString())
        ..write(_paragraph('', size: 12));
    }

    // E. Financial Summary & Totals
    if (taxTotalsSection.enabled) {
      final wordsParas = <String>[
        _paragraph(
          uppercaseHeadings ? 'AMOUNT IN WORDS' : 'Amount in Words',
          bold: true,
          size: 18,
          color: '64748B',
        ),
        _paragraph(
          AmountToWords.convert(invoice.total, currency: invoice.currencyCode),
          bold: true,
          italic: true,
          size: 19,
          color: '1E293B',
        ),
      ];

      final totalsParas = <String>[
        if (isFieldVisible(taxTotalsSection, 'f_tot_sub'))
          _paragraph(
            'Subtotal : ${formatAmount(invoice.subtotal)}',
            size: 19,
            color: '475569',
            align: 'right',
          ),
        if (isFieldVisible(taxTotalsSection, 'f_tot_disc'))
          _paragraph(
            'Discount : (-) ${formatAmount(invoice.totalDiscount)}',
            size: 19,
            color: '475569',
            align: 'right',
          ),
        if (isFieldVisible(taxTotalsSection, 'f_tot_taxable'))
          _paragraph(
            'Taxable Amount : ${formatAmount(invoice.taxableAmount)}',
            bold: true,
            size: 19,
            color: '1E293B',
            align: 'right',
          ),
        if (!invoice.isRcm && invoice.taxRate > 0) ...[
          if (!gstBreakdown.isInterState) ...[
            if (isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
              _paragraph(
                'CGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%) : ${formatAmount(invoice.taxAmount / 2)}',
                size: 19,
                color: '475569',
                align: 'right',
              ),
            if (isFieldVisible(taxTotalsSection, 'f_tot_sgst'))
              _paragraph(
                'SGST (${(invoice.taxRate / 2).toStringAsFixed(invoice.taxRate % 2 == 0 ? 0 : 1)}%) : ${formatAmount(invoice.taxAmount / 2)}',
                size: 19,
                color: '475569',
                align: 'right',
              ),
          ] else ...[
            _paragraph(
              'IGST (${invoice.taxRate.toStringAsFixed(invoice.taxRate % 1 == 0 ? 0 : 1)}%) : ${formatAmount(invoice.taxAmount)}',
              size: 19,
              color: '475569',
              align: 'right',
            ),
          ],
        ],
        if (isFieldVisible(taxTotalsSection, 'f_tot_grand'))
          _paragraph(
            '${uppercaseHeadings ? 'GRAND TOTAL' : 'Grand Total'} : ${formatAmount(invoice.total)}',
            bold: true,
            size: 24,
            color: primaryHex,
            align: 'right',
          ),
      ];

      body
        ..write(_twoColumnLayoutTable(wordsParas, totalsParas))
        ..write(_paragraph('', size: 12));
    }

    // F. Payment Details
    if (bankSection.enabled) {
      final bankParas = <String>[
        _paragraph(
          uppercaseHeadings ? 'PAYMENT DETAILS' : 'Payment Details',
          bold: true,
          size: 20,
          color: '0F172A',
        ),
        if (isFieldVisible(bankSection, 'f_bnk_name'))
          _paragraph('Bank Name : $bankName', size: 19, color: '475569'),
        if (isFieldVisible(bankSection, 'f_bnk_ac'))
          _paragraph('A/C No.   : $bankAccount', size: 19, color: '475569'),
        if (isFieldVisible(bankSection, 'f_bnk_ifsc'))
          _paragraph('IFSC      : $bankIfsc', size: 19, color: '475569'),
        if (isFieldVisible(bankSection, 'f_bnk_upi'))
          _paragraph('UPI       : $bankUpi', size: 19, color: '475569'),
      ];
      body
        ..write(_singleBoxTable(bankParas))
        ..write(_paragraph('', size: 12));
    }

    // G. Terms & Signatory
    if (termsSection.enabled) {
      final trmParas = <String>[
        _paragraph(
          uppercaseHeadings ? 'TERMS & CONDITIONS' : 'Terms & Conditions',
          bold: true,
          size: 20,
          color: '0F172A',
        ),
        if (isFieldVisible(termsSection, 'f_trm_lines'))
          for (int i = 0; i < termsLines.length; i++)
            _paragraph(
              RegExp(r'^\d+\.').hasMatch(termsLines[i])
                  ? termsLines[i]
                  : '${i + 1}. ${termsLines[i]}',
              size: 17,
              color: '475569',
            ),
      ];

      final sigParas = <String>[
        if (isFieldVisible(termsSection, 'f_trm_company'))
          _paragraph(
            'For $companyLegalName',
            bold: true,
            size: 19,
            color: '1E293B',
            align: 'right',
          ),
        _paragraph('', size: 24),
        if (isFieldVisible(termsSection, 'f_trm_title'))
          _paragraph(
            signeeTitle,
            bold: true,
            size: 18,
            color: '64748B',
            align: 'right',
          ),
        if (isFieldVisible(termsSection, 'f_trm_auto_stamp'))
          _paragraph(
            '(This is a system generated invoice)',
            size: 15,
            color: '94A3B8',
            align: 'right',
          ),
      ];

      body
        ..write(_twoColumnLayoutTable(trmParas, sigParas))
        ..write(_paragraph('', size: 12));
    }

    // H. Footer
    body
      ..write(_dividerParagraph('E2E8F0'))
      ..write(
        _twoColumnLayoutTable(
          [
            _paragraph(
              'Thank you for your business!',
              italic: true,
              size: 18,
              color: '64748B',
            ),
          ],
          [
            _paragraph(
              'Page 1 of 1',
              size: 17,
              color: '94A3B8',
              align: 'right',
            ),
          ],
        ),
      );

    final archive = Archive()
      ..addFile(_file(
        '[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
      ))
      ..addFile(_file(
        '_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
      ))
      ..addFile(_file(
        'word/document.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr></w:body>
</w:document>''',
      ));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static ArchiveFile _file(String name, String content) {
    final data = utf8.encode(content);
    return ArchiveFile(name, data.length, data);
  }

  static String _twoColumnLayoutTable(
    List<String> leftParagraphs,
    List<String> rightParagraphs, {
    bool shaded = false,
  }) {
    final borderXml = shaded
        ? '<w:tblBorders>'
            '<w:top w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            '<w:left w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            '<w:right w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            '</w:tblBorders>'
        : '<w:tblBorders>'
            '<w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '</w:tblBorders>';
    final shdXml = shaded
        ? '<w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/>'
        : '';
    final leftContent =
        leftParagraphs.isNotEmpty ? leftParagraphs.join() : _paragraph('');
    final rightContent =
        rightParagraphs.isNotEmpty ? rightParagraphs.join() : _paragraph('');
    return '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>$borderXml</w:tblPr>'
        '<w:tr>'
        '<w:tc><w:tcPr><w:tcW w:w="2500" w:type="pct"/>$shdXml</w:tcPr>$leftContent</w:tc>'
        '<w:tc><w:tcPr><w:tcW w:w="2500" w:type="pct"/>$shdXml</w:tcPr>$rightContent</w:tc>'
        '</w:tr></w:tbl>';
  }

  static String _singleBoxTable(List<String> paragraphs) {
    final content = paragraphs.isNotEmpty ? paragraphs.join() : _paragraph('');
    return '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>'
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        '</w:tblBorders></w:tblPr>'
        '<w:tr><w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr>'
        '$content</w:tc></w:tr></w:tbl>';
  }

  static String _dividerParagraph(String colorHex) {
    return '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="12" w:space="4" w:color="$colorHex"/></w:pBdr></w:pPr></w:p>';
  }

  static String _paragraph(
    String text, {
    bool bold = false,
    bool italic = false,
    int size = 20,
    String color = '1E293B',
    String align = 'left',
  }) {
    final safe = _xmlEscape(text);
    final boldXml = bold ? '<w:b/>' : '';
    final italicXml = italic ? '<w:i/>' : '';
    return '<w:p><w:pPr><w:jc w:val="$align"/></w:pPr>'
        '<w:r><w:rPr>$boldXml$italicXml<w:color w:val="$color"/><w:sz w:val="$size"/></w:rPr>'
        '<w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
