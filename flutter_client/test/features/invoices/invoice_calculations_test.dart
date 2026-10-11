import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/invoices/data/invoice.dart';

void main() {
  group('InvoiceItem Formula Calculations', () {
    test('monthly_salary_26 calculates (Staff × Duty × Salary) / 26 correctly', () {
      const item = InvoiceItem(
        description: 'Security Guard (12 Hrs Shift)',
        quantity: 1,
        dutyCount: 26,
        unitPrice: 18500,
        calculationFormula: 'monthly_salary_26',
        standardDutyDays: 26,
      );

      // (1 × 26 × 18500) / 26 = 18500.0
      expect(item.grossLineAmount, equals(18500.0));
      expect(item.total, equals(18500.0));
    });

    test('monthly_salary_26 handles partial duties accurately', () {
      const item = InvoiceItem(
        description: 'Security Guard (12 Hrs Shift)',
        quantity: 1,
        dutyCount: 13, // worked half month
        unitPrice: 18500,
        calculationFormula: 'monthly_salary_26',
        standardDutyDays: 26,
      );

      // (1 × 13 × 18500) / 26 = 9250.0
      expect(item.grossLineAmount, equals(9250.0));
    });

    test('monthly_salary_26 scales with multiple guards and duties', () {
      const item = InvoiceItem(
        description: 'Security Guard (12 Hrs Shift)',
        quantity: 4,
        dutyCount: 26,
        unitPrice: 18500,
        calculationFormula: 'monthly_salary_26',
        standardDutyDays: 26,
      );

      // (4 × 26 × 18500) / 26 = 74000.0
      expect(item.grossLineAmount, equals(74000.0));
    });

    test('monthly_salary_30 calculates (Staff × Duty × Salary) / 30', () {
      const item = InvoiceItem(
        description: 'Commercial Guard',
        quantity: 2,
        dutyCount: 30,
        unitPrice: 15000,
        calculationFormula: 'monthly_salary_30',
        standardDutyDays: 30,
      );

      // (2 × 30 × 15000) / 30 = 30000.0
      expect(item.grossLineAmount, equals(30000.0));
    });

    test('calendar_month calculates (Net Salary / Month Days) × Duty Days exactly', () {
      const item = InvoiceItem(
        description: 'Security Guard',
        quantity: 1,
        dutyCount: 21,
        unitPrice: 30000,
        calculationFormula: 'calendar_month',
        standardDutyDays: 30, // 30 calendar days in month
      );

      // (1 × 21 × 30000) / 30 = 21000.0
      expect(item.grossLineAmount, equals(21000.0));
      expect(item.total, equals(21000.0));
    });

    test('calendar_month handles 31-day month pro-rata correctly', () {
      const item = InvoiceItem(
        description: 'Site Supervisor',
        quantity: 1,
        dutyCount: 31,
        unitPrice: 31000,
        calculationFormula: 'calendar_month',
        standardDutyDays: 31, // 31 calendar days in month (e.g. October)
      );

      // (1 × 31 × 31000) / 31 = 31000.0
      expect(item.grossLineAmount, equals(31000.0));
    });

    test('per_duty calculates Guards × Duties × Daily Rate', () {
      const item = InvoiceItem(
        description: 'Bouncer / Event Security',
        quantity: 2,
        dutyCount: 5,
        unitPrice: 2500,
        calculationFormula: 'per_duty',
      );

      // 2 × 5 × 2500 = 25000.0
      expect(item.grossLineAmount, equals(25000.0));
    });

    test('flat_monthly calculates Guards × Monthly Salary directly', () {
      const item = InvoiceItem(
        description: 'Security Supervisor',
        quantity: 2,
        dutyCount: 26,
        unitPrice: 24000,
        calculationFormula: 'flat_monthly',
      );

      // 2 × 24000 = 48000.0
      expect(item.grossLineAmount, equals(48000.0));
    });

    test('standard calculates Quantity × Unit Price', () {
      const item = InvoiceItem(
        description: 'CCTV Camera Unit',
        quantity: 10,
        dutyCount: 0,
        unitPrice: 3500,
        calculationFormula: 'standard',
      );

      // 10 × 3500 = 35000.0
      expect(item.grossLineAmount, equals(35000.0));
    });

    test('JSON serialization preserves formula and standardDutyDays', () {
      const item = InvoiceItem(
        description: 'Armed Guard',
        quantity: 1,
        dutyCount: 26,
        unitPrice: 28000,
        calculationFormula: 'monthly_salary_26',
        standardDutyDays: 26,
      );

      final json = item.toJson();
      final decoded = InvoiceItem.fromJson(json);

      expect(decoded.calculationFormula, equals('monthly_salary_26'));
      expect(decoded.standardDutyDays, equals(26.0));
      expect(decoded.grossLineAmount, equals(28000.0));
    });
  });

  group('Invoice Reverse Charge Mechanism (RCM)', () {
    test('Standard forward charge calculates GST on taxable amount', () {
      const item = InvoiceItem(
        description: 'Service',
        quantity: 1,
        unitPrice: 10000,
      );
      final invoice = Invoice(
        invoiceNumber: 'INV-001',
        clientName: 'Client Alpha',
        issueDate: '2026-10-11',
        dueDate: '2026-10-26',
        taxRate: 18,
        isRcm: false,
        items: [item],
      );

      expect(invoice.subtotal, equals(10000.0));
      expect(invoice.taxAmount, equals(1800.0));
      expect(invoice.total, equals(11800.0));
    });

    test('RCM invoice calculates ₹0.00 tax on bill (tax payable by recipient)', () {
      const item = InvoiceItem(
        description: 'Security Services',
        quantity: 1,
        dutyCount: 26,
        unitPrice: 18500,
        calculationFormula: 'monthly_salary_26',
      );
      final invoice = Invoice(
        invoiceNumber: 'INV-002',
        clientName: 'Client Beta',
        issueDate: '2026-10-11',
        dueDate: '2026-10-26',
        taxRate: 18,
        isRcm: true,
        items: [item],
      );

      expect(invoice.subtotal, equals(18500.0));
      expect(invoice.taxAmount, equals(0.0)); // No tax charged to client on bill
      expect(invoice.total, equals(18500.0));
    });

    test('Invoice JSON serialization preserves isRcm flag', () {
      final invoice = Invoice(
        invoiceNumber: 'INV-003',
        clientName: 'Client Gamma',
        issueDate: '2026-10-11',
        dueDate: '2026-10-26',
        taxRate: 18,
        isRcm: true,
        items: const [],
      );

      final json = invoice.toJson();
      expect(json['isRcm'], isTrue);

      final decoded = Invoice.fromJson(json);
      expect(decoded.isRcm, isTrue);
      expect(decoded.taxAmount, equals(0.0));
    });
  });
}
