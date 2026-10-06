import 'dart:math' as math;

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
                    _DashboardAnalytics(
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

class _DashboardAnalytics extends StatelessWidget {
  const _DashboardAnalytics({
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
        : _InvoiceDashboardMetrics.fromInvoices(invoices!);
    final metrics = <_Metric>[
      _Metric(
        title: isEmployee ? 'Your total invoiced' : 'Total invoiced',
        value: totals == null ? '—' : _money(totals.totalInvoiced),
        subtext:
            '${totals?.invoiceCount ?? statistics.totalInvoices} total invoices',
        icon: Icons.trending_up,
        color: AppColors.blue,
        onTap: () => onViewInvoices('All'),
      ),
      _Metric(
        title: isEmployee ? 'Your paid collected' : 'Paid collected',
        value: _money(totals?.paidTotal ?? statistics.totalRevenue),
        subtext:
            '${totals?.paidCount ?? statistics.paidInvoices} fully settled',
        icon: Icons.check_circle_outline,
        color: AppColors.paid,
        onTap: () => onViewInvoices('Paid'),
      ),
      _Metric(
        title: isEmployee ? 'Your outstanding' : 'Outstanding',
        value: totals == null ? '—' : _money(totals.outstandingTotal),
        subtext: '${totals?.pendingCount ?? 0} pending payment',
        icon: Icons.hourglass_top,
        color: AppColors.warning,
        onTap: () => onViewInvoices('Sent'),
      ),
      _Metric(
        title: isEmployee ? 'Your overdue' : 'Overdue',
        value: totals == null ? '—' : _money(totals.overdueTotal),
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
            final gap = 12.0;
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
                    child: _MetricCard(metric: metric),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _CollectionHealthCard(
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
                    child: _InvoiceHealthCard(statistics: statistics),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _RevenueExpenseChart(
                      statistics: statistics,
                      onViewExpenses: onViewExpenses,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _InvoiceHealthCard(statistics: statistics),
                const SizedBox(height: 14),
                _RevenueExpenseChart(
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

class _Metric {
  const _Metric({
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: metric.onTap,
          child: AppCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: metric.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 19),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        metric.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  metric.subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
}

class _InvoiceHealthCard extends StatelessWidget {
  const _InvoiceHealthCard({required this.statistics});

  final DashboardStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final paid = statistics.paidInvoices;
    final overdue = statistics.overdueInvoices;
    final drafts = statistics.draftInvoices;
    final open = (statistics.totalInvoices - paid - overdue - drafts)
        .clamp(0, statistics.totalInvoices);
    final total = statistics.totalInvoices;
    final segments = <_DonutSegment>[
      _DonutSegment('Paid', paid, AppColors.paid),
      _DonutSegment('Overdue', overdue, AppColors.overdue),
      _DonutSegment('Draft', drafts, AppColors.muted),
      _DonutSegment('Other', open, AppColors.blue),
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
                      painter: _DonutPainter(
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
                      _LegendRow(
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

class _InvoiceDashboardMetrics {
  const _InvoiceDashboardMetrics({
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

  factory _InvoiceDashboardMetrics.fromInvoices(List<Invoice> invoices) {
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
    return _InvoiceDashboardMetrics(
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

class _CollectionHealthCard extends StatelessWidget {
  const _CollectionHealthCard({
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
                          ? 'Collected: ${_money(collected)}'
                          : 'Collected amount unavailable',
                      style: const TextStyle(
                        color: AppColors.paid,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    showAmounts ? 'Pending: ${_money(pending)}' : '',
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

class _RevenueExpenseChart extends StatelessWidget {
  const _RevenueExpenseChart({
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
              _ComparisonBar(
                label: 'Paid revenue',
                amount: statistics.totalRevenue,
                maxAmount: maxValue,
                color: AppColors.blue,
              ),
              const SizedBox(height: 20),
              _ComparisonBar(
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
                    Expanded(
                      child: Text(
                        'Net cashflow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _money(
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

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
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
    final progress =
        maxAmount <= 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              _money(amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.total,
    required this.trackColor,
  });

  final List<_DonutSegment> segments;
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
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.segments != segments;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
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

String _money(double amount) => '₹${amount.toStringAsFixed(2)}';
