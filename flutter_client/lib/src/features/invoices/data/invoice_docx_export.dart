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
  }) {
    bool show(String key) => localSettings[key] != false;
    final body = StringBuffer()
      ..write(_paragraph(template?.title ?? 'INVOICE', bold: true, size: 32))
      ..write(_paragraph('Invoice ${invoice.invoiceNumber}', bold: true))
      ..write(_paragraph(''))
      ..write(_paragraph('BILL TO', bold: true))
      ..write(_paragraph(invoice.clientName))
      ..write(_paragraph(''));
    if (show('showStatus')) {
      body.write(_paragraph('Status: ${invoice.status}'));
    }
    if (show('showIssueDate')) {
      body.write(_paragraph('Issue date: ${invoice.issueDate}'));
    }
    if (show('showDueDate')) {
      body.write(_paragraph('Due date: ${invoice.dueDate}'));
    }
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
      body.write(_paragraph(invoice.clientTaxId));
    }
    if (show('showPoNumber') && invoice.poNumber.isNotEmpty) {
      body.write(_paragraph('PO: ${invoice.poNumber}'));
    }
    final shipping = _shippingLines(invoice.shippingDetailsJson);
    if (shipping.isNotEmpty) {
      body
        ..write(_paragraph('Shipping details', bold: true))
        ..writeAll(shipping.map(_paragraph));
    }
    body
      ..write(_paragraph(''))
      ..write(_paragraph(
        <String>[
          template?.itemHeader ?? 'Description',
          if (show('showItemQty')) template?.quantityHeader ?? 'Qty',
          if (show('showItemRate')) template?.rateHeader ?? 'Rate',
          if (show('showItemDiscount')) 'Discount',
          if (show('showItemTax')) 'Tax',
          template?.amountHeader ?? 'Amount',
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
          if (show('showItemDiscount')) '${item.discountRate}%',
          if (show('showItemTax')) '${item.taxRate}%',
          '${invoice.currencySymbol}${item.total.toStringAsFixed(2)}',
        ].join(' | '),
      ));
    }
    body
      ..write(_paragraph(''))
      ..write(_paragraph(
        'Subtotal: ${invoice.currencySymbol}${invoice.subtotal.toStringAsFixed(2)}',
      ));
    if (template?.showTaxBreakdown != false) {
      body.write(_paragraph(
        '${invoice.taxLabel}: ${invoice.currencySymbol}${invoice.taxAmount.toStringAsFixed(2)}',
      ));
    }
    body
      ..write(_paragraph(
          'Total: ${invoice.currencySymbol}${invoice.total.toStringAsFixed(2)}',
          bold: true))
      ..write(_paragraph(
          'Amount paid: ${invoice.currencySymbol}${invoice.amountPaid.toStringAsFixed(2)}'))
      ..write(_paragraph(
          'Balance due: ${invoice.currencySymbol}${invoice.balanceDue.toStringAsFixed(2)}',
          bold: true));
    if (show('showNotes') &&
        invoice.notes.isNotEmpty) {
      body
        ..write(_paragraph('Notes', bold: true))
        ..write(_paragraph(invoice.notes));
    }
    if (show('showTerms') &&
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
