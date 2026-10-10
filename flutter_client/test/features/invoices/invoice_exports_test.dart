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

  test('calculates security service items with staff and duty count', () {
    const item = InvoiceItem(
      description: 'Armed Security Guard',
      quantity: 4, // 4 guards
      dutyCount: 26, // 26 days/duty
      unitPrice: 500, // 500 per duty
      unit: 'guards',
    );

    expect(item.grossLineAmount, 4 * 26 * 500); // 52,000
    expect(item.total, 52000);
  });

  test('verifies security agency and category presets exist', () {
    final securityPresets = templatePresets.where((p) => p.businessCategory == 'Security Agency');
    expect(securityPresets.length, greaterThanOrEqualTo(6));
    expect(securityPresets.any((p) => p.designStyle == 'Modern'), isTrue);
    expect(securityPresets.any((p) => p.designStyle == 'Classic'), isTrue);
    expect(securityPresets.any((p) => p.designStyle == 'Corporate'), isTrue);
    expect(securityPresets.any((p) => p.designStyle == 'Industry'), isTrue);
  });

  test('generates PDF with QR payment payload and bank details', () async {
    final secInvoice = Invoice(
      invoiceNumber: 'SEC-2026-099',
      clientName: 'Alpha Security Client',
      issueDate: '2026-10-10',
      dueDate: '2026-10-31',
      items: const [
        InvoiceItem(
          description: 'Night Shift Supervisor',
          quantity: 2,
          dutyCount: 30,
          unitPrice: 650,
        ),
      ],
    );

    final secTemplate = templatePresets.firstWhere((p) => p.id == 'security_modern');
    final pdfBytes = await InvoicePdfExport.build(
      secInvoice,
      template: secTemplate,
      businessProfile: {
        'businessName': 'Vanguard Security Services',
        'bankName': 'HDFC Bank',
        'accountNumber': '50100987654321',
        'ifscCode': 'HDFC0001234',
        'upiId': 'vanguard@upi',
      },
    );

    expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    expect(pdfBytes.length, greaterThan(1000));
  });
}
