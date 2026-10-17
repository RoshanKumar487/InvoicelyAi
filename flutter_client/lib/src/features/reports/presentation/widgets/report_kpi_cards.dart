import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';

class ReportFinancialKpiCards extends StatelessWidget {
  const ReportFinancialKpiCards({
    super.key,
    required this.netCashflow,
    required this.collectionRate,
    required this.totalInvoiced,
    required this.cashCollected,
    required this.totalExpenses,
    required this.datePreset,
    required this.paidCount,
    required this.scopedInvoicesCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.draftCount,
    required this.formatCurrency,
  });

  final double netCashflow;
  final double collectionRate;
  final double totalInvoiced;
  final double cashCollected;
  final double totalExpenses;
  final String datePreset;
  final int paidCount;
  final int scopedInvoicesCount;
  final int pendingCount;
  final int overdueCount;
  final int draftCount;
  final String Function(double) formatCurrency;

  Widget _buildStatusPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final net = netCashflow;
    final netColor = net >= 0 ? AppColors.paid : AppColors.overdue;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Net Cashflow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            datePreset,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(net),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: netColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      net >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: netColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      net >= 0 ? 'Surplus' : 'Deficit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Invoiced',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(totalInvoiced),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cash Collected',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(cashCollected),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.paid),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Expenses',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(totalExpenses),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Rate: ${(collectionRate * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
              ),
              Text(
                '$paidCount of $scopedInvoicesCount paid',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: collectionRate,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.paid),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusPill('Paid', paidCount, AppColors.paid),
              const SizedBox(width: 8),
              _buildStatusPill('Pending', pendingCount, AppColors.warning),
              const SizedBox(width: 8),
              _buildStatusPill('Overdue', overdueCount, AppColors.overdue),
              const SizedBox(width: 8),
              _buildStatusPill('Draft', draftCount, AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class EnterpriseMetricSummaryStrip extends StatelessWidget {
  const EnterpriseMetricSummaryStrip({
    super.key,
    required this.totalCount,
    required this.inProgressCount,
    required this.sentCount,
    required this.pendingApprovalCount,
    required this.completedCount,
    required this.cycleTimeLabel,
    this.totalLabel = 'New Request',
    this.inProgressLabel = 'Onboarding inprogress',
    this.sentLabel = 'Invite Sent to Customer',
    this.pendingApprovalLabel = 'Pending Approval',
    this.completedLabel = 'Onboarding Completed',
    this.cycleTimeHeader = 'Onboarding Cycle-time',
  });

  final int totalCount;
  final int inProgressCount;
  final int sentCount;
  final int pendingApprovalCount;
  final int completedCount;
  final String cycleTimeLabel;
  final String totalLabel;
  final String inProgressLabel;
  final String sentLabel;
  final String pendingApprovalLabel;
  final String completedLabel;
  final String cycleTimeHeader;

  Widget _buildItem(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: _buildItem(totalLabel, '$totalCount'),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildItem(inProgressLabel, '$inProgressCount'),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildItem(sentLabel, '$sentCount'),
                    ),
                    SizedBox(
                      width: 140,
                      child: _buildItem(pendingApprovalLabel, '$pendingApprovalCount'),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildItem(completedLabel, '$completedCount'),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildItem(cycleTimeHeader, cycleTimeLabel, isLast: true),
                    ),
                  ],
                ),
              ),
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildItem(totalLabel, '$totalCount')),
                Expanded(child: _buildItem(inProgressLabel, '$inProgressCount')),
                Expanded(child: _buildItem(sentLabel, '$sentCount')),
                Expanded(child: _buildItem(pendingApprovalLabel, '$pendingApprovalCount')),
                Expanded(child: _buildItem(completedLabel, '$completedCount')),
                Expanded(child: _buildItem(cycleTimeHeader, cycleTimeLabel, isLast: true)),
              ],
            ),
          );
        },
      ),
    );
  }
}

