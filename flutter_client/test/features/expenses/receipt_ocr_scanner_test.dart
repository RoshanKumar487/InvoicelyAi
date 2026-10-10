import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/features/expenses/data/receipt_ocr_scanner.dart';

void main() {
  group('ReceiptOcrScanner parser', () {
    test('correctly extracts vendor, total amount, GST, date and category from Indian receipt', () {
      const sampleOcrText = '''
STARBUCKS COFFEE
Tata Starbucks Private Limited
GSTIN: 27AABCT3456C1Z1
Date: 15/09/2026
Time: 14:32:10

1 Caffe Latte       245.00
1 Blueberry Muffin  180.00
Subtotal            425.00
CGST 2.5%            10.63
SGST 2.5%            10.63
Total Due: ₹ 446.26
Payment: UPI / Card
Thank you for visiting!
''';

      final result = ReceiptOcrScanner.parse(sampleOcrText);

      expect(result.vendor, contains('STARBUCKS'));
      expect(result.amount, equals(446.26));
      expect(result.currency, equals('INR'));
      expect(result.currencySymbol, equals('₹'));
      expect(result.date, equals('2026-09-15'));
      expect(result.taxAmount, closeTo(21.26, 0.01));
      expect(result.category, equals('Meals & Entertainment'));
      expect(result.title, contains('STARBUCKS'));
    });

    test('correctly extracts Uber travel receipt', () {
      const sampleUberText = '''
Uber India Systems Pvt Ltd
Ride receipt
Date: 2026-08-20
Trip to International Airport

Trip Fare: 850.00
Toll Charges: 120.00
CGST: 25.00
SGST: 25.00
Total Amount: ₹ 1020.00
Paid with Credit Card
''';

      final result = ReceiptOcrScanner.parse(sampleUberText);

      expect(result.vendor, contains('Uber'));
      expect(result.amount, equals(1020.00));
      expect(result.currency, equals('INR'));
      expect(result.currencySymbol, equals('₹'));
      expect(result.date, equals('2026-08-20'));
      expect(result.category, equals('Travel & Transport'));
    });

    test('correctly converts ScannedReceiptData to Expense draft', () {
      const sampleAwsText = '''
AWS Cloud Services
Invoice Date: 10-07-2026
EC2 Compute Instance
Total: \$ 150.00
''';
      final data = ReceiptOcrScanner.parse(sampleAwsText);

      final expense = data.toExpenseDraft(receiptImageUri: '/path/to/receipt.jpg');

      expect(expense.vendor, contains('AWS'));
      expect(expense.amount, equals(150.00));
      expect(expense.currency, equals('USD'));
      expect(expense.currencySymbol, equals(r'$'));
      expect(expense.category, equals('Software & IT'));
      expect(expense.receiptImageUri, equals('/path/to/receipt.jpg'));
    });
  });
}
