import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
        .replaceAll('₹', 'Rs.')
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
    return text.trim();
  }

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

    final paymentLink = businessProfile['paymentLink']?.toString().trim().isNotEmpty == true
        ? businessProfile['paymentLink'].toString()
        : (localSettings['paymentLink']?.toString().trim().isNotEmpty == true
            ? localSettings['paymentLink'].toString()
            : '');
    final qrPayload = upiId.isNotEmpty
        ? 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(bizName.isNotEmpty ? bizName : "Merchant")}&am=${(invoice.balanceDue > 0 ? invoice.balanceDue : invoice.total).toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Invoice ${invoice.invoiceNumber}")}'
        : paymentLink;

    // Currency Symbol Resolution (INR / Rs. Latin-1 safe)
    final rawCurrency = localSettings['defaultCurrencySymbol']?.toString().trim().isNotEmpty == true
        ? localSettings['defaultCurrencySymbol'].toString().trim()
        : (localSettings['defaultCurrency']?.toString().trim().isNotEmpty == true
            ? localSettings['defaultCurrency'].toString().trim()
            : (invoice.currencySymbol.trim().isNotEmpty && invoice.currencySymbol.trim() != r'$'
                ? invoice.currencySymbol.trim()
                : 'INR'));
    final currencySymbol = (rawCurrency == '₹' || rawCurrency.toUpperCase() == 'INR') ? 'Rs. ' : rawCurrency;

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
    final customQrImage = (show('showQrCode') && (template?.showQrCode ?? true))
        ? _memoryImage(localSettings['invoiceQrCode'])
        : null;
    final hasCustomQr = customQrImage != null;
    final hasUpiOrLink = upiId.isNotEmpty || paymentLink.isNotEmpty;
    final shouldShowQr = (template?.showQrCode ?? true) &&
        (localSettings['showQrCode'] != false) &&
        (hasCustomQr || hasUpiOrLink);

    final document = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: _cleanText(invoice.clientName),
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
    final dutyHeader =
        localSettings['customDutyHeader']?.toString().trim().isNotEmpty == true
            ? localSettings['customDutyHeader'].toString()
            : (template?.dutyHeader.isNotEmpty == true ? template!.dutyHeader : 'Duty / Days');
    final showDuty = show('showItemDuty') || invoice.items.any((it) => it.dutyCount > 0);

    // Font selection based on template
    pw.Font baseFont;
    pw.Font boldFont;
    final fontChoice = (template?.font ?? '').toLowerCase();
    if (fontChoice.contains('times')) {
      baseFont = pw.Font.times();
      boldFont = pw.Font.timesBold();
    } else if (fontChoice.contains('courier') || fontChoice.contains('consolas')) {
      baseFont = pw.Font.courier();
      boldFont = pw.Font.courierBold();
    } else {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) => [
          // -------------------------------------------------------------------
          // HEADER SECTION (Branch on template?.headerLayout)
          // -------------------------------------------------------------------
          () {
            if (template?.headerLayout == 'classic') {
              return pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      pw.SizedBox(
                        height: 40,
                        width: 140,
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 6),
                    ],
                    if (showBillFrom && bizName.isNotEmpty) ...[
                      pw.Text(
                        _cleanText(bizName),
                        style: pw.TextStyle(
                          color: brand,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                        pw.Text(_cleanText(bizLegalName), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                      if (bizAddress.isNotEmpty)
                        pw.Text(_cleanText(bizAddress), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                      if (bizGstin.isNotEmpty || bizPan.isNotEmpty || bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                        pw.Text(
                          [
                            if (bizGstin.isNotEmpty) 'GSTIN: ${_cleanText(bizGstin)}',
                            if (bizPan.isNotEmpty) 'PAN: ${_cleanText(bizPan)}',
                            if (bizPhone.isNotEmpty) 'Ph: ${_cleanText(bizPhone)}',
                            if (bizEmail.isNotEmpty) 'Email: ${_cleanText(bizEmail)}',
                          ].join('  |  '),
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.center,
                        ),
                      pw.SizedBox(height: 6),
                    ],
                    pw.Text(
                      _cleanText(title),
                      style: pw.TextStyle(
                        color: brand,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      [
                        '${_cleanText(invoiceNoLabel)} ${_cleanText(invoice.invoiceNumber)}',
                        if (show('showIssueDate', fallback: true)) '${_cleanText(dateLabel)}: ${invoice.issueDate}',
                        if (show('showDueDate', fallback: false)) '${_cleanText(dueDateLabel)}: ${invoice.dueDate}',
                      ].join('   |   '),
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (show('showStatus', fallback: false))
                      pw.Text('Status: ${invoice.status}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              );
            }

            if (template?.headerLayout == 'minimal') {
              return pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logo != null) ...[
                          pw.SizedBox(
                            height: 36,
                            width: 120,
                            child: pw.Image(logo, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        if (showBillFrom && bizName.isNotEmpty) ...[
                          pw.Text(
                            _cleanText(bizName),
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (bizAddress.isNotEmpty)
                            pw.Text(_cleanText(bizAddress), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                          if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                            pw.Text([if (bizPhone.isNotEmpty) _cleanText(bizPhone), if (bizEmail.isNotEmpty) _cleanText(bizEmail)].join(' | '), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _cleanText(title),
                        style: pw.TextStyle(
                          color: brand,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('${_cleanText(invoiceNoLabel)} ${_cleanText(invoice.invoiceNumber)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      if (show('showIssueDate', fallback: true))
                        pw.Text('${_cleanText(dateLabel)}: ${invoice.issueDate}', style: const pw.TextStyle(fontSize: 8)),
                      if (show('showDueDate', fallback: false))
                        pw.Text('${_cleanText(dueDateLabel)}: ${invoice.dueDate}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              );
            }

            // Modern / Corporate / Smart / Industry (Default side-by-side with brand accents)
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null) ...[
                        pw.SizedBox(
                          height: 40,
                          width: 140,
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      if (showBillFrom && bizName.isNotEmpty) ...[
                        pw.Text(
                          _cleanText(bizName),
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                          pw.Text(_cleanText(bizLegalName), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        if (bizAddress.isNotEmpty)
                          pw.Text(_cleanText(bizAddress), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        if (bizGstin.isNotEmpty || bizPan.isNotEmpty)
                          pw.Text([if (bizGstin.isNotEmpty) 'GSTIN: ${_cleanText(bizGstin)}', if (bizPan.isNotEmpty) 'PAN: ${_cleanText(bizPan)}'].join('  |  '), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                          pw.Text([if (bizPhone.isNotEmpty) _cleanText(bizPhone), if (bizEmail.isNotEmpty) _cleanText(bizEmail)].join(' - '), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 6),
                      ],
                      pw.Text(
                        _cleanText(title),
                        style: pw.TextStyle(
                          color: brand,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('${_cleanText(invoiceNoLabel)} ${_cleanText(invoice.invoiceNumber)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                      if (show('showStatus', fallback: false))
                        pw.Text('Status: ${invoice.status}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (show('showIssueDate', fallback: true))
                      pw.Text('${_cleanText(dateLabel)}: ${invoice.issueDate}', style: const pw.TextStyle(fontSize: 8.5)),
                    if (show('showDueDate', fallback: false))
                      pw.Text('${_cleanText(dueDateLabel)}: ${invoice.dueDate}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    if (show('showPoNumber', fallback: false) && invoice.poNumber.isNotEmpty)
                      pw.Text('PO: ${_cleanText(invoice.poNumber)}', style: const pw.TextStyle(fontSize: 8)),
                    for (final field in customFields('customFields_details'))
                      if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                        pw.Text('${_cleanText(field['label'].toString())}: ${_cleanText(field['value']?.toString() ?? '')}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            );
          }(),

          pw.SizedBox(height: 10),
          pw.Container(height: 1.5, color: secondary),
          pw.SizedBox(height: 10),

          // -------------------------------------------------------------------
          // BILL TO & SHIPPING
          // -------------------------------------------------------------------
          if (showBillTo) ...[
            pw.Text(
              _cleanText(billToLabel),
              style: pw.TextStyle(
                color: brand,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _cleanText(invoice.clientName),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (show('showClientCompany') && invoice.clientCompany.isNotEmpty)
              pw.Text(_cleanText(invoice.clientCompany)),
            if (show('showClientEmail') && invoice.clientEmail.isNotEmpty)
              pw.Text(_cleanText(invoice.clientEmail)),
            if (show('showClientPhone') && invoice.clientPhone.isNotEmpty)
              pw.Text(_cleanText(invoice.clientPhone)),
            if (show('showClientAddress') && invoice.clientAddress.isNotEmpty)
              pw.Text(_cleanText(invoice.clientAddress)),
            if (show('showClientTaxId') && invoice.clientTaxId.isNotEmpty)
              pw.Text('Tax ID: ${_cleanText(invoice.clientTaxId)}'),
            for (final field in customFields('customFields_billing'))
              if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                pw.Text('${_cleanText(field['label'].toString())}: ${_cleanText(field['value']?.toString() ?? '')}'),
          ],
          if (show('showShippingSection', fallback: false) || (template?.showShipping ?? false))
            ..._shippingWidgets(invoice.shippingDetailsJson),
          pw.SizedBox(height: 10),

          // -------------------------------------------------------------------
          // LINE ITEMS TABLE (Branch on template?.tableStyle)
          // -------------------------------------------------------------------
          () {
            final hasQty = show('showItemQty');
            final hasRate = show('showItemRate');
            final hasDiscount = show('showItemDiscount', fallback: false);
            final hasTax = show('showItemTax');

            final pdfHeaders = <String>[
              _cleanText(itemHeader),
              if (hasQty) _cleanText(qtyHeader),
              if (showDuty) _cleanText(dutyHeader),
              if (hasRate) _cleanText(rateHeader),
              if (hasDiscount)
                _cleanText(localSettings['customDiscountHeader']?.toString() ?? 'Discount'),
              if (hasTax)
                _cleanText(localSettings['customTaxHeader']?.toString() ?? 'Tax'),
              for (final col in customCols)
                _cleanText(col['label']?.toString() ?? ''),
              _cleanText(amountHeader),
            ];

            final columnWidths = <int, pw.TableColumnWidth>{};
            final headerAlignments = <int, pw.Alignment>{};
            final cellAlignments = <int, pw.Alignment>{};

            var colIdx = 0;
            columnWidths[colIdx] = const pw.FlexColumnWidth(4.5);
            headerAlignments[colIdx] = pw.Alignment.centerLeft;
            cellAlignments[colIdx] = pw.Alignment.centerLeft;
            colIdx++;

            if (hasQty) {
              columnWidths[colIdx] = pw.FlexColumnWidth(qtyHeader.length > 8 ? 2.0 : 1.5);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            if (showDuty) {
              columnWidths[colIdx] = pw.FlexColumnWidth(dutyHeader.length > 10 ? 2.4 : 1.8);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            if (hasRate) {
              columnWidths[colIdx] = pw.FlexColumnWidth(rateHeader.length > 12 ? 2.8 : 2.0);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            if (hasDiscount) {
              columnWidths[colIdx] = const pw.FlexColumnWidth(1.8);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            if (hasTax) {
              columnWidths[colIdx] = const pw.FlexColumnWidth(1.8);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            for (var i = 0; i < customCols.length; i++) {
              columnWidths[colIdx] = const pw.FlexColumnWidth(1.8);
              headerAlignments[colIdx] = pw.Alignment.centerRight;
              cellAlignments[colIdx] = pw.Alignment.centerRight;
              colIdx++;
            }
            columnWidths[colIdx] = const pw.FlexColumnWidth(2.8);
            headerAlignments[colIdx] = pw.Alignment.centerRight;
            cellAlignments[colIdx] = pw.Alignment.centerRight;

            final hasLongHeaders = pdfHeaders.any((h) => h.length > 13);
            final isBoxed = template?.tableStyle == 'boxed' || template?.tableStyle == 'bordered';
            final isStriped = template?.tableStyle == 'striped';
            final tableBorder = isBoxed
                ? pw.TableBorder.all(color: PdfColors.grey400, width: 0.5)
                : const pw.TableBorder(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  );

            return pw.TableHelper.fromTextArray(
              headers: pdfHeaders,
              data: invoice.items
                  .map(
                    (item) {
                      final cleanDesc = _cleanText(item.description);
                      final cleanDetails = _cleanText(item.itemDetails);
                      final descText = cleanDetails.isNotEmpty ? '$cleanDesc\n$cleanDetails' : cleanDesc;

                      return <String>[
                        descText,
                        if (hasQty)
                          '${_quantity(item.quantity)}'
                              '${show('showItemUnit') ? ' ${_cleanText(item.unit)}' : ''}',
                        if (showDuty)
                          item.dutyCount > 0 ? _quantity(item.dutyCount) : '-',
                        if (hasRate)
                          _money(item.unitPrice, currencySymbol),
                        if (hasDiscount) '${item.discountRate}%',
                        if (hasTax) '${item.taxRate}%',
                        for (final col in customCols)
                          _cleanText(col['value']?.toString() ?? '-'),
                        _money(item.total, currencySymbol),
                      ];
                    },
                  )
                  .toList(growable: false),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: hasLongHeaders ? 8.0 : 8.8,
              ),
              headerDecoration: pw.BoxDecoration(color: brand),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              columnWidths: columnWidths,
              headerAlignments: headerAlignments,
              cellAlignments: cellAlignments,
              border: tableBorder,
              oddRowDecoration: isStriped ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
            );
          }(),

          pw.SizedBox(height: 10),

          // -------------------------------------------------------------------
          // TOTALS SECTION
          // -------------------------------------------------------------------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 240,
              child: pw.Column(
                children: [
                  _line(
                    _cleanText(localSettings['customSubtotalLabel']?.toString().isNotEmpty == true
                        ? localSettings['customSubtotalLabel'].toString()
                        : 'Subtotal'),
                    _money(invoice.subtotal, currencySymbol),
                  ),
                  if (invoice.totalDiscount != 0 && show('showDiscount', fallback: true))
                    _line(
                      _cleanText(localSettings['customDiscountLabel']?.toString().isNotEmpty == true
                          ? localSettings['customDiscountLabel'].toString()
                          : 'Discount'),
                      '-${_money(invoice.totalDiscount, currencySymbol)}',
                    ),
                  if (template?.showTaxBreakdown != false && show('showTax', fallback: true))
                    _line(
                      _cleanText(localSettings['customTaxLabel']?.toString().isNotEmpty == true
                          ? localSettings['customTaxLabel'].toString()
                          : '${invoice.taxLabel} (${invoice.taxRate}%)'),
                      _money(invoice.taxAmount, currencySymbol),
                    ),
                  if (invoice.shippingFee != 0 || show('showShippingFee', fallback: false))
                    _line(
                      _cleanText(localSettings['customShippingLabel']?.toString().isNotEmpty == true
                          ? localSettings['customShippingLabel'].toString()
                          : 'Shipping'),
                      _money(invoice.shippingFee, currencySymbol),
                    ),
                  if (invoice.additionalCharges != 0 || show('showAdditionalCharges', fallback: false))
                    _line(
                      _cleanText(localSettings['customAdjustmentsLabel']?.toString().isNotEmpty == true
                          ? localSettings['customAdjustmentsLabel'].toString()
                          : 'Additional charges'),
                      _money(invoice.additionalCharges, currencySymbol),
                    ),
                  if (invoice.roundOff != 0 || show('showRoundOff', fallback: false))
                    _line(
                      _cleanText(localSettings['customRoundOffLabel']?.toString().isNotEmpty == true
                          ? localSettings['customRoundOffLabel'].toString()
                          : 'Round off'),
                      _money(invoice.roundOff, currencySymbol),
                    ),
                  for (final adj in customFields('customFields_adjustments'))
                    if (adj['isVisible'] != false && adj['label']?.toString().isNotEmpty == true)
                      _line(
                        _cleanText(adj['label'] as String),
                        adj['value'] != null && adj['value'].toString().isNotEmpty
                            ? '$currencySymbol${_cleanText(adj['value'].toString())}'
                            : '-',
                      ),
                  pw.Divider(color: brand),
                  _line(
                    _cleanText(localSettings['customTotalLabel']?.toString().isNotEmpty == true
                        ? localSettings['customTotalLabel'].toString()
                        : 'Total'),
                    _money(invoice.total, currencySymbol),
                    bold: true,
                  ),
                  if (show('showAmountPaid', fallback: true))
                    _line(
                      _cleanText(localSettings['customAmountPaidLabel']?.toString().isNotEmpty == true
                          ? localSettings['customAmountPaidLabel'].toString()
                          : 'Paid'),
                      _money(invoice.amountPaid, currencySymbol),
                    ),
                  if (show('showBalanceDue', fallback: true))
                    _line(
                      _cleanText(localSettings['customBalanceDueLabel']?.toString().isNotEmpty == true
                          ? localSettings['customBalanceDueLabel'].toString()
                          : 'Balance due'),
                      _money(invoice.balanceDue, currencySymbol),
                      bold: true,
                    ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // ROW: BANK & PAYMENT DETAILS + QR CODE (LEFT) & SIGNATURE / STAMP (RIGHT)
          // -------------------------------------------------------------------
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // LEFT HALF: Bank Details & QR Code (Scan to Pay)
              pw.Expanded(
                flex: 6,
                child: (showBank &&
                        (bankName.isNotEmpty ||
                            accountNumber.isNotEmpty ||
                            upiId.isNotEmpty ||
                            paymentLink.isNotEmpty))
                    ? pw.Container(
                        padding: const pw.EdgeInsets.all(9),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          color: PdfColors.grey50,
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'BANK & PAYMENT DETAILS',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: brand,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  if (bankName.isNotEmpty)
                                    pw.Text('Bank: ${_cleanText(bankName)}', style: const pw.TextStyle(fontSize: 8)),
                                  if (accountHolder.isNotEmpty)
                                    pw.Text('A/C Name: ${_cleanText(accountHolder)}', style: const pw.TextStyle(fontSize: 8)),
                                  if (accountNumber.isNotEmpty)
                                    pw.Text('A/C No: ${_cleanText(accountNumber)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  if (ifscCode.isNotEmpty)
                                    pw.Text('IFSC / SWIFT: ${_cleanText(ifscCode)}', style: const pw.TextStyle(fontSize: 8)),
                                  if (upiId.isNotEmpty)
                                    pw.Text('UPI ID: ${_cleanText(upiId)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                                  if (paymentLink.isNotEmpty)
                                    pw.Text('Pay Link: ${_cleanText(paymentLink)}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue700)),
                                ],
                              ),
                            ),
                            if (shouldShowQr) ...[
                              pw.SizedBox(width: 8),
                              pw.Column(
                                children: [
                                  if (hasCustomQr)
                                    pw.Container(
                                      width: 62,
                                      height: 62,
                                      child: pw.Image(customQrImage, fit: pw.BoxFit.contain),
                                    )
                                  else if (qrPayload.isNotEmpty)
                                    pw.BarcodeWidget(
                                      barcode: pw.Barcode.qrCode(),
                                      data: qrPayload,
                                      width: 62,
                                      height: 62,
                                      drawText: false,
                                    ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'SCAN TO PAY',
                                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    : pw.SizedBox.shrink(),
              ),

              pw.SizedBox(width: 16),

              // RIGHT HALF: SIGNATURE & STAMP BLOCK (Ample space)
              pw.Expanded(
                flex: 5,
                child: ((show('showSignature') && (template?.showSignature ?? true)) || show('showStamp'))
                    ? pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              if (stamp != null)
                                pw.Container(
                                  width: 60,
                                  height: 60,
                                  child: pw.Image(stamp, fit: pw.BoxFit.contain),
                                ),
                              if (stamp != null) pw.SizedBox(width: 8),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 130,
                                    height: 48,
                                    child: signature != null
                                        ? pw.Image(signature, fit: pw.BoxFit.contain)
                                        : pw.SizedBox.shrink(),
                                  ),
                                  pw.Container(width: 130, height: 0.8, color: PdfColors.grey500),
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    _cleanText(localSettings['signeeTitle']?.toString().trim().isNotEmpty == true
                                        ? localSettings['signeeTitle'].toString()
                                        : 'Authorized Signatory'),
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                                  ),
                                  if (localSettings['signeeName']?.toString().trim().isNotEmpty == true)
                                    pw.Text(
                                      _cleanText(localSettings['signeeName'].toString()),
                                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : pw.SizedBox.shrink(),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // FULL WIDTH (TOTAL DOWN): Notes, Terms & Conditions, Payment Instructions
          // -------------------------------------------------------------------
          if (show('showNotes') &&
              (template?.showNotes ?? true) &&
              invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              _cleanText(localSettings['customNotesLabel']?.toString().trim().isNotEmpty == true
                  ? localSettings['customNotesLabel'].toString()
                  : 'Notes'),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(_cleanText(invoice.notes), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
          if (show('showTerms') &&
              (template?.showTerms ?? true) &&
              invoice.terms.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              _cleanText(localSettings['customTermsLabel']?.toString().trim().isNotEmpty == true
                  ? localSettings['customTermsLabel'].toString()
                  : 'Terms and conditions'),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(_cleanText(invoice.terms), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
          if (show('showPaymentInstructions') &&
              template?.showPaymentInstructions != false &&
              invoice.paymentInstructions.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Payment instructions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(_cleanText(invoice.paymentInstructions), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ],
          for (final foot in customFields('customFields_footer'))
            if (foot['isVisible'] != false && foot['label']?.toString().isNotEmpty == true) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                _cleanText(foot['label'].toString().toUpperCase()),
                style: pw.TextStyle(
                  color: brand,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (foot['value']?.toString().isNotEmpty == true)
                pw.Text(_cleanText(foot['value'].toString()), style: const pw.TextStyle(fontSize: 8)),
            ],
          if (template?.footer.isNotEmpty == true) ...[
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              _cleanText(template!.footer),
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

  static String _money(double amount, String symbol) {
    final cleanSym = (symbol == '₹' || symbol.contains('₹') || symbol.toUpperCase() == 'INR')
        ? 'Rs. '
        : symbol;
    return '$cleanSym${amount.toStringAsFixed(2)}';
  }

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
        _cleanText(decoded['sectionTitle']?.toString().trim().isNotEmpty == true
            ? decoded['sectionTitle'].toString()
            : 'Shipping details'),
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      for (final entry in fields.entries)
        if (decoded[entry.key]?.toString().trim().isNotEmpty == true)
          pw.Text('${entry.value}: ${_cleanText(decoded[entry.key]?.toString())}'),
    ];
  }

  static int _parseColor(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return const Color(0xFF1E3A8A).toARGB32();
    return normalized.length == 6 ? 0xFF000000 | parsed : parsed;
  }
}
