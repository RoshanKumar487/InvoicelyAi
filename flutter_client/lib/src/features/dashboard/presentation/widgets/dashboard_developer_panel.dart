import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import '../../data/developer_overview.dart';
import 'dashboard_analytics_cards.dart';

class DeveloperOverviewPanel extends StatelessWidget {
  const DeveloperOverviewPanel({
    required this.overview,
    required this.selectedCompanyId,
    required this.onCompanySelected,
    super.key,
  });

  final DeveloperOverview overview;
  final int? selectedCompanyId;
  final ValueChanged<int?> onCompanySelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform snapshot',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformMetric(
                label: 'Organizations',
                value: '${overview.totalCompanies}',
              ),
              PlatformMetric(label: 'Users', value: '${overview.totalUsers}'),
              PlatformMetric(
                label: 'Invoices',
                value: '${overview.totalInvoices}',
              ),
              PlatformMetric(
                label: 'Platform revenue',
                value: formatDashboardMoney(overview.totalPlatformRevenue),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All companies'),
                  selected: selectedCompanyId == null,
                  onSelected: (_) => onCompanySelected(null),
                ),
                for (final company in overview.companies)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${company.companyName} (${company.companyCode})',
                      ),
                      selected: selectedCompanyId == company.companyId,
                      onSelected: company.companyId == null
                          ? null
                          : (_) => onCompanySelected(company.companyId),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlatformMetric extends StatelessWidget {
  const PlatformMetric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      );
}

class DashboardErrorCard extends StatelessWidget {
  const DashboardErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.overdue),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
