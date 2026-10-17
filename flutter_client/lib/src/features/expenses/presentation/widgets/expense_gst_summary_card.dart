import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/expense.dart';

/// Enterprise Business Component: Displays Input Tax Credit (ITC) and GST breakdown
/// for operational expenses. Helps finance teams audit tax deductions and claimable ITC.
class ExpenseGstSummaryCard extends StatefulWidget {
  const ExpenseGstSummaryCard({
    required this.expenses,
    required this.currencySymbol,
    super.key,
  });

  final List<Expense> expenses;
  final String currencySymbol;

  @override
  State<ExpenseGstSummaryCard> createState() => _ExpenseGstSummaryCardState();
}

class _ExpenseGstSummaryCardState extends State<ExpenseGstSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) return const SizedBox.shrink();

    final totalExpenses = widget.expenses.fold<double>(0.0, (acc, e) => acc + e.amount);
    final deductibleExpenses = widget.expenses.where((e) => e.taxDeductible).toList();
    final totalDeductible = deductibleExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);

    // Compute explicit tax amount or estimate 18% standard GST on eligible business expenses
    final totalTaxClaimable = widget.expenses.fold<double>(0.0, (acc, e) {
      if (e.taxAmount > 0) return acc + e.taxAmount;
      if (e.taxDeductible) return acc + (e.amount * 0.18 / 1.18);
      return acc;
    });

    final netExpenseLiability = totalExpenses - totalTaxClaimable;

    // Category breakdown of tax deductible expenses
    final categoryTotals = <String, double>{};
    for (final exp in deductibleExpenses) {
      final cat = exp.category.isNotEmpty ? exp.category : 'General';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + exp.amount;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.neuCardDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title, Badge, and Expand/Collapse toggle
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF2563EB),
                  ),
                  child: const Center(
                    child: Icon(Icons.account_balance_rounded, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'GST & Input Tax Credit (ITC) Summary',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              'Tax Audit Ready',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Statutory tax deductible breakdown & claimable Input Tax Credit',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: AppTheme.neuPillDecoration(radius: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Hide Details' : 'View Breakdown',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Summary Grid (Responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final cards = [
                  _buildMetricCell(
                    label: 'Total Expenses',
                    value: '${widget.currencySymbol}${totalExpenses.toStringAsFixed(2)}',
                    subtext: '${widget.expenses.length} Total records',
                    accentColor: const Color(0xFF1E293B),
                  ),
                  _buildMetricCell(
                    label: 'Tax Deductible',
                    value: '${widget.currencySymbol}${totalDeductible.toStringAsFixed(2)}',
                    subtext: '${deductibleExpenses.length} Eligible entries',
                    accentColor: const Color(0xFF2563EB),
                  ),
                  _buildMetricCell(
                    label: 'Claimable Input GST (ITC)',
                    value: '${widget.currencySymbol}${totalTaxClaimable.toStringAsFixed(2)}',
                    subtext: 'Offset against output GST',
                    accentColor: const Color(0xFF16A34A),
                    isHighlighted: true,
                  ),
                  _buildMetricCell(
                    label: 'Net Business Cost',
                    value: '${widget.currencySymbol}${netExpenseLiability.toStringAsFixed(2)}',
                    subtext: 'Post-tax cash outflow',
                    accentColor: const Color(0xFF7C3AED),
                  ),
                ];

                if (isCompact) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            ),

            // Expanded Breakdown: Category distribution chips & Statutory Compliance Info
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              const Text(
                'Category-wise Tax Deductions (Eligible for Input Tax Credit):',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryTotals.entries.map((entry) {
                  final pct = totalDeductible > 0 ? (entry.value / totalDeductible * 100).toStringAsFixed(1) : '0';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: AppTheme.neuRecessedDecoration(radius: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.currencySymbol}${entry.value.toStringAsFixed(0)} ($pct%)',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Keep supplier GSTIN on bills and attach digital receipts for automatic GST reconciliation in quarterly filings.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({
    required String label,
    required String value,
    required String subtext,
    required Color accentColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isHighlighted ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
