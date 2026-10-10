import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

enum ReportType {
  invoices('Invoices', Icons.receipt_long_outlined),
  expenses('Expenses', Icons.payments_outlined),
  clients('Clients', Icons.people_outline);

  const ReportType(this.label, this.icon);

  final String label;
  final IconData icon;
}

DateTime? parseRecordDateValue(Object? value) {
  if (value is num) {
    final milliseconds = value.toInt();
    if (milliseconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  if (value is String && value.trim().isNotEmpty) {
    final numeric = int.tryParse(value);
    if (numeric != null) return parseRecordDateValue(numeric);
    return DateTime.tryParse(value);
  }
  return null;
}

DateTime dayStart(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime dayEnd(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

String formatReportDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String reportText(Object? value, {String fallback = '—'}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

double reportNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String reportMoney(double amount, Map<String, dynamic> row) {
  final symbol = row['currencySymbol']?.toString() ?? '';
  final currency =
      row['currencyCode']?.toString() ?? row['currency']?.toString() ?? '';
  final prefix =
      symbol.isNotEmpty ? symbol : (currency.isNotEmpty ? '$currency ' : '');
  return '$prefix${amount.toStringAsFixed(2)}';
}

String creatorNameFromRow(Map<String, dynamic> row) {
  for (final key in const [
    'createdByUserName',
    'creatorName',
    'createdByName',
    'createdBy',
  ]) {
    final value = row[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

double calculateInvoiceTotal(Map<String, dynamic> invoice) {
  final explicit = invoice['total'] ?? invoice['grandTotal'];
  if (explicit != null) return reportNumber(explicit);
  final items = invoice['itemsJson'];
  Object? decodedItems = items;
  if (items is String && items.isNotEmpty) {
    try {
      decodedItems = jsonDecode(items);
    } on FormatException {
      return 0;
    }
  }
  if (decodedItems is! List<Object?>) return 0;
  var subtotal = 0.0;
  var itemDiscounts = 0.0;
  for (final item in decodedItems.whereType<Map<String, dynamic>>()) {
    final base = reportNumber(item['quantity'] ?? 1) * reportNumber(item['unitPrice']);
    subtotal += base;
    itemDiscounts += base * reportNumber(item['discountRate']) / 100;
  }
  final taxableBase = (subtotal -
          itemDiscounts -
          (subtotal - itemDiscounts) *
              reportNumber(invoice['discountPercent']) /
              100 -
          reportNumber(invoice['discountAmount']))
      .clamp(0, double.infinity)
      .toDouble();
  final taxRate = reportNumber(invoice['taxRate']);
  final isTaxInclusive = invoice['isTaxInclusive'] == true;
  final tax = isTaxInclusive
      ? taxableBase - taxableBase / (1 + taxRate / 100)
      : taxableBase * taxRate / 100;
  return (taxableBase +
          (isTaxInclusive ? 0 : tax) +
          reportNumber(invoice['shippingFee']) +
          reportNumber(invoice['additionalCharges']) +
          reportNumber(invoice['roundOff']))
      .clamp(0, double.infinity)
      .toDouble();
}

String statusLabelFromRow(Map<String, dynamic> row) {
  final status = reportText(row['status'], fallback: 'Unknown');
  final normalized = status.toLowerCase().replaceAll('_', ' ');
  if (normalized == 'paid' ||
      normalized == 'overdue' ||
      normalized == 'draft' ||
      normalized == 'cancelled') {
    return status;
  }
  final dueDate = parseRecordDateValue(row['dueDate']);
  if (dueDate != null &&
      dueDate.isBefore(DateTime.now()) &&
      reportNumber(row['amountPaid']) < calculateInvoiceTotal(row)) {
    return 'Overdue';
  }
  return status;
}

Color groupColorForStatus(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'paid' || normalized == 'partially paid') {
    return AppColors.paid;
  }
  if (normalized.contains('overdue') || normalized.contains('due')) {
    return AppColors.overdue;
  }
  if (normalized.contains('draft')) return AppColors.muted;
  if (normalized.contains('sent') || normalized.contains('pending')) {
    return AppColors.warning;
  }
  return AppColors.blue;
}
