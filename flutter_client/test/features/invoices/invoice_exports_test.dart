import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/invoices/data/invoice.dart';
import 'package:invoicely_flutter/src/features/invoices/data/invoice_docx_export.dart';
import 'package:invoicely_flutter/src/features/invoices/data/invoice_pdf_export.dart';
import 'package:invoicely_flutter/src/features/templates/data/template_config.dart';

void main() {
  final invoice = Invoice(
    invoiceNumber: 'INV-2026-001',
    clientName: 'Sample Client',
    clientEmail: 'client@example.test',
    issueDate: '2026-01-01',
    dueDate: '2026-01-31',
    items: const [
      InvoiceItem(
        description: 'Consulting service',
        quantity: 2,
        unitPrice: 150,
      ),
    ],
    templateId: 'gst_tax',
  );

  test('builds a readable PDF document', () async {
    final bytes = await InvoicePdfExport.build(
      invoice,
      template: templatePresets.first,
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });

  test('builds a DOCX archive with a Word document body', () {
    final bytes = InvoiceDocxExport.build(invoice);
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(
      archive.files.map((file) => file.name),
      containsAll(['[Content_Types].xml', 'word/document.xml']),
    );
  });

  test('embeds local branding and shipping details in invoice PDFs', () async {
    const onePixelPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC';
    final brandedInvoice = Invoice(
      invoiceNumber: invoice.invoiceNumber,
      clientName: invoice.clientName,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      shippingDetailsJson: jsonEncode({
        'isEnabled': true,
        'deliveryAddress': '123 Main Street',
        'courier': 'Example Carrier',
      }),
      items: invoice.items,
    );

    final bytes = await InvoicePdfExport.build(
      brandedInvoice,
      localSettings: {
        'invoiceLogo': onePixelPng,
        'invoiceSignature': onePixelPng,
        'invoiceStamp': onePixelPng,
      },
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(700));
  });

  test('round-trips saved template configuration', () {
    final original = templatePresets.first.copyWith(
      footer: 'Saved footer',
      showTaxBreakdown: false,
    );

    final restored = TemplateConfig.tryDecode(original.encode());

    expect(restored?.id, original.id);
    expect(restored?.footer, 'Saved footer');
    expect(restored?.showTaxBreakdown, isFalse);
  });
}
