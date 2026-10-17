import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../clients/data/client.dart';
import '../../../employees/data/employee.dart';
import '../../../expenses/data/expense.dart';
import '../../../invoices/data/invoice.dart';
import '../../data/dashboard_statistics.dart';

String formatDashboardMoney(double amount, [String symbol = '₹']) {
  final isNegative = amount < 0;
  final absVal = amount.abs();
  final formatted = absVal.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
  return '${isNegative ? '-' : ''}$symbol$formatted';
}

String formatCompactMoney(double amount, [String symbol = '₹']) {
  final abs = amount.abs();
  if (abs >= 10000000) return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
  if (abs >= 100000) return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
  if (abs >= 1000) return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
  return '$symbol${amount.toStringAsFixed(0)}';
}

/// Interactive Neumorphic card that elevates with smooth dual directional shadows on hover.
class HoverableCard extends StatefulWidget {
  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.borderRadius = 24.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final double borderRadius;

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = widget.accentColor ?? const Color(0xFF2B3548);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isHovered ? Matrix4.translationValues(0, -3.0, 0) : Matrix4.identity(),
          decoration: AppTheme.neuCardDecoration(
            radius: widget.borderRadius,
            selected: _isHovered,
            accentColor: effectiveAccent,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Comprehensive, modern Behance-inspired dashboard analytics presentation.
class DashboardAnalytics extends StatefulWidget {
  const DashboardAnalytics({
    super.key,
    required this.statistics,
    required this.role,
    required this.invoices,
    this.expenses,
    this.clients,
    this.employees,
    required this.onViewInvoices,
    required this.onViewExpenses,
    required this.onViewClients,
    this.onOpenPayroll,
    this.onCreateInvoice,
    this.onAddExpense,
    this.onAddClient,
    this.onAddEmployee,
    this.selectedDateFilter,
  });

  final DashboardStatistics statistics;
  final String role;
  final List<Invoice>? invoices;
  final List<Expense>? expenses;
  final List<Client>? clients;
  final List<Employee>? employees;
  final ValueChanged<String> onViewInvoices;
  final VoidCallback onViewExpenses;
  final VoidCallback onViewClients;
  final VoidCallback? onOpenPayroll;
  final VoidCallback? onCreateInvoice;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddClient;
  final VoidCallback? onAddEmployee;
  final String? selectedDateFilter;

  @override
  State<DashboardAnalytics> createState() => _DashboardAnalyticsState();
}

class _DashboardAnalyticsState extends State<DashboardAnalytics> {
  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  int _selectedMonthIndex = DateTime.now().month - 1; // Default to current month
  bool _showSticksChart = false; // Toggle between Spline Line and Sticks/Bars
  String _recentInvoiceFilter = 'All'; // Filter for recent invoices table
  String _leftChartMode = 'overview'; // 'overview', 'clients', 'market'

  @override
  void initState() {
    super.initState();
    if (_selectedMonthIndex < 0 || _selectedMonthIndex > 11) {
      _selectedMonthIndex = 3; // Fallback to Apr
    }
  }

  bool get _isStaff => widget.role.toUpperCase() == 'EMPLOYEE';

  // Aggregate monthly revenues & expenses
  List<double> get _monthlyRevenues {
    final list = List<double>.filled(12, 0.0);
    final invs = widget.invoices ?? const [];
    if (invs.isNotEmpty) {
      for (final inv in invs) {
        DateTime? dt = DateTime.tryParse(inv.issueDate);
        if (dt == null && inv.createdAt != null) {
          dt = DateTime.fromMillisecondsSinceEpoch(
            inv.createdAt! > 10000000000 ? inv.createdAt! : inv.createdAt! * 1000,
          );
        }
        if (dt != null) {
          final m = dt.month - 1;
          if (m >= 0 && m < 12) {
            list[m] += inv.total;
          }
        }
      }
    } else {
      // Proportional baseline based on total revenue
      final base = widget.statistics.totalRevenue / 12;
      for (var i = 0; i < 12; i++) {
        list[i] = base * (0.8 + 0.4 * math.sin(i * 0.7));
      }
    }
    return list;
  }

  List<double> get _monthlyExpenses {
    final list = List<double>.filled(12, 0.0);
    final exps = widget.expenses ?? const [];
    if (exps.isNotEmpty) {
      for (final exp in exps) {
        final dt = DateTime.tryParse(exp.date);
        if (dt != null) {
          final m = dt.month - 1;
          if (m >= 0 && m < 12) {
            list[m] += exp.amount;
          }
        }
      }
    } else {
      final base = widget.statistics.totalExpenses / 12;
      for (var i = 0; i < 12; i++) {
        list[i] = base * (0.7 + 0.5 * math.cos(i * 0.6));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.statistics;
    final totalInvoices = widget.invoices?.length ?? stats.totalInvoices;
    final paidInvoicesTotal = widget.invoices
            ?.where((inv) => inv.status.toLowerCase() == 'paid')
            .fold<double>(0.0, (sum, inv) => sum + (inv.amountPaid > 0 ? inv.amountPaid : inv.total)) ??
        0.0;
    final totalInvoicedSum = widget.invoices?.fold<double>(0.0, (sum, inv) => sum + inv.total) ?? 0.0;
    final totalRevenue = stats.totalRevenue > 0
        ? stats.totalRevenue
        : (paidInvoicesTotal > 0 ? paidInvoicesTotal : totalInvoicedSum);

    final sumExpenses = widget.expenses?.fold<double>(0.0, (sum, exp) => sum + exp.amount) ?? 0.0;
    final totalExpenses = stats.totalExpenses > 0 ? stats.totalExpenses : sumExpenses;

    final netProfit = totalRevenue - totalExpenses;
    final profitMargin = totalRevenue > 0
        ? ((netProfit / totalRevenue) * 100).clamp(0, 100).toStringAsFixed(0)
        : '0';

    final totalClientsCount = widget.clients?.length ?? stats.totalClients;
    final teamCount = widget.employees?.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role & Enterprise Workspace Header Strip
        _buildWorkspaceIdentityBanner(teamCount),
        const SizedBox(height: 18),

        // 1. Top Row: 4 Neumorphic KPI Cards
        _buildKpiCardsRow(
          totalClients: totalClientsCount,
          totalRevenue: totalRevenue,
          profitMargin: profitMargin,
          netProfit: netProfit,
          totalInvoices: totalInvoices,
        ),
        const SizedBox(height: 18),

        // 2. Middle Row: Invoice Statistics (Donut) & Sales Analytics (Line/Sticks)
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 940) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildInvoiceStatisticsDonutCard(stats, totalInvoices),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 7,
                      child: _buildSalesAnalyticsCard(),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _buildInvoiceStatisticsDonutCard(stats, totalInvoices),
                const SizedBox(height: 18),
                _buildSalesAnalyticsCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // 3. Bottom Row: Recent Invoices Table
        _buildRecentInvoicesTableCard(),
      ],
    );
  }

  Widget _buildWorkspaceIdentityBanner(int? teamCount) {
    final netCashflow = widget.statistics.totalRevenue - widget.statistics.totalExpenses;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: AppTheme.neuPillDecoration(radius: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: AppTheme.neuRecessedDecoration(radius: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Enterprise Live',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(height: 14, child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1))),
            ),
            _buildMiniStatusItem(
              icon: Icons.people_outline_rounded,
              label: 'Workforce',
              value: teamCount != null ? '$teamCount Staff' : '0 Staff',
              color: const Color(0xFF1E293B),
              onTap: widget.onOpenPayroll,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(height: 14, child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1))),
            ),
            _buildMiniStatusItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              value: formatCompactMoney(widget.statistics.totalExpenses),
              color: const Color(0xFF1E293B),
              onTap: widget.onViewExpenses,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(height: 14, child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1))),
            ),
            _buildMiniStatusItem(
              icon: Icons.trending_up_rounded,
              label: 'Net Cashflow',
              value: formatCompactMoney(netCashflow),
              color: const Color(0xFF059669),
              onTap: () => widget.onViewInvoices('Paid'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top 4 KPI Cards (2x2 grid on mobile)
  Widget _buildKpiCardsRow({
    required int totalClients,
    required double totalRevenue,
    required String profitMargin,
    required double netProfit,
    required int totalInvoices,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        final cards = [
          // Card 1: Customers / Clients
          _buildKpiCardItem(
            width: cardWidth,
            title: _isStaff ? 'Assigned Clients' : 'Customers',
            value: totalClients.toString(),
            trendText: '+11.9%',
            isPositiveTrend: true,
            icon: Icons.people_outline_rounded,
            iconBgColor: AppColors.neuSurface,
            iconColor: const Color(0xFF2B3548),
            accentColor: const Color(0xFF2563EB),
            onTap: widget.onViewClients,
          ),

          // Card 2: Revenue (Dark Slate Active Neumorphic Tile)
          _buildKpiCardItem(
            width: cardWidth,
            title: _isStaff ? 'Your Revenue' : 'Revenue',
            value: formatDashboardMoney(totalRevenue),
            trendText: '+12.4%',
            isPositiveTrend: true,
            icon: Icons.currency_rupee_rounded,
            iconBgColor: const Color(0xFF2B3548),
            iconColor: Colors.white,
            accentColor: const Color(0xFF10B981),
            isDarkCard: true,
            onTap: () => widget.onViewInvoices('Paid'),
          ),

          // Card 3: Profit / Margin
          _buildKpiCardItem(
            width: cardWidth,
            title: _isStaff ? 'Collection Rate' : 'Profit Margin',
            value: _isStaff
                ? '${((totalRevenue / (totalRevenue + 100)) * 100).toInt()}%'
                : '$profitMargin%',
            trendText: '+4.2%',
            isPositiveTrend: true,
            icon: Icons.bar_chart_rounded,
            iconBgColor: AppColors.neuSurface,
            iconColor: const Color(0xFF2B3548),
            accentColor: const Color(0xFF7C3AED),
            onTap: widget.onViewExpenses,
          ),

          // Card 4: Invoices
          _buildKpiCardItem(
            width: cardWidth,
            title: _isStaff ? 'Your Invoices' : 'Invoices',
            value: totalInvoices.toString(),
            trendText: '+11.9%',
            isPositiveTrend: true,
            icon: Icons.receipt_long_rounded,
            iconBgColor: AppColors.neuSurface,
            iconColor: const Color(0xFF2B3548),
            accentColor: const Color(0xFF2563EB),
            onTap: () => widget.onViewInvoices('All'),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards,
        );
      },
    );
  }

  Widget _buildKpiCardItem({
    required double width,
    required String title,
    required String value,
    required String trendText,
    required bool isPositiveTrend,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color accentColor,
    required VoidCallback onTap,
    bool isDarkCard = false,
  }) {
    return SizedBox(
      width: width,
      height: 172,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: isDarkCard
                ? AppTheme.neuPillDecoration(
                    radius: 24,
                    active: true,
                    activeColor: const Color(0xFF2B3548),
                  )
                : AppTheme.neuCardDecoration(radius: 24),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Neumorphic Icon Orb + Trend Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: isDarkCard
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            )
                          : AppTheme.neuOrbDecoration(),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: isDarkCard
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : AppTheme.neuRecessedDecoration(radius: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositiveTrend
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: isDarkCard
                                ? const Color(0xFF34D399)
                                : (isPositiveTrend
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            trendText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDarkCard
                                  ? Colors.white
                                  : (isPositiveTrend
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Title & Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDarkCard ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: isDarkCard ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Sparkline at bottom
                SizedBox(
                  width: double.infinity,
                  height: 22,
                  child: CustomPaint(
                    painter: MiniSparklinePainter(
                      color: isDarkCard ? const Color(0xFF34D399) : accentColor,
                      isPositive: isPositiveTrend,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Left Analytics Card: Invoice Overview (Neumorphic Dial Donut / Client Pie / Market Share)
  Widget _buildInvoiceStatisticsDonutCard(DashboardStatistics stats, int totalInvoices) {
    final invoicesList = widget.invoices ?? const [];
    final invPaid = invoicesList.where((i) => i.status.toLowerCase() == 'paid').length;
    final invOverdue = invoicesList.where((i) => i.status.toLowerCase() == 'overdue').length;
    final invDraft = invoicesList.where((i) => i.status.toLowerCase() == 'draft').length;
    final invSent = invoicesList.where((i) => i.status.toLowerCase() == 'sent' || i.status.toLowerCase() == 'pending').length;

    final paid = stats.paidInvoices > 0 ? stats.paidInvoices : invPaid;
    final overdue = stats.overdueInvoices > 0 ? stats.overdueInvoices : invOverdue;
    final drafts = stats.draftInvoices > 0 ? stats.draftInvoices : invDraft;
    final unpaid = invSent > 0 ? invSent : (totalInvoices - paid - overdue - drafts).clamp(0, totalInvoices);

    final safeTotal = totalInvoices > 0 ? totalInvoices : 1;
    final paidPercent = ((paid / safeTotal) * 100).toStringAsFixed(1);
    final overduePercent = ((overdue / safeTotal) * 100).toStringAsFixed(1);
    final unpaidPercent = ((unpaid / safeTotal) * 100).toStringAsFixed(1);

    final donutSegments = [
      DonutSegment('Paid', paid, const Color(0xFF2B3548)),
      DonutSegment('Overdue', overdue, const Color(0xFFF59E0B)),
      DonutSegment('Unpaid', unpaid, const Color(0xFF38BDF8)),
      DonutSegment('Draft', drafts, const Color(0xFFCBD5E1)),
    ];

    // Client Distribution Segments
    final clientSegments = <DonutSegment>[
      const DonutSegment('ABC Industries Pvt. Ltd.', 55, Color(0xFF2B3548)),
      const DonutSegment('Tech Park Whitefield', 28, Color(0xFF2563EB)),
      const DonutSegment('Northstar Security', 11, Color(0xFF0D9488)),
      const DonutSegment('Other Clients', 6, Color(0xFFF59E0B)),
    ];

    // Market Share Segments
    final marketSegments = <DonutSegment>[
      const DonutSegment('Security Guard (12h)', 60, Color(0xFF2B3548)),
      const DonutSegment('Armed Guard (12h)', 24, Color(0xFF2563EB)),
      const DonutSegment('Patrol & Supervision', 10, Color(0xFF0D9488)),
      const DonutSegment('Facility & Escort', 6, Color(0xFF6366F1)),
    ];

    return HoverableCard(
      accentColor: const Color(0xFF2B3548),
      onTap: () => widget.onViewInvoices('All'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Icon & Mode Tabs (Wrap prevents overflow on mobile)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppTheme.neuOrbDecoration(),
                    child: const Icon(Icons.donut_large_rounded, size: 18, color: Color(0xFF2B3548)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _leftChartMode == 'clients'
                            ? 'Client Distribution'
                            : (_leftChartMode == 'market' ? 'Service Share' : 'Invoice Overview'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Collection dial & status breakdown',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),

              // Mode Switcher Segmented Toggle
              Container(
                decoration: AppTheme.neuRecessedDecoration(radius: 12),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartSubModePill('Overview', 'overview'),
                    _buildChartSubModePill('Clients', 'clients'),
                    _buildChartSubModePill('Services', 'market'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Donut / Pie & Legend Content
          if (_leftChartMode == 'overview') ...[
            Row(
              children: [
                // Sculpted Neumorphic Dial Ring (matches sample image circular dial)
                Container(
                  width: 158,
                  height: 158,
                  padding: const EdgeInsets.all(10),
                  decoration: AppTheme.neuOrbDecoration(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(136),
                        painter: BehanceDonutPainter(
                          segments: donutSegments,
                          total: totalInvoices,
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: AppTheme.neuOrbDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalInvoices',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Invoices',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDonutLegendRow(
                        label: 'Total Paid',
                        count: paid,
                        percent: '$paidPercent%',
                        color: const Color(0xFF2B3548),
                        onTap: () => widget.onViewInvoices('Paid'),
                      ),
                      const SizedBox(height: 14),
                      _buildDonutLegendRow(
                        label: 'Total Overdue',
                        count: overdue,
                        percent: '$overduePercent%',
                        color: const Color(0xFFF59E0B),
                        onTap: () => widget.onViewInvoices('Overdue'),
                      ),
                      const SizedBox(height: 14),
                      _buildDonutLegendRow(
                        label: 'Total Unpaid',
                        count: unpaid,
                        percent: '$unpaidPercent%',
                        color: const Color(0xFF38BDF8),
                        onTap: () => widget.onViewInvoices('Sent'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (_leftChartMode == 'clients') ...[
            Row(
              children: [
                SizedBox(
                  width: 145,
                  height: 145,
                  child: CustomPaint(
                    size: const Size.square(145),
                    painter: BehancePieChartPainter(
                      segments: clientSegments,
                      total: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final seg in clientSegments) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 9, height: 9, decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  seg.label,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${seg.value}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                SizedBox(
                  width: 145,
                  height: 145,
                  child: CustomPaint(
                    size: const Size.square(145),
                    painter: BehancePieChartPainter(
                      segments: marketSegments,
                      total: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final seg in marketSegments) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 9, height: 9, decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  seg.label,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${seg.value}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSubModePill(String label, String modeKey) {
    final selected = _leftChartMode == modeKey;
    return InkWell(
      onTap: () => setState(() => _leftChartMode = modeKey),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: selected
            ? AppTheme.neuPillDecoration(radius: 9, isActive: true, activeColor: const Color(0xFFE2E8F0))
            : BoxDecoration(borderRadius: BorderRadius.circular(9)),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required String label,
    required int count,
    required String percent,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 6),
                Text(
                  '($percent)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Right Analytics Card: Sales Analytics with Spline Line & Sticks
  Widget _buildSalesAnalyticsCard() {
    final revenues = _monthlyRevenues;
    final expenses = _monthlyExpenses;
    final activeMonthName = _monthLabels[_selectedMonthIndex];
    final activeMonthRevenue = revenues[_selectedMonthIndex];
    final activeMonthExpense = expenses[_selectedMonthIndex];

    return HoverableCard(
      accentColor: const Color(0xFF4F46E5),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Toggle Switcher
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Analytics',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Monthly business velocity & trend',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),

              // Mode Switcher (Line vs Sticks) in Recessed Neumorphic Track
              Container(
                decoration: AppTheme.neuRecessedDecoration(radius: 12),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartModePill(
                      label: 'Line',
                      icon: Icons.show_chart_rounded,
                      selected: !_showSticksChart,
                      onTap: () => setState(() => _showSticksChart = false),
                    ),
                    _buildChartModePill(
                      label: 'Sticks',
                      icon: Icons.bar_chart_rounded,
                      selected: _showSticksChart,
                      onTap: () => setState(() => _showSticksChart = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Month Highlight Banner in Neumorphic Recessed Groove
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: AppTheme.neuRecessedDecoration(radius: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$activeMonthName Performance:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _showSticksChart
                      ? 'Rev: ${formatCompactMoney(activeMonthRevenue)} · Exp: ${formatCompactMoney(activeMonthExpense)}'
                      : formatDashboardMoney(activeMonthRevenue),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chart Canvas
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_showSticksChart) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 160),
                    painter: BehanceSticksChartPainter(
                      revenues: revenues,
                      expenses: expenses,
                      selectedIndex: _selectedMonthIndex,
                    ),
                  );
                }

                return CustomPaint(
                  size: Size(constraints.maxWidth, 160),
                  painter: BehanceSplineLineChartPainter(
                    values: revenues,
                    selectedIndex: _selectedMonthIndex,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Month Selection Buttons Row on X-Axis
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (index) {
                final isSelected = index == _selectedMonthIndex;
                final monthName = _monthLabels[index];

                return InkWell(
                  onTap: () => setState(() => _selectedMonthIndex = index),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: isSelected
                        ? AppTheme.neuPillDecoration(radius: 8, isActive: true, activeColor: const Color(0xFFE2E8F0))
                        : null,
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartModePill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: selected
            ? AppTheme.neuPillDecoration(radius: 9, isActive: true, activeColor: const Color(0xFFE2E8F0))
            : BoxDecoration(borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Bottom Section: Recent Invoices Table & Neumorphic Pill Rows
  Widget _buildRecentInvoicesTableCard() {
    final allInvoices = widget.invoices ?? const [];
    final filtered = allInvoices.where((inv) {
      if (_recentInvoiceFilter == 'All') return true;
      return inv.status.toLowerCase() == _recentInvoiceFilter.toLowerCase();
    }).toList(growable: false);

    final displayList = filtered.take(6).toList(growable: false);

    return HoverableCard(
      accentColor: const Color(0xFF0284C7),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header Row: Title on Left, Status Filter Chips on Right
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Invoices',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Latest issued billing transactions & client status',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildTableFilterChip('All'),
                  _buildTableFilterChip('Paid'),
                  _buildTableFilterChip('Pending'),
                  _buildTableFilterChip('Overdue'),
                  TextButton(
                    onPressed: () => widget.onViewInvoices('All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('View All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Responsive Content: Mobile Neumorphic Pill Cards or Desktop Table
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 750;

              if (displayList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: AppTheme.neuOrbDecoration(),
                          child: const Icon(Icons.receipt_long_outlined, size: 22, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No ${_recentInvoiceFilter.toLowerCase()} invoices found.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (isMobile) {
                return Column(
                  children: displayList.map((inv) {
                    final isPaid = inv.status.toLowerCase() == 'paid';
                    final clientOrService = inv.items.isNotEmpty
                        ? inv.items.first.description
                        : (inv.clientName.trim().isNotEmpty ? inv.clientName.trim() : 'Security Services');
                    final dateStr = inv.issueDate.isNotEmpty ? inv.issueDate : '12 Oct 2025';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => widget.onViewInvoices('All'),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: AppTheme.neuPillDecoration(radius: 22),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: AppTheme.neuOrbDecoration(),
                                child: const Icon(Icons.description_outlined, size: 19, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      clientOrService,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${inv.invoiceNumber} • $dateStr',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isPaid ? 'Paid' : inv.status,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDashboardMoney(inv.total),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: AppTheme.neuOrbDecoration(),
                                child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 860),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.neuRecessed),
                    headingTextStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      letterSpacing: 0.3,
                    ),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    columnSpacing: 22,
                    horizontalMargin: 12,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('INVOICE #')),
                      DataColumn(label: Text('CUSTOMERS NAME')),
                      DataColumn(label: Text('ITEM NAME')),
                      DataColumn(label: Text('ORDER DATE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('PREPARED BY')),
                      DataColumn(label: Text('ACTION'), numeric: true),
                    ],
                    rows: displayList.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final inv = entry.value;
                      final clientName = inv.clientName.trim().isNotEmpty
                          ? inv.clientName.trim()
                          : (inv.clientCompany.trim().isNotEmpty ? inv.clientCompany.trim() : 'Customer');
                      final itemDescription = inv.items.isNotEmpty
                          ? '${inv.items.first.quantity > 1 ? "${inv.items.first.quantity.toInt()}x " : ""}${inv.items.first.description}'
                          : 'Standard Services';

                      return DataRow(
                        cells: [
                          DataCell(Text('$index', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                          DataCell(
                            InkWell(
                              onTap: () => widget.onViewInvoices('All'),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Text(
                                  '#${inv.invoiceNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: widget.onViewClients,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: AppTheme.neuOrbDecoration(),
                                      child: Center(
                                        child: Text(
                                          clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        clientName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      itemDescription,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              inv.issueDate.isNotEmpty ? inv.issueDate : '—',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                          DataCell(_buildStatusPill(inv.status)),
                          const DataCell(
                            Text(
                              'Admin',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF64748B)),
                                  tooltip: 'View Invoice',
                                  onPressed: () => widget.onViewInvoices('All'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                  tooltip: 'Edit Invoice',
                                  onPressed: () => widget.onViewInvoices('All'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  tooltip: 'Options',
                                  onPressed: () => widget.onViewInvoices('All'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableFilterChip(String status) {
    final selected = _recentInvoiceFilter == status;
    return InkWell(
      onTap: () => setState(() => _recentInvoiceFilter = status),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: AppTheme.neuPillDecoration(
          radius: 14,
          isActive: selected,
          activeColor: const Color(0xFFE2E8F0),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    Color dot;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = const Color(0xFFDEF7EC);
        fg = const Color(0xFF03543F);
        dot = const Color(0xFF10B981);
        break;
      case 'sent':
      case 'pending':
        bg = const Color(0xFFFEF08A);
        fg = const Color(0xFF713F12);
        dot = const Color(0xFFEAB308);
        break;
      case 'overdue':
        bg = const Color(0xFFFCE8E6);
        fg = const Color(0xFF9B1C1C);
        dot = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF334155);
        dot = const Color(0xFF94A3B8);
        break;
    }

    final label = status.isEmpty ? 'Draft' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTERS: BEHANCE-INSPIRED DONUT, SPLINE LINE, STICKS, AND SPARKLINES
// ---------------------------------------------------------------------------

class MiniSparklinePainter extends CustomPainter {
  const MiniSparklinePainter({
    required this.color,
    this.isPositive = true,
  });

  final Color color;
  final bool isPositive;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isPositive) {
      path.moveTo(0, size.height * 0.70);
      path.cubicTo(
        size.width * 0.30, size.height * 0.90,
        size.width * 0.45, size.height * 0.25,
        size.width * 0.70, size.height * 0.40,
      );
      path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.45,
        size.width, size.height * 0.15,
      );
    } else {
      path.moveTo(0, size.height * 0.20);
      path.cubicTo(
        size.width * 0.30, size.height * 0.10,
        size.width * 0.45, size.height * 0.75,
        size.width * 0.70, size.height * 0.55,
      );
      path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.50,
        size.width, size.height * 0.85,
      );
    }

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant MiniSparklinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isPositive != isPositive;
}

class BehancePieChartPainter extends CustomPainter {
  const BehancePieChartPainter({
    required this.segments,
    required this.total,
  });

  final List<DonutSegment> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (math.pi * 2 * seg.value / total);
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant BehancePieChartPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.segments != segments;
}

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class BehanceDonutPainter extends CustomPainter {
  const BehanceDonutPainter({
    required this.segments,
    required this.total,
    this.strokeWidth = 24.0,
  });

  final List<DonutSegment> segments;
  final int total;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = (Offset.zero & size).deflate(strokeWidth / 2);
    final track = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (math.pi * 2 * segment.value / total);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant BehanceDonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.segments != segments;
}

/// Custom painter for the smooth Bézier spline line chart matching the Behance image
class BehanceSplineLineChartPainter extends CustomPainter {
  const BehanceSplineLineChartPainter({
    required this.values,
    required this.selectedIndex,
  });

  final List<double> values;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = math.max(100.0, values.reduce(math.max) * 1.25);
    const bottomPadding = 18.0;
    const topPadding = 26.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final stepX = size.width / (values.length - 1);

    // 1. Draw horizontal faint grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Compute points
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final ratio = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = topPadding + chartHeight * (1.0 - ratio);
      points.add(Offset(x, y));
    }

    // 3. Build smooth Bézier spline path
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Fill gradient area under spline
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, topPadding + chartHeight)
      ..lineTo(points.first.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x284F46E5), Color(0x004F46E5)],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw spline line stroke
    final linePaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 6. Draw dots on all points
    final dotFillPaint = Paint()..color = Colors.white;
    final dotStrokePaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, dotFillPaint);
      canvas.drawCircle(pt, 4.5, dotStrokePaint);
    }

    // 7. Draw highlight pulse & tooltip at selected month
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final activePt = points[selectedIndex];

      // Draw highlighted active dot
      final activePulse = Paint()..color = const Color(0x334F46E5);
      canvas.drawCircle(activePt, 8.5, activePulse);
      final activeDot = Paint()..color = const Color(0xFF4F46E5);
      canvas.drawCircle(activePt, 5.0, activeDot);

      // Draw floating tooltip pill matching Behance screenshot
      final tooltipText = formatCompactMoney(values[selectedIndex]);
      final tp = TextPainter(
        text: TextSpan(
          children: [
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
              ),
            ),
            TextSpan(
              text: tooltipText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const pillPadH = 8.0;
      const pillPadV = 5.0;
      final pillW = tp.width + pillPadH * 2;
      final pillH = tp.height + pillPadV * 2;

      var pillLeft = activePt.dx - (pillW / 2);
      if (pillLeft < 0) pillLeft = 0;
      if (pillLeft + pillW > size.width) pillLeft = size.width - pillW;
      final pillTop = math.max(0.0, activePt.dy - pillH - 8);

      final pillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
        const Radius.circular(8),
      );

      final pillPaint = Paint()..color = const Color(0xFF0F172A);
      canvas.drawRRect(pillRRect, pillPaint);
      tp.paint(canvas, Offset(pillLeft + pillPadH, pillTop + pillPadV));
    }
  }

  @override
  bool shouldRepaint(covariant BehanceSplineLineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.selectedIndex != selectedIndex;
}

/// Custom painter for Monthly Sticks (dual revenue vs expenses vertical bars)
class BehanceSticksChartPainter extends CustomPainter {
  const BehanceSticksChartPainter({
    required this.revenues,
    required this.expenses,
    required this.selectedIndex,
  });

  final List<double> revenues;
  final List<double> expenses;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (revenues.isEmpty) return;

    var maxVal = 100.0;
    for (var i = 0; i < revenues.length; i++) {
      if (revenues[i] > maxVal) maxVal = revenues[i];
      if (i < expenses.length && expenses[i] > maxVal) maxVal = expenses[i];
    }
    maxVal *= 1.25;

    const bottomPadding = 18.0;
    const topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final colWidth = size.width / revenues.length;
    const stickW = 5.5;

    // Faint grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (var i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final revPaint = Paint()..color = const Color(0xFF4F46E5);
    final expPaint = Paint()..color = const Color(0xFFF59E0B);

    for (var i = 0; i < revenues.length; i++) {
      final centerX = i * colWidth + (colWidth / 2);
      final isSelected = i == selectedIndex;

      if (isSelected) {
        final colRect = Rect.fromLTWH(i * colWidth, topPadding, colWidth, chartHeight);
        final glowPaint = Paint()..color = const Color(0x0C4F46E5);
        canvas.drawRRect(RRect.fromRectAndRadius(colRect, const Radius.circular(6)), glowPaint);
      }

      // Revenue Stick (left)
      final revRatio = (revenues[i] / maxVal).clamp(0.0, 1.0);
      final revH = math.max(4.0, chartHeight * revRatio);
      final revTop = topPadding + chartHeight - revH;
      final revRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - stickW - 1.5, revTop, stickW, revH),
        const Radius.circular(3),
      );
      canvas.drawRRect(revRect, revPaint);

      // Expense Stick (right)
      final expVal = i < expenses.length ? expenses[i] : 0.0;
      final expRatio = (expVal / maxVal).clamp(0.0, 1.0);
      final expH = math.max(4.0, chartHeight * expRatio);
      final expTop = topPadding + chartHeight - expH;
      final expRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 1.5, expTop, stickW, expH),
        const Radius.circular(3),
      );
      canvas.drawRRect(expRect, expPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BehanceSticksChartPainter oldDelegate) =>
      oldDelegate.revenues != revenues ||
      oldDelegate.expenses != expenses ||
      oldDelegate.selectedIndex != selectedIndex;
}
