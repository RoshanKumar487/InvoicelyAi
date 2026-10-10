import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../data/invoice.dart';
import '../../../templates/data/template_config.dart';

String formatQuantity(double quantity) => quantity == quantity.truncateToDouble()
    ? quantity.toInt().toString()
    : '$quantity';

String formatMoney(double amount, String symbol) =>
    '$symbol${amount.toStringAsFixed(2)}';

Color parseTemplateColor(String? hex, Color fallback) {
  final value = hex?.replaceFirst('#', '');
  if (value == null || !RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
    return fallback;
  }
  return Color(0xFF000000 | int.parse(value, radix: 16));
}

class LineItemsTable extends StatelessWidget {
  const LineItemsTable({
    required this.invoice,
    required this.localSettings,
    required this.template,
    required this.headerColor,
    super.key,
  });

  final Invoice invoice;
  final Map<String, Object?> localSettings;
  final TemplateConfig? template;
  final Color headerColor;

  bool _show(String key) => localSettings[key] != false;

  String _label(String key, String fallback) {
    final custom = localSettings[key]?.toString().trim();
    return (custom != null && custom.isNotEmpty) ? custom : fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (invoice.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('This invoice has no line items.'),
      );
    }

    final itemHeader = _label(
      'customItemHeader',
      template?.itemHeader ?? 'Description',
    );
    final qtyHeader = _label(
      'customQtyHeader',
      template?.quantityHeader ?? 'Qty',
    );
    final rateHeader = _label(
      'customRateHeader',
      template?.rateHeader ?? 'Rate',
    );
    final amountHeader = _label(
      'customAmountHeader',
      template?.amountHeader ?? 'Amount',
    );

    final customCols = <Map<String, dynamic>>[];
    final rawCols = localSettings['customColumns_items'];
    if (rawCols is List) {
      for (final c in rawCols) {
        if (c is Map && c['isVisible'] != false) {
          customCols.add(Map<String, dynamic>.from(c));
        }
      }
    }

    final showDuty = _show('showItemDuty') || invoice.items.any((InvoiceItem it) => it.dutyCount > 0);
    final dutyHeader = _label('customDutyHeader', 'Duty');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(itemHeader),
                ),
                if (_show('showItemQty'))
                  Expanded(
                    flex: 2,
                    child: Text(qtyHeader, textAlign: TextAlign.end),
                  ),
                if (showDuty)
                  Expanded(
                    flex: 2,
                    child: Text(dutyHeader, textAlign: TextAlign.end),
                  ),
                if (_show('showItemRate'))
                  Expanded(
                    flex: 2,
                    child: Text(rateHeader, textAlign: TextAlign.end),
                  ),
                if (_show('showItemDiscount'))
                  Expanded(
                    flex: 2,
                    child: Text(_label('customDiscountHeader', 'Discount'), textAlign: TextAlign.end),
                  ),
                if (_show('showItemTax'))
                  Expanded(
                    flex: 2,
                    child: Text(_label('customTaxHeader', 'Tax'), textAlign: TextAlign.end),
                  ),
                for (final col in customCols)
                  Expanded(
                    flex: 2,
                    child: Text(col['label']?.toString() ?? '', textAlign: TextAlign.end),
                  ),
                Expanded(
                  flex: 3,
                  child: Text(amountHeader, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < invoice.items.length; i++) ...[
          () {
            final item = invoice.items[i];
            final isAlt = template?.tableStyle == 'striped' && (i % 2 == 1);
            final isBoxed = template?.tableStyle == 'boxed';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: isAlt ? const Color(0xFFF8FAFC) : Colors.transparent,
                border: isBoxed
                    ? const Border(
                        left: BorderSide(color: Color(0xFFCBD5E1)),
                        right: BorderSide(color: Color(0xFFCBD5E1)),
                        bottom: BorderSide(color: Color(0xFFCBD5E1)),
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (item.itemDetails.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.itemDetails,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_show('showItemQty'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${formatQuantity(item.quantity)}'
                        '${_show('showItemUnit') ? ' ${item.unit}' : ''}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (showDuty)
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.dutyCount > 0 ? formatQuantity(item.dutyCount) : '−',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemRate'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatMoney(item.unitPrice, invoice.currencySymbol),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemDiscount'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.discountRate}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemTax'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.taxRate}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  for (final col in customCols)
                    Expanded(
                      flex: 2,
                      child: Text(
                        col['value']?.toString() ?? '−',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      formatMoney(item.total, invoice.currencySymbol),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],
        if (template?.tableStyle != 'boxed')
          const Divider(color: Color(0xFFCBD5E1)),
      ],
    );
  }
}

class PreviewTotalLine extends StatelessWidget {
  const PreviewTotalLine({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.fontSize = 13,
    super.key,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: color ?? const Color(0xFF334155),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: color ?? const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
}

class PreviewStatusChip extends StatelessWidget {
  const PreviewStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'paid' => const Color(0xFF059669),
      'overdue' => const Color(0xFFDC2626),
      'sent' => const Color(0xFF2563EB),
      'cancelled' => const Color(0xFF64748B),
      _ => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class InvoiceQrCodeWidget extends StatelessWidget {
  const InvoiceQrCodeWidget({
    required this.data,
    this.size = 92,
    this.color = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    super.key,
  });

  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) return const SizedBox.shrink();
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        padding: const EdgeInsets.all(5),
        child: CustomPaint(
          size: Size(size - 10, size - 10),
          painter: QrPainter(qrImage: qrImage, color: color),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class QrPainter extends CustomPainter {
  QrPainter({required this.qrImage, required this.color});

  final QrImage qrImage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final int count = qrImage.moduleCount;
    final double pixelSize = size.width / count;

    for (int r = 0; r < count; r++) {
      for (int c = 0; c < count; c++) {
        if (qrImage.isDark(r, c)) {
          final rect = Rect.fromLTWH(
            c * pixelSize,
            r * pixelSize,
            pixelSize,
            pixelSize,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage || oldDelegate.color != color;
}
