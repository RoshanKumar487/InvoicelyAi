import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../../invoices/data/invoice.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_statistics.dart';
import '../data/developer_overview.dart';
import 'widgets/dashboard_analytics_cards.dart';

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
    required this.onOpenTemplates,
    super.key,
  });

  final AuthSession session;
  final DashboardRepository repository;
  final Future<void> Function() onLogout;
  final VoidCallback onCreateInvoice;
  final ValueChanged<String> onViewInvoices;
  final VoidCallback onViewClients;
  final VoidCallback onViewExpenses;
  final VoidCallback onOpenAiChat;
  final VoidCallback onOpenTemplates;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStatistics? _statistics;
  List<Invoice>? _invoices;
  DeveloperOverview? _developerOverview;
  int? _selectedCompanyId;
  int _loadGeneration = 0;
  String? _error;
  bool _isLoading = true;
  bool _usingCachedData = false;
  String? _invoiceLoadError;

  bool get _isDeveloper =>
      widget.session.user.role.toUpperCase() == 'DEVELOPER';

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
      if (_isDeveloper) {
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
          _invoiceLoadError = null;
        });
      }
      if (widget.session.user.hasPermission('INVOICES')) {
        try {
          final invoices = await widget.repository.loadInvoices();
          if (mounted && generation == _loadGeneration) {
            setState(() {
              _invoices = invoices;
              _usingCachedData =
                  usedCachedData || widget.repository.lastLoadUsedCache;
            });
          }
        } catch (error) {
          if (mounted && generation == _loadGeneration) {
            setState(() => _invoiceLoadError =
                'Invoice totals could not be refreshed: $error');
          }
        }
      } else if (mounted && generation == _loadGeneration) {
        setState(() {
          _invoices = null;
          _invoiceLoadError = null;
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
    final role = widget.session.user.role.toUpperCase();
    final subtitle = switch (role) {
      'DEVELOPER' => 'Platform health and company activity',
      'EMPLOYEE' => 'Your invoice and collection activity',
      _ => 'Your business performance',
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = constraints.maxWidth > 1192
                ? (constraints.maxWidth - 1160) / 2
                : 16.0;
            return RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 28),
                children: [
                  _DashboardHeader(
                    name: _isDeveloper ? 'Platform overview' : name,
                    subtitle: subtitle,
                    onRefresh: _isLoading ? null : _loadStatistics,
                    onCreateInvoice: widget.onCreateInvoice,
                    canOpenInvoices:
                        widget.session.user.hasPermission('INVOICES'),
                  ),
                  const SizedBox(height: 16),
                  if (!_isDeveloper)
                    _AssistantBanner(onTap: widget.onOpenAiChat),
                  if (_usingCachedData) ...[
                    const SizedBox(height: 12),
                    const OfflineCacheBanner(),
                  ],
                  const SizedBox(height: 12),
                  _DashboardShortcuts(
                    user: widget.session.user,
                    onViewInvoices: () => widget.onViewInvoices('All'),
                    onViewExpenses: widget.onViewExpenses,
                    onViewClients: widget.onViewClients,
                    onOpenTemplates: widget.onOpenTemplates,
                  ),
                  const SizedBox(height: 16),
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
                  if (_invoiceLoadError != null) ...[
                    _ErrorCard(
                      message: _invoiceLoadError!,
                      onRetry: _loadStatistics,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isLoading && _statistics == null)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_statistics != null)
                    DashboardAnalytics(
                      statistics: _statistics!,
                      role: role,
                      invoices: _invoices,
                      onViewInvoices: widget.onViewInvoices,
                      onViewExpenses: widget.onViewExpenses,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.subtitle,
    required this.onRefresh,
    required this.onCreateInvoice,
    required this.canOpenInvoices,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback onCreateInvoice;
  final bool canOpenInvoices;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sync dashboard',
            onPressed: onRefresh,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
          if (canOpenInvoices)
            IconButton.filled(
              tooltip: 'Create invoice',
              onPressed: onCreateInvoice,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add),
            ),
        ],
      );
}

class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AI VOICE & CHAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Invoice assistant',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Generate invoices via chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create invoices, save clients, or ask questions by voice or text.',
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.auto_awesome, color: AppColors.blue),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DashboardShortcuts extends StatelessWidget {
  const _DashboardShortcuts({
    required this.user,
    required this.onViewInvoices,
    required this.onViewExpenses,
    required this.onViewClients,
    required this.onOpenTemplates,
  });

  final UserSummary user;
  final VoidCallback onViewInvoices;
  final VoidCallback onViewExpenses;
  final VoidCallback onViewClients;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            if (user.hasPermission('INVOICES'))
              _ShortcutChip(
                label: 'Invoices',
                icon: Icons.receipt_long,
                onTap: onViewInvoices,
              ),
            if (user.hasPermission('EXPENSES'))
              _ShortcutChip(
                label: 'Expenses',
                icon: Icons.account_balance_wallet_outlined,
                onTap: onViewExpenses,
              ),
            if (user.hasPermission('CLIENTS'))
              _ShortcutChip(
                label: 'Clients',
                icon: Icons.people_outline,
                onTap: onViewClients,
              ),
            if (user.hasPermission('INVOICES'))
              _ShortcutChip(
                label: 'Templates',
                icon: Icons.description_outlined,
                onTap: onOpenTemplates,
              ),
          ],
        ),
      );
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      icon,
                      size: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
              _PlatformMetric(
                label: 'Organizations',
                value: '${overview.totalCompanies}',
              ),
              _PlatformMetric(label: 'Users', value: '${overview.totalUsers}'),
              _PlatformMetric(
                label: 'Invoices',
                value: '${overview.totalInvoices}',
              ),
              _PlatformMetric(
                label: 'Platform revenue',
                value: _money(overview.totalPlatformRevenue),
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

class _PlatformMetric extends StatelessWidget {
  const _PlatformMetric({required this.label, required this.value});

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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

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


String _money(double amount) => formatDashboardMoney(amount);
