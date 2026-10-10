import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

import '../../templates/data/template_config.dart';
import 'invoice.dart';

class InvoiceDocxExport {
  InvoiceDocxExport._();

  static Uint8List build(
    Invoice invoice, {
    TemplateConfig? template,
    Map<String, Object?> localSettings = const <String, Object?>{},
    Map<String, dynamic> businessProfile = const <String, dynamic>{},
  }) {
    bool show(String key, {bool fallback = true}) {
      if (localSettings.containsKey(key)) {
        return localSettings[key] == true;
      }
      return fallback;
    }

    final showBillFrom = show('showBillFrom', fallback: true) && (template?.showBillFrom ?? true);
    final showBank = show('showBankDetails', fallback: true) && (template?.showBankDetails ?? true);
    final showBillTo = show('showBillTo', fallback: true) && (template?.showBillTo ?? true);

    final bizName = businessProfile['businessName']?.toString().trim().isNotEmpty == true
        ? businessProfile['businessName'].toString()
        : (localSettings['businessName']?.toString().trim().isNotEmpty == true
            ? localSettings['businessName'].toString()
            : '');
    final bizLegalName = businessProfile['legalName']?.toString().trim().isNotEmpty == true
        ? businessProfile['legalName'].toString()
        : '';
    final bizAddress = businessProfile['address']?.toString().trim().isNotEmpty == true
        ? businessProfile['address'].toString()
        : (localSettings['businessAddress']?.toString().trim().isNotEmpty == true
            ? localSettings['businessAddress'].toString()
            : '');
    final bizGstin = businessProfile['gstin']?.toString().trim().isNotEmpty == true
        ? businessProfile['gstin'].toString()
        : (businessProfile['taxId']?.toString().trim().isNotEmpty == true
            ? businessProfile['taxId'].toString()
            : (localSettings['businessGstin']?.toString().trim().isNotEmpty == true
                ? localSettings['businessGstin'].toString()
                : ''));
    final bizPan = businessProfile['panNumber']?.toString().trim().isNotEmpty == true
        ? businessProfile['panNumber'].toString()
        : (localSettings['businessPan']?.toString().trim().isNotEmpty == true
            ? localSettings['businessPan'].toString()
            : '');
    final bizPhone = businessProfile['phone']?.toString().trim().isNotEmpty == true
        ? businessProfile['phone'].toString()
        : (localSettings['businessPhone']?.toString().trim().isNotEmpty == true
            ? localSettings['businessPhone'].toString()
            : '');
    final bizEmail = businessProfile['email']?.toString().trim().isNotEmpty == true
        ? businessProfile['email'].toString()
        : (localSettings['businessEmail']?.toString().trim().isNotEmpty == true
            ? localSettings['businessEmail'].toString()
            : '');

    final bankName = businessProfile['bankName']?.toString().trim().isNotEmpty == true
        ? businessProfile['bankName'].toString()
        : (localSettings['bankName']?.toString().trim().isNotEmpty == true
            ? localSettings['bankName'].toString()
            : '');
    final accountHolder = businessProfile['accountHolder']?.toString().trim().isNotEmpty == true
        ? businessProfile['accountHolder'].toString()
        : (localSettings['accountHolder']?.toString().trim().isNotEmpty == true
            ? localSettings['accountHolder'].toString()
            : '');
    final accountNumber = businessProfile['accountNumber']?.toString().trim().isNotEmpty == true
        ? businessProfile['accountNumber'].toString()
        : (localSettings['accountNumber']?.toString().trim().isNotEmpty == true
            ? localSettings['accountNumber'].toString()
            : '');
    final ifscCode = businessProfile['ifscCode']?.toString().trim().isNotEmpty == true
        ? businessProfile['ifscCode'].toString()
        : (localSettings['ifscCode']?.toString().trim().isNotEmpty == true
            ? localSettings['ifscCode'].toString()
            : '');
    final upiId = businessProfile['upiId']?.toString().trim().isNotEmpty == true
        ? businessProfile['upiId'].toString()
        : (localSettings['upiId']?.toString().trim().isNotEmpty == true
            ? localSettings['upiId'].toString()
            : '');

    List<Map<String, dynamic>> customFields(String key) {
      final raw = localSettings[key];
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

    final customTitle = localSettings['customTitle']?.toString().trim();
    final title = (customTitle != null && customTitle.isNotEmpty)
        ? customTitle
        : template?.title ?? 'INVOICE';
    final invoiceNoLabel =
        localSettings['customInvoiceNoLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customInvoiceNoLabel'].toString()
            : 'Invoice';
    final billToLabel =
        localSettings['customBillToLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customBillToLabel'].toString()
            : 'BILL TO';
    final dateLabel =
        localSettings['customDateLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customDateLabel'].toString()
            : 'Creation date';
    final dueDateLabel =
        localSettings['customDueDateLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customDueDateLabel'].toString()
            : 'Due date';
    final itemHeader =
        localSettings['customItemHeader']?.toString().trim().isNotEmpty == true
            ? localSettings['customItemHeader'].toString()
            : template?.itemHeader ?? 'Description';
    final qtyHeader =
        localSettings['customQtyHeader']?.toString().trim().isNotEmpty == true
            ? localSettings['customQtyHeader'].toString()
            : template?.quantityHeader ?? 'Qty';
    final rateHeader =
        localSettings['customRateHeader']?.toString().trim().isNotEmpty == true
            ? localSettings['customRateHeader'].toString()
            : template?.rateHeader ?? 'Rate';
    final amountHeader =
        localSettings['customAmountHeader']?.toString().trim().isNotEmpty == true
            ? localSettings['customAmountHeader'].toString()
            : template?.amountHeader ?? 'Amount';

    final customCols = customFields('customColumns_items')
        .where((c) => c['isVisible'] != false)
        .toList();

    final body = StringBuffer();

    if (showBillFrom && bizName.isNotEmpty) {
      body.write(_paragraph(bizName, bold: true, size: 28));
      if (bizLegalName.isNotEmpty && bizLegalName != bizName) {
        body.write(_paragraph(bizLegalName, size: 20));
      }
      if (bizAddress.isNotEmpty) {
        body.write(_paragraph(bizAddress, size: 18));
      }
      if (bizGstin.isNotEmpty || bizPan.isNotEmpty) {
        body.write(_paragraph([if (bizGstin.isNotEmpty) 'GSTIN: $bizGstin', if (bizPan.isNotEmpty) 'PAN: $bizPan'].join('  |  '), size: 18));
      }
      if (bizPhone.isNotEmpty || bizEmail.isNotEmpty) {
        body.write(_paragraph([if (bizPhone.isNotEmpty) bizPhone, if (bizEmail.isNotEmpty) bizEmail].join(' • '), size: 18));
      }
      body.write(_paragraph(''));
    }

    body
      ..write(_paragraph(title, bold: true, size: 32))
      ..write(_paragraph('$invoiceNoLabel ${invoice.invoiceNumber}', bold: true))
      ..write(_paragraph(''));
    if (show('showStatus', fallback: false)) {
      body.write(_paragraph('Status: ${invoice.status}'));
    }
    if (show('showIssueDate', fallback: true)) {
      body.write(_paragraph('$dateLabel: ${invoice.issueDate}'));
    }
    if (show('showDueDate', fallback: false)) {
      body.write(_paragraph('$dueDateLabel: ${invoice.dueDate}'));
    }
    if (show('showPoNumber', fallback: false) && invoice.poNumber.isNotEmpty) {
      body.write(_paragraph('PO: ${invoice.poNumber}'));
    }
    for (final field in customFields('customFields_details')) {
      if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true) {
        body.write(_paragraph('${field['label']}: ${field['value'] ?? ''}'));
      }
    }

    if (showBillTo) {
      body
        ..write(_paragraph(''))
        ..write(_paragraph(billToLabel, bold: true))
        ..write(_paragraph(invoice.clientName));
      if (show('showClientCompany') && invoice.clientCompany.isNotEmpty) {
        body.write(_paragraph(invoice.clientCompany));
      }
      if (show('showClientEmail') && invoice.clientEmail.isNotEmpty) {
        body.write(_paragraph(invoice.clientEmail));
      }
      if (show('showClientPhone') && invoice.clientPhone.isNotEmpty) {
        body.write(_paragraph(invoice.clientPhone));
      }
      if (show('showClientAddress') && invoice.clientAddress.isNotEmpty) {
        body.write(_paragraph(invoice.clientAddress));
      }
      if (show('showClientTaxId') && invoice.clientTaxId.isNotEmpty) {
        body.write(_paragraph('Tax ID: ${invoice.clientTaxId}'));
      }
      for (final field in customFields('customFields_billing')) {
        if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true) {
          body.write(_paragraph('${field['label']}: ${field['value'] ?? ''}'));
        }
      }
    }

    final shipping = _shippingLines(invoice.shippingDetailsJson);
    if (shipping.isNotEmpty && (show('showShippingSection', fallback: false) || (template?.showShipping ?? false))) {
      body
        ..write(_paragraph('Shipping details', bold: true))
        ..writeAll(shipping.map(_paragraph));
    }
    body
      ..write(_paragraph(''))
      ..write(_paragraph(
        <String>[
          itemHeader,
          if (show('showItemQty')) qtyHeader,
          if (show('showItemRate')) rateHeader,
          if (show('showItemDiscount', fallback: false))
            localSettings['customDiscountHeader']?.toString() ?? 'Discount',
          if (show('showItemTax'))
            localSettings['customTaxHeader']?.toString() ?? 'Tax',
          for (final col in customCols)
            col['label']?.toString() ?? '',
          amountHeader,
        ].join(' | '),
        bold: true,
      ));

    for (final item in invoice.items) {
      body.write(_paragraph(
        <String>[
          item.description,
          if (show('showItemQty'))
            '${item.quantity}${show('showItemUnit') ? ' ${item.unit}' : ''}',
          if (show('showItemRate'))
            '${invoice.currencySymbol}${item.unitPrice.toStringAsFixed(2)}',
          if (show('showItemDiscount', fallback: false)) '${item.discountRate}%',
          if (show('showItemTax')) '${item.taxRate}%',
          for (final col in customCols)
            col['value']?.toString() ?? '-',
          '${invoice.currencySymbol}${item.total.toStringAsFixed(2)}',
        ].join(' | '),
      ));
    }
    body
      ..write(_paragraph(''))
      ..write(_paragraph(
        '${localSettings['customSubtotalLabel']?.toString().isNotEmpty == true ? localSettings['customSubtotalLabel'] : 'Subtotal'}: ${invoice.currencySymbol}${invoice.subtotal.toStringAsFixed(2)}',
      ));
    if (invoice.totalDiscount != 0 && show('showDiscount', fallback: true)) {
      body.write(_paragraph(
        '${localSettings['customDiscountLabel']?.toString().isNotEmpty == true ? localSettings['customDiscountLabel'] : 'Discount'}: -${invoice.currencySymbol}${invoice.totalDiscount.toStringAsFixed(2)}',
      ));
    }
    if (template?.showTaxBreakdown != false && show('showTax', fallback: true)) {
      body.write(_paragraph(
        '${localSettings['customTaxLabel']?.toString().isNotEmpty == true ? localSettings['customTaxLabel'] : '${invoice.taxLabel} (${invoice.taxRate}%)'}: ${invoice.currencySymbol}${invoice.taxAmount.toStringAsFixed(2)}',
      ));
    }
    if (invoice.shippingFee != 0 || show('showShippingFee', fallback: false)) {
      body.write(_paragraph(
        '${localSettings['customShippingLabel']?.toString().isNotEmpty == true ? localSettings['customShippingLabel'] : 'Shipping'}: ${invoice.currencySymbol}${invoice.shippingFee.toStringAsFixed(2)}',
      ));
    }
    if (invoice.additionalCharges != 0 || show('showAdditionalCharges', fallback: false)) {
      body.write(_paragraph(
        '${localSettings['customAdjustmentsLabel']?.toString().isNotEmpty == true ? localSettings['customAdjustmentsLabel'] : 'Additional charges'}: ${invoice.currencySymbol}${invoice.additionalCharges.toStringAsFixed(2)}',
      ));
    }
    if (invoice.roundOff != 0 || show('showRoundOff', fallback: false)) {
      body.write(_paragraph(
        '${localSettings['customRoundOffLabel']?.toString().isNotEmpty == true ? localSettings['customRoundOffLabel'] : 'Round off'}: ${invoice.currencySymbol}${invoice.roundOff.toStringAsFixed(2)}',
      ));
    }
    for (final adj in customFields('customFields_adjustments')) {
      if (adj['isVisible'] != false && adj['label']?.toString().isNotEmpty == true) {
        body.write(_paragraph(
          '${adj['label']}: ${adj['value'] != null && adj['value'].toString().isNotEmpty ? '${invoice.currencySymbol}${adj['value']}' : '-'}',
        ));
      }
    }
    body
      ..write(_paragraph(
          '${localSettings['customTotalLabel']?.toString().isNotEmpty == true ? localSettings['customTotalLabel'] : 'Total'}: ${invoice.currencySymbol}${invoice.total.toStringAsFixed(2)}',
          bold: true))
      ..write(_paragraph(
          '${localSettings['customAmountPaidLabel']?.toString().isNotEmpty == true ? localSettings['customAmountPaidLabel'] : 'Amount paid'}: ${invoice.currencySymbol}${invoice.amountPaid.toStringAsFixed(2)}'))
      ..write(_paragraph(
          '${localSettings['customBalanceDueLabel']?.toString().isNotEmpty == true ? localSettings['customBalanceDueLabel'] : 'Balance due'}: ${invoice.currencySymbol}${invoice.balanceDue.toStringAsFixed(2)}',
          bold: true));

    if (showBank &&
        (bankName.isNotEmpty ||
            accountNumber.isNotEmpty ||
            upiId.isNotEmpty)) {
      body
        ..write(_paragraph(''))
        ..write(_paragraph('Bank and payment details', bold: true));
      if (bankName.isNotEmpty) body.write(_paragraph('Bank: $bankName'));
      if (accountHolder.isNotEmpty) {
        body.write(_paragraph('Account name: $accountHolder'));
      }
      if (accountNumber.isNotEmpty) {
        body.write(_paragraph('Account number: $accountNumber', bold: true));
      }
      if (ifscCode.isNotEmpty) {
        body.write(_paragraph('IFSC / SWIFT: $ifscCode'));
      }
      if (upiId.isNotEmpty) body.write(_paragraph('UPI ID: $upiId', bold: true));
    }

    if (show('showNotes') &&
        (template?.showNotes ?? true) &&
        invoice.notes.isNotEmpty) {
      body
        ..write(_paragraph('Notes', bold: true))
        ..write(_paragraph(invoice.notes));
    }
    if (show('showTerms') &&
        (template?.showTerms ?? true) &&
        invoice.terms.isNotEmpty) {
      body
        ..write(_paragraph('Terms and conditions', bold: true))
        ..write(_paragraph(invoice.terms));
    }
    if (show('showPaymentInstructions') &&
        template?.showPaymentInstructions != false &&
        invoice.paymentInstructions.isNotEmpty) {
      body
        ..write(_paragraph('Payment instructions', bold: true))
        ..write(_paragraph(invoice.paymentInstructions));
    }
    for (final field in customFields('customFields_terms')) {
      if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true) {
        body
          ..write(_paragraph(field['label'].toString(), bold: true))
          ..write(_paragraph(field['value']?.toString() ?? ''));
      }
    }
    if (template?.footer.isNotEmpty == true) {
      body.write(_paragraph(template!.footer));
    }

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
<w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="850" w:right="850" w:bottom="850" w:left="850"/></w:sectPr></w:body>
</w:document>''',
      ));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static ArchiveFile _file(String name, String content) {
    final data = utf8.encode(content);
    return ArchiveFile(name, data.length, data);
  }

  static List<String> _shippingLines(String json) {
    if (json.trim().isEmpty || json.trim() == '{}') return const [];
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> || decoded['isEnabled'] != true) {
      return const [];
    }
    const fields = <String, String>{
      'shippingAddress': 'Shipping address',
      'deliveryAddress': 'Delivery address',
      'shippingMethod': 'Shipping method',
      'courier': 'Carrier',
      'trackingNumber': 'Tracking',
      'expectedDelivery': 'Expected delivery',
    };
    return fields.entries
        .where((entry) =>
            decoded[entry.key]?.toString().trim().isNotEmpty == true)
        .map((entry) => '${entry.value}: ${decoded[entry.key]}')
        .toList(growable: false);
  }

  static String _paragraph(String text, {bool bold = false, int size = 22}) {
    final safe = _xmlEscape(text);
    final boldXml = bold ? '<w:b/>' : '';
    return '<w:p><w:r><w:rPr>$boldXml<w:sz w:val="$size"/></w:rPr>'
        '<w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
