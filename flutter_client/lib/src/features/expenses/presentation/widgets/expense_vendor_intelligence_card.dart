import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/expense.dart';

class VendorSpendSummary {
  const VendorSpendSummary({
    required this.vendorName,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });

  final String vendorName;
  final double totalAmount;
  final int count;
  final double percentage;
}

/// Vendor Spend Intelligence & Monthly Operating Budget Card.
/// Gives financial controllers instant visibility into vendor concentration,
/// budget burn velocity, and recurring fixed overheads.
class ExpenseVendorIntelligenceCard extends StatelessWidget {
  const ExpenseVendorIntelligenceCard({
    required this.expenses,
    this.currencySymbol = '₹',
    this.monthlyBudgetLimit = 150000.0,
    this.onSelectVendor,
    super.key,
  });

  final List<Expense> expenses;
  final String currencySymbol;
  final double monthlyBudgetLimit;
  final ValueChanged<String>? onSelectVendor;

  List<VendorSpendSummary> _getTopVendors() {
    final map = <String, List<Expense>>{};
    for (final exp in expenses) {
      final v = exp.vendor.trim().isNotEmpty ? exp.vendor.trim() : 'Unspecified Vendor';
      map.putIfAbsent(v, () => []).add(exp);
    }

    final totalAll = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final list = <VendorSpendSummary>[];

    map.forEach((vendor, listExp) {
      final amount = listExp.fold<double>(0.0, (sum, e) => sum + e.amount);
      final pct = totalAll > 0 ? (amount / totalAll) * 100 : 0.0;
      list.add(
        VendorSpendSummary(
          vendorName: vendor,
          totalAmount: amount,
          count: listExp.length,
          percentage: pct,
        ),
      );
    });

    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list.take(4).toList();
  }

  double get _currentMonthSpend {
    final now = DateTime.now();
    return expenses.where((exp) {
      final d = DateTime.tryParse(exp.date);
      if (d == null) return false;
      return d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _fixedOverheadsSpend {
    // Categories considered recurring fixed overheads
    final fixedCats = {'Office & Rent', 'Software & IT', 'Hardware & Equipment'};
    return expenses
        .where((e) => fixedCats.contains(e.category))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final topVendors = _getTopVendors();
    final monthSpend = _currentMonthSpend;
    final budgetPct = monthlyBudgetLimit > 0
        ? ((monthSpend / monthlyBudgetLimit) * 100).clamp(0, 150).toDouble()
        : 0.0;

    final fixedSpend = _fixedOverheadsSpend;
    final totalSpend = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final variableSpend = (totalSpend - fixedSpend).clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.neuCardDecoration(radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF1E3A8A),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Concentration & Budget Pulse',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Spend distribution across key suppliers & monthly burn rate',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Responsive Dual-Column or Stacked View
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;

                final leftColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Supplier Concentration',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    if (topVendors.isEmpty)
                      const Text('No vendor data available yet.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                    else
                      ...topVendors.map((v) => _buildVendorRow(context, v)),
                  ],
                );

                final rightColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monthly Operating Budget',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: budgetPct > 90 ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            budgetPct > 90
                                ? 'Alert: ${budgetPct.toStringAsFixed(0)}% Used'
                                : '${budgetPct.toStringAsFixed(0)}% Burn Rate',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: budgetPct > 90 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (budgetPct / 100).clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          budgetPct > 90 ? const Color(0xFFDC2626) : (budgetPct > 75 ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: $currencySymbol${monthSpend.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Target: $currencySymbol${monthlyBudgetLimit.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fixed vs Variable Ratio Strip
                    const Text(
                      'Fixed Overheads vs Variable Spend',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fixed Overheads', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${fixedSpend.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Variable Expenses', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  '$currencySymbol${variableSpend.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0D9488)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: leftColumn),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: rightColumn),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                    rightColumn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorRow(BuildContext context, VendorSpendSummary vendor) {
    return InkWell(
      onTap: onSelectVendor != null ? () => onSelectVendor!(vendor.vendorName) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vendor.vendorName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$currencySymbol${vendor.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${vendor.percentage.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (vendor.percentage / 100).clamp(0.01, 1.0),
                minHeight: 4,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
