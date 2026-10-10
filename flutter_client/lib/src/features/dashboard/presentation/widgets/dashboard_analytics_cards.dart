import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import '../../../invoices/data/invoice.dart';
import '../../data/dashboard_statistics.dart';

String formatDashboardMoney(double amount) => '₹${amount.toStringAsFixed(2)}';

class DashboardAnalytics extends StatelessWidget {
  const DashboardAnalytics({
    super.key,
    required this.statistics,
    required this.role,
    required this.invoices,
    required this.onViewInvoices,
    required this.onViewExpenses,
  });

  final DashboardStatistics statistics;
  final String role;
  final List<Invoice>? invoices;
  final ValueChanged<String> onViewInvoices;
  final VoidCallback onViewExpenses;

  @override
  Widget build(BuildContext context) {
    final isEmployee = role == 'EMPLOYEE';
    final totals = invoices == null
        ? null
        : InvoiceDashboardMetrics.fromInvoices(invoices!);
    final metrics = <DashboardMetric>[
      DashboardMetric(
        title: isEmployee ? 'Your total invoiced' : 'Total invoiced',
        value: totals == null ? '—' : formatDashboardMoney(totals.totalInvoiced),
        subtext:
            '${totals?.invoiceCount ?? statistics.totalInvoices} total invoices',
        icon: Icons.trending_up,
        color: AppColors.blue,
        onTap: () => onViewInvoices('All'),
      ),
      DashboardMetric(
        title: isEmployee ? 'Your paid collected' : 'Paid collected',
        value: formatDashboardMoney(totals?.paidTotal ?? statistics.totalRevenue),
        subtext:
            '${totals?.paidCount ?? statistics.paidInvoices} fully settled',
        icon: Icons.check_circle_outline,
        color: AppColors.paid,
        onTap: () => onViewInvoices('Paid'),
      ),
      DashboardMetric(
        title: isEmployee ? 'Your outstanding' : 'Outstanding',
        value: totals == null ? '—' : formatDashboardMoney(totals.outstandingTotal),
        subtext: '${totals?.pendingCount ?? 0} pending payment',
        icon: Icons.hourglass_top,
        color: AppColors.warning,
        onTap: () => onViewInvoices('Sent'),
      ),
      DashboardMetric(
        title: isEmployee ? 'Your overdue' : 'Overdue',
        value: totals == null ? '—' : formatDashboardMoney(totals.overdueTotal),
        subtext:
            '${totals?.overdueCount ?? statistics.overdueInvoices} require reminder',
        icon: Icons.warning_amber_rounded,
        color: AppColors.overdue,
        onTap: () => onViewInvoices('Overdue'),
      ),
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 760
                    ? 3
                    : 2;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: width,
                    height: 142,
                    child: MetricCard(metric: metric),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        CollectionHealthCard(
          totalInvoiced: totals?.totalInvoiced ?? 0,
          collected: totals?.paidTotal ?? statistics.totalRevenue,
          pending: totals == null
              ? 0
              : totals.outstandingTotal + totals.overdueTotal,
          onTap: () => onViewInvoices('All'),
          showAmounts: totals != null,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InvoiceHealthCard(statistics: statistics),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RevenueExpenseChart(
                      statistics: statistics,
                      onViewExpenses: onViewExpenses,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                InvoiceHealthCard(statistics: statistics),
                const SizedBox(height: 14),
                RevenueExpenseChart(
                  statistics: statistics,
                  onViewExpenses: onViewExpenses,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: metric.onTap,
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: metric.color.withAlpha(28),
                      child: Icon(metric.icon, color: metric.color, size: 17),
                    ),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        metric.value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metric.subtext,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class InvoiceHealthCard extends StatelessWidget {
  const InvoiceHealthCard({super.key, required this.statistics});

  final DashboardStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final paid = statistics.paidInvoices;
    final overdue = statistics.overdueInvoices;
    final drafts = statistics.draftInvoices;
    final open = (statistics.totalInvoices - paid - overdue - drafts)
        .clamp(0, statistics.totalInvoices);
    final total = statistics.totalInvoices;
    final segments = <DonutSegment>[
      DonutSegment('Paid', paid, AppColors.paid),
      DonutSegment('Overdue', overdue, AppColors.overdue),
      DonutSegment('Draft', drafts, AppColors.muted),
      DonutSegment('Other', open, AppColors.blue),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice health',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Status mix across your invoices',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(142),
                      painter: DonutPainter(
                        segments: segments,
                        total: total,
                        trackColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'invoices',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final segment in segments)
                      LegendRow(
                        label: segment.label,
                        value: segment.value,
                        color: segment.color,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvoiceDashboardMetrics {
  const InvoiceDashboardMetrics({
    required this.totalInvoiced,
    required this.paidTotal,
    required this.outstandingTotal,
    required this.overdueTotal,
    required this.invoiceCount,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
  });

  final double totalInvoiced;
  final double paidTotal;
  final double outstandingTotal;
  final double overdueTotal;
  final int invoiceCount;
  final int paidCount;
  final int pendingCount;
  final int overdueCount;

  factory InvoiceDashboardMetrics.fromInvoices(List<Invoice> invoices) {
    var totalInvoiced = 0.0;
    var paidTotal = 0.0;
    var outstandingTotal = 0.0;
    var overdueTotal = 0.0;
    var paidCount = 0;
    var pendingCount = 0;
    var overdueCount = 0;
    for (final invoice in invoices) {
      totalInvoiced += invoice.total;
      switch (invoice.status.toLowerCase()) {
        case 'paid':
          paidTotal += invoice.total;
          paidCount++;
        case 'sent':
          outstandingTotal += invoice.balanceDue;
          pendingCount++;
        case 'overdue':
          overdueTotal += invoice.balanceDue;
          overdueCount++;
      }
    }
    return InvoiceDashboardMetrics(
      totalInvoiced: totalInvoiced,
      paidTotal: paidTotal,
      outstandingTotal: outstandingTotal,
      overdueTotal: overdueTotal,
      invoiceCount: invoices.length,
      paidCount: paidCount,
      pendingCount: pendingCount,
      overdueCount: overdueCount,
    );
  }
}

class CollectionHealthCard extends StatelessWidget {
  const CollectionHealthCard({
    super.key,
    required this.totalInvoiced,
    required this.collected,
    required this.pending,
    required this.onTap,
    required this.showAmounts,
  });

  final double totalInvoiced;
  final double collected;
  final double pending;
  final VoidCallback onTap;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) {
    final percentage = totalInvoiced <= 0
        ? 0
        : (collected / totalInvoiced * 100).clamp(0, 100).round();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Executive cashflow & collection',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percentage% collected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: percentage / 100,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showAmounts
                          ? 'Collected: ${formatDashboardMoney(collected)}'
                          : 'Collected amount unavailable',
                      style: const TextStyle(
                        color: AppColors.paid,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    showAmounts ? 'Pending: ${formatDashboardMoney(pending)}' : '',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RevenueExpenseChart extends StatelessWidget {
  const RevenueExpenseChart({
    super.key,
    required this.statistics,
    required this.onViewExpenses,
  });

  final DashboardStatistics statistics;
  final VoidCallback onViewExpenses;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        math.max(statistics.totalRevenue, statistics.totalExpenses);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onViewExpenses,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue & spending',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compare paid invoice revenue with recorded expenses',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              ComparisonBar(
                label: 'Paid revenue',
                amount: statistics.totalRevenue,
                maxAmount: maxValue,
                color: AppColors.blue,
              ),
              const SizedBox(height: 20),
              ComparisonBar(
                label: 'Expenses',
                amount: statistics.totalExpenses,
                maxAmount: maxValue,
                color: AppColors.warning,
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_outlined,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Net cashflow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatDashboardMoney(
                          statistics.totalRevenue - statistics.totalExpenses),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color:
                            statistics.totalRevenue >= statistics.totalExpenses
                                ? AppColors.paid
                                : AppColors.overdue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComparisonBar extends StatelessWidget {
  const ComparisonBar({
    super.key,
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final factor = maxAmount <= 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              formatDashboardMoney(amount),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 11,
            value: factor,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class DonutPainter extends CustomPainter {
  const DonutPainter({
    required this.segments,
    required this.total,
    required this.trackColor,
  });

  final List<DonutSegment> segments;
  final int total;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 15.0;
    final arcRect = (Offset.zero & size).deflate(strokeWidth / 2);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = math.pi * 2 * segment.value / total;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.segments != segments;
}

class LegendRow extends StatelessWidget {
  const LegendRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
