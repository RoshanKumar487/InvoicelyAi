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

  String get _currencySymbol {
    final s = localSettings['defaultCurrencySymbol']?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
    final c = localSettings['defaultCurrency']?.toString().trim();
    if (c != null && c.isNotEmpty) return currencySymbolFor(c);
    if (invoice.currencySymbol.isNotEmpty && invoice.currencySymbol != r'$') {
      return invoice.currencySymbol;
    }
    return '₹';
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
    final hasQty = _show('showItemQty');
    final hasRate = _show('showItemRate');
    final hasDiscount = _show('showItemDiscount');
    final hasTax = _show('showItemTax');

    final totalExtraCols = (hasQty ? 1 : 0) +
        (showDuty ? 1 : 0) +
        (hasRate ? 1 : 0) +
        (hasDiscount ? 1 : 0) +
        (hasTax ? 1 : 0) +
        customCols.length;

    final itemFlex = totalExtraCols >= 5 ? 5 : 6;
    final qtyFlex = qtyHeader.length > 8 ? 2 : 1;
    final dutyFlex = dutyHeader.length > 10 ? 3 : 2;
    final rateFlex = rateHeader.length > 12 ? 3 : 2;
    const discountFlex = 2;
    const taxFlex = 2;
    const customFlex = 2;
    const amountFlex = 3;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _buildHeaderCell(itemHeader, flex: itemFlex, align: TextAlign.start),
              if (hasQty)
                _buildHeaderCell(qtyHeader, flex: qtyFlex, align: TextAlign.end),
              if (showDuty)
                _buildHeaderCell(dutyHeader, flex: dutyFlex, align: TextAlign.end),
              if (hasRate)
                _buildHeaderCell(rateHeader, flex: rateFlex, align: TextAlign.end),
              if (hasDiscount)
                _buildHeaderCell(_label('customDiscountHeader', 'Discount'), flex: discountFlex, align: TextAlign.end),
              if (hasTax)
                _buildHeaderCell(_label('customTaxHeader', 'Tax'), flex: taxFlex, align: TextAlign.end),
              for (final col in customCols)
                _buildHeaderCell(col['label']?.toString() ?? '', flex: customFlex, align: TextAlign.end),
              _buildHeaderCell(amountHeader, flex: amountFlex, align: TextAlign.end),
            ],
          ),
        ),
        for (var i = 0; i < invoice.items.length; i++) ...[
          () {
            final item = invoice.items[i];
            final isAlt = template?.tableStyle == 'striped' && (i % 2 == 1);
            final isBoxed = template?.tableStyle == 'boxed';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                  _buildDescriptionCell(
                    item.description,
                    item.itemDetails,
                    flex: itemFlex,
                  ),
                  if (hasQty)
                    _buildDataCell(
                      '${formatQuantity(item.quantity)}'
                      '${_show('showItemUnit') ? ' ${item.unit}' : ''}',
                      flex: qtyFlex,
                      align: TextAlign.end,
                    ),
                  if (showDuty)
                    _buildDataCell(
                      item.dutyCount > 0 ? formatQuantity(item.dutyCount) : '−',
                      flex: dutyFlex,
                      align: TextAlign.end,
                    ),
                  if (hasRate)
                    _buildDataCell(
                      formatMoney(item.unitPrice, _currencySymbol),
                      flex: rateFlex,
                      align: TextAlign.end,
                    ),
                  if (hasDiscount)
                    _buildDataCell(
                      '${item.discountRate}%',
                      flex: discountFlex,
                      align: TextAlign.end,
                    ),
                  if (hasTax)
                    _buildDataCell(
                      '${item.taxRate}%',
                      flex: taxFlex,
                      align: TextAlign.end,
                    ),
                  for (final col in customCols)
                    _buildDataCell(
                      col['value']?.toString() ?? '−',
                      flex: customFlex,
                      align: TextAlign.end,
                    ),
                  _buildDataCell(
                    formatMoney(item.total, _currencySymbol),
                    flex: amountFlex,
                    align: TextAlign.end,
                    isBold: true,
                    color: const Color(0xFF0F172A),
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

  Widget _buildHeaderCell(
    String text, {
    required int flex,
    required TextAlign align,
  }) {
    final len = text.length;
    final double fs = len > 20 ? 10.0 : (len > 12 ? 11.0 : 12.5);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: fs,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCell(
    String title,
    String subtitle, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (subtitle.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle.trim(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    required int flex,
    required TextAlign align,
    bool isBold = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
      ),
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
