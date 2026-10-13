import 'dart:convert';
import 'package:flutter/material.dart';

import '../../data/document_template_schema.dart';
import '../../data/template_layout_engine.dart';

/// Pixel-perfect WYSIWYG A4 Canvas Preview with border-boxed table architecture
/// and strict section visibility controls matching the Security Service Agency 5-column layout.
class WysiwygCanvasPreview extends StatelessWidget {
  const WysiwygCanvasPreview({
    required this.schema,
    required this.layoutResult,
    this.activePageIndex = 0,
    this.onPageChanged,
    this.companyName = 'Central Security Force',
    this.companyAddress = '',
    this.companyGstin = 'TG72882828TGH818',
    this.companyPan = 'IC8188282J',
    this.clientName = 'Enterprise Client Corp',
    this.clientCompany = '',
    this.clientAddress = '',
    this.clientGstin = '',
    this.currencySymbol = '₹',
    this.invoiceNumber = 'INV-2026-001',
    this.issueDate = '2026-10-15',
    this.dueDate = '2026-10-31',
    this.total = 159300.0,
    this.subtotal = 135000.0,
    this.tax = 24300.0,
    this.notes = '',
    this.terms = '',
    this.bankName = 'Axis Bank',
    this.accountNumber = '717272727727',
    this.ifsc = 'T7272GGF',
    this.upiId = 'csf7887@kotak',
    this.signatureBase64,
    this.logoWidget,
    this.showLogo = true,
    this.showBillFrom = true,
    this.showBillTo = true,
    this.showShipping = false,
    this.showBankDetails = true,
    this.showQrCode = true,
    this.showNotes = true,
    this.showTerms = true,
    this.showSignature = true,
    this.showDocumentTitle = true,
    this.showInvoiceNumber = true,
    this.showIssueDate = true,
    this.showDueDate = false,
    this.showPoNumber = false,
    this.poNumber = '',
    this.showPaymentTerms = false,
    this.paymentTerms = '',
    this.showStatus = false,
    this.status = 'PAID',
    this.showClientCompany = true,
    this.showClientAddress = true,
    this.showClientTaxId = true,
    this.customTitle,
    this.customBillToLabel = 'BILLED TO',
    this.customShipToLabel = 'DISPATCH & SUPPLY DETAILS',
    this.customInvoiceNoLabel = 'Invoice #',
    this.customDateLabel = 'Issue Date',
    this.customDueDateLabel = 'Due Date',
    this.customPoLabel = 'PO Number',
    this.tableSectionTitle = '',
    this.tableFooterNote = '',
    this.shipToDetails,
    this.scale = 1.0,
    this.renderAllPagesStacked = false,
    super.key,
  });

  final DocumentTemplateSchema schema;
  final TemplateLayoutResult layoutResult;
  final int activePageIndex;
  final ValueChanged<int>? onPageChanged;
  final String companyName;
  final String companyAddress;
  final String companyGstin;
  final String companyPan;
  final String clientName;
  final String clientCompany;
  final String clientAddress;
  final String clientGstin;
  final String currencySymbol;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final double total;
  final double subtotal;
  final double tax;
  final String notes;
  final String terms;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String upiId;
  final String? signatureBase64;
  final Widget? logoWidget;
  final bool showLogo;
  final bool showBillFrom;
  final bool showBillTo;
  final bool showShipping;
  final bool showBankDetails;
  final bool showQrCode;
  final bool showNotes;
  final bool showTerms;
  final bool showSignature;
  final bool showDocumentTitle;
  final bool showInvoiceNumber;
  final bool showIssueDate;
  final bool showDueDate;
  final bool showPoNumber;
  final String poNumber;
  final bool showPaymentTerms;
  final String paymentTerms;
  final bool showStatus;
  final String status;
  final bool showClientCompany;
  final bool showClientAddress;
  final bool showClientTaxId;
  final String? customTitle;
  final String customBillToLabel;
  final String customShipToLabel;
  final String customInvoiceNoLabel;
  final String customDateLabel;
  final String customDueDateLabel;
  final String customPoLabel;
  final String tableSectionTitle;
  final String tableFooterNote;
  final String? shipToDetails;
  final double scale;
  final bool renderAllPagesStacked;

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

  @override
  Widget build(BuildContext context) {
    if (layoutResult.pages.isEmpty) {
      return const Center(child: Text('No layout pages generated.'));
    }

    final previewWidth = schema.metadata.pageSize.previewWidth;
    final previewHeight = schema.metadata.pageSize.previewHeight;

    if (renderAllPagesStacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < layoutResult.pages.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: Text(
                    'PAGE ${i + 1} OF ${layoutResult.pages.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: _buildA4PaperSheet(layoutResult.pages[i], previewWidth, previewHeight),
            ),
          ],
        ],
      );
    }

    final safeIndex = activePageIndex.clamp(0, layoutResult.pages.length - 1);
    final currentPage = layoutResult.pages[safeIndex];

    return Column(
      children: [
        // Top Toolbar: Page switcher & Zero-Overflow Safety Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Page',
                    onPressed: safeIndex > 0 ? () => onPageChanged?.call(safeIndex - 1) : null,
                  ),
                  Text(
                    'Page ${safeIndex + 1} of ${layoutResult.pages.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Page',
                    onPressed: safeIndex < layoutResult.pages.length - 1
                        ? () => onPageChanged?.call(safeIndex + 1)
                        : null,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF15803D)),
                    SizedBox(width: 5),
                    Text(
                      'Border-Boxed Grid (Zero Overflow)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // A4 Paper Sheet with Drop Shadow
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: _buildA4PaperSheet(currentPage, previewWidth, previewHeight),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildA4PaperSheet(TemplatePageLayout page, double previewWidth, double previewHeight) {
    return Container(
      width: previewWidth,
      constraints: BoxConstraints(minHeight: previewHeight),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.fromLTRB(
        schema.metadata.marginLeft,
        schema.metadata.marginTop,
        schema.metadata.marginRight,
        schema.metadata.marginBottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(schema.style.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header (if on this page and enabled)
          if (page.hasHeader) ...[
            _buildHeader(),
            const SizedBox(height: 14),
          ],

          // 2. Party details (STRICTLY ONLY IF showBillTo or showShipping)
          if (page.hasPartyDetails && (showBillTo || showShipping)) ...[
            _buildPartyDetails(),
            const SizedBox(height: 14),
          ],

          // 3. Border-Boxed Item Table (with SERVICE DETAILS top badge)
          _buildItemTable(page),
          const SizedBox(height: 14),

          // 4. Totals Block (if on this page)
          if (page.hasTotals) ...[
            _buildTotalsBlock(),
            const SizedBox(height: 14),
          ],

          // 5. Bank & QR details (STRICTLY ONLY IF showBankDetails or showQrCode)
          if (page.hasBankDetails && (showBankDetails || showQrCode)) ...[
            _buildBankAndQr(),
            const SizedBox(height: 12),
          ],

          // 6. Notes & Terms (STRICTLY ONLY IF enabled and not empty)
          if (page.hasNotes && ((showNotes && notes.isNotEmpty) || (showTerms && terms.isNotEmpty))) ...[
            _buildNotesAndTerms(),
            const SizedBox(height: 12),
          ],

          // 7. Signature Block (STRICTLY ONLY IF showSignature)
          if (page.hasSignature && showSignature) ...[
            _buildSignatureBlock(),
            const SizedBox(height: 12),
          ],

          const Spacer(),

          // 8. Footer (Page numbers & auto-notice)
          _buildFooter(page),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final primary = schema.style.primaryFlutterColor;
    final title = customTitle?.trim().isNotEmpty == true
        ? customTitle!.trim().toUpperCase()
        : 'TAX INVOICE';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Identity Block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLogo && logoWidget != null) ...[
                logoWidget!,
                const SizedBox(height: 6),
              ] else if (showLogo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BUSINESS INVOICE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                companyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (showBillFrom) ...[
                if (companyAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    companyAddress,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'GSTIN: ${companyGstin.isNotEmpty ? companyGstin : "N/A"}${companyPan.isNotEmpty ? "  |  PAN: $companyPan" : ""}',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),

        // Document Details (Invoice No, Dates, Title, PO #, Due Date)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showDocumentTitle) ...[
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (showInvoiceNumber) ...[
              Text(
                '$customInvoiceNoLabel: $invoiceNumber',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
            ],
            if (showIssueDate) ...[
              Text(
                '$customDateLabel: $issueDate',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
            // STRICTLY CONDITIONAL: Due Date ONLY if enabled!
            if (showDueDate) ...[
              const SizedBox(height: 2),
              Text(
                '$customDueDateLabel: $dueDate',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
            // STRICTLY CONDITIONAL: PO Number ONLY if enabled!
            if (showPoNumber) ...[
              const SizedBox(height: 2),
              Text(
                '$customPoLabel: ${poNumber.isNotEmpty ? poNumber : "PO-2026-992"}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
            ],
            // STRICTLY CONDITIONAL: Payment Terms ONLY if enabled!
            if (showPaymentTerms) ...[
              const SizedBox(height: 2),
              Text(
                'Terms: ${paymentTerms.isNotEmpty ? paymentTerms : "Net 30 Days"}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
              ),
            ],
            // STRICTLY CONDITIONAL: Status Badge ONLY if enabled!
            if (showStatus) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPartyDetails() {
    if (!showBillTo && !showShipping) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bill To (Client) Box
        if (showBillTo)
          Expanded(
            flex: showShipping ? 5 : 10,
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
                    customBillToLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (showClientCompany && clientCompany.isNotEmpty && clientCompany != clientName) ...[
                    Text(clientCompany, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                  if (showClientAddress && clientAddress.isNotEmpty) ...[
                    Text(clientAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  ],
                  if (showClientTaxId && clientGstin.isNotEmpty) ...[
                    Text('GSTIN: $clientGstin', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
        if (showBillTo && showShipping) const SizedBox(width: 14),

        // Shipping / Dispatch Box (STRICTLY AND COMPLETELY HIDDEN IF showShipping == false)
        if (showShipping)
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
                    customShipToLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Place of Supply: Registered State', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const Text('Reverse Charge: No', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  const Text('Payment Terms: Net 15 Days', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  if (shipToDetails != null && shipToDetails!.isNotEmpty)
                    Text(shipToDetails!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Border-Boxed Items Table using Flutter Table with TableBorder.all matching Screenshot 1
  Widget _buildItemTable(TemplatePageLayout page) {
    final columns = layoutResult.columns.columns;
    final primary = schema.style.primaryFlutterColor;
    final colCount = columns.length;

    // Dynamically scale font size based on column count so text never clips or overlaps
    final headerFontSize = colCount > 6 ? 9.5 : 10.5;
    final dataFontSize = colCount > 6 ? 10.0 : 11.5;

    // Compute proportional column width map for Table
    final columnWidthMap = <int, TableColumnWidth>{};
    for (int i = 0; i < colCount; i++) {
      final col = columns[i];
      if (col.isFlex || col.key == 'item') {
        columnWidthMap[i] = const FlexColumnWidth(3.4);
      } else if (col.key == 'rate' || col.key == 'amount') {
        columnWidthMap[i] = const FlexColumnWidth(1.4);
      } else if (col.key == 'duty' || col.key.contains('duty')) {
        columnWidthMap[i] = const FlexColumnWidth(1.15);
      } else if (col.key == 'qty' || col.key == '#' || col.key == 'no') {
        columnWidthMap[i] = const FlexColumnWidth(0.85);
      } else {
        columnWidthMap[i] = const FlexColumnWidth(1.1);
      }
    }

    String resolveCellText(String key, LayoutLineItem item, int index) {
      switch (key) {
        case 'no':
        case '#':
          return '${page.startIndex + index + 1}';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Section Bar (Only rendered if explicit title provided)
        if (tableSectionTitle.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Text(
              tableSectionTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 0.8,
              ),
            ),
          ),

        // Border-Boxed Table
        Container(
          decoration: BoxDecoration(
            borderRadius: tableSectionTitle.trim().isNotEmpty
                ? const BorderRadius.vertical(bottom: Radius.circular(6))
                : BorderRadius.circular(6),
            border: Border.all(color: schema.style.borderFlutterColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            border: TableBorder.all(
              color: schema.style.borderFlutterColor,
              width: 0.8,
            ),
            columnWidths: columnWidthMap,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // 1. Header Row
              if (page.hasTableHeader)
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: columns.map((col) {
                    final align = col.align == 'right'
                        ? Alignment.centerRight
                        : (col.align == 'center' ? Alignment.center : Alignment.centerLeft);

                    return Container(
                      alignment: align,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        col.label,
                        textAlign: col.align == 'right'
                            ? TextAlign.right
                            : (col.align == 'center' ? TextAlign.center : TextAlign.left),
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // 2. Data Rows
              ...page.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isEven = idx.isEven;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : schema.style.zebraFlutterColor,
                  ),
                  children: columns.map((col) {
                    final isItemCol = col.key == 'item';
                    final isAmountCol = col.key == 'amount';
                    final align = col.align == 'right'
                        ? Alignment.centerRight
                        : (col.align == 'center' ? Alignment.center : Alignment.centerLeft);

                    if (isItemCol) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: dataFontSize,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                item.description,
                                style: TextStyle(fontSize: dataFontSize - 1.5, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    final cellText = resolveCellText(col.key, item, idx);

                    return Container(
                      alignment: align,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        cellText,
                        textAlign: col.align == 'right'
                            ? TextAlign.right
                            : (col.align == 'center' ? TextAlign.center : TextAlign.left),
                        style: TextStyle(
                          fontSize: dataFontSize,
                          fontWeight: isAmountCol ? FontWeight.bold : FontWeight.normal,
                          color: isAmountCol ? const Color(0xFF0F172A) : const Color(0xFF334155),
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
        const SizedBox(height: 6),
        Text(
          tableFooterNote.isNotEmpty
              ? tableFooterNote
              : 'Illustrative format only. Confirm whether each rate is per guard per month, per duty day, or another contracted billing unit. The quantity and line totals must follow that unit.',
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF64748B),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsBlock() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            _buildTotalLine('Taxable Subtotal', '$currencySymbol${_formatAmount(subtotal)}'),
            const SizedBox(height: 4),
            _buildTotalLine('Taxes / GST', '$currencySymbol${_formatAmount(tax)}'),
            const Divider(height: 14),
            _buildTotalLine(
              'Total Payable',
              '$currencySymbol${_formatAmount(total)}',
              isBold: true,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalLine(String label, String value, {bool isBold = false, double fontSize = 11.5}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildBankAndQr() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BANK & PAYMENT ROUTING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                if (showBankDetails) ...[
                  Text(
                    'Bank: $bankName  |  A/C: $accountNumber',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'IFSC: $ifsc${upiId.isNotEmpty ? "  |  UPI: $upiId" : ""}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ] else ...[
                  Text(
                    'UPI ID: $upiId',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (showQrCode) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 36, color: Color(0xFF0F172A)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesAndTerms() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTerms && terms.isNotEmpty) ...[
            const Text(
              'TERMS & CONDITIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(terms, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
          ],
          if (showNotes && notes.isNotEmpty) ...[
            if (showTerms && terms.isNotEmpty) const SizedBox(height: 6),
            const Text(
              'CLIENT NOTES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(notes, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
          ],
        ],
      ),
    );
  }

  Widget _buildSignatureBlock() {
    final primary = schema.style.primaryFlutterColor;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 220,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (signatureBase64 != null && signatureBase64!.isNotEmpty) ...[
              tryDecodeSignature(signatureBase64!) ??
                  Text(
                    'DIGITALLY SIGNED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
                  ),
            ] else ...[
              Text(
                'DIGITALLY SIGNED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: primary,
                ),
              ),
            ],
            Container(
              height: 1.5,
              width: 160,
              color: primary,
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),
            const Text(
              'Authorized Signatory',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const Text(
              'Director / Partner',
              style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget? tryDecodeSignature(String b64) {
    try {
      return Image.memory(
        base64Decode(b64),
        height: 45,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildFooter(TemplatePageLayout page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Generated by Invoicely AI Enterprise Platform',
          style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
        ),
        Text(
          page.pageLabel,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
