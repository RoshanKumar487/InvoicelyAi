import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/invoice.dart';

class ArAgingBucket {
  const ArAgingBucket({
    required this.key,
    required this.label,
    required this.invoiceCount,
    required this.totalAmount,
    required this.color,
    required this.badgeColor,
    required this.description,
  });

  final String key;
  final String label;
  final int invoiceCount;
  final double totalAmount;
  final Color color;
  final Color badgeColor;
  final String description;
}

/// Accounts Receivable (AR) Aging & DSO Intelligence Card.
/// Gives business owners real-time visibility into uncollected receivables and aging risk.
class InvoiceArAgingCard extends StatelessWidget {
  const InvoiceArAgingCard({
    required this.invoices,
    this.currencySymbol = '₹',
    this.selectedBucket,
    this.onSelectBucket,
    super.key,
  });

  final List<Invoice> invoices;
  final String currencySymbol;
  final String? selectedBucket;
  final ValueChanged<String>? onSelectBucket;

  List<ArAgingBucket> _calculateBuckets() {
    final now = DateTime.now();

    var currentCount = 0;
    var currentAmount = 0.0;

    var b30Count = 0;
    var b30Amount = 0.0;

    var b60Count = 0;
    var b60Amount = 0.0;

    var b90PlusCount = 0;
    var b90PlusAmount = 0.0;

    for (final inv in invoices) {
      if (inv.status.toLowerCase() == 'paid' || inv.status.toLowerCase() == 'cancelled') {
        continue;
      }
      final due = inv.balanceDue > 0 ? inv.balanceDue : inv.total;
      if (due <= 0) continue;

      DateTime? dueDate = DateTime.tryParse(inv.dueDate);
      if (dueDate == null) {
        currentCount++;
        currentAmount += due;
        continue;
      }

      final diffDays = now.difference(dueDate).inDays;
      if (diffDays <= 0) {
        // Not yet past due
        currentCount++;
        currentAmount += due;
      } else if (diffDays <= 30) {
        b30Count++;
        b30Amount += due;
      } else if (diffDays <= 60) {
        b60Count++;
        b60Amount += due;
      } else {
        b90PlusCount++;
        b90PlusAmount += due;
      }
    }

    return [
      ArAgingBucket(
        key: 'current',
        label: 'Current (0-30d)',
        invoiceCount: currentCount,
        totalAmount: currentAmount,
        color: const Color(0xFF0284C7),
        badgeColor: const Color(0xFFE0F2FE),
        description: 'Not yet due / Grace period',
      ),
      ArAgingBucket(
        key: '31_60',
        label: '1-30d Overdue',
        invoiceCount: b30Count,
        totalAmount: b30Amount,
        color: const Color(0xFFD97706),
        badgeColor: const Color(0xFFFEF3C7),
        description: 'Follow-up reminder sent',
      ),
      ArAgingBucket(
        key: '61_90',
        label: '31-60d Overdue',
        invoiceCount: b60Count,
        totalAmount: b60Amount,
        color: const Color(0xFFEA580C),
        badgeColor: const Color(0xFFFFEDD5),
        description: 'Escalation required',
      ),
      ArAgingBucket(
        key: '90_plus',
        label: '60d+ Critical',
        invoiceCount: b90PlusCount,
        totalAmount: b90PlusAmount,
        color: const Color(0xFFDC2626),
        badgeColor: const Color(0xFFFEE2E2),
        description: 'High risk of bad debt',
      ),
    ];
  }

  double get _totalOutstanding {
    return invoices
        .where((i) => i.status.toLowerCase() != 'paid' && i.status.toLowerCase() != 'cancelled')
        .fold(0.0, (sum, i) => sum + (i.balanceDue > 0 ? i.balanceDue : i.total));
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _calculateBuckets();
    final totalDue = _totalOutstanding;
    if (totalDue <= 0 && invoices.isNotEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.neuCardDecoration(radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Total Receivables Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF2B3548),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accounts Receivable (AR) Aging Analysis',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Total Outstanding: $currencySymbol${totalDue.toStringAsFixed(2)} across ${invoices.where((i) => i.balanceDue > 0 && i.status.toLowerCase() != "paid").length} invoices',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (selectedBucket != null)
                  TextButton.icon(
                    onPressed: () => onSelectBucket?.call(''),
                    icon: const Icon(Icons.clear_all_rounded, size: 14),
                    label: const Text('Show all', style: TextStyle(fontSize: 11.5)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Responsive Bucket Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final isMedium = constraints.maxWidth >= 480 && !isWide;

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < buckets.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: _buildBucketItem(buckets[i])),
                      ],
                    ],
                  );
                }

                if (isMedium) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildBucketItem(buckets[0])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildBucketItem(buckets[1])),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildBucketItem(buckets[2])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildBucketItem(buckets[3])),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < buckets.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildBucketItem(buckets[i]),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketItem(ArAgingBucket bucket) {
    final isSelected = selectedBucket == bucket.key;

    return InkWell(
      onTap: onSelectBucket != null && bucket.invoiceCount > 0
          ? () => onSelectBucket!(isSelected ? '' : bucket.key)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bucket.badgeColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? bucket.color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bucket.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? bucket.color : const Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bucket.badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bucket.invoiceCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: bucket.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$currencySymbol${bucket.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: bucket.invoiceCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bucket.description,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
