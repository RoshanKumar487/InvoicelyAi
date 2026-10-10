import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../data/invoice.dart';

String _num(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

String _money(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

class TotalsPreview extends StatelessWidget {
  const TotalsPreview({required this.invoice, super.key});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TotalLine(
              label: 'Subtotal',
              value: _money(invoice.subtotal, invoice.currencySymbol),
            ),
            TotalLine(
              label: 'Discount',
              value:
                  '−${_money(invoice.totalDiscount, invoice.currencySymbol)}',
            ),
            TotalLine(
              label:
                  '${invoice.taxLabel} (${_num(invoice.taxRate)}%${invoice.isTaxInclusive ? ', included' : ''})',
              value: _money(invoice.taxAmount, invoice.currencySymbol),
            ),
            TotalLine(
              label: 'Shipping & additional charges',
              value: _money(
                invoice.shippingFee + invoice.additionalCharges,
                invoice.currencySymbol,
              ),
            ),
            const Divider(),
            TotalLine(
              label: 'Total',
              value: _money(invoice.total, invoice.currencySymbol),
              emphasized: true,
            ),
            TotalLine(
              label: 'Balance due',
              value: _money(invoice.balanceDue, invoice.currencySymbol),
              emphasized: true,
            ),
          ],
        ),
      );
}

class TotalLine extends StatelessWidget {
  const TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: emphasized
                    ? const TextStyle(fontWeight: FontWeight.w700)
                    : null,
              ),
            ),
            Text(
              value,
              style: emphasized
                  ? const TextStyle(fontWeight: FontWeight.w800)
                  : null,
            ),
          ],
        ),
      );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      );
}

class ResponsiveFields extends StatelessWidget {
  const ResponsiveFields({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final responsiveColumns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          const gap = 12.0;
          final width = (constraints.maxWidth - (responsiveColumns - 1) * gap) /
              responsiveColumns;
          return Wrap(
            spacing: gap,
            runSpacing: 12,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

Widget appTextField({
  required TextEditingController controller,
  required String label,
  bool isRequired = true,
  int maxLines = 1,
  String? hintText,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  String? Function(String?)? validator,
  ValueChanged<String>? onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: validator ?? (isRequired ? requiredValidator : null),
      onChanged: onChanged,
    );

Widget appDecimalField({
  required TextEditingController controller,
  required String label,
  required double min,
  double? max,
  bool allowNegative = false,
  required VoidCallback onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'^-?\d*\.?\d{0,4}' : r'^\d*\.?\d{0,4}'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < min || (max != null && parsed > max)) {
          return max == null ? 'Must be at least $min' : 'Enter $min–$max';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );

Widget appItemNumberField({
  required TextEditingController controller,
  required String label,
  required double min,
  double? max,
  required VoidCallback onChanged,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < min || (max != null && parsed > max)) {
          return max == null ? 'Must be at least $min' : 'Enter $min–$max';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );

Widget appDateField({
  required String label,
  required String date,
  required VoidCallback onTap,
}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(date),
      ),
    );

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      );
}

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

InvoiceItem makeNewLineItem([bool isSecurity = false]) => InvoiceItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      description: '',
      itemDetails: '',
      quantity: 1,
      dutyCount: isSecurity ? 26 : 0,
      unitPrice: 0,
      unit: isSecurity ? 'Duty' : 'pcs',
    );

String formatDateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int parsePaymentTermDays(String terms) {
  if (terms.toLowerCase().contains('receipt')) return 0;
  final days = RegExp(r'net\s*(\d+)', caseSensitive: false)
      .firstMatch(terms)
      ?.group(1);
  return int.tryParse(days ?? '') ?? 30;
}

String formatNum(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

String formatMoney(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

double parseSettingNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String parseSettingString(Object? value, String fallback) {
  final string = value?.toString().trim() ?? '';
  return string.isEmpty ? fallback : string;
}

String readShippingDetails(String? value) {
  if (value == null || value.trim().isEmpty || value.trim() == '{}') return '';
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) return value;
    const labels = <String, String>{
      'shippingAddress': 'Shipping address',
      'deliveryAddress': 'Delivery address',
      'shippingMethod': 'Shipping method',
      'courier': 'Carrier',
      'trackingNumber': 'Tracking',
      'expectedDelivery': 'Expected delivery',
      'warehouse': 'Warehouse',
      'deliveryContact': 'Delivery contact',
      'vehicleNumber': 'Vehicle number',
      'dispatchDate': 'Dispatch date',
    };
    return labels.entries
        .where(
            (entry) => decoded[entry.key]?.toString().trim().isNotEmpty == true)
        .map((entry) => '${entry.value}: ${decoded[entry.key]}')
        .join('\n');
  } on FormatException {
    return value;
  }
}

String serializeShippingDetails(String value) {
  if (value.trim().isEmpty) return '{}';
  const keys = <String, String>{
    'shipping address': 'shippingAddress',
    'delivery address': 'deliveryAddress',
    'shipping method': 'shippingMethod',
    'carrier': 'courier',
    'tracking': 'trackingNumber',
    'expected delivery': 'expectedDelivery',
    'warehouse': 'warehouse',
    'delivery contact': 'deliveryContact',
    'vehicle number': 'vehicleNumber',
    'dispatch date': 'dispatchDate',
  };
  final details = <String, Object?>{
    'isEnabled': true,
    'sameAsBilling': false,
    'sectionTitle': 'Shipping Details',
  };
  final unmatchedLines = <String>[];
  for (final line in value.split('\n')) {
    final separator = line.indexOf(':');
    final label =
        separator < 0 ? '' : line.substring(0, separator).trim().toLowerCase();
    final content =
        separator < 0 ? line.trim() : line.substring(separator + 1).trim();
    if (content.isEmpty) continue;
    final key = keys[label];
    if (key == null) {
      unmatchedLines.add(content);
    } else {
      details[key] = content;
    }
  }
  if (unmatchedLines.isNotEmpty && details['deliveryAddress'] == null) {
    details['deliveryAddress'] = unmatchedLines.join('\n');
  }
  return jsonEncode(details);
}
