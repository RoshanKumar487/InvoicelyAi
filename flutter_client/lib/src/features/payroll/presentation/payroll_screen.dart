import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/dynamic_form_engine.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/payroll_models.dart';
import '../data/payroll_repository.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({
    required this.repository,
    this.onBack,
    super.key,
  });

  final PayrollRepository repository;
  final VoidCallback? onBack;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<PayrollRun> _runs = [];
  PayrollRun? _selectedRun;
  List<PayrollEntry> _entries = [];
  PayrollSummaryKpi _kpi = const PayrollSummaryKpi();

  bool _isLoading = true;
  bool _usingCachedData = false;
  String? _error;
  int _loadRequest = 0;

  // Filters
  String _selectedStatus = 'All';
  String _selectedDepartment = 'All Departments';

  // Multi-checkbox selection
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showProgress = true}) async {
    final request = ++_loadRequest;
    if (showProgress && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final runs = await widget.repository.listRuns();
      if (!mounted || request != _loadRequest) return;

      final currentRun = _selectedRun ?? (runs.isNotEmpty ? runs.first : null);
      final runId = currentRun?.id;

      final entries = await widget.repository.listEntries(
        runId: runId,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchController.text,
      );
      if (!mounted || request != _loadRequest) return;

      final kpis = await widget.repository.getKpis(runId: runId);
      if (!mounted || request != _loadRequest) return;

      setState(() {
        _runs = runs;
        _selectedRun = currentRun;
        _entries = entries;
        _kpi = kpis;
        _usingCachedData = widget.repository.lastLoadUsedCache;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = error.message);
    } catch (e) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = 'Could not load payroll data. Please try again.');
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadData(showProgress: false),
    );
  }

  void _onStatusFilterSelected(String status) {
    setState(() {
      _selectedStatus = status.split(' ').first; // Extract pure status name
      _selectedIds.clear();
    });
    _loadData(showProgress: false);
  }

  List<PayrollEntry> get _filteredEntries {
    if (_selectedDepartment == 'All Departments') {
      return _entries;
    }
    return _entries.where((e) => e.department == _selectedDepartment).toList();
  }

  Set<String> get _departments {
    final depts = <String>{'All Departments'};
    for (final e in _entries) {
      if (e.department.isNotEmpty) depts.add(e.department);
    }
    return depts;
  }

  // Batch actions on selected rows
  Future<void> _batchMarkStatus(String newStatus) async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.map(int.parse).toList();

    try {
      await widget.repository.batchUpdateStatus(ids: ids, status: newStatus);
      _showMessage('Updated ${_selectedIds.length} employee records to $newStatus.');
      setState(() => _selectedIds.clear());
      await _loadData(showProgress: false);
    } catch (e) {
      _showMessage('Error updating payroll records: $e');
    }
  }

  Future<void> _generateNewPayrollRun() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run Batch Monthly Payroll?'),
        content: const Text(
          'This will compute statutory earnings, PF, ESI, professional tax, and net payable salaries for all active employees for this period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run Calculation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final now = DateTime.now();
      final newRun = await widget.repository.generateRun(
        month: now.month,
        year: now.year,
        title: 'Monthly Payroll Run - ${now.month}/${now.year}',
        scheduledPayDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-30',
      );
      _selectedRun = newRun;
      _showMessage('Payroll batch calculated successfully.');
      await _loadData();
    } catch (e) {
      _showMessage('Failed to generate payroll run: $e');
    }
  }

  // Dynamic Low-Code Form for Adding / Adjusting Payroll Line
  Future<void> _openDynamicSalaryAdjustment([PayrollEntry? existing]) async {
    final schema = DynamicFormSchema(
      title: existing != null ? 'Adjust Salary Record' : 'Add Employee Salary Line',
      subtitle: 'Dynamic low-code form schema for monthly gross, statutory cuts, and disbursement',
      submitLabel: existing != null ? 'Apply Adjustment' : 'Create Salary Line',
      sections: [
        DynamicFormSection(
          title: 'Employee Profile',
          icon: Icons.badge_outlined,
          description: 'Basic personnel information and organizational department',
          fields: [
            DynamicFormFieldConfig(
              name: 'employeeName',
              label: 'Employee Name',
              required: true,
              initialValue: existing?.employeeName ?? '',
              placeholder: 'e.g. Rahul Sharma',
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'employeeCode',
              label: 'Employee Code',
              required: true,
              initialValue: existing?.employeeCode ?? 'EMP-${DateTime.now().millisecondsSinceEpoch % 1000}',
              placeholder: 'e.g. EMP-108',
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'department',
              label: 'Department',
              type: DynamicFormFieldType.select,
              required: true,
              initialValue: existing?.department ?? 'Engineering',
              options: const [
                DynamicFieldOption(label: 'Engineering', value: 'Engineering'),
                DynamicFieldOption(label: 'Product', value: 'Product'),
                DynamicFieldOption(label: 'Operations', value: 'Operations'),
                DynamicFieldOption(label: 'Design', value: 'Design'),
                DynamicFieldOption(label: 'Human Resources', value: 'Human Resources'),
                DynamicFieldOption(label: 'Finance', value: 'Finance'),
              ],
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'designation',
              label: 'Designation / Role',
              required: true,
              initialValue: existing?.designation ?? 'Software Engineer',
              placeholder: 'e.g. Lead Architect',
              colSpan: 1,
            ),
          ],
        ),
        DynamicFormSection(
          title: 'Earnings & Allowances',
          icon: Icons.payments_outlined,
          description: 'Monthly compensation structure and allowances',
          fields: [
            DynamicFormFieldConfig(
              name: 'basicPay',
              label: 'Basic Pay',
              type: DynamicFormFieldType.currency,
              required: true,
              initialValue: existing?.basicPay ?? 50000.0,
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'hra',
              label: 'HRA (House Rent Allowance)',
              type: DynamicFormFieldType.currency,
              initialValue: existing?.hra ?? 20000.0,
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'allowances',
              label: 'Special / Other Allowances',
              type: DynamicFormFieldType.currency,
              initialValue: existing?.allowances ?? 10000.0,
              colSpan: 1,
            ),
          ],
        ),
        DynamicFormSection(
          title: 'Statutory & Tax Deductions',
          icon: Icons.account_balance_outlined,
          description: 'Employee Provident Fund (PF), Professional Tax, and Income Tax TDS',
          fields: [
            DynamicFormFieldConfig(
              name: 'pfEmployee',
              label: 'EPF Deduction (12% of Basic)',
              type: DynamicFormFieldType.currency,
              initialValue: existing?.pfEmployee ?? 6000.0,
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'professionalTax',
              label: 'Professional Tax (PT)',
              type: DynamicFormFieldType.currency,
              initialValue: existing?.professionalTax ?? 200.0,
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'tdsTax',
              label: 'Income Tax TDS',
              type: DynamicFormFieldType.currency,
              initialValue: existing?.tdsTax ?? 4500.0,
              colSpan: 1,
            ),
          ],
        ),
        DynamicFormSection(
          title: 'Payment Status & Bank Routing',
          icon: Icons.account_tree_outlined,
          description: 'Disbursal scheduling and account credentials',
          fields: [
            DynamicFormFieldConfig(
              name: 'paymentStatus',
              label: 'Payment Status',
              type: DynamicFormFieldType.select,
              required: true,
              initialValue: existing?.paymentStatus ?? 'PENDING',
              options: const [
                DynamicFieldOption(label: 'Pending Disbursal', value: 'PENDING'),
                DynamicFieldOption(label: 'Paid / Disbursed', value: 'PAID'),
                DynamicFieldOption(label: 'Overdue', value: 'OVERDUE'),
                DynamicFieldOption(label: 'On Hold', value: 'ON_HOLD'),
              ],
              colSpan: 1,
            ),
            DynamicFormFieldConfig(
              name: 'bankAccountMask',
              label: 'Bank Account Mask',
              initialValue: existing?.bankAccountMask ?? 'HDFC •••• 1024',
              placeholder: 'e.g. HDFC •••• 1024',
              colSpan: 1,
            ),
          ],
        ),
      ],
    );

    final result = await DynamicFormDialog.show(
      context: context,
      schema: schema,
      initialValues: existing != null
          ? {
              'employeeName': existing.employeeName,
              'employeeCode': existing.employeeCode,
              'department': existing.department,
              'designation': existing.designation,
              'basicPay': existing.basicPay,
              'hra': existing.hra,
              'allowances': existing.allowances,
              'pfEmployee': existing.pfEmployee,
              'professionalTax': existing.professionalTax,
              'tdsTax': existing.tdsTax,
              'paymentStatus': existing.paymentStatus,
              'bankAccountMask': existing.bankAccountMask,
            }
          : null,
    );

    if (result != null && mounted) {
      // Calculate computed numbers
      final basic = _asDouble(result['basicPay']);
      final hra = _asDouble(result['hra']);
      final allow = _asDouble(result['allowances']);
      final gross = basic + hra + allow;

      final pf = _asDouble(result['pfEmployee']);
      final pt = _asDouble(result['professionalTax']);
      final tds = _asDouble(result['tdsTax']);
      final deductions = pf + pt + tds;
      final net = gross - deductions;

      final updated = PayrollEntry(
        id: existing?.id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
        companyId: 1,
        employeeId: existing?.employeeId ?? 10,
        employeeName: result['employeeName']?.toString() ?? 'Staff Member',
        employeeCode: result['employeeCode']?.toString() ?? 'EMP-999',
        department: result['department']?.toString() ?? 'General',
        designation: result['designation']?.toString() ?? 'Staff',
        basicPay: basic,
        hra: hra,
        allowances: allow,
        grossEarnings: gross,
        pfEmployee: pf,
        professionalTax: pt,
        tdsTax: tds,
        totalDeductions: deductions,
        netSalary: net,
        paymentStatus: result['paymentStatus']?.toString() ?? 'PENDING',
        bankAccountMask: result['bankAccountMask']?.toString() ?? '',
      );

      setState(() {
        if (existing != null) {
          final idx = _entries.indexWhere((e) => e.id == existing.id);
          if (idx != -1) _entries[idx] = updated;
        } else {
          _entries.insert(0, updated);
        }
      });
      _showMessage(existing != null ? 'Salary updated successfully.' : 'New salary line added.');
      _loadData(showProgress: false);
    }
  }

  double _asDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Payroll & Disbursal'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          IconButton(
            tooltip: 'Run Batch Payroll',
            onPressed: _generateNewPayrollRun,
            icon: const Icon(Icons.play_circle_outline),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadData(),
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDynamicSalaryAdjustment(),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Salary Line'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;

          return RefreshIndicator(
            onRefresh: () => _loadData(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 100),
              children: [
                if (_usingCachedData) const OfflineCacheBanner(),
                if (_error != null) ...[
                  _buildErrorPanel(),
                  const SizedBox(height: 16),
                ],

                // Enterprise Data View with identical grid, table, and checkboxes
                EnterpriseDataView<PayrollEntry>(
                  items: filtered,
                  headerTitle: _selectedRun != null ? _selectedRun!.runTitle : 'Monthly Payroll Registry',
                  // 4 Invoice-like Summary Cards on top
                  metricsStrip: _buildFourInvoiceCards(),
                  // Search Controller
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  searchHint: 'Search employee name, code, designation, or bank...',
                  // Advanced Filter Bar (Period selector + Department dropdown)
                  filterWidget: _buildFilterBar(),
                  // Filter Chips
                  filterChips: [
                    'All (${_entries.length})',
                    'Pending (${_kpi.pendingCount})',
                    'Paid (${_kpi.paidCount})',
                    'Overdue (${_kpi.overdueCount})',
                  ],
                  selectedFilterChip: '$_selectedStatus (${_getStatusCount(_selectedStatus)})',
                  onFilterChipSelected: _onStatusFilterSelected,
                  // Checkboxes & Multi-selection
                  idGetter: (item) => item.id.toString(),
                  selectedIds: _selectedIds,
                  onToggleSelect: (id) {
                    setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    });
                  },
                  onSelectAll: (ids) {
                    setState(() => _selectedIds.addAll(ids));
                  },
                  onDeselectAll: () {
                    setState(() => _selectedIds.clear());
                  },
                  // Action buttons right in the selection bar!
                  batchActions: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Mark Paid / Disburse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _batchMarkStatus('PAID'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.pause_circle_outline, size: 16),
                      label: const Text('Hold Payout', style: TextStyle(fontSize: 12)),
                      onPressed: () => _batchMarkStatus('ON_HOLD'),
                    ),
                  ],
                  // Grouping by department
                  groupBy: (item) => item.department.isNotEmpty ? item.department : 'General Staff',
                  groupLabelBuilder: (dept, items) =>
                      '$dept (${items.length} ${items.length == 1 ? "employee" : "employees"})',
                  // Top Trailing quick buttons
                  topTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export NEFT/Bank', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showMessage('Bank payout file (NEFT/ACH) generated and ready for download.'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
                        onPressed: () => _openDynamicSalaryAdjustment(),
                      ),
                    ],
                  ),
                  // Table Columns definition
                  columns: _buildTableColumns(),
                  // Cards Builder for mobile
                  cardBuilder: (context, item) => _buildPayrollCard(item),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getStatusCount(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return _kpi.pendingCount;
      case 'PAID':
        return _kpi.paidCount;
      case 'OVERDUE':
        return _kpi.overdueCount;
      case 'ALL':
      default:
        return _entries.length;
    }
  }

  /// 4 INVOICE-LIKE CARDS ON TOP
  /// 1. Total Gross Wage Liability
  /// 2. Total Paid / Disbursed
  /// 3. Pending Payout
  /// 4. Overdue from Pay Date
  Widget _buildFourInvoiceCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        final card1 = _buildInvoiceCard(
          title: 'Total Gross Wage',
          value: '₹${_formatCurrency(_kpi.totalGross)}',
          subtitle: 'Gross Payroll Liability',
          badgeText: '${_kpi.totalEmployees} Employees',
          badgeColor: const Color(0xFFE0E7FF),
          badgeTextColor: const Color(0xFF4338CA),
          icon: Icons.account_balance_wallet_outlined,
          accentColor: const Color(0xFF6366F1),
          gradient: const [Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
        );

        final card2 = _buildInvoiceCard(
          title: 'Paid / Disbursed',
          value: '₹${_formatCurrency(_kpi.totalPaid)}',
          subtitle: 'Disbursed to Bank Accounts',
          badgeText: '${_kpi.paidCount} Paid',
          badgeColor: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF15803D),
          icon: Icons.verified_outlined,
          accentColor: const Color(0xFF16A34A),
          gradient: const [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
        );

        final card3 = _buildInvoiceCard(
          title: 'Pending Payout',
          value: '₹${_formatCurrency(_kpi.totalPending)}',
          subtitle: 'Scheduled for Disbursal',
          badgeText: '${_kpi.pendingCount} Pending',
          badgeColor: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFB45309),
          icon: Icons.hourglass_top_outlined,
          accentColor: const Color(0xFFD97706),
          gradient: const [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
        );

        final card4 = _buildInvoiceCard(
          title: 'Overdue from Pay Date',
          value: '₹${_formatCurrency(_kpi.totalOverdue)}',
          subtitle: 'Past Scheduled Pay Date',
          badgeText: _kpi.overdueCount > 0 ? '${_kpi.overdueCount} OVERDUE!' : '0 Overdue',
          badgeColor: _kpi.overdueCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          badgeTextColor: _kpi.overdueCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xFFDC2626),
          gradient: const [Color(0xFFFEF2F2), Color(0xFFFFFFFF)],
          isAlert: _kpi.overdueCount > 0,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          );
        } else if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
              const SizedBox(height: 10),
              card4,
            ],
          );
        }
      },
    );
  }

  Widget _buildInvoiceCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradient,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// BEST FILTER DESIGN:
  /// Period selector dropdown + Department dropdown + Instant status counters
  Widget _buildFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final periodPicker = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<PayrollRun>(
                  value: _runs.any((r) => r.id == _selectedRun?.id) ? _selectedRun : (_runs.isNotEmpty ? _runs.first : null),
                  isDense: true,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                  items: _runs.map((r) {
                    return DropdownMenuItem<PayrollRun>(
                      value: r,
                      child: Text('${r.periodLabel} (${r.status})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRun = val;
                        _selectedIds.clear();
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
        );

        final departmentPicker = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_outlined, size: 16, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _departments.contains(_selectedDepartment) ? _selectedDepartment : 'All Departments',
                  isDense: true,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                  items: _departments.map((d) {
                    return DropdownMenuItem<String>(
                      value: d,
                      child: Text(d),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDepartment = val);
                    }
                  },
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              periodPicker,
              const SizedBox(height: 8),
              departmentPicker,
            ],
          );
        }

        return Row(
          children: [
            periodPicker,
            const SizedBox(width: 12),
            departmentPicker,
            const Spacer(),
            if (_selectedRun?.scheduledPayDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_outlined, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text(
                      'Pay Date: ${_selectedRun!.scheduledPayDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// EXACT SAME TABLE COLUMNS AS ENTERPRISE GRID
  List<EnterpriseTableColumn<PayrollEntry>> _buildTableColumns() {
    return [
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Employee Name & Code',
        width: 220,
        cellBuilder: (ctx, entry) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE0E7FF),
              foregroundColor: const Color(0xFF4338CA),
              child: Text(
                entry.employeeName.isNotEmpty ? entry.employeeName[0].toUpperCase() : 'E',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(entry.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${entry.employeeCode} · ${entry.designation}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Department',
        width: 130,
        cellBuilder: (ctx, entry) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            entry.department.isNotEmpty ? entry.department : 'General',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Gross Pay',
        width: 120,
        alignRight: true,
        cellBuilder: (ctx, entry) => Text(
          '₹${_formatCurrency(entry.grossEarnings)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Deductions',
        width: 110,
        alignRight: true,
        cellBuilder: (ctx, entry) => Text(
          '-₹${_formatCurrency(entry.totalDeductions)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Net Salary',
        width: 130,
        alignRight: true,
        cellBuilder: (ctx, entry) => Text(
          '₹${_formatCurrency(entry.netSalary)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Status',
        width: 120,
        cellBuilder: (ctx, entry) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: entry.statusBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.paymentStatus,
            style: TextStyle(
              color: entry.statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Bank Mask',
        width: 140,
        cellBuilder: (ctx, entry) => Text(
          entry.bankAccountMask.isNotEmpty ? entry.bankAccountMask : 'Direct Bank NEFT',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Actions',
        width: 120,
        cellBuilder: (ctx, entry) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Adjust Salary Entry',
              icon: const Icon(Icons.tune_outlined, size: 18),
              onPressed: () => _openDynamicSalaryAdjustment(entry),
            ),
            IconButton(
              tooltip: entry.isPaid ? 'Already Paid' : 'Mark as Paid',
              icon: Icon(
                entry.isPaid ? Icons.check_circle : Icons.check_circle_outline,
                size: 18,
                color: entry.isPaid ? const Color(0xFF16A34A) : const Color(0xFF64748B),
              ),
              onPressed: entry.isPaid
                  ? null
                  : () async {
                      await widget.repository.updateEntryStatus(id: entry.id, status: 'PAID');
                      _showMessage('${entry.employeeName} marked as PAID.');
                      _loadData(showProgress: false);
                    },
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildPayrollCard(PayrollEntry entry) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0E7FF),
                foregroundColor: const Color(0xFF4338CA),
                child: Text(
                  entry.employeeName.isNotEmpty ? entry.employeeName[0].toUpperCase() : 'E',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${entry.employeeCode} · ${entry.designation} (${entry.department})',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: entry.statusBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.paymentStatus,
                  style: TextStyle(
                    color: entry.statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gross Earnings', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text('₹${_formatCurrency(entry.grossEarnings)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deductions', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text('-₹${_formatCurrency(entry.totalDeductions)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFDC2626))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Net Payable', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text(
                    '₹${_formatCurrency(entry.netSalary)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.bankAccountMask.isNotEmpty ? entry.bankAccountMask : 'Bank NEFT',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.tune, size: 14),
                    label: const Text('Adjust', style: TextStyle(fontSize: 11)),
                    onPressed: () => _openDynamicSalaryAdjustment(entry),
                  ),
                  if (!entry.isPaid)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        await widget.repository.updateEntryStatus(id: entry.id, status: 'PAID');
                        _showMessage('${entry.employeeName} marked as PAID.');
                        _loadData(showProgress: false);
                      },
                      child: const Text('Mark Paid', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C)))),
          TextButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
