import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'document_template_schema.dart';
import 'template_layout_engine.dart';

/// Pixel-perfect PDF Exporter with zero-overflow border-boxed table architecture
/// matching the Security Service Agency 5-column layout and strict section visibility.
class WysiwygPdfExporter {
  WysiwygPdfExporter._();

  static String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      final intPart = val.toInt().toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    }
    final fixed = val.toStringAsFixed(2);
    final parts = fixed.split('.');
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final whole = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$whole.${parts[1]}';
  }

  static Future<Uint8List> build({
    required DocumentTemplateSchema schema,
    required TemplateLayoutResult layoutResult,
    String companyName = 'Central Security Force',
    String companyAddress = '',
    String companyGstin = 'TG72882828TGH818',
    String companyPan = 'IC8188282J',
    String clientName = 'Enterprise Client Corp',
    String clientCompany = '',
    String clientAddress = '',
    String clientGstin = '',
    String currencySymbol = '₹',
    String invoiceNumber = 'INV-2026-001',
    String issueDate = '2026-10-15',
    String dueDate = '2026-10-31',
    double total = 159300.0,
    double subtotal = 135000.0,
    double tax = 24300.0,
    String notes = '',
    String terms = '',
    String bankName = 'Axis Bank',
    String accountNumber = '717272727727',
    String ifsc = 'T7272GGF',
    String upiId = 'csf7887@kotak',
    String? signatureBase64,
    String? logoBase64,
    bool showLogo = true,
    bool showBillFrom = true,
    bool showBillTo = true,
    bool showShipping = false,
    bool showBankDetails = true,
    bool showQrCode = true,
    bool showNotes = true,
    bool showTerms = true,
    bool showSignature = true,
    bool showDocumentTitle = true,
    bool showInvoiceNumber = true,
    bool showIssueDate = true,
    bool showDueDate = false,
    bool showPoNumber = false,
    String poNumber = '',
    bool showPaymentTerms = false,
    String paymentTerms = '',
    bool showStatus = false,
    String status = 'PAID',
    bool showClientCompany = true,
    bool showClientAddress = true,
    bool showClientTaxId = true,
    String? customTitle,
    String customBillToLabel = 'BILLED TO',
    String customShipToLabel = 'DISPATCH & SUPPLY DETAILS',
    String customInvoiceNoLabel = 'Invoice #',
    String customDateLabel = 'Issue Date',
    String customDueDateLabel = 'Due Date',
    String customPoLabel = 'PO Number',
    String tableSectionTitle = '',
    String tableFooterNote = '',
    String? shipToDetails,
  }) async {
    final pdf = pw.Document();

    final margins = schema.metadata;
    final primaryColor = PdfColor.fromHex(schema.style.primaryColor.replaceAll('#', ''));
    final zebraColor = PdfColor.fromHex(schema.style.zebraColor.replaceAll('#', ''));
    final borderColor = PdfColor.fromHex(schema.style.borderColor.replaceAll('#', ''));

    final format = schema.metadata.pageSize == TemplatePageSize.letter
        ? PdfPageFormat.letter
        : PdfPageFormat.a4;

    pw.MemoryImage? logoImage;
    if (showLogo && logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(logoBase64));
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    if (showSignature && signatureBase64 != null && signatureBase64.isNotEmpty) {
      try {
        signatureImage = pw.MemoryImage(base64Decode(signatureBase64));
      } catch (_) {}
    }

    final docTitle = customTitle?.trim().isNotEmpty == true
        ? customTitle!.trim().toUpperCase()
        : 'TAX INVOICE';

    for (final pageLayout in layoutResult.pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.fromLTRB(
            margins.marginLeft,
            margins.marginTop,
            margins.marginRight,
            margins.marginBottom,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Page 1 only and if enabled)
                if (pageLayout.hasHeader) ...[
                  _buildPdfHeader(
                    primaryColor: primaryColor,
                    name: companyName,
                    addr: companyAddress,
                    gstin: companyGstin,
                    pan: companyPan,
                    invNo: invoiceNumber,
                    issueDate: issueDate,
                    dueDate: dueDate,
                    logo: logoImage,
                    title: docTitle,
                    showBillFrom: showBillFrom,
                    showDocumentTitle: showDocumentTitle,
                    showInvoiceNumber: showInvoiceNumber,
                    showIssueDate: showIssueDate,
                    showDueDate: showDueDate,
                    showPoNumber: showPoNumber,
                    poNumber: poNumber,
                    showPaymentTerms: showPaymentTerms,
                    paymentTerms: paymentTerms,
                    showStatus: showStatus,
                    status: status,
                    customInvoiceNoLabel: customInvoiceNoLabel,
                    customDateLabel: customDateLabel,
                    customDueDateLabel: customDueDateLabel,
                    customPoLabel: customPoLabel,
                  ),
                  pw.SizedBox(height: 12),
                ],

                // 2. Party Details (STRICTLY ONLY IF showBillTo or showShipping)
                if (pageLayout.hasPartyDetails && (showBillTo || showShipping)) ...[
                  _buildPdfPartyDetails(
                    border: borderColor,
                    client: clientName,
                    clientCompany: clientCompany,
                    clientAddress: clientAddress,
                    clientGstin: clientGstin,
                    showShipping: showShipping,
                    showBillTo: showBillTo,
                    showClientCompany: showClientCompany,
                    showClientAddress: showClientAddress,
                    showClientTaxId: showClientTaxId,
                    customBillToLabel: customBillToLabel,
                    customShipToLabel: customShipToLabel,
                    shipToDetails: shipToDetails,
                  ),
                  pw.SizedBox(height: 12),
                ],

                // 3. Item Table with Boxed Border Table & SERVICE DETAILS bar
                _buildPdfItemTable(
                  pageLayout: pageLayout,
                  layoutResult: layoutResult,
                  primaryColor: primaryColor,
                  zebraColor: zebraColor,
                  borderColor: borderColor,
                  currencySymbol: currencySymbol,
                  tableSectionTitle: tableSectionTitle,
                  tableFooterNote: tableFooterNote,
                ),
                pw.SizedBox(height: 12),

                // 4. Totals Block
                if (pageLayout.hasTotals) ...[
                  _buildPdfTotalsBlock(borderColor, subtotal, tax, total, currencySymbol),
                  pw.SizedBox(height: 12),
                ],

                // 5. Bank & Payment routing (STRICTLY ONLY IF showBankDetails or showQrCode)
                if (pageLayout.hasBankDetails && (showBankDetails || showQrCode)) ...[
                  _buildPdfBankDetails(borderColor, bankName, accountNumber, ifsc, upiId, showBankDetails, showQrCode),
                  pw.SizedBox(height: 10),
                ],

                // 6. Notes & Terms
                if (pageLayout.hasNotes &&
                    ((showNotes && notes.isNotEmpty) || (showTerms && terms.isNotEmpty))) ...[
                  _buildPdfNotes(borderColor, notes, terms, showNotes, showTerms),
                  pw.SizedBox(height: 10),
                ],

                // 7. Signature Block (STRICTLY ONLY IF showSignature)
                if (pageLayout.hasSignature && showSignature) ...[
                  _buildPdfSignature(schema, primaryColor, signatureImage),
                  pw.SizedBox(height: 10),
                ],

                pw.Spacer(),

                // 8. Footer with exact page numbering
                _buildPdfFooter(pageLayout.pageLabel),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader({
    required PdfColor primaryColor,
    required String name,
    required String addr,
    required String gstin,
    required String pan,
    required String invNo,
    required String issueDate,
    required String dueDate,
    required pw.MemoryImage? logo,
    required String title,
    required bool showBillFrom,
    required bool showDocumentTitle,
    required bool showInvoiceNumber,
    required bool showIssueDate,
    required bool showDueDate,
    required bool showPoNumber,
    required String poNumber,
    required bool showPaymentTerms,
    required String paymentTerms,
    required bool showStatus,
    required String status,
    required String customInvoiceNoLabel,
    required String customDateLabel,
    required String customDueDateLabel,
    required String customPoLabel,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null) ...[
                pw.Container(
                  height: 40,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              if (showBillFrom) ...[
                if (addr.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(addr, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                ],
                pw.SizedBox(height: 2),
                pw.Text(
                  'GSTIN: ${gstin.isNotEmpty ? gstin : "N/A"}${pan.isNotEmpty ? "  |  PAN: $pan" : ""}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (showDocumentTitle) ...[
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 3),
            ],
            if (showInvoiceNumber) ...[
              pw.Text('$customInvoiceNoLabel: $invNo', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            ],
            if (showIssueDate) ...[
              pw.Text('$customDateLabel: $issueDate', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            ],
            // STRICTLY CONDITIONAL: Due Date ONLY if showDueDate == true
            if (showDueDate) ...[
              pw.Text('$customDueDateLabel: $dueDate', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            ],
            // STRICTLY CONDITIONAL: PO Number ONLY if showPoNumber == true
            if (showPoNumber) ...[
              pw.Text('$customPoLabel: ${poNumber.isNotEmpty ? poNumber : "PO-2026-992"}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
            // STRICTLY CONDITIONAL: Payment Terms ONLY if showPaymentTerms == true
            if (showPaymentTerms) ...[
              pw.Text('Terms: ${paymentTerms.isNotEmpty ? paymentTerms : "Net 30 Days"}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
            if (showStatus) ...[
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.green300, width: 0.5),
                ),
                child: pw.Text(status.toUpperCase(), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPdfPartyDetails({
    required PdfColor border,
    required String client,
    required String clientCompany,
    required String clientAddress,
    required String clientGstin,
    required bool showShipping,
    required bool showBillTo,
    required bool showClientCompany,
    required bool showClientAddress,
    required bool showClientTaxId,
    required String customBillToLabel,
    required String customShipToLabel,
    String? shipToDetails,
  }) {
    if (!showBillTo && !showShipping) return pw.SizedBox.shrink();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (showBillTo)
          pw.Expanded(
            flex: showShipping ? 5 : 10,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: border, width: 0.6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    customBillToLabel.toUpperCase(),
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(client, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  if (showClientCompany && clientCompany.isNotEmpty && clientCompany != client) ...[
                    pw.Text(clientCompany, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ],
                  if (showClientAddress && clientAddress.isNotEmpty) ...[
                    pw.Text(clientAddress, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                  if (showClientTaxId && clientGstin.isNotEmpty) ...[
                    pw.Text('GSTIN: $clientGstin', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
        if (showBillTo && showShipping) pw.SizedBox(width: 8),

        // STRICTLY AND COMPLETELY HIDDEN IF showShipping == false
        if (showShipping)
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: border, width: 0.6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    customShipToLabel.toUpperCase(),
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('Place of Supply: Registered State', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Reverse Charge: No', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Payment Terms: Net 15 Days', style: const pw.TextStyle(fontSize: 8)),
                  if (shipToDetails != null && shipToDetails.isNotEmpty)
                    pw.Text(shipToDetails, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Auto-scaled, border-boxed Table using native pw.Table matching Screenshot 1
  static pw.Widget _buildPdfItemTable({
    required TemplatePageLayout pageLayout,
    required TemplateLayoutResult layoutResult,
    required PdfColor primaryColor,
    required PdfColor zebraColor,
    required PdfColor borderColor,
    required String currencySymbol,
    required String tableSectionTitle,
    required String tableFooterNote,
  }) {
    final columns = layoutResult.columns.columns;
    final colCount = columns.length;

    // Dynamically scale font size based on column count so text never clips or wraps awkwardly
    final headerFontSize = colCount > 6 ? 7.5 : 8.5;
    final dataFontSize = colCount > 6 ? 7.5 : 8.5;

    // Compute proportional column width weights
    final columnWidthMap = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < colCount; i++) {
      final col = columns[i];
      if (col.isFlex || col.key == 'item') {
        columnWidthMap[i] = const pw.FlexColumnWidth(3.4);
      } else if (col.key == 'rate' || col.key == 'amount') {
        columnWidthMap[i] = const pw.FlexColumnWidth(1.4);
      } else if (col.key == 'duty' || col.key.contains('duty')) {
        columnWidthMap[i] = const pw.FlexColumnWidth(1.15);
      } else if (col.key == 'qty' || col.key == '#' || col.key == 'no') {
        columnWidthMap[i] = const pw.FlexColumnWidth(0.85);
      } else {
        columnWidthMap[i] = const pw.FlexColumnWidth(1.1);
      }
    }

    String resolveCellText(String key, LayoutLineItem item, int index) {
      switch (key) {
        case 'no':
        case '#':
          return '${pageLayout.startIndex + index + 1}';
        case 'item':
          return item.name;
        case 'qty':
          return item.qty.toStringAsFixed(item.qty == item.qty.roundToDouble() ? 0 : 1);
        case 'duty':
          final d = item.duty > 0 ? item.duty.toInt() : 26;
          return '$d days';
        case 'unit':
          return item.unit.isNotEmpty ? item.unit : 'Days';
        case 'hsn':
          return item.hsn.isNotEmpty ? item.hsn : '998525';
        case 'rate':
          return '$currencySymbol${_formatAmount(item.unitPrice)}';
        case 'tax':
          return '18%';
        case 'discount':
          return '0%';
        case 'amount':
          return '$currencySymbol${_formatAmount(item.amount)}';
        default:
          if (item.customValues.containsKey(key)) {
            return item.customValues[key]!;
          }
          return '-';
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Top Section Bar (Only rendered if explicit title provided)
        if (tableSectionTitle.trim().isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
            ),
            child: pw.Text(
              tableSectionTitle.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                letterSpacing: 0.6,
              ),
            ),
          ),

        // Border-Boxed pw.Table
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: tableSectionTitle.trim().isNotEmpty
                ? const pw.BorderRadius.vertical(bottom: pw.Radius.circular(4))
                : const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: borderColor, width: 0.6),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: columnWidthMap,
            children: [
              // 1. Header Row
              if (pageLayout.hasTableHeader)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: columns.map((col) {
                    final align = col.align == 'right'
                        ? pw.Alignment.centerRight
                        : (col.align == 'center' ? pw.Alignment.center : pw.Alignment.centerLeft);

                    return pw.Container(
                      alignment: align,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        col.label,
                        textAlign: col.align == 'right'
                            ? pw.TextAlign.right
                            : (col.align == 'center' ? pw.TextAlign.center : pw.TextAlign.left),
                        style: pw.TextStyle(
                          color: PdfColors.grey900,
                          fontSize: headerFontSize,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // 2. Data Rows
              ...pageLayout.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isEven = idx.isEven;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : zebraColor),
                  children: columns.map((col) {
                    final isItemCol = col.key == 'item';
                    final isAmountCol = col.key == 'amount';
                    final align = col.align == 'right'
                        ? pw.Alignment.centerRight
                        : (col.align == 'center' ? pw.Alignment.center : pw.Alignment.centerLeft);

                    if (isItemCol) {
                      return pw.Container(
                        alignment: pw.Alignment.centerLeft,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.name,
                              style: pw.TextStyle(fontSize: dataFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                            if (item.description.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text(
                                item.description,
                                style: pw.TextStyle(fontSize: dataFontSize - 1, color: PdfColors.grey700),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    final cellText = resolveCellText(col.key, item, idx);

                    return pw.Container(
                      alignment: align,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
                      child: pw.Text(
                        cellText,
                        textAlign: col.align == 'right'
                            ? pw.TextAlign.right
                            : (col.align == 'center' ? pw.TextAlign.center : pw.TextAlign.left),
                        style: pw.TextStyle(
                          fontSize: dataFontSize,
                          fontWeight: isAmountCol ? pw.FontWeight.bold : pw.FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),

        // Bottom Note from Screenshot 1
        pw.SizedBox(height: 4),
        pw.Text(
          tableFooterNote.isNotEmpty
              ? tableFooterNote
              : 'Illustrative format only. Confirm whether each rate is per guard per month, per duty day, or another contracted billing unit. The quantity and line totals must follow that unit.',
          style: pw.TextStyle(
            fontSize: 7.5,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfTotalsBlock(
    PdfColor border,
    double subtotal,
    double tax,
    double total,
    String currencySymbol,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 0.6),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          children: [
            _buildPdfTotalRow('Taxable Subtotal', '$currencySymbol${_formatAmount(subtotal)}'),
            pw.SizedBox(height: 3),
            _buildPdfTotalRow('Taxes / GST', '$currencySymbol${_formatAmount(tax)}'),
            pw.Divider(color: border, height: 8),
            _buildPdfTotalRow(
              'Total Payable',
              '$currencySymbol${_formatAmount(total)}',
              isBold: true,
              fontSize: 10,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTotalRow(String label, String value, {bool isBold = false, double fontSize = 8.5}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static pw.Widget _buildPdfBankDetails(
    PdfColor border,
    String bank,
    String acc,
    String ifsc,
    String upi,
    bool showBank,
    bool showQr,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BANK & PAYMENT ROUTING', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          if (showBank)
            pw.Text('Bank: $bank   |   A/C: $acc   |   IFSC: $ifsc${upi.isNotEmpty ? "   |   UPI: $upi" : ""}',
                style: const pw.TextStyle(fontSize: 8))
          else
            pw.Text('UPI: $upi', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfNotes(PdfColor border, String notes, String terms, bool showNotes, bool showTerms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (showTerms && terms.isNotEmpty) ...[
            pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 1.5),
            pw.Text(terms, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          ],
          if (showNotes && notes.isNotEmpty) ...[
            if (showTerms && terms.isNotEmpty) pw.SizedBox(height: 4),
            pw.Text('CLIENT NOTES', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 1.5),
            pw.Text(notes, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSignature(DocumentTemplateSchema schema, PdfColor primary, pw.MemoryImage? signature) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 170,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (signature != null)
              pw.Container(
                height: 36,
                child: pw.Image(signature, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                child: pw.Text('DIGITALLY SIGNED', style: pw.TextStyle(fontSize: 7.5, color: primary, fontWeight: pw.FontWeight.bold)),
              ),
            pw.Container(
              height: 1,
              width: 130,
              color: primary,
              margin: const pw.EdgeInsets.symmetric(vertical: 3),
            ),
            pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            pw.Text('Director / Partner', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfFooter(String pageLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generated by Invoicely AI Enterprise Platform', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
        pw.Text(pageLabel, style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
