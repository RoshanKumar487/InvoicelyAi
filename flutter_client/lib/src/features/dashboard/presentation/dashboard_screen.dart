import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../../audit/data/audit_log.dart';
import '../../audit/data/audit_log_service.dart';
import '../../invoices/data/invoice.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_statistics.dart';
import '../data/developer_overview.dart';
import '../../clients/data/client.dart';

import '../../clients/data/clients_repository.dart';
import '../../employees/data/employee.dart';
import '../../employees/data/employee_repository.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expenses_repository.dart';
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
    this.onOpenPayroll,
    this.onOpenAuditLogs,
    this.registeredCompanyName,
    this.localSettings = const {},
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
  final VoidCallback? onOpenPayroll;
  final VoidCallback? onOpenAuditLogs;
  final String? registeredCompanyName;
  final Map<String, Object?> localSettings;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class DashboardNotificationItem {
  DashboardNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color color;
  bool isRead;
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStatistics? _statistics;
  List<Invoice>? _invoices;
  List<Expense>? _expenses;
  List<Client>? _clients;
  List<Employee>? _employees;
  DeveloperOverview? _developerOverview;
  int? _selectedCompanyId;
  int _loadGeneration = 0;
  String? _error;
  bool _isLoading = true;
  bool _usingCachedData = false;
  String? _invoiceLoadError;
  String? _backendBusinessName;
  List<AuditLog> _recentAuditLogs = [];
  StreamSubscription<AuditLog>? _auditSubscription;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDateFilter = 'FY 2025-26';
  bool _hasUserSelectedDateFilter = false;
  DateTimeRange? _customDateRange;

  final List<DashboardNotificationItem> _notifications = [
    DashboardNotificationItem(
      id: '1',
      title: 'Payment Received',
      message: 'Payment of ₹45,200 received for Invoice #INV-2025-001 from Acme Security',
      timeAgo: '12m ago',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '2',
      title: 'Invoice Overdue Notice',
      message: 'Invoice #INV-2025-004 is overdue by 3 days (₹18,500)',
      timeAgo: '2h ago',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFEF4444),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '3',
      title: 'New Client Onboarded',
      message: 'Metro Guard Logistics profile has been verified and activated',
      timeAgo: 'Yesterday',
      icon: Icons.person_add_alt_1_rounded,
      color: const Color(0xFF0284C7),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '4',
      title: 'Tax & GST Summary Ready',
      message: 'Monthly GST summary for March 2025 is ready for review',
      timeAgo: '2d ago',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF8B5CF6),
      isRead: true,
    ),
  ];

  int get _unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  void _markAllNotificationsAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _showNotificationsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final unreadCount = _notifications.where((n) => !n.isRead).length;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      _markAllNotificationsAsRead();
                      setDialogState(() {});
                    },
                    child: const Text('Mark all as read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: _notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No notifications yet', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, index) {
                        final notif = _notifications[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: notif.isRead ? Colors.transparent : const Color(0xFFF8FAFC),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: notif.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notif.icon, size: 18, color: notif.color),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                notif.timeAgo,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              notif.message,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ),
                          trailing: notif.isRead
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () {
                            setState(() {
                              notif.isRead = true;
                            });
                            setDialogState(() {});
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime? _parseInvoiceDate(Invoice inv) {
    if (inv.issueDate.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(inv.issueDate);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    if (inv.createdAt != null && inv.createdAt! > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        inv.createdAt! > 100000000000 ? inv.createdAt! : inv.createdAt! * 1000,
      );
    }
    return null;
  }

  DateTime? _parseExpenseDate(Expense exp) {
    if (exp.date.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(exp.date);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return null;
  }

  (DateTime?, DateTime?) _getDateRangeForFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'FY 2025-26':
        return (DateTime(2025, 4, 1), DateTime(2026, 3, 31, 23, 59, 59));
      case 'FY 2024-25':
        return (DateTime(2024, 4, 1), DateTime(2025, 3, 31, 23, 59, 59));
      case 'FY 2023-24':
        return (DateTime(2023, 4, 1), DateTime(2024, 3, 31, 23, 59, 59));
      case 'Apr 15, 2025 - May 15, 2025':
        return (DateTime(2025, 4, 15), DateTime(2025, 5, 15, 23, 59, 59));
      case 'This Month':
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'Last 30 Days':
        return (
          now.subtract(const Duration(days: 30)),
          now,
        );
      case 'All Dates':
        return (null, null);
      default:
        if (_customDateRange != null) {
          return (
            _customDateRange!.start,
            DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
            ),
          );
        }
        return (null, null);
    }
  }

  List<Invoice>? get _filteredInvoices {
    if (_invoices == null) return null;
    var list = _invoices!;
    final (start, end) = _getDateRangeForFilter(_selectedDateFilter);
    if (start != null && end != null) {
      final dateFiltered = list.where((inv) {
        final d = _parseInvoiceDate(inv);
        if (d == null) return false;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
      if (dateFiltered.isNotEmpty || _hasUserSelectedDateFilter) {
        list = dateFiltered;
      }
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.clientName.toLowerCase().contains(q) ||
            inv.status.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  List<Expense>? get _filteredExpenses {
    if (_expenses == null) return null;
    final (start, end) = _getDateRangeForFilter(_selectedDateFilter);
    if (start == null || end == null) return _expenses;
    final filtered = _expenses!.where((exp) {
      final d = _parseExpenseDate(exp);
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    if (filtered.isNotEmpty || _hasUserSelectedDateFilter) {
      return filtered;
    }
    return _expenses;
  }

  DashboardStatistics get _effectiveStatistics {
    if (_statistics == null) {
      return const DashboardStatistics(
        totalInvoices: 0,
        paidInvoices: 0,
        overdueInvoices: 0,
        draftInvoices: 0,
        totalRevenue: 0,
        totalExpenses: 0,
        totalClients: 0,
      );
    }
    final invs = _filteredInvoices;
    final exps = _filteredExpenses;
    if (invs == null) return _statistics!;

    if (_hasUserSelectedDateFilter || _searchQuery.isNotEmpty) {
      final totalInv = invs.length;
      final paidInv = invs.where((i) => i.status.toUpperCase() == 'PAID').length;
      final overdueInv = invs.where((i) => i.status.toUpperCase() == 'OVERDUE').length;
      final draftInv = invs.where((i) => i.status.toUpperCase() == 'DRAFT').length;
      final totalRev = invs.where((i) => i.status.toUpperCase() == 'PAID').fold<double>(0.0, (s, i) => s + i.total);
      final totalExp = (exps ?? _expenses ?? []).fold<double>(0.0, (s, e) => s + e.amount);
      final totalCli = invs
          .map((i) => i.clientName.trim().isNotEmpty
              ? i.clientName.trim()
              : (i.clientId?.toString() ?? ''))
          .where((c) => c.isNotEmpty)
          .toSet()
          .length;

      return DashboardStatistics(
        totalInvoices: totalInv,
        paidInvoices: paidInv,
        overdueInvoices: overdueInv,
        draftInvoices: draftInv,
        totalRevenue: totalRev,
        totalExpenses: totalExp,
        totalClients: totalCli,
      );
    }

    return _statistics!;
  }

  Future<void> _onDateFilterChanged(String filter) async {
    if (filter == 'Custom Date Range...') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: _customDateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      );
      if (picked != null) {
        setState(() {
          _hasUserSelectedDateFilter = true;
          _customDateRange = picked;
          _selectedDateFilter = '${_formatDate(picked.start)} - ${_formatDate(picked.end)}';
        });
      }
      return;
    }
    setState(() {
      _hasUserSelectedDateFilter = true;
      _selectedDateFilter = filter;
    });
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  bool get _isDeveloper =>
      widget.session.user.role.toUpperCase() == 'DEVELOPER';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadRecentLogs();
    _auditSubscription = AuditLogService.onLogAdded.listen((_) {
      if (mounted) _loadRecentLogs();
    });
  }

  @override
  void dispose() {
    _auditSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLogs() async {
    try {
      final logs = await AuditLogService(apiClient: widget.repository.apiClient).getRecent(count: 4);
      if (mounted) {
        setState(() => _recentAuditLogs = logs);
      }
    } catch (_) {}
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

      // Fetch registered business name directly from backend profile
      try {
        final profile = await widget.repository.loadProfile();
        final bName = profile['businessName']?.toString().trim().isNotEmpty == true
            ? profile['businessName'].toString().trim()
            : (profile['companyName']?.toString().trim().isNotEmpty == true
                ? profile['companyName'].toString().trim()
                : (profile['legalName']?.toString().trim().isNotEmpty == true
                    ? profile['legalName'].toString().trim()
                    : null));
        if (bName != null && bName.isNotEmpty && mounted && generation == _loadGeneration) {
          setState(() => _backendBusinessName = bName);
        }
      } catch (_) {}

      // Fetch Invoices
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

      // Fetch Expenses
      try {
        final expenses = await ExpensesRepository(apiClient: widget.repository.apiClient).list();
        if (mounted && generation == _loadGeneration) {
          setState(() => _expenses = expenses);
        }
      } catch (_) {}

      // Fetch Clients
      try {
        final clients = await ClientsRepository(apiClient: widget.repository.apiClient).list();
        if (mounted && generation == _loadGeneration) {
          setState(() => _clients = clients);
        }
      } catch (_) {}

      // Fetch Employees (for Admin only)
      if (widget.session.user.role.toUpperCase() != 'EMPLOYEE') {
        try {
          final employees = await EmployeeRepository(apiClient: widget.repository.apiClient).list();
          if (mounted && generation == _loadGeneration) {
            setState(() => _employees = employees);
          }
        } catch (_) {}
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
    final registeredName = _backendBusinessName?.trim().isNotEmpty == true
        ? _backendBusinessName!.trim()
        : (widget.registeredCompanyName?.trim().isNotEmpty == true
            ? widget.registeredCompanyName!.trim()
            : (widget.localSettings['businessName']?.toString().trim().isNotEmpty == true
                ? widget.localSettings['businessName']!.toString().trim()
                : (widget.localSettings['companyName']?.toString().trim().isNotEmpty == true
                    ? widget.localSettings['companyName']!.toString().trim()
                    : (widget.session.company?.name.trim().isNotEmpty == true
                        ? widget.session.company!.name.trim()
                        : 'Your business'))));
    final role = widget.session.user.role.toUpperCase();
    final subtitle = switch (role) {
      'DEVELOPER' => 'Platform health and company activity',
      'EMPLOYEE' => 'Your invoice and collection activity',
      _ => 'Your business performance',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
            return RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 28),
                children: [
                  _DashboardHeader(
                    companyName: _isDeveloper ? 'Platform overview' : registeredName,
                    selectedFilter: _selectedDateFilter,
                    onFilterChanged: _onDateFilterChanged,
                    userInitial: widget.session.user.fullName.trim().isNotEmpty
                        ? widget.session.user.fullName.trim()[0].toUpperCase()
                        : 'R',
                    onMenuTap: null,
                    unreadNotificationCount: _unreadNotificationCount,
                    onOpenNotifications: _showNotificationsDialog,
                    searchController: _searchController,
                    onSearchChanged: (val) => setState(() => _searchQuery = val),
                    onRefresh: _isLoading ? null : _loadStatistics,
                  ),
                  const SizedBox(height: 18),
                  _DashboardWelcomeRow(
                    userName: widget.session.user.fullName.trim().isNotEmpty
                        ? widget.session.user.fullName.trim()
                        : 'Roshan Kumar',
                    subtitle: subtitle,
                    onCreateInvoice: widget.session.user.hasPermission('INVOICES')
                        ? widget.onCreateInvoice
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (!_isDeveloper)
                    _AssistantBanner(onTap: widget.onOpenAiChat),
                  if (_usingCachedData) ...[
                    const SizedBox(height: 12),
                    const OfflineCacheBanner(),
                  ],
                  const SizedBox(height: 16),
                  _DashboardShortcuts(
                    user: widget.session.user,
                    onViewInvoices: () => widget.onViewInvoices('All'),
                    onViewExpenses: widget.onViewExpenses,
                    onViewClients: widget.onViewClients,
                    onOpenTemplates: widget.onOpenTemplates,
                    onOpenPayroll: widget.onOpenPayroll,
                  ),
                  const SizedBox(height: 18),
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
                      statistics: _effectiveStatistics,
                      role: role,
                      invoices: _filteredInvoices,
                      expenses: _filteredExpenses,
                      clients: _clients,
                      employees: _employees,
                      onViewInvoices: widget.onViewInvoices,
                      onViewExpenses: widget.onViewExpenses,
                      onViewClients: widget.onViewClients,
                      onOpenPayroll: widget.onOpenPayroll,
                      onCreateInvoice: widget.onCreateInvoice,
                      onAddExpense: widget.onViewExpenses,
                      onAddClient: widget.onViewClients,
                      onAddEmployee: widget.onOpenPayroll,
                      selectedDateFilter: _selectedDateFilter,
                    ),
                  if (_recentAuditLogs.isNotEmpty)
                    _RecentAuditLogsSection(
                      logs: _recentAuditLogs,
                      onOpenAuditLogs: widget.onOpenAuditLogs,
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
    required this.companyName,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.userInitial,
    required this.onMenuTap,
    required this.unreadNotificationCount,
    required this.onOpenNotifications,
    required this.searchController,
    required this.onSearchChanged,
    this.onRefresh,
  });

  final String companyName;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String userInitial;
  final VoidCallback? onMenuTap;
  final int unreadNotificationCount;
  final VoidCallback onOpenNotifications;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 10 : 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 2,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                _buildCompanyTopNavBadge(isDesktop: true),
                const Spacer(),
                _buildSearchField(width: 240),
                const SizedBox(width: 10),
                _buildFilterDropdown(context),
                const SizedBox(width: 8),
                _buildClayIconButton(
                  tooltip: 'Sync dashboard',
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh,
                ),
                const SizedBox(width: 8),
                _buildNotificationButton(),
                const SizedBox(width: 10),
                _buildUserAvatar(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCompanyTopNavBadge(isDesktop: false)),
                    const SizedBox(width: 6),
                    _buildClayIconButton(
                      tooltip: 'Sync dashboard',
                      icon: Icons.refresh_rounded,
                      onTap: onRefresh,
                    ),
                    const SizedBox(width: 6),
                    _buildNotificationButton(),
                    const SizedBox(width: 8),
                    _buildUserAvatar(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    _buildFilterDropdown(context),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyTopNavBadge({required bool isDesktop}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop) ...[
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1)),
            ),
          ),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x142563EB),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 2,
                  offset: Offset(-1, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 280 : 190),
                    child: Text(
                      companyName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({double? width}) {
    return Container(
      height: 38,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: 'Search invoices, clients...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 9),
        ),
      ),
    );
  }

  Widget _buildClayIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.white,
                blurRadius: 2,
                offset: Offset(-1, -1),
              ),
            ],
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildClayIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 8.5,
              height: 8.5,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          userInitial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final options = [
      'FY 2025-26',
      'FY 2024-25',
      'FY 2023-24',
      'Apr 15, 2025 - May 15, 2025',
      'This Month',
      'Last 30 Days',
      'All Dates',
      'Custom Date Range...',
    ];

    return PopupMenuButton<String>(
      onSelected: onFilterChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => options.map((opt) {
        final isSelected = opt == selectedFilter;
        return PopupMenuItem<String>(
          value: opt,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.calendar_today_outlined,
                size: 15,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF1F5F9)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(
              selectedFilter,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _DashboardWelcomeRow extends StatelessWidget {
  const _DashboardWelcomeRow({
    required this.userName,
    required this.subtitle,
    this.onCreateInvoice,
  });

  final String userName;
  final String subtitle;
  final VoidCallback? onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (onCreateInvoice != null)
          InkWell(
            onTap: onCreateInvoice,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x382563EB),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Color(0x40FFFFFF),
                    blurRadius: 2,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    'New Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F7FF), Color(0xFFE0EFFE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 3,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Claymorphic Robot Icon Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x222563EB),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Text Content
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI INVOICE ASSISTANT',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Generate Invoices & insights in seconds',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Talk to our intelligent assistant to auto-fill line items, calculate taxes, and query financial metrics.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Claymorphic Try Assistant button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x382563EB),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x40FFFFFF),
                    blurRadius: 2,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Try Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardShortcuts extends StatelessWidget {
  const _DashboardShortcuts({
    required this.user,
    required this.onViewInvoices,
    required this.onViewExpenses,
    required this.onViewClients,
    required this.onOpenTemplates,
    this.onOpenPayroll,
  });

  final UserSummary user;
  final VoidCallback onViewInvoices;
  final VoidCallback onViewExpenses;
  final VoidCallback onViewClients;
  final VoidCallback onOpenTemplates;
  final VoidCallback? onOpenPayroll;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (user.hasPermission('INVOICES'))
        _ModuleCardData(
          label: 'Invoices',
          icon: Icons.description_outlined,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          onTap: onViewInvoices,
        ),
      if (user.hasPermission('EXPENSES'))
        _ModuleCardData(
          label: 'Expenses',
          icon: Icons.receipt_outlined,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          onTap: onViewExpenses,
        ),
      if (onOpenPayroll != null)
        _ModuleCardData(
          label: 'Payroll',
          icon: Icons.groups_outlined,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          onTap: onOpenPayroll!,
        ),
      if (user.hasPermission('CLIENTS'))
        _ModuleCardData(
          label: 'Clients',
          icon: Icons.people_alt_outlined,
          iconBg: const Color(0xFFFCE7F3),
          iconColor: const Color(0xFFE11D48),
          onTap: onViewClients,
        ),
      if (user.hasPermission('INVOICES'))
        _ModuleCardData(
          label: 'Templates',
          icon: Icons.article_outlined,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          onTap: onOpenTemplates,
        ),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _ClayModuleTile(item: items[i])),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ClayModuleTile extends StatefulWidget {
  const _ClayModuleTile({required this.item});

  final _ModuleCardData item;

  @override
  State<_ClayModuleTile> createState() => _ClayModuleTileState();
}

class _ClayModuleTileState extends State<_ClayModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _hovered ? Matrix4.translationValues(0, -3, 0) : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? item.iconColor.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
              width: _hovered ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? item.iconColor.withValues(alpha: 0.14)
                    : const Color(0x0D0F172A),
                blurRadius: _hovered ? 16 : 12,
                offset: _hovered ? const Offset(0, 7) : const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 2,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      item.iconBg,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: item.iconColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCardData {
  const _ModuleCardData({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
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

class _RecentAuditLogsSection extends StatelessWidget {
  const _RecentAuditLogsSection({
    required this.logs,
    required this.onOpenAuditLogs,
  });

  final List<AuditLog> logs;
  final VoidCallback? onOpenAuditLogs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    size: 18,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recent Audit & Activity Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (onOpenAuditLogs != null)
              TextButton.icon(
                onPressed: onOpenAuditLogs,
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _buildLogItem(context, logs[i]),
                if (i < logs.length - 1)
                  const Divider(height: 16, thickness: 0.5),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(BuildContext context, AuditLog log) {
    final (icon, color) = _getModuleIconAndColor(log.module);
    final timeStr = _formatRelativeTime(log.createdAt);

    return InkWell(
      onTap: onOpenAuditLogs,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.userName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          log.description.isNotEmpty ? log.description : log.action,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getModuleIconAndColor(String module) {
    switch (module.toUpperCase()) {
      case 'INVOICE':
        return (Icons.receipt_long_rounded, const Color(0xFF2563EB));
      case 'EXPENSE':
        return (Icons.account_balance_wallet_rounded, const Color(0xFFD97706));
      case 'CLIENT':
        return (Icons.people_alt_rounded, const Color(0xFF059669));
      case 'EMPLOYEE':
        return (Icons.badge_rounded, const Color(0xFF7C3AED));
      case 'TEAM':
        return (Icons.manage_accounts_rounded, const Color(0xFFDC2626));
      default:
        return (Icons.history_rounded, const Color(0xFF0284C7));
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
