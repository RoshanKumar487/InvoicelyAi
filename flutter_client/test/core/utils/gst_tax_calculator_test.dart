import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/core/utils/gst_tax_calculator.dart';

void main() {
  group('GstTaxCalculator', () {
    test('splits intra-state GST into CGST and SGST', () {
      final res = GstTaxCalculator.calculate(
        taxableAmount: 20000,
        taxRate: 18,
        supplierPlaceOfSupply: 'Maharashtra',
        clientPlaceOfSupply: 'Maharashtra',
      );
      expect(res.taxLines.length, 2);
      expect(res.taxLines[0].label, 'CGST (9%)');
      expect(res.taxLines[0].amount, 1800.0);
      expect(res.taxLines[1].label, 'SGST (9%)');
      expect(res.taxLines[1].amount, 1800.0);
      expect(res.totalTaxAmount, 3600.0);
      expect(res.isInterState, false);
    });

    test('calculates IGST for inter-state supply', () {
      final res = GstTaxCalculator.calculate(
        taxableAmount: 20000,
        taxRate: 18,
        supplierPlaceOfSupply: 'Maharashtra',
        clientPlaceOfSupply: 'Gujarat',
      );
      expect(res.taxLines.length, 1);
      expect(res.taxLines[0].label, 'IGST (18%)');
      expect(res.taxLines[0].amount, 3600.0);
      expect(res.isInterState, true);
    });

    test('handles RCM correctly', () {
      final res = GstTaxCalculator.calculate(
        taxableAmount: 20000,
        taxRate: 18,
        isRcm: true,
      );
      expect(res.isRcm, true);
      expect(res.totalTaxAmount, 0.0);
      expect(res.taxLines.isEmpty, true);
      expect(res.rcmNote, contains('Reverse Charge'));
    });
  });
}
