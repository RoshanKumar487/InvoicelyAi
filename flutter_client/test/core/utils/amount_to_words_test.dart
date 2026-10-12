import 'package:flutter_test/flutter_test.dart';
import 'package:invoicely_flutter/src/core/utils/amount_to_words.dart';

void main() {
  group('AmountToWords', () {
    test('converts basic whole amounts in INR', () {
      expect(
        AmountToWords.convert(21000, currency: 'INR'),
        'Indian Rupees Twenty-One Thousand Only',
      );
      expect(
        AmountToWords.convert(30000, currency: 'INR'),
        'Indian Rupees Thirty Thousand Only',
      );
      expect(
        AmountToWords.convert(12000, currency: 'INR'),
        'Indian Rupees Twelve Thousand Only',
      );
    });

    test('converts Lakhs and Crores properly in Indian numbering', () {
      expect(
        AmountToWords.convert(150000, currency: 'INR'),
        'Indian Rupees One Lakh Fifty Thousand Only',
      );
      expect(
        AmountToWords.convert(2575250, currency: 'INR'),
        'Indian Rupees Twenty-Five Lakh Seventy-Five Thousand Two Hundred Fifty Only',
      );
      expect(
        AmountToWords.convert(10000000, currency: 'INR'),
        'Indian Rupees One Crore Only',
      );
    });

    test('handles decimals (paise)', () {
      expect(
        AmountToWords.convert(21000.50, currency: 'INR'),
        'Indian Rupees Twenty-One Thousand and Fifty Paise Only',
      );
      expect(
        AmountToWords.convert(500.05, currency: 'INR'),
        'Indian Rupees Five Hundred and Five Paise Only',
      );
    });

    test('handles zero and international currencies', () {
      expect(
        AmountToWords.convert(0, currency: 'INR'),
        'Indian Rupees Zero Only',
      );
      expect(
        AmountToWords.convert(25000, currency: 'USD'),
        'US Dollars Twenty-Five Thousand Only',
      );
    });
  });
}
