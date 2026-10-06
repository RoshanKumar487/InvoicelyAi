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
  }) async {
    bool show(String key) => localSettings[key] != false;
    final document = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: invoice.clientName,
      subject: 'Invoice ${invoice.invoiceNumber}',
    );
    final brand = PdfColor.fromInt(_parseColor(template?.color ?? '#1E3A8A'));
    final secondary =
        PdfColor.fromInt(_parseColor(template?.secondaryColor ?? '#0D9488'));
    final title = template?.title ?? 'INVOICE';

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
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        color: brand,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice ${invoice.invoiceNumber}'),
                    if (show('showStatus'))
                      pw.Text('Status: ${invoice.status}'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (show('showIssueDate'))
                    pw.Text('Issue date: ${invoice.issueDate}'),
                  if (show('showDueDate'))
                    pw.Text('Due date: ${invoice.dueDate}'),
                  if (show('showPoNumber') && invoice.poNumber.isNotEmpty)
                    pw.Text('PO: ${invoice.poNumber}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Container(height: 2, color: secondary),
          pw.SizedBox(height: 18),
          pw.Text(
            'BILL TO',
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
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              template?.itemHeader ?? 'Description',
              if (show('showItemQty')) template?.quantityHeader ?? 'Qty',
              if (show('showItemRate')) template?.rateHeader ?? 'Rate',
              if (show('showItemDiscount')) 'Discount',
              if (show('showItemTax')) 'Tax',
              template?.amountHeader ?? 'Amount',
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
                    if (show('showItemDiscount')) '${item.discountRate}%',
                    if (show('showItemTax')) '${item.taxRate}%',
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
                          (show('showItemDiscount') ? 1 : 0) +
                          (show('showItemTax') ? 1 : 0) +
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
                  _line('Subtotal',
                      _money(invoice.subtotal, invoice.currencySymbol)),
                  if (invoice.totalDiscount != 0)
                    _line(
                      'Discount',
                      '-${_money(invoice.totalDiscount, invoice.currencySymbol)}',
                    ),
                  if (template?.showTaxBreakdown != false)
                    _line(
                      '${invoice.taxLabel} (${invoice.taxRate}%)',
                      _money(invoice.taxAmount, invoice.currencySymbol),
                    ),
                  if (show('showShippingSection') && invoice.shippingFee != 0)
                    _line(
                      'Shipping',
                      _money(invoice.shippingFee, invoice.currencySymbol),
                    ),
                  if (show('showShippingSection') &&
                      invoice.additionalCharges != 0)
                    _line(
                      'Additional charges',
                      _money(invoice.additionalCharges, invoice.currencySymbol),
                    ),
                  if (invoice.roundOff != 0)
                    _line(
                      'Round off',
                      _money(invoice.roundOff, invoice.currencySymbol),
                    ),
                  pw.Divider(color: brand),
                  _line(
                    'Total',
                    _money(invoice.total, invoice.currencySymbol),
                    bold: true,
                  ),
                  _line(
                    'Paid',
                    _money(invoice.amountPaid, invoice.currencySymbol),
                  ),
                  _line(
                    'Balance due',
                    _money(invoice.balanceDue, invoice.currencySymbol),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          if (show('showNotesSection') &&
              show('showNotes') &&
              invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Notes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes),
          ],
          if (show('showNotesSection') &&
              show('showTerms') &&
              invoice.terms.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Terms and conditions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoice.terms),
          ],
          if (show('showNotesSection') &&
              show('showPaymentInstructions') &&
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

  static int _parseColor(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return const Color(0xFF1E3A8A).toARGB32();
    return normalized.length == 6 ? 0xFF000000 | parsed : parsed;
  }
}
