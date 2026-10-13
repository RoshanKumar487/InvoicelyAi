import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'document_template_schema.dart';
import 'template_layout_engine.dart';

class WysiwygPdfExporter {
  WysiwygPdfExporter._();

  static Future<Uint8List> build({
    required DocumentTemplateSchema schema,
    required TemplateLayoutResult layoutResult,
    String companyName = 'Acme Global Technologies Pvt Ltd',
    String clientName = 'Enterprise Client Corp',
    String currencySymbol = 'Rs.',
    String invoiceNumber = 'INV-2026-0881',
    String issueDate = '2026-10-15',
    String dueDate = '2026-10-30',
    double total = 142800.0,
    double subtotal = 120000.0,
    double tax = 22800.0,
  }) async {
    final pdf = pw.Document();

    final margins = schema.metadata;
    final primaryColor = PdfColor.fromHex(schema.style.primaryColor.replaceAll('#', ''));
    final zebraColor = PdfColor.fromHex(schema.style.zebraColor.replaceAll('#', ''));
    final borderColor = PdfColor.fromHex(schema.style.borderColor.replaceAll('#', ''));

    final format = schema.metadata.pageSize == TemplatePageSize.letter
        ? PdfPageFormat.letter
        : PdfPageFormat.a4;

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
                // 1. Header (Page 1 only)
                if (pageLayout.hasHeader) ...[
                  _buildPdfHeader(primaryColor, companyName, invoiceNumber, issueDate, dueDate),
                  pw.SizedBox(height: 12),
                ],

                // 2. Party Details
                if (pageLayout.hasPartyDetails) ...[
                  _buildPdfPartyDetails(borderColor, clientName),
                  pw.SizedBox(height: 14),
                ],

                // 3. Item Table
                _buildPdfItemTable(
                  pageLayout: pageLayout,
                  layoutResult: layoutResult,
                  primaryColor: primaryColor,
                  zebraColor: zebraColor,
                  borderColor: borderColor,
                  currencySymbol: currencySymbol,
                ),
                pw.SizedBox(height: 12),

                // 4. Totals Block
                if (pageLayout.hasTotals) ...[
                  _buildPdfTotalsBlock(borderColor, subtotal, tax, total, currencySymbol),
                  pw.SizedBox(height: 12),
                ],

                // 5. Bank & Payment info
                if (pageLayout.hasBankDetails) ...[
                  _buildPdfBankDetails(borderColor),
                  pw.SizedBox(height: 10),
                ],

                // 6. Notes & Terms
                if (pageLayout.hasNotes) ...[
                  _buildPdfNotes(borderColor),
                  pw.SizedBox(height: 10),
                ],

                // 7. Signature Block
                if (pageLayout.hasSignature) ...[
                  _buildPdfSignature(schema, primaryColor),
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

  static pw.Widget _buildPdfHeader(
    PdfColor primary,
    String company,
    String invNo,
    String issueDate,
    String dueDate,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              company,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'GSTIN: 27AABCU9603R1ZM  |  PAN: AABCU9603R',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
            pw.Text('Invoice #: $invNo', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Issue Date: $issueDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text('Due Date: $dueDate', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPdfPartyDetails(PdfColor border, String client) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(client, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('402, High Street Business Tower, Mumbai', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('GSTIN: 27AABCT3529Q1ZX', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DISPATCH & SUPPLY DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text('Place of Supply: 27 - Maharashtra', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Reverse Charge: No', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Vehicle No: MH-02-CD-4109', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfItemTable({
    required TemplatePageLayout pageLayout,
    required TemplateLayoutResult layoutResult,
    required PdfColor primaryColor,
    required PdfColor zebraColor,
    required PdfColor borderColor,
    required String currencySymbol,
  }) {
    final columns = layoutResult.columns.columns;
    final widths = layoutResult.columns.widths;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          // Header
          if (pageLayout.hasTableHeader)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: primaryColor,
              child: pw.Row(
                children: columns.map((col) {
                  final w = widths[col.key] ?? 60.0;
                  final textAlign = col.align == 'right'
                      ? pw.TextAlign.right
                      : (col.align == 'center' ? pw.TextAlign.center : pw.TextAlign.left);

                  final widget = pw.Text(
                    col.label.toUpperCase(),
                    textAlign: textAlign,
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                  );
                  return col.isFlex ? pw.Expanded(child: widget) : pw.SizedBox(width: w, child: widget);
                }).toList(),
              ),
            ),

          // Rows
          ...pageLayout.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isEven = idx.isEven;

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: isEven ? PdfColors.white : zebraColor,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: columns.map((col) {
                  final w = widths[col.key] ?? 60.0;
                  final align = col.align == 'right'
                      ? pw.Alignment.centerRight
                      : (col.align == 'center' ? pw.Alignment.center : pw.Alignment.centerLeft);

                  pw.Widget cell;
                  switch (col.key) {
                    case 'item':
                      cell = pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          if (item.description.isNotEmpty)
                            pw.Text(item.description, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        ],
                      );
                      break;
                    case 'hsn':
                      cell = pw.Text(item.hsn.isNotEmpty ? item.hsn : '998313', style: const pw.TextStyle(fontSize: 8.5));
                      break;
                    case 'qty':
                      cell = pw.Text(item.qty.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8.5));
                      break;
                    case 'rate':
                      cell = pw.Text('$currencySymbol${item.unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8.5));
                      break;
                    case 'amount':
                    default:
                      cell = pw.Text('$currencySymbol${item.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold));
                  }

                  return col.isFlex
                      ? pw.Expanded(child: pw.Align(alignment: align, child: cell))
                      : pw.SizedBox(width: w, child: pw.Align(alignment: align, child: cell));
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTotalsBlock(
    PdfColor border,
    double subtotal,
    double tax,
    double total,
    String currency,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            _buildPdfLine('Taxable Amount', '$currency${subtotal.toStringAsFixed(2)}'),
            pw.SizedBox(height: 3),
            _buildPdfLine('IGST / Taxes (18%)', '$currency${tax.toStringAsFixed(2)}'),
            pw.Divider(thickness: 0.8),
            _buildPdfLine('Total Payable', '$currency${total.toStringAsFixed(2)}', bold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfLine(String label, String val, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(val, style: pw.TextStyle(fontSize: 8.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static pw.Widget _buildPdfBankDetails(PdfColor border) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BANK & PAYMENT ROUTING', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          pw.Text('Bank: HDFC Bank Ltd  |  A/C: 50200049281094', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          pw.Text('IFSC: HDFC0000128  |  UPI: invoicely@hdfcbank', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfNotes(PdfColor border) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          pw.Text('Payment is strictly due within 15 days of invoice generation.', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSignature(DocumentTemplateSchema schema, PdfColor primary) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 160,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              height: 32,
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: primary, width: 1))),
              child: pw.Center(
                child: pw.Text('DIGITALLY SIGNED', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primary)),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            pw.Text('Director / Partner', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfFooter(String pageLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Computer generated document. Valid without physical signature.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        pw.Text(pageLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
