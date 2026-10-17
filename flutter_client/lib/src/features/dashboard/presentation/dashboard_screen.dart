import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../data/models/auth_models.dart';
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
import 'widgets/dashboard_developer_panel.dart';
import 'widgets/dashboard_module_shortcuts.dart';
import 'widgets/dashboard_recent_audit_logs.dart';
import 'widgets/dashboard_top_header.dart';
import 'widgets/user_profile_dialog.dart';

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
    this.onOpenBusinessSettings,
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
  final VoidCallback? onOpenBusinessSettings;
  final String? registeredCompanyName;
  final Map<String, Object?> localSettings;

  static void showNotificationsDialog({
    required BuildContext context,
    required List<DashboardNotificationItem> notifications,
    required VoidCallback onMarkAllRead,
    ValueChanged<DashboardNotificationItem>? onNotificationRead,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
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
                      onMarkAllRead();
                      setDialogState(() {});
                    },
                    child: const Text('Mark all as read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No notifications yet', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, index) {
                        final notif = notifications[index];
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
                            notif.isRead = true;
                            onNotificationRead?.call(notif);
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

  static void showUserProfileDialog({
    required BuildContext context,
    required AuthSession session,
    required String userInitial,
    VoidCallback? onOpenBusinessSettings,
    required Future<void> Function() onLogout,
  }) {
    UserProfileDialog.show(
      context,
      session: session,
      onOpenBusinessSettings: onOpenBusinessSettings,
      onLogout: onLogout,
    );
  }

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
      message: 'Payment of â‚¹45,200 received for Invoice #INV-2025-001 from Acme Security',
      timeAgo: '12m ago',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '2',
      title: 'Invoice Overdue Notice',
      message: 'Invoice #INV-2025-004 is overdue by 3 days (â‚¹18,500)',
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
    DashboardScreen.showNotificationsDialog(
      context: context,
      notifications: _notifications,
      onMarkAllRead: _markAllNotificationsAsRead,
      onNotificationRead: (_) => setState(() {}),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
            return RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 28),
                children: [
                  DashboardTopHeader(
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
                    session: widget.session,
                    onOpenBusinessSettings: widget.onOpenBusinessSettings,
                    onLogout: widget.onLogout,
                  ),
                  const SizedBox(height: 20),
                  DashboardWelcomeRow(
                    userName: widget.session.user.fullName.trim().isNotEmpty
                        ? widget.session.user.fullName.trim()
                        : 'Roshan Kumar',
                    subtitle: subtitle,
                    onCreateInvoice: widget.session.user.hasPermission('INVOICES')
                        ? widget.onCreateInvoice
                        : null,
                  ),
                  const SizedBox(height: 18),
                  if (!_isDeveloper)
                    DashboardAssistantBanner(onTap: widget.onOpenAiChat),
                  if (_usingCachedData) ...[
                    const SizedBox(height: 12),
                    const OfflineCacheBanner(),
                  ],
                  const SizedBox(height: 18),
                  DashboardModuleShortcuts(
                    user: widget.session.user,
                    onViewInvoices: () => widget.onViewInvoices('All'),
                    onViewExpenses: widget.onViewExpenses,
                    onViewClients: widget.onViewClients,
                    onOpenTemplates: widget.onOpenTemplates,
                    onOpenPayroll: widget.onOpenPayroll,
                  ),
                  const SizedBox(height: 20),
                  if (_developerOverview != null) ...[
                    DeveloperOverviewPanel(
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
                    DashboardErrorCard(message: _error!, onRetry: _loadStatistics),
                    const SizedBox(height: 18),
                  ],
                  if (_invoiceLoadError != null) ...[
                    DashboardErrorCard(
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
                    DashboardRecentAuditLogs(
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
