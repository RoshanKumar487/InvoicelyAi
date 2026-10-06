import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/developer_overview.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_statistics.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.session,
    required this.repository,
    required this.onLogout,
    required this.onCreateInvoice,
    required this.onViewInvoices,
    required this.onViewClients,
    required this.onViewExpenses,
    required this.onOpenAiChat,
    super.key,
  });

  final AuthSession session;
  final DashboardRepository repository;
  final Future<void> Function() onLogout;
  final VoidCallback onCreateInvoice;
  final VoidCallback onViewInvoices;
  final VoidCallback onViewClients;
  final VoidCallback onViewExpenses;
  final VoidCallback onOpenAiChat;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStatistics? _statistics;
  DeveloperOverview? _developerOverview;
  int? _selectedCompanyId;
  int _loadGeneration = 0;
  String? _error;
  bool _isLoading = true;
  bool _usingCachedData = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var usedCachedData = false;
      DeveloperOverview? refreshedOverview;
      if (widget.session.user.role.toUpperCase() == 'DEVELOPER') {
        refreshedOverview = await widget.repository.loadDeveloperOverview();
        usedCachedData = widget.repository.lastLoadUsedCache;
      }
      final statistics = await widget.repository.loadStatistics(
        companyId: _selectedCompanyId,
      );
      usedCachedData = usedCachedData || widget.repository.lastLoadUsedCache;
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _statistics = statistics;
          if (refreshedOverview != null) {
            _developerOverview = refreshedOverview;
          }
          _usingCachedData = usedCachedData;
        });
      }
    } on ApiException catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.session.company?.name.isNotEmpty == true
        ? widget.session.company!.name
        : 'Your business';
    final isDeveloper = widget.session.user.role.toUpperCase() == 'DEVELOPER';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isDeveloper ? 'Platform Developer' : name),
            Text(
              isDeveloper ? 'Platform overview' : 'Organization overview',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadStatistics,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Welcome, ${widget.session.user.fullName}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Here is your business at a glance.',
              style: TextStyle(color: AppColors.muted),
            ),
            if (_usingCachedData) ...[
              const SizedBox(height: 16),
              const OfflineCacheBanner(),
            ],
            const SizedBox(height: 22),
            if (_developerOverview != null) ...[
              _DeveloperOverviewPanel(
                overview: _developerOverview!,
                selectedCompanyId: _selectedCompanyId,
                onCompanySelected: (companyId) {
                  setState(() {
                    _selectedCompanyId = companyId;
                    _statistics = null;
                  });
                  _loadStatistics();
                },
              ),
              const SizedBox(height: 18),
            ],
            if (_error != null) ...[
              _ErrorCard(message: _error!, onRetry: _loadStatistics),
              const SizedBox(height: 18),
            ],
            if (_isLoading && _statistics == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_statistics != null)
              _StatisticsGrid(statistics: _statistics!),
            const SizedBox(height: 24),
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _QuickActions(
              onCreateInvoice: widget.onCreateInvoice,
              onViewInvoices: widget.onViewInvoices,
              onViewClients: widget.onViewClients,
              onViewExpenses: widget.onViewExpenses,
              onOpenAiChat: widget.onOpenAiChat,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperOverviewPanel extends StatelessWidget {
  const _DeveloperOverviewPanel({
    required this.overview,
    required this.selectedCompanyId,
    required this.onCompanySelected,
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
            'Platform overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PlatformMetric(
                label: 'Organizations',
                value: '${overview.totalCompanies}',
              ),
              _PlatformMetric(
                label: 'Users',
                value: '${overview.totalUsers}',
              ),
              _PlatformMetric(
                label: 'Invoices',
                value: '${overview.totalInvoices}',
              ),
              _PlatformMetric(
                label: 'Expenses',
                value: '${overview.totalExpenses}',
              ),
              _PlatformMetric(
                label: 'Platform revenue',
                value: _money(overview.totalPlatformRevenue),
              ),
              _PlatformMetric(
                label: 'Platform expenses',
                value: _money(overview.totalPlatformExpenses),
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
                  label: const Text('All companies (Global)'),
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

  String _money(double amount) => '₹${amount.toStringAsFixed(2)}';
}

class _PlatformMetric extends StatelessWidget {
  const _PlatformMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.statistics});

  final DashboardStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Revenue', _money(statistics.totalRevenue), Icons.trending_up,
          AppColors.paid),
      _Metric('Expenses', _money(statistics.totalExpenses), Icons.payments,
          AppColors.warning),
      _Metric('Invoices', '${statistics.totalInvoices}', Icons.receipt_long,
          AppColors.blue),
      _Metric('Clients', '${statistics.totalClients}', Icons.people,
          const Color(0xFF7C3AED)),
      _Metric('Paid', '${statistics.paidInvoices}', Icons.check_circle,
          AppColors.paid),
      _Metric('Overdue', '${statistics.overdueInvoices}', Icons.warning,
          AppColors.overdue),
      _Metric('Drafts', '${statistics.draftInvoices}', Icons.edit_note,
          AppColors.muted),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 640
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 124,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }

  String _money(double amount) => '₹${amount.toStringAsFixed(2)}';
}

class _Metric {
  const _Metric(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(metric.icon, color: metric.color, size: 22),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            metric.title,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreateInvoice,
    required this.onViewInvoices,
    required this.onViewClients,
    required this.onViewExpenses,
    required this.onOpenAiChat,
  });

  final VoidCallback onCreateInvoice;
  final VoidCallback onViewInvoices;
  final VoidCallback onViewClients;
  final VoidCallback onViewExpenses;
  final VoidCallback onOpenAiChat;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionChip(
          icon: Icons.add,
          label: 'New invoice',
          onPressed: onCreateInvoice,
        ),
        _ActionChip(
          icon: Icons.receipt_long,
          label: 'View invoices',
          onPressed: onViewInvoices,
        ),
        _ActionChip(
          icon: Icons.person_add_alt,
          label: 'Clients',
          onPressed: onViewClients,
        ),
        _ActionChip(
          icon: Icons.add_card,
          label: 'Add expense',
          onPressed: onViewExpenses,
        ),
        _ActionChip(
          icon: Icons.auto_awesome,
          label: 'AI assistant',
          onPressed: onOpenAiChat,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.blue),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
}
