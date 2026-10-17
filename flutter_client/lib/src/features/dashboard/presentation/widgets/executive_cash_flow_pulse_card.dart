import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../expenses/data/expense.dart';
import '../../../invoices/data/invoice.dart';

/// Executive Working Capital & Cash Runway Intelligence Pulse.
/// Provides C-suite and business owners instant clarity on net cash flow velocity,
/// Days Sales Outstanding (DSO), and upcoming 30-day liquidity health.
class ExecutiveCashFlowPulseCard extends StatelessWidget {
  const ExecutiveCashFlowPulseCard({
    this.invoices,
    this.expenses,
    this.currencySymbol = '₹',
    this.onViewInvoices,
    this.onViewExpenses,
    super.key,
  });

  final List<Invoice>? invoices;
  final List<Expense>? expenses;
  final String currencySymbol;
  final VoidCallback? onViewInvoices;
  final VoidCallback? onViewExpenses;

  double get _totalCollectedRevenue {
    if (invoices == null || invoices!.isEmpty) return 0.0;
    return invoices!
        .where((i) => i.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, i) => sum + (i.amountPaid > 0 ? i.amountPaid : i.total));
  }

  double get _totalSettledExpenses {
    if (expenses == null || expenses!.isEmpty) return 0.0;
    return expenses!
        .where((e) => !e.isDue)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _netOperatingCashFlow => _totalCollectedRevenue - _totalSettledExpenses;

  double get _uncollectedReceivables {
    if (invoices == null || invoices!.isEmpty) return 0.0;
    return invoices!
        .where((i) => i.status.toLowerCase() != 'paid' && i.status.toLowerCase() != 'cancelled')
        .fold(0.0, (sum, i) => sum + (i.balanceDue > 0 ? i.balanceDue : i.total));
  }

  double get _pendingPayables {
    if (expenses == null || expenses!.isEmpty) return 0.0;
    return expenses!
        .where((e) => e.isDue)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Days Sales Outstanding (DSO) estimation
  int get _estimatedDso {
    if (invoices == null || invoices!.isEmpty) return 21;
    final totalInvoiced = invoices!.fold<double>(0.0, (sum, i) => sum + i.total);
    if (totalInvoiced <= 0) return 21;
    final dso = (_uncollectedReceivables / totalInvoiced) * 60; // 60-day velocity base
    return dso.clamp(7, 90).round();
  }

  @override
  Widget build(BuildContext context) {
    final netCash = _netOperatingCashFlow;
    final receivables = _uncollectedReceivables;
    final payables = _pendingPayables;
    final dso = _estimatedDso;
    final isSurplus = netCash >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.neuCardDecoration(radius: 22),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Strip
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF0F172A),
                  ),
                  child: const Icon(Icons.speed_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Working Capital & Cash Flow Pulse',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSurplus ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSurplus ? 'Healthy Liquidity' : 'Cash Burn Alert',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSurplus ? const Color(0xFF15803D) : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Operating cash flow, Days Sales Outstanding (DSO) & working capital buffer',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Responsive 3-Column Metrics
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                final item1 = _buildMetricBox(
                  context,
                  title: 'Net Operating Cash Flow',
                  value: '${isSurplus ? '+' : ''}$currencySymbol${netCash.toStringAsFixed(0)}',
                  subtitle: 'Collections ($currencySymbol${_totalCollectedRevenue.toStringAsFixed(0)}) - Paid Expenses ($currencySymbol${_totalSettledExpenses.toStringAsFixed(0)})',
                  icon: isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  accentColor: isSurplus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  bgColor: isSurplus ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                );

                final item2 = _buildMetricBox(
                  context,
                  title: 'Receivables vs. Payables',
                  value: '$currencySymbol${receivables.toStringAsFixed(0)}',
                  subtitle: 'Receivables ($currencySymbol${receivables.toStringAsFixed(0)}) vs Payables ($currencySymbol${payables.toStringAsFixed(0)})',
                  icon: Icons.account_balance_rounded,
                  accentColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: onViewInvoices,
                );

                final item3 = _buildMetricBox(
                  context,
                  title: 'Days Sales Outstanding (DSO)',
                  value: '$dso Days',
                  subtitle: dso <= 30 ? 'Optimal cash turnover (<30d)' : 'Aging collections (>30d)',
                  icon: Icons.timer_outlined,
                  accentColor: dso <= 30 ? const Color(0xFF059669) : const Color(0xFFD97706),
                  bgColor: const Color(0xFFF8FAFC),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: item1),
                      const SizedBox(width: 14),
                      Expanded(child: item2),
                      const SizedBox(width: 14),
                      Expanded(child: item3),
                    ],
                  );
                }

                return Column(
                  children: [
                    item1,
                    const SizedBox(height: 10),
                    item2,
                    const SizedBox(height: 10),
                    item3,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
