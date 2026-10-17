import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/amount_to_words.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/invoice.dart';

String _num(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

String _money(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

class TotalsPreview extends StatelessWidget {
  const TotalsPreview({
    required this.invoice,
    this.onAutoRound,
    super.key,
  });

  final Invoice invoice;
  final VoidCallback? onAutoRound;

  String get _symbol {
    final sym = invoice.currencySymbol.trim();
    if (sym.isNotEmpty && sym != r'$') return sym;
    if (invoice.currencyCode.isNotEmpty && invoice.currencyCode != 'USD') {
      return currencySymbolFor(invoice.currencyCode);
    }
    return '₹';
  }

  @override
  Widget build(BuildContext context) {
    final isGst = invoice.taxType.toUpperCase() == 'GST' &&
        !invoice.isRcm &&
        invoice.taxRate > 0;
    final halfTaxRate = invoice.taxRate / 2;
    final halfTaxAmount = invoice.taxAmount / 2;
    final extraCharges = invoice.shippingFee + invoice.additionalCharges;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141E3A8A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 2,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Colored Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'INVOICE TOTAL & TAX SUMMARY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (onAutoRound != null)
                  InkWell(
                    onTap: onAutoRound,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Auto Round',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Breakdown Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              children: [
                TotalLine(
                  label: 'Gross Subtotal (${invoice.items.length} ${invoice.items.length == 1 ? "item" : "items"})',
                  value: _money(invoice.subtotal, _symbol),
                ),
                if (invoice.totalDiscount > 0)
                  TotalLine(
                    label: 'Total Discount',
                    value: '−${_money(invoice.totalDiscount, _symbol)}',
                    valueColor: const Color(0xFF059669),
                    badgeText: 'SAVED',
                    badgeColor: const Color(0xFFDCFCE7),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Taxable Value',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      Text(
                        _money(invoice.taxableAmount, _symbol),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (invoice.isRcm) ...[
                  TotalLine(
                    label: 'Reverse Charge (RCM)',
                    value: '${_symbol}0.00',
                    badgeText: 'Payable by Recipient',
                    badgeColor: const Color(0xFFFEF3C7),
                    valueColor: const Color(0xFFB45309),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tax is payable directly to government by recipient (RCM Sec 9(3)/9(4)). Supplier invoice total excludes tax collection.',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                else if (isGst) ...[
                  TotalLine(
                    label: 'CGST (${_num(halfTaxRate)}%)',
                    value: _money(halfTaxAmount, _symbol),
                    valueColor: const Color(0xFF334155),
                  ),
                  TotalLine(
                    label: 'SGST (${_num(halfTaxRate)}%)',
                    value: _money(halfTaxAmount, _symbol),
                    valueColor: const Color(0xFF334155),
                  ),
                  TotalLine(
                    label: 'Total GST (${_num(invoice.taxRate)}%${invoice.isTaxInclusive ? " incl." : ""})',
                    value: _money(invoice.taxAmount, _symbol),
                    valueColor: const Color(0xFF1D4ED8),
                    emphasized: true,
                  ),
                ] else
                  TotalLine(
                    label:
                        '${invoice.taxLabel} (${_num(invoice.taxRate)}%${invoice.isTaxInclusive ? ", included" : ""})',
                    value: _money(invoice.taxAmount, _symbol),
                    valueColor: const Color(0xFF1D4ED8),
                  ),
                if (extraCharges > 0)
                  TotalLine(
                    label: 'Shipping & Additional Charges',
                    value: '+${_money(extraCharges, _symbol)}',
                  ),
                if (invoice.roundOff != 0)
                  TotalLine(
                    label: 'Round Off Adjustment',
                    value:
                        '${invoice.roundOff > 0 ? "+" : ""}${_money(invoice.roundOff, _symbol)}',
                    valueColor: const Color(0xFF6366F1),
                  ),
              ],
            ),
          ),

          // Vibrant Claymorphic Grand Total Banner
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x381E3A8A),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x33FFFFFF),
                  blurRadius: 2,
                  offset: Offset(-1, -1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GRAND TOTAL PAYABLE',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invoice.isRcm
                                ? 'Reverse Charge: GST payable by Recipient'
                                : (invoice.isTaxInclusive
                                    ? 'Inclusive of all applicable taxes'
                                    : 'Inclusive of ${invoice.taxLabel} (${_num(invoice.taxRate)}%)'),
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _money(invoice.total, _symbol),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (invoice.total > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.spellcheck_rounded,
                          size: 14,
                          color: Color(0xFFBFDBFE),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AmountToWords.convert(invoice.total, currency: _symbol),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (invoice.amountPaid > 0 || invoice.balanceDue != invoice.total) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid: ${_money(invoice.amountPaid, _symbol)}',
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Balance Due: ${_money(invoice.balanceDue, _symbol)}',
                          style: const TextStyle(
                            color: Color(0xFFFDE047),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TotalLine extends StatelessWidget {
  const TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
    this.badgeText,
    this.badgeColor,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                        color: emphasized
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: valueColor ?? const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: emphasized ? 13.5 : 12.5,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
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
      dutyCount: isSecurity ? 30 : 0,
      unitPrice: 0,
      unit: isSecurity ? 'Duty' : 'pcs',
      calculationFormula: isSecurity ? 'monthly_salary_30' : null,
      standardDutyDays: 30,
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
