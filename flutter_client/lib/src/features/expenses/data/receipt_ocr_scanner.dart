import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'expense.dart';

class ScannedReceiptData {
  const ScannedReceiptData({
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.currencySymbol,
    required this.date,
    required this.taxAmount,
    required this.category,
    required this.title,
    required this.notes,
    required this.rawText,
  });

  final String vendor;
  final double amount;
  final String currency;
  final String currencySymbol;
  final String date;
  final double taxAmount;
  final String category;
  final String title;
  final String notes;
  final String rawText;

  Expense toExpenseDraft({
    String? receiptImageUri,
    int? companyId,
  }) {
    return Expense(
      companyId: companyId,
      title: title.isNotEmpty ? title : (vendor.isNotEmpty ? '$vendor Expense' : 'Receipt Expense'),
      category: category,
      amount: amount,
      currency: currency,
      currencySymbol: currencySymbol,
      date: date,
      vendor: vendor,
      paymentMethod: 'Credit Card',
      taxDeductible: true,
      taxAmount: taxAmount,
      receiptImageUri: receiptImageUri,
      notes: notes,
    );
  }
}

class ReceiptOcrScanner {
  const ReceiptOcrScanner();

  static Future<ScannedReceiptData> scan({
    required String imagePath,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return parse(recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }

  static ScannedReceiptData parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final vendor = _extractVendor(lines);
    final amount = _extractTotalAmount(lines, rawText);
    final taxAmount = _extractTaxAmount(lines);
    final date = _extractDate(lines);
    final (currency, currencySymbol) = _extractCurrency(rawText);
    final category = _categorize(vendor, rawText);
    final notes = _buildSummaryNotes(lines, vendor, rawText);

    final title = vendor.isNotEmpty
        ? '$vendor - $category'
        : (amount > 0 ? 'Business Expense ($currencySymbol$amount)' : 'Receipt Expense');

    return ScannedReceiptData(
      vendor: vendor,
      amount: amount,
      currency: currency,
      currencySymbol: currencySymbol,
      date: date,
      taxAmount: taxAmount,
      category: category,
      title: title,
      notes: notes,
      rawText: rawText,
    );
  }

  static String _extractVendor(List<String> lines) {
    final skipPatterns = [
      RegExp(r'^(tax\s+)?invoice', caseSensitive: false),
      RegExp(r'^(cash\s+)?receipt', caseSensitive: false),
      RegExp(r'^(cash\s+)?memo', caseSensitive: false),
      RegExp(r'^bill\s+of\s+supply', caseSensitive: false),
      RegExp(r'^customer\s+copy', caseSensitive: false),
      RegExp(r'^original\s+for\s+recipient', caseSensitive: false),
      RegExp(r'^welcome', caseSensitive: false),
      RegExp(r'^thank\s+you', caseSensitive: false),
      RegExp(r'^\d+$'),
      RegExp(r'^(date|time|tel|ph|phone|email|www|http|gstin|pan|cin)', caseSensitive: false),
    ];

    for (final line in lines.take(8)) {
      if (line.length < 3 || line.length > 50) continue;
      final shouldSkip = skipPatterns.any((pattern) => pattern.hasMatch(line));
      if (!shouldSkip) {
        return line.replaceAll(RegExp(r'[*#_]'), '').trim();
      }
    }
    return lines.isNotEmpty ? lines.first : '';
  }

  static double _extractTotalAmount(List<String> lines, String rawText) {
    // 1. Look for explicit Total / Grand Total / Net Amount labels
    final totalPatterns = [
      RegExp(r'(?:grand\s+total|total\s+amount|net\s+amount|balance\s+due|total\s+due|payable|amount\s+due|total)\s*[:=]?\s*[$₹€£]?\s*([0-9,]+\.?[0-9]{0,2})', caseSensitive: false),
      RegExp(r'(?:total\s+(?:inr|rs|usd|eur|gbp))\s*[:=]?\s*([0-9,]+\.?[0-9]{0,2})', caseSensitive: false),
    ];

    for (final line in lines.reversed) {
      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          final clean = match.group(1)!.replaceAll(',', '');
          final val = double.tryParse(clean);
          if (val != null && val > 0 && val < 100000000) {
            return val;
          }
        }
      }
    }

    // 2. Look for lines with currency symbols and numbers
    final currencyPattern = RegExp(r'[$₹€£]\s*([0-9,]+\.[0-9]{2})');
    final matches = currencyPattern.allMatches(rawText);
    double maxCurrencyAmount = 0;
    for (final match in matches) {
      final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (val != null && val > maxCurrencyAmount && val < 5000000) {
        maxCurrencyAmount = val;
      }
    }
    if (maxCurrencyAmount > 0) return maxCurrencyAmount;

    // 3. Fallback: look for general two-decimal numbers near the bottom
    final decimalPattern = RegExp(r'\b([0-9,]+\.[0-9]{2})\b');
    for (final line in lines.reversed.take(10)) {
      final m = decimalPattern.firstMatch(line);
      if (m != null) {
        final val = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (val != null && val > 0 && val < 5000000) {
          return val;
        }
      }
    }

    return 0;
  }

  static double _extractTaxAmount(List<String> lines) {
    final taxHeaderPattern = RegExp(
      r'\b(cgst|sgst|igst|vat|sales\s+tax|service\s+tax|tax\s+amount|tax)\b',
      caseSensitive: false,
    );
    final amountPattern = RegExp(r'[$₹€£]?\s*([0-9,]+\.[0-9]{2})');

    double totalTax = 0;
    for (final line in lines) {
      if (!taxHeaderPattern.hasMatch(line)) continue;
      final cleanedLine = line.replaceAll(RegExp(r'\d+(\.\d+)?%'), '');
      final match = amountPattern.allMatches(cleanedLine).lastOrNull;
      if (match != null && match.group(1) != null) {
        final val = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && val > 0 && val < 100000) {
          totalTax += val;
        }
      }
    }
    return totalTax;
  }

  static String _extractDate(List<String> lines) {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final ymdPattern = RegExp(r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\b');
    final dmyPattern = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b');
    final monthNames = {
      'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
      'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
      'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
    };
    final namedMonthPattern = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})\b',
    );

    for (final line in lines) {
      final namedMatch = namedMonthPattern.firstMatch(line);
      if (namedMatch != null) {
        final day = namedMatch.group(1)!.padLeft(2, '0');
        final monthRaw = namedMatch.group(2)!.substring(0, 3).toLowerCase();
        final yearRaw = namedMatch.group(3)!;
        final year = yearRaw.length == 2 ? '20$yearRaw' : yearRaw;
        final month = monthNames[monthRaw];
        if (month != null) {
          return '$year-$month-$day';
        }
      }

      final ymdMatch = ymdPattern.firstMatch(line);
      if (ymdMatch != null) {
        final y = ymdMatch.group(1)!;
        final m = ymdMatch.group(2)!.padLeft(2, '0');
        final d = ymdMatch.group(3)!.padLeft(2, '0');
        if (int.tryParse(m)! <= 12 && int.tryParse(d)! <= 31) {
          return '$y-$m-$d';
        }
      }

      final dmyMatch = dmyPattern.firstMatch(line);
      if (dmyMatch != null) {
        final d = dmyMatch.group(1)!.padLeft(2, '0');
        final m = dmyMatch.group(2)!.padLeft(2, '0');
        final yRaw = dmyMatch.group(3)!;
        final y = yRaw.length == 2 ? '20$yRaw' : yRaw;
        if (int.tryParse(m)! <= 12 && int.tryParse(d)! <= 31) {
          return '$y-$m-$d';
        }
      }
    }
    return today;
  }

  static (String, String) _extractCurrency(String rawText) {
    final lower = rawText.toLowerCase();
    if (rawText.contains('₹') || lower.contains('inr') || lower.contains('rs.') || lower.contains('rupees')) {
      return ('INR', '₹');
    }
    if (rawText.contains('€') || lower.contains('eur')) {
      return ('EUR', '€');
    }
    if (rawText.contains('£') || lower.contains('gbp')) {
      return ('GBP', '£');
    }
    if (rawText.contains(r'$') || lower.contains('usd')) {
      return ('USD', r'$');
    }
    return ('INR', '₹');
  }

  static String _categorize(String vendor, String rawText) {
    final text = '$vendor $rawText'.toLowerCase();

    if (text.contains('uber') ||
        text.contains('ola') ||
        text.contains('cab') ||
        text.contains('taxi') ||
        text.contains('flight') ||
        text.contains('airline') ||
        text.contains('indigo') ||
        text.contains('air india') ||
        text.contains('petrol') ||
        text.contains('fuel') ||
        text.contains('diesel') ||
        text.contains('toll') ||
        text.contains('irctc') ||
        text.contains('metro') ||
        text.contains('parking')) {
      return 'Travel & Transport';
    }

    if (text.contains('restaurant') ||
        text.contains('cafe') ||
        text.contains('coffee') ||
        text.contains('starbucks') ||
        text.contains('food') ||
        text.contains('dinner') ||
        text.contains('lunch') ||
        text.contains('breakfast') ||
        text.contains('pizza') ||
        text.contains('burger') ||
        text.contains('swiggy') ||
        text.contains('zomato') ||
        text.contains('mcdonald') ||
        text.contains('subway') ||
        text.contains('tea') ||
        text.contains('bar') ||
        text.contains('kitchen') ||
        text.contains('dining') ||
        text.contains('bistro')) {
      return 'Meals & Entertainment';
    }

    if (text.contains('aws') ||
        text.contains('amazon web') ||
        text.contains('google cloud') ||
        text.contains('azure') ||
        text.contains('github') ||
        text.contains('gitlab') ||
        text.contains('software') ||
        text.contains('hosting') ||
        text.contains('domain') ||
        text.contains('zoom') ||
        text.contains('slack') ||
        text.contains('jetbrains') ||
        text.contains('adobe') ||
        text.contains('microsoft') ||
        text.contains('openai') ||
        text.contains('gemini') ||
        text.contains('saas')) {
      return 'Software & IT';
    }

    if (text.contains('apple') ||
        text.contains('dell') ||
        text.contains('lenovo') ||
        text.contains('hp') ||
        text.contains('croma') ||
        text.contains('reliance digital') ||
        text.contains('hardware') ||
        text.contains('electronic') ||
        text.contains('laptop') ||
        text.contains('monitor') ||
        text.contains('printer') ||
        text.contains('mouse') ||
        text.contains('keyboard')) {
      return 'Hardware & Equipment';
    }

    if (text.contains('facebook ads') ||
        text.contains('meta') ||
        text.contains('google ads') ||
        text.contains('adwords') ||
        text.contains('marketing') ||
        text.contains('linkedin ads') ||
        text.contains('flyer') ||
        text.contains('banner') ||
        text.contains('branding')) {
      return 'Marketing & Ads';
    }

    if (text.contains('office') ||
        text.contains('rent') ||
        text.contains('lease') ||
        text.contains('stationery') ||
        text.contains('paper') ||
        text.contains('depot') ||
        text.contains('staples') ||
        text.contains('desk') ||
        text.contains('coworking') ||
        text.contains('wework') ||
        text.contains('supply')) {
      return 'Office & Rent';
    }

    return 'General Business';
  }

  static String _buildSummaryNotes(List<String> lines, String vendor, String rawText) {
    final previewLines = lines
        .where((l) => l.length > 3 && l != vendor)
        .take(6)
        .join(' • ');
    if (previewLines.isNotEmpty) {
      return 'Scanned lines: $previewLines';
    }
    return 'Scanned via On-Device ML Kit OCR';
  }
}
