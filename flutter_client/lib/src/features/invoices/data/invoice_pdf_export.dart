import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../templates/data/template_config.dart';
import 'invoice.dart';

class InvoicePdfExport {
  InvoicePdfExport._();

  static Future<Uint8List> build(
    Invoice invoice, {
    TemplateConfig? template,
    Map<String, Object?> localSettings = const <String, Object?>{},
    Map<String, dynamic> businessProfile = const <String, dynamic>{},
  }) async {
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

    final logo = (show('showLogo') && (template?.showLogo ?? true))
        ? _memoryImage(localSettings['invoiceLogo'])
        : null;
    final stamp =
        show('showStamp') ? _memoryImage(localSettings['invoiceStamp']) : null;
    final signature = (show('showSignature') && (template?.showSignature ?? true))
        ? _memoryImage(localSettings['invoiceSignature'])
        : null;
    final document = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: invoice.clientName,
      subject: 'Invoice ${invoice.invoiceNumber}',
    );
    final brand = PdfColor.fromInt(_parseColor(template?.color ?? '#1E3A8A'));
    final secondary =
        PdfColor.fromInt(_parseColor(template?.secondaryColor ?? '#0D9488'));
    final customTitle = localSettings['customTitle']?.toString().trim();
    final title = (customTitle != null && customTitle.isNotEmpty)
        ? customTitle
        : template?.title ?? 'INVOICE';
    final invoiceNoLabel =
        localSettings['customInvoiceNoLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customInvoiceNoLabel'].toString()
            : 'Invoice';
    final dateLabel =
        localSettings['customDateLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customDateLabel'].toString()
            : 'Creation date';
    final dueDateLabel =
        localSettings['customDueDateLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customDueDateLabel'].toString()
            : 'Due date';
    final billToLabel =
        localSettings['customBillToLabel']?.toString().trim().isNotEmpty == true
            ? localSettings['customBillToLabel'].toString()
            : 'BILL TO';
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

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null) ...[
                      pw.SizedBox(
                        height: 48,
                        width: 150,
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                    if (showBillFrom && bizName.isNotEmpty) ...[
                      pw.Text(
                        bizName,
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                        pw.Text(bizLegalName, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      if (bizAddress.isNotEmpty)
                        pw.Text(bizAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      if (bizGstin.isNotEmpty || bizPan.isNotEmpty)
                        pw.Text([if (bizGstin.isNotEmpty) 'GSTIN: $bizGstin', if (bizPan.isNotEmpty) 'PAN: $bizPan'].join('  |  '), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                        pw.Text([if (bizPhone.isNotEmpty) bizPhone, if (bizEmail.isNotEmpty) bizEmail].join(' • '), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                    ],
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        color: brand,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('$invoiceNoLabel ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    if (show('showStatus', fallback: false))
                      pw.Text('Status: ${invoice.status}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (show('showIssueDate', fallback: true))
                    pw.Text('$dateLabel: ${invoice.issueDate}', style: const pw.TextStyle(fontSize: 9)),
                  if (show('showDueDate', fallback: false))
                    pw.Text('$dueDateLabel: ${invoice.dueDate}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if (show('showPoNumber', fallback: false) && invoice.poNumber.isNotEmpty)
                    pw.Text('PO: ${invoice.poNumber}', style: const pw.TextStyle(fontSize: 8.5)),
                  for (final field in customFields('customFields_details'))
                    if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                      pw.Text('${field['label']}: ${field['value'] ?? ''}', style: const pw.TextStyle(fontSize: 8.5)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Container(height: 2, color: secondary),
          pw.SizedBox(height: 18),
          if (showBillTo) ...[
            pw.Text(
              billToLabel,
              style: pw.TextStyle(
                color: brand,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              invoice.clientName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (show('showClientCompany') && invoice.clientCompany.isNotEmpty)
              pw.Text(invoice.clientCompany),
            if (show('showClientEmail') && invoice.clientEmail.isNotEmpty)
              pw.Text(invoice.clientEmail),
            if (show('showClientPhone') && invoice.clientPhone.isNotEmpty)
              pw.Text(invoice.clientPhone),
            if (show('showClientAddress') && invoice.clientAddress.isNotEmpty)
              pw.Text(invoice.clientAddress),
            if (show('showClientTaxId') && invoice.clientTaxId.isNotEmpty)
              pw.Text('Tax ID: ${invoice.clientTaxId}'),
            for (final field in customFields('customFields_billing'))
              if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                pw.Text('${field['label']}: ${field['value'] ?? ''}'),
          ],
          if (show('showShippingSection', fallback: false) || (template?.showShipping ?? false))
            ..._shippingWidgets(invoice.shippingDetailsJson),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
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
            ],
            data: invoice.items
                .map(
                  (item) => <String>[
                    item.description,
                    if (show('showItemQty'))
                      '${_quantity(item.quantity)}'
                          '${show('showItemUnit') ? ' ${item.unit}' : ''}',
                    if (show('showItemRate'))
                      _money(item.unitPrice, invoice.currencySymbol),
                    if (show('showItemDiscount', fallback: false)) '${item.discountRate}%',
                    if (show('showItemTax')) '${item.taxRate}%',
                    for (final col in customCols)
                      col['value']?.toString() ?? '-',
                    _money(item.total, invoice.currencySymbol),
                  ],
                )
                .toList(growable: false),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(color: brand),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            cellAlignments: {
              for (var index = 1;
                  index <
                      1 +
                          (show('showItemQty') ? 1 : 0) +
                          (show('showItemRate') ? 1 : 0) +
                          (show('showItemDiscount', fallback: false) ? 1 : 0) +
                          (show('showItemTax') ? 1 : 0) +
                          customCols.length +
                          1;
                  index++)
                index: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 260,
              child: pw.Column(
                children: [
                  _line(
                    localSettings['customSubtotalLabel']?.toString().isNotEmpty == true
                        ? localSettings['customSubtotalLabel'].toString()
                        : 'Subtotal',
                    _money(invoice.subtotal, invoice.currencySymbol),
                  ),
                  if (invoice.totalDiscount != 0 && show('showDiscount', fallback: true))
                    _line(
                      localSettings['customDiscountLabel']?.toString().isNotEmpty == true
                          ? localSettings['customDiscountLabel'].toString()
                          : 'Discount',
                      '-${_money(invoice.totalDiscount, invoice.currencySymbol)}',
                    ),
                  if (template?.showTaxBreakdown != false && show('showTax', fallback: true))
                    _line(
                      localSettings['customTaxLabel']?.toString().isNotEmpty == true
                          ? localSettings['customTaxLabel'].toString()
                          : '${invoice.taxLabel} (${invoice.taxRate}%)',
                      _money(invoice.taxAmount, invoice.currencySymbol),
                    ),
                  if (invoice.shippingFee != 0 || show('showShippingFee', fallback: false))
                    _line(
                      localSettings['customShippingLabel']?.toString().isNotEmpty == true
                          ? localSettings['customShippingLabel'].toString()
                          : 'Shipping',
                      _money(invoice.shippingFee, invoice.currencySymbol),
                    ),
                  if (invoice.additionalCharges != 0 || show('showAdditionalCharges', fallback: false))
                    _line(
                      localSettings['customAdjustmentsLabel']?.toString().isNotEmpty == true
                          ? localSettings['customAdjustmentsLabel'].toString()
                          : 'Additional charges',
                      _money(invoice.additionalCharges, invoice.currencySymbol),
                    ),
                  if (invoice.roundOff != 0 || show('showRoundOff', fallback: false))
                    _line(
                      localSettings['customRoundOffLabel']?.toString().isNotEmpty == true
                          ? localSettings['customRoundOffLabel'].toString()
                          : 'Round off',
                      _money(invoice.roundOff, invoice.currencySymbol),
                    ),
                  for (final adj in customFields('customFields_adjustments'))
                    if (adj['isVisible'] != false && adj['label']?.toString().isNotEmpty == true)
                      _line(
                        adj['label'] as String,
                        adj['value'] != null && adj['value'].toString().isNotEmpty
                            ? '${invoice.currencySymbol}${adj['value']}'
                            : '-',
                      ),
                  pw.Divider(color: brand),
                  _line(
                    localSettings['customTotalLabel']?.toString().isNotEmpty == true
                        ? localSettings['customTotalLabel'].toString()
                        : 'Total',
                    _money(invoice.total, invoice.currencySymbol),
                    bold: true,
                  ),
                  if (show('showAmountPaid', fallback: true))
                    _line(
                      localSettings['customAmountPaidLabel']?.toString().isNotEmpty == true
                          ? localSettings['customAmountPaidLabel'].toString()
                          : 'Paid',
                      _money(invoice.amountPaid, invoice.currencySymbol),
                    ),
                  if (show('showBalanceDue', fallback: true))
                    _line(
                      localSettings['customBalanceDueLabel']?.toString().isNotEmpty == true
                          ? localSettings['customBalanceDueLabel'].toString()
                          : 'Balance due',
                      _money(invoice.balanceDue, invoice.currencySymbol),
                      bold: true,
                    ),
                ],
              ),
            ),
          ),
          if (showBank &&
              (bankName.isNotEmpty ||
                  accountNumber.isNotEmpty ||
                  upiId.isNotEmpty)) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BANK & PAYMENT DETAILS',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: brand,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 12,
                    children: [
                      if (bankName.isNotEmpty)
                        pw.Text('Bank: $bankName', style: const pw.TextStyle(fontSize: 8.5)),
                      if (accountHolder.isNotEmpty)
                        pw.Text('A/C Name: $accountHolder', style: const pw.TextStyle(fontSize: 8.5)),
                      if (accountNumber.isNotEmpty)
                        pw.Text('A/C No: $accountNumber', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      if (ifscCode.isNotEmpty)
                        pw.Text('IFSC / SWIFT: $ifscCode', style: const pw.TextStyle(fontSize: 8.5)),
                      if (upiId.isNotEmpty)
                        pw.Text('UPI ID: $upiId', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          for (final foot in customFields('customFields_footer'))
            if (foot['isVisible'] != false && foot['label']?.toString().isNotEmpty == true) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                foot['label'].toString().toUpperCase(),
                style: pw.TextStyle(
                  color: brand,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (foot['value']?.toString().isNotEmpty == true)
                pw.Text(foot['value'].toString()),
            ],
          if (show('showNotes') &&
              (template?.showNotes ?? true) &&
              invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              localSettings['customNotesLabel']?.toString().trim().isNotEmpty == true
                  ? localSettings['customNotesLabel'].toString()
                  : 'Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes),
          ],
          if (show('showTerms') &&
              (template?.showTerms ?? true) &&
              invoice.terms.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              localSettings['customTermsLabel']?.toString().trim().isNotEmpty == true
                  ? localSettings['customTermsLabel'].toString()
                  : 'Terms and conditions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoice.terms),
          ],
          if (show('showPaymentInstructions') &&
              template?.showPaymentInstructions != false &&
              invoice.paymentInstructions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Payment instructions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoice.paymentInstructions),
          ],
          if (signature != null || stamp != null) ...[
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (signature != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 60,
                        child: pw.Image(signature, fit: pw.BoxFit.contain),
                      ),
                      pw.Container(width: 150, height: 0.8, color: PdfColors.grey500),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        localSettings['signeeTitle']?.toString().trim().isNotEmpty == true
                            ? localSettings['signeeTitle'].toString()
                            : 'Authorized Signatory',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      if (localSettings['signeeName']?.toString().trim().isNotEmpty == true)
                        pw.Text(
                          localSettings['signeeName'].toString(),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                    ],
                  ),
                if (stamp != null) ...[
                  pw.SizedBox(width: 16),
                  pw.Container(
                    width: 90,
                    height: 90,
                    child: pw.Image(stamp, fit: pw.BoxFit.contain),
                  ),
                ],
              ],
            ),
          ],
          if (template?.footer.isNotEmpty == true) ...[
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              template!.footer,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _line(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  static String _quantity(double quantity) =>
      quantity == quantity.roundToDouble()
          ? quantity.toStringAsFixed(0)
          : quantity.toString();

  static String _money(double amount, String symbol) =>
      '$symbol${amount.toStringAsFixed(2)}';

  static pw.MemoryImage? _memoryImage(Object? value) {
    final encoded = value?.toString() ?? '';
    if (encoded.isEmpty) return null;
    return pw.MemoryImage(base64Decode(encoded));
  }

  static List<pw.Widget> _shippingWidgets(String json) {
    if (json.trim().isEmpty || json.trim() == '{}') return const [];
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invoice shipping details are invalid.');
    }
    if (decoded['isEnabled'] != true) return const [];
    const fields = <String, String>{
      'shippingAddress': 'Shipping address',
      'deliveryAddress': 'Delivery address',
      'shippingMethod': 'Shipping method',
      'courier': 'Carrier',
      'trackingNumber': 'Tracking',
      'expectedDelivery': 'Expected delivery',
    };
    return [
      pw.SizedBox(height: 8),
      pw.Text(
        decoded['sectionTitle']?.toString().trim().isNotEmpty == true
            ? decoded['sectionTitle'].toString()
            : 'Shipping details',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      for (final entry in fields.entries)
        if (decoded[entry.key]?.toString().trim().isNotEmpty == true)
          pw.Text('${entry.value}: ${decoded[entry.key]}'),
    ];
  }

  static int _parseColor(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return const Color(0xFF1E3A8A).toARGB32();
    return normalized.length == 6 ? 0xFF000000 | parsed : parsed;
  }
}
