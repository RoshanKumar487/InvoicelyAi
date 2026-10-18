import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../data/audit_log.dart';
import '../data/audit_log_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({
    required this.apiClient,
    required this.session,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final AuthSession session;
  final VoidCallback? onBack;

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  late final AuditLogService _auditLogService;
  final TextEditingController _searchController = TextEditingController();

  List<AuditLog> _logs = <AuditLog>[];
  bool _isLoading = true;
  String? _error;

  String _selectedModule = 'All';
  String _creatorScope = 'All'; // 'All' or 'Me'

  static const _moduleFilters = <String>[
    'All',
    'INVOICE',
    'EXPENSE',
    'EMPLOYEE',
    'CLIENT',
    'TEAM',
    'SETTINGS',
  ];

  @override
  void initState() {
    super.initState();
    _auditLogService = AuditLogService(apiClient: widget.apiClient);
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _auditLogService.list(
        module: _selectedModule == 'All' ? null : _selectedModule,
        searchQuery: _searchController.text,
        onlyMyLogs: _creatorScope == 'Me',
        currentUserId: widget.session.user.id,
      );

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load audit logs: $e';
        _isLoading = false;
      });
    }
  }

  List<EnterpriseTableColumn<AuditLog>> _tableColumns() {
    return [
      EnterpriseTableColumn<AuditLog>(
        title: 'Time',
        width: 130,
        cellBuilder: (ctx, log) {
          final dt = log.createdAt ?? DateTime.now();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${log.relativeTime})',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          );
        },
      ),
      EnterpriseTableColumn<AuditLog>(
        title: 'User / Actor',
        width: 160,
        cellBuilder: (ctx, log) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: log.moduleColor.withValues(alpha: 0.15),
                child: Text(
                  log.userName.isNotEmpty ? log.userName[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: log.moduleColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.userName.isNotEmpty ? log.userName : 'System',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      log.userRole,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      EnterpriseTableColumn<AuditLog>(
        title: 'Module',
        width: 110,
        cellBuilder: (ctx, log) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: log.moduleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: log.moduleColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(log.icon, size: 12, color: log.moduleColor),
                const SizedBox(width: 4),
                Text(
                  log.module,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: log.moduleColor),
                ),
              ],
            ),
          );
        },
      ),
      EnterpriseTableColumn<AuditLog>(
        title: 'Action',
        width: 120,
        cellBuilder: (ctx, log) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.action,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          );
        },
      ),
      EnterpriseTableColumn<AuditLog>(
        title: 'Entity ID',
        width: 100,
        cellBuilder: (ctx, log) {
          return Text(
            log.entityId.isNotEmpty ? log.entityId : '—',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
          );
        },
      ),
      EnterpriseTableColumn<AuditLog>(
        title: 'Activity Title & Details',
        width: 320,
        cellBuilder: (ctx, log) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                log.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              if (log.description.isNotEmpty)
                Text(
                  log.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildAuditCard(AuditLog log) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.moduleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(log.icon, size: 20, color: log.moduleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Text(
                      log.relativeTime,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (log.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.moduleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.module,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: log.moduleColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF334155)),
                      ),
                    ),
                    if (log.entityId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.entityId,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                      ),
                    Text(
                      'by ${log.userName} (${log.userRole})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsStrip() {
    final total = _logs.length;
    final invoiceCount = _logs.where((l) => l.module.toUpperCase() == 'INVOICE').length;
    final expenseCount = _logs.where((l) => l.module.toUpperCase() == 'EXPENSE').length;
    final workforceCount = _logs.where((l) => l.module.toUpperCase() == 'EMPLOYEE' || l.module.toUpperCase() == 'TEAM').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        final metrics = [
          _AuditMetric(title: 'Total Activities', count: '$total', icon: Icons.history_edu_rounded, color: const Color(0xFF1E3A8A)),
          _AuditMetric(title: 'Invoice Actions', count: '$invoiceCount', icon: Icons.receipt_long_rounded, color: const Color(0xFF0284C7)),
          _AuditMetric(title: 'Expense Events', count: '$expenseCount', icon: Icons.payments_rounded, color: const Color(0xFFD97706)),
          _AuditMetric(title: 'Staff & Roles', count: '$workforceCount', icon: Icons.badge_rounded, color: const Color(0xFF7C3AED)),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(m.icon, color: m.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(m.title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.session.user.role.toUpperCase() == 'ADMIN';
    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              leading: widget.onBack == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    ),
              title: const Text('Activity & Audit Trail'),
              actions: [
                IconButton(
                  tooltip: 'Refresh audit logs',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLogs,
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;

          return RefreshIndicator(
            onRefresh: _loadLogs,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, isDesktop ? 6 : 12, horizontalPadding, 80),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                        TextButton(onPressed: _loadLogs, child: const Text('Retry')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 8),
                ],

                EnterpriseDataView<AuditLog>(
                  items: _logs,
                  headerTitle: 'Security & Operations Log',
                  metricsStrip: _buildMetricsStrip(),
                  searchController: _searchController,
                  searchHint: 'Search audit logs by title, user, entity ID...',
                  onSearchChanged: (_) => _loadLogs(),
                  filterChips: _moduleFilters,
                  selectedFilterChip: _selectedModule,
                  onFilterChipSelected: (mod) {
                    setState(() => _selectedModule = mod);
                    _loadLogs();
                  },
                  topTrailing: isAdmin
                      ? SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'All', label: Text('All Company')),
                            ButtonSegment(value: 'Me', label: Text('My Logs')),
                          ],
                          selected: {_creatorScope},
                          onSelectionChanged: (set) {
                            setState(() => _creatorScope = set.first);
                            _loadLogs();
                          },
                        )
                      : null,
                  groupBy: (log) => log.module,
                  groupLabelBuilder: (mod, items) => '$mod Activities (${items.length} records)',
                  cardBuilder: (ctx, log) => _buildAuditCard(log),
                  columns: _tableColumns(),
                  emptyMessage: 'No audit log entries found for current filters.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuditMetric {
  const _AuditMetric({required this.title, required this.count, required this.icon, required this.color});
  final String title;
  final String count;
  final IconData icon;
  final Color color;
}
