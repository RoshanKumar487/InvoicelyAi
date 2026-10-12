class AmountToWords {
  AmountToWords._();

  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String convert(double amount, {String currency = 'INR'}) {
    if (amount.isNaN || amount.isInfinite) return '';
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final integerPart = absAmount.truncate();
    final decimalPart = ((absAmount - integerPart) * 100).round();

    final isIndian = currency.toUpperCase() == 'INR' || currency == '₹' || currency.toUpperCase() == 'RS.';
    final words = isIndian
        ? _convertIndian(integerPart)
        : _convertInternational(integerPart);

    final currencyPrefix = isIndian
        ? 'Indian Rupees'
        : (currency.toUpperCase() == 'USD' || currency == r'$')
            ? 'US Dollars'
            : (currency.toUpperCase() == 'EUR' || currency == '€')
                ? 'Euros'
                : (currency.toUpperCase() == 'GBP' || currency == '£')
                    ? 'British Pounds'
                    : currency.toUpperCase();

    final mainText = integerPart == 0 ? 'Zero' : words;
    final buffer = StringBuffer();
    if (isNegative) buffer.write('Minus ');
    buffer.write('$currencyPrefix $mainText');

    if (decimalPart > 0) {
      final decimalWords = _convertTwoDigits(decimalPart);
      final subunit = isIndian ? 'Paise' : 'Cents';
      buffer.write(' and $decimalWords $subunit');
    }

    buffer.write(' Only');
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _convertTwoDigits(int n) {
    if (n < 20) return _units[n];
    final ten = _tens[n ~/ 10];
    final unit = _units[n % 10];
    return unit.isEmpty ? ten : '$ten-$unit';
  }

  static String _convertThreeDigits(int n) {
    final hundred = n ~/ 100;
    final rest = n % 100;
    final buffer = StringBuffer();
    if (hundred > 0) {
      buffer.write('${_units[hundred]} Hundred');
    }
    if (rest > 0) {
      if (hundred > 0) buffer.write(' ');
      buffer.write(_convertTwoDigits(rest));
    }
    return buffer.toString();
  }

  // Indian Numbering Format: Crores (1,00,00,000), Lakhs (1,00,000), Thousands (1,000), Hundreds (100)
  static String _convertIndian(int n) {
    if (n == 0) return 'Zero';
    final parts = <String>[];

    final crores = n ~/ 10000000;
    var rem = n % 10000000;

    final lakhs = rem ~/ 100000;
    rem = rem % 100000;

    final thousands = rem ~/ 1000;
    rem = rem % 1000;

    final hundredsAndRest = rem;

    if (crores > 0) {
      parts.add('${_convertIndian(crores)} Crore');
    }
    if (lakhs > 0) {
      parts.add('${_convertIndian(lakhs)} Lakh');
    }
    if (thousands > 0) {
      parts.add('${_convertIndian(thousands)} Thousand');
    }
    if (hundredsAndRest > 0) {
      parts.add(_convertThreeDigits(hundredsAndRest));
    }

    return parts.join(' ');
  }

  // International Numbering Format: Billions, Millions, Thousands, Hundreds
  static String _convertInternational(int n) {
    if (n == 0) return 'Zero';
    final parts = <String>[];

    final billions = n ~/ 1000000000;
    var rem = n % 1000000000;

    final millions = rem ~/ 1000000;
    rem = rem % 1000000;

    final thousands = rem ~/ 1000;
    rem = rem % 1000;

    final hundredsAndRest = rem;

    if (billions > 0) {
      parts.add('${_convertThreeDigits(billions)} Billion');
    }
    if (millions > 0) {
      parts.add('${_convertThreeDigits(millions)} Million');
    }
    if (thousands > 0) {
      parts.add('${_convertThreeDigits(thousands)} Thousand');
    }
    if (hundredsAndRest > 0) {
      parts.add(_convertThreeDigits(hundredsAndRest));
    }

    return parts.join(' ');
  }
}
