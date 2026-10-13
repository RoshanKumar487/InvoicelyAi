import 'package:flutter/material.dart';

import '../../data/document_template_schema.dart';
import '../../data/template_layout_engine.dart';

class WysiwygCanvasPreview extends StatelessWidget {
  const WysiwygCanvasPreview({
    required this.schema,
    required this.layoutResult,
    required this.activePageIndex,
    required this.onPageChanged,
    this.companyName = 'Acme Global Technologies Pvt Ltd',
    this.clientName = 'Enterprise Client Corp',
    this.currencySymbol = '₹',
    this.invoiceNumber = 'INV-2026-0881',
    this.issueDate = '2026-10-15',
    this.dueDate = '2026-10-30',
    this.total = 142800.0,
    this.subtotal = 120000.0,
    this.tax = 22800.0,
    this.scale = 1.0,
    super.key,
  });

  final DocumentTemplateSchema schema;
  final TemplateLayoutResult layoutResult;
  final int activePageIndex;
  final ValueChanged<int> onPageChanged;
  final String companyName;
  final String clientName;
  final String currencySymbol;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final double total;
  final double subtotal;
  final double tax;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (layoutResult.pages.isEmpty) {
      return const Center(child: Text('No layout pages generated.'));
    }

    final safeIndex = activePageIndex.clamp(0, layoutResult.pages.length - 1);
    final currentPage = layoutResult.pages[safeIndex];

    final previewWidth = schema.metadata.pageSize.previewWidth;
    final previewHeight = schema.metadata.pageSize.previewHeight;

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
              // Page switcher controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Page',
                    onPressed: safeIndex > 0 ? () => onPageChanged(safeIndex - 1) : null,
                  ),
                  Text(
                    'Page ${safeIndex + 1} of ${layoutResult.pages.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Page',
                    onPressed: safeIndex < layoutResult.pages.length - 1
                        ? () => onPageChanged(safeIndex + 1)
                        : null,
                  ),
                ],
              ),

              // Zero-Overflow Safety Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 5),
                    Text(
                      layoutResult.metrics.isOverflowSafe
                          ? 'Zero-Overflow Safe (Auto-Layout)'
                          : 'Potential Overflow',
                      style: const TextStyle(
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
                  child: Container(
                    width: previewWidth,
                    constraints: BoxConstraints(minHeight: previewHeight),
                    margin: const EdgeInsets.symmetric(vertical: 12),
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
                          color: Color(0x1F000000),
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
                        // 1. Header (if on this page)
                        if (currentPage.hasHeader) ...[
                          _buildHeader(),
                          const SizedBox(height: 16),
                        ],

                        // 2. Party details (Bill From & Bill To)
                        if (currentPage.hasPartyDetails) ...[
                          _buildPartyDetails(),
                          const SizedBox(height: 18),
                        ],

                        // 3. Item Table
                        _buildItemTable(currentPage),
                        const SizedBox(height: 16),

                        // 4. Totals Block (if on this page)
                        if (currentPage.hasTotals) ...[
                          _buildTotalsBlock(),
                          const SizedBox(height: 16),
                        ],

                        // 5. Bank & QR details
                        if (currentPage.hasBankDetails) ...[
                          _buildBankAndQr(),
                          const SizedBox(height: 14),
                        ],

                        // 6. Notes & Terms
                        if (currentPage.hasNotes) ...[
                          _buildNotesAndTerms(),
                          const SizedBox(height: 14),
                        ],

                        // 7. Signature Block
                        if (currentPage.hasSignature) ...[
                          _buildSignatureBlock(),
                          const SizedBox(height: 14),
                        ],

                        const Spacer(),

                        // 8. Footer (Page numbers & auto-notice)
                        _buildFooter(currentPage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final primary = schema.style.primaryFlutterColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Identity Block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BUSINESS LOGO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                companyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'GSTIN: 27AABCU9603R1ZM  |  PAN: AABCU9603R',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Document Details (Invoice No, Dates, Status)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TAX INVOICE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invoice #: $invoiceNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text('Issue Date: $issueDate', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('Due Date: $dueDate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildPartyDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bill To (Client)
        Expanded(
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
                const Text(
                  'BILLED TO',
                  style: TextStyle(
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
                const Text('402, High Street Business Tower, Bandra West, Mumbai', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                const Text('GSTIN: 27AABCT3529Q1ZX', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Shipping / Place of Supply
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH & SUPPLY DETAILS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text('Place of Supply: 27 - Maharashtra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Reverse Charge: No', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                Text('Vehicle No: MH-02-CD-4109', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTable(TemplatePageLayout page) {
    final columns = layoutResult.columns.columns;
    final widths = layoutResult.columns.widths;
    final primary = schema.style.primaryFlutterColor;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: schema.style.borderFlutterColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header (if enabled on this page)
          if (page.hasTableHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              child: Row(
                children: columns.map((col) {
                  final w = widths[col.key] ?? 60.0;
                  final isFlex = col.isFlex;
                  final textAlign = col.align == 'right'
                      ? TextAlign.right
                      : (col.align == 'center' ? TextAlign.center : TextAlign.left);

                  final headerWidget = Text(
                    col.label.toUpperCase(),
                    textAlign: textAlign,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  );

                  return isFlex ? Expanded(child: headerWidget) : SizedBox(width: w, child: headerWidget);
                }).toList(),
              ),
            ),

          // Table Rows
          if (page.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '— Continued on summary page —',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ),
            )
          else
            ...page.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isEven = idx.isEven;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isEven ? Colors.transparent : schema.style.zebraFlutterColor,
                  border: Border(bottom: BorderSide(color: schema.style.borderFlutterColor, width: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.map((col) {
                    final w = widths[col.key] ?? 60.0;
                    final isFlex = col.isFlex;
                    final align = col.align == 'right'
                        ? Alignment.centerRight
                        : (col.align == 'center' ? Alignment.center : Alignment.centerLeft);

                    Widget cellContent;
                    switch (col.key) {
                      case 'item':
                        cellContent = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                            if (item.description.isNotEmpty)
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                          ],
                        );
                        break;
                      case 'hsn':
                        cellContent = Text(item.hsn.isNotEmpty ? item.hsn : '998313', style: const TextStyle(fontSize: 11));
                        break;
                      case 'qty':
                        cellContent = Text(item.qty.toStringAsFixed(0), style: const TextStyle(fontSize: 11));
                        break;
                      case 'rate':
                        cellContent = Text('$currencySymbol${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11));
                        break;
                      case 'amount':
                      default:
                        cellContent = Text(
                          '$currencySymbol${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        );
                    }

                    return isFlex
                        ? Expanded(child: Align(alignment: align, child: cellContent))
                        : SizedBox(width: w, child: Align(alignment: align, child: cellContent));
                  }).toList(),
                ),
              );
            }),
        ],
      ),
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
            _buildTotalLine('Taxable Amount', '$currencySymbol${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _buildTotalLine('IGST / Taxes (18%)', '$currencySymbol${tax.toStringAsFixed(2)}'),
            const Divider(height: 14),
            _buildTotalLine(
              'Total Payable',
              '$currencySymbol${total.toStringAsFixed(2)}',
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BANK & PAYMENT ROUTING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                const Text('Bank: HDFC Bank Ltd  |  A/C: 50200049281094', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const Text('IFSC: HDFC0000128  |  UPI: invoicely@hdfcbank', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCBD5E1))),
            child: const Icon(Icons.qr_code_2, size: 48, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesAndTerms() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TERMS & NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          SizedBox(height: 2),
          Text(
            '1. Payment is strictly due within 15 days of invoice generation.\n2. Please mention the invoice number on the bank transfer reference.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock() {
    final signSec = schema.sectionOfType('signature');
    final label = signSec?.config.signatureLabel ?? 'Authorized Signatory';
    final signee = signSec?.config.signeeTitle ?? 'Director / Partner';

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 220,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 140,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: schema.style.primaryFlutterColor, width: 1.5)),
              ),
              child: Center(
                child: Text(
                  'DIGITALLY SIGNED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: schema.style.primaryFlutterColor.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text(signee, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(TemplatePageLayout page) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Computer generated document. Valid without physical signature.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
          Text(
            page.pageLabel,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
