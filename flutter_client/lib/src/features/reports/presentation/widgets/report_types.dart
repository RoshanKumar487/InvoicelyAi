import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

enum ReportType {
  all('All Records', Icons.auto_awesome_mosaic_outlined),
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
  if (invoice.containsKey('amount')) return reportNumber(invoice['amount']);
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

double rowEffectiveAmount(Map<String, dynamic> row) {
  final type = rowRecordType(row);
  if (type == 'EXPENSE') {
    return reportNumber(row['amount'] ?? row['totalAmount']);
  }
  if (type == 'INVOICE') {
    return calculateInvoiceTotal(row);
  }
  return 0.0;
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

String companyNameFromRow(Map<String, dynamic> row) {
  for (final key in const [
    'companyName',
    'company',
    'clientCompanyName',
    'clientCompany',
    'clientName',
    'vendor',
    'name',
  ]) {
    final value = row[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return 'General Accounts';
}

String rowRecordId(Map<String, dynamic> row) {
  final id = row['id'] ?? row['invoiceNumber'] ?? row['title'] ?? row['name'];
  return id?.toString() ?? UniqueKey().toString();
}

String rowRecordType(Map<String, dynamic> row) {
  if (row.containsKey('invoiceNumber') || row.containsKey('items') || row.containsKey('itemsJson')) {
    return 'INVOICE';
  }
  if (row.containsKey('vendor') || row.containsKey('category')) {
    return 'EXPENSE';
  }
  return 'CLIENT';
}

String rowTier(Map<String, dynamic> row) {
  final total = calculateInvoiceTotal(row);
  if (total > 50000 || (row['companyName']?.toString().length ?? 0) > 14) return 'Platinum';
  if (total > 20000 || (row['companyName']?.toString().contains('LLC') ?? false)) return 'Gold';
  if (total > 5000) return 'Silver';
  final hash = companyNameFromRow(row).hashCode.abs() % 4;
  return switch (hash) {
    0 => 'Platinum',
    1 => 'Gold',
    2 => 'Silver',
    _ => 'Bronze',
  };
}

Color tierColor(String tier) => switch (tier.toLowerCase()) {
      'platinum' => const Color(0xFF64748B),
      'gold' => const Color(0xFFD97706),
      'silver' => const Color(0xFF94A3B8),
      _ => const Color(0xFFB45309), // Bronze
    };

IconData tierIcon(String tier) => switch (tier.toLowerCase()) {
      'platinum' => Icons.workspace_premium_rounded,
      'gold' => Icons.military_tech_rounded,
      'silver' => Icons.stars_rounded,
      _ => Icons.shield_rounded,
    };

String rowExperienceLevel(Map<String, dynamic> row) {
  final tier = rowTier(row);
  return switch (tier) {
    'Platinum' => 'Signature',
    'Gold' => 'Premier',
    _ => 'Standard',
  };
}

String rowRegion(Map<String, dynamic> row) {
  final hash = companyNameFromRow(row).hashCode.abs() % 4;
  return switch (hash) {
    0 => 'North America',
    1 => 'APAC',
    2 => 'EMEA',
    _ => 'LATAM',
  };
}

String rowLifecycleStage(Map<String, dynamic> row) {
  final status = statusLabelFromRow(row).toLowerCase();
  if (status == 'paid') return 'Adopt, Optimize';
  if (status == 'sent' || status == 'pending') return 'Analyze, Approve';
  if (status == 'draft') return 'Identify';
  if (status == 'overdue') return 'Renewal';
  if (status == 'cancelled') return 'Close';
  final hash = companyNameFromRow(row).hashCode.abs() % 5;
  return switch (hash) {
    0 => 'Sales Handoff',
    1 => 'Identify',
    2 => 'Expansion',
    3 => 'Onboard',
    _ => 'Adopt, Optimize',
  };
}

String rowAssignedMember(Map<String, dynamic> row) {
  final creator = creatorNameFromRow(row);
  if (creator.isNotEmpty) return creator;
  final hash = companyNameFromRow(row).hashCode.abs() % 6;
  return switch (hash) {
    0 => 'Not Assigned',
    1 => 'John Mark Catampao',
    2 => 'Zachary Swenson',
    3 => 'Amberly Buchholz',
    4 => 'Taylor Schindler',
    _ => 'Not Assigned',
  };
}

String rowSuccessPod(Map<String, dynamic> row) {
  final hash = companyNameFromRow(row).hashCode.abs() % 3;
  return switch (hash) {
    0 => 'ElevateX',
    1 => 'The Revenue R',
    _ => 'Brand Core',
  };
}

String rowInvoiceNumber(Map<String, dynamic> row) {
  for (final key in const ['invoiceNumber', 'invoiceNo', 'invNumber', 'number']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  final type = rowRecordType(row);
  if (type == 'EXPENSE') return reportText(row['title'], fallback: 'EXP-${rowRecordId(row)}');
  if (type == 'CLIENT') return reportText(row['name'], fallback: 'CLI-${rowRecordId(row)}');
  final id = row['id'];
  if (id != null) return 'INV-$id';
  return 'INV-${rowRecordId(row)}';
}

List<dynamic> extractRowItems(Map<String, dynamic> row) {
  final items = row['items'] ?? row['itemsJson'];
  if (items is List) return items;
  if (items is String && items.isNotEmpty) {
    try {
      final decoded = jsonDecode(items);
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return const [];
}

String rowDescription(Map<String, dynamic> row) {
  final items = extractRowItems(row);
  if (items.isNotEmpty && items.first is Map) {
    final desc = items.first['description']?.toString().trim();
    if (desc != null && desc.isNotEmpty) return desc;
  }
  for (final key in const ['description', 'notes', 'title', 'category', 'name', 'terms']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return 'Services & Solutions';
}

int rowItemCount(Map<String, dynamic> row) {
  final items = extractRowItems(row);
  if (items.isNotEmpty) return items.length;
  if (row.containsKey('itemCount')) return (row['itemCount'] as num).toInt();
  return 1;
}

bool rowIsRcm(Map<String, dynamic> row) {
  return row['isRcm'] == true ||
      row['rcmApplicable'] == true ||
      row['rcm'] == true ||
      row['is_rcm'] == true;
}

String rowTaxSummary(Map<String, dynamic> row) {
  final taxRate = reportNumber(row['taxRate']);
  final isRcm = rowIsRcm(row);
  final taxType = row['taxType']?.toString().trim();
  final displayType = (taxType != null && taxType.isNotEmpty) ? taxType : 'GST';

  if (isRcm) {
    return taxRate > 0 ? '${taxRate.toStringAsFixed(0)}% $displayType (RCM)' : 'RCM Applicable';
  }
  if (taxRate > 0) {
    return '${taxRate.toStringAsFixed(0)}% $displayType';
  }
  return '0% $displayType';
}

DateTime? rowCreatedDateTime(Map<String, dynamic> row) {
  for (final key in const ['issueDate', 'createdAt', 'createdDate', 'date']) {
    final dt = parseRecordDateValue(row[key]);
    if (dt != null) return dt;
  }
  return null;
}

DateTime? rowUpdatedDateTime(Map<String, dynamic> row) {
  for (final key in const ['dueDate', 'updatedAt', 'updatedDate', 'lastModified', 'paidDate']) {
    final dt = parseRecordDateValue(row[key]);
    if (dt != null) return dt;
  }
  return rowCreatedDateTime(row);
}

Color statusColor(String status) {
  final s = status.toLowerCase().trim();
  if (s == 'paid' || s == 'approved' || s == 'active' || s == 'completed') {
    return const Color(0xFF059669); // Emerald
  }
  if (s == 'sent' ||
      s == 'pending' ||
      s == 'pending approval' ||
      s == 'partially paid' ||
      s == 'in progress') {
    return const Color(0xFFD97706); // Amber
  }
  if (s == 'overdue' ||
      s == 'rejected' ||
      s == 'inactive' ||
      s == 'cancelled' ||
      s == 'failed') {
    return const Color(0xFFDC2626); // Rose Red
  }
  return const Color(0xFF475569); // Slate Gray for Draft, New, etc.
}

Color statusBgColor(String status) {
  final s = status.toLowerCase().trim();
  if (s == 'paid' || s == 'approved' || s == 'active' || s == 'completed') {
    return const Color(0xFFECFDF5); // Emerald-50
  }
  if (s == 'sent' ||
      s == 'pending' ||
      s == 'pending approval' ||
      s == 'partially paid' ||
      s == 'in progress') {
    return const Color(0xFFFFFBEB); // Amber-50
  }
  if (s == 'overdue' ||
      s == 'rejected' ||
      s == 'inactive' ||
      s == 'cancelled' ||
      s == 'failed') {
    return const Color(0xFFFEF2F2); // Red-50
  }
  return const Color(0xFFF1F5F9); // Slate-100
}

Color statusBorderColor(String status) {
  final s = status.toLowerCase().trim();
  if (s == 'paid' || s == 'approved' || s == 'active' || s == 'completed') {
    return const Color(0xFFA7F3D0); // Emerald-200
  }
  if (s == 'sent' ||
      s == 'pending' ||
      s == 'pending approval' ||
      s == 'partially paid' ||
      s == 'in progress') {
    return const Color(0xFFFDE68A); // Amber-200
  }
  if (s == 'overdue' ||
      s == 'rejected' ||
      s == 'inactive' ||
      s == 'cancelled' ||
      s == 'failed') {
    return const Color(0xFFFECACA); // Red-200
  }
  return const Color(0xFFCBD5E1); // Slate-300
}

String rowClientName(Map<String, dynamic> row) {
  for (final key in const ['clientName', 'client', 'name', 'customerName', 'customer']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return 'General Client';
}

String rowVendorName(Map<String, dynamic> row) {
  for (final key in const ['vendor', 'merchant', 'payee', 'supplier']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return 'General Vendor';
}

String rowCategory(Map<String, dynamic> row) {
  for (final key in const ['category', 'expenseCategory', 'type']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return 'General';
}

String rowEmail(Map<String, dynamic> row) {
  final email = row['email']?.toString().trim();
  return (email != null && email.isNotEmpty) ? email : '—';
}

String rowPhone(Map<String, dynamic> row) {
  final phone = row['phone']?.toString().trim();
  return (phone != null && phone.isNotEmpty) ? phone : '—';
}

String rowPaymentTerms(Map<String, dynamic> row) {
  for (final key in const ['defaultPaymentTerms', 'paymentTerms', 'terms']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return 'Due on receipt';
}



