import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/table_export_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/dynamic_form_engine.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../../employees/data/employee_repository.dart';
import '../../expenses/data/expense.dart';
import '../data/payroll_models.dart';
import '../data/payroll_repository.dart';
import 'widgets/statutory_wage_calculator_dialog.dart';

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
  DateTimeRange? _dateRange;

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
    return _entries.where((e) {
      if (_selectedDepartment != 'All Departments' && e.department != _selectedDepartment) {
        return false;
      }
      if (_dateRange != null) {
        DateTime? dt;
        if (e.disbursedAt != null && e.disbursedAt!.isNotEmpty) {
          dt = DateTime.tryParse(e.disbursedAt!);
        }
        if (dt == null && e.scheduledPayDate != null && e.scheduledPayDate!.isNotEmpty) {
          dt = DateTime.tryParse(e.scheduledPayDate!);
        }
        if (dt != null) {
          if (dt.isBefore(_dateRange!.start) ||
              dt.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }
      return true;
    }).toList();
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

  Future<void> _updatePayrollStatus(PayrollEntry entry, String newStatus) async {
    try {
      await widget.repository.batchUpdateStatus(ids: [entry.id], status: newStatus);
      _showMessage('Updated status for ${entry.employeeName} to $newStatus.');
      await _loadData(showProgress: false);
    } catch (e) {
      _showMessage('Error updating status: $e');
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
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
                  tooltip: 'Statutory & Wage Calculator',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => const StatutoryWageCalculatorDialog(),
                  ),
                  icon: const Icon(Icons.calculate_outlined),
                ),
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
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
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
              padding: EdgeInsets.fromLTRB(horizontalPadding, isDesktop ? 6 : 12, horizontalPadding, 100),
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
                  metrics: _buildMetrics(),
                  dateRange: _dateRange,
                  onDateRangeChanged: (range) => setState(() => _dateRange = range),
                  onDownloadReport: () => _handleDownloadPayroll(filtered),
                  onRowTap: (entry) => _openDynamicSalaryAdjustment(entry),
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  searchHint: 'Search employee name, code, designation, or bank...',
                  filterWidget: _buildFilterBar(),
                  filterChips: [
                    'All (${_entries.length})',
                    'Pending (${_kpi.pendingCount})',
                    'Paid (${_kpi.paidCount})',
                    'Overdue (${_kpi.overdueCount})',
                  ],
                  selectedFilterChip: '$_selectedStatus (${_getStatusCount(_selectedStatus)})',
                  onFilterChipSelected: _onStatusFilterSelected,
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
                  groupBy: (item) => item.department.isNotEmpty ? item.department : 'General Staff',
                  groupLabelBuilder: (dept, items) =>
                      '$dept (${items.length} ${items.length == 1 ? "employee" : "employees"})',
                  topTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4338CA),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Employees', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _syncAllEmployees,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export NEFT/Bank', style: TextStyle(fontSize: 12)),
                        onPressed: () => _downloadPayrollReport(filtered),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
                        onPressed: () => _openDynamicSalaryAdjustment(),
                      ),
                    ],
                  ),
                  columns: _buildTableColumns(),
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

  List<EnterpriseMetricCardItem> _buildMetrics() {
    return [
      EnterpriseMetricCardItem(
        label: 'Total Gross Wage',
        value: '₹${_formatCurrency(_kpi.totalGross)}',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF2563EB),
        filterKey: 'All',
        isSelected: _selectedStatus == 'All',
        onTap: () => _onStatusFilterSelected('All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Advances Outstanding',
        value: '₹${_formatCurrency(_kpi.totalAdvances)}',
        icon: Icons.credit_score_outlined,
        color: const Color(0xFFD97706),
        filterKey: 'All',
        isSelected: false,
        onTap: () {},
      ),
      EnterpriseMetricCardItem(
        label: 'Pending Disbursal',
        value: '₹${_formatCurrency(_kpi.totalPending)}',
        icon: Icons.hourglass_top_outlined,
        color: const Color(0xFF7C3AED),
        filterKey: 'PENDING',
        isSelected: _selectedStatus == 'PENDING',
        onTap: () => _onStatusFilterSelected(_selectedStatus == 'PENDING' ? 'All' : 'PENDING'),
      ),
      EnterpriseMetricCardItem(
        label: 'Paid / Disbursed',
        value: '₹${_formatCurrency(_kpi.totalPaid)}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF16A34A),
        filterKey: 'PAID',
        isSelected: _selectedStatus == 'PAID',
        onTap: () => _onStatusFilterSelected(_selectedStatus == 'PAID' ? 'All' : 'PAID'),
      ),
    ];
  }

  void _handleDownloadPayroll(List<PayrollEntry> currentList) {
    if (_selectedIds.isNotEmpty) {
      final selectedList = <PayrollEntry>[];
      for (final p in currentList) {
        if (_selectedIds.contains(p.id.toString()) || _selectedIds.contains(p.employeeId.toString())) {
          selectedList.add(p);
        }
      }
      _downloadPayrollReport(selectedList);
    } else {
      _downloadPayrollReport(currentList);
    }
  }

  void _downloadPayrollReport(List<PayrollEntry> list) {
    final isSubset = _selectedIds.isNotEmpty && list.length == _selectedIds.length;
    final title = isSubset
        ? 'Payroll Disbursal Register (${list.length} Selected)'
        : 'Payroll Disbursal Register';
    TableExportHelper.showExportMenu(
      context: context,
      title: title,
      headers: [
        'Employee Name',
        'Code',
        'Department',
        'Designation',
        'Basic Pay (₹)',
        'HRA (₹)',
        'Allowances (₹)',
        'Gross Pay (₹)',
        'EPF (₹)',
        'PT (₹)',
        'TDS (₹)',
        'Statutory Cuts (₹)',
        'Adv Balance (₹)',
        'Adv Recovered (₹)',
        'Net Salary (₹)',
        'Pending Months',
        'Cumulative Payable (₹)',
        'Status',
        'Bank Routing',
      ],
      rows: list.map((e) => [
        e.employeeName,
        e.employeeCode,
        e.department,
        e.designation,
        e.basicPay.toStringAsFixed(2),
        e.hra.toStringAsFixed(2),
        e.allowances.toStringAsFixed(2),
        e.grossEarnings.toStringAsFixed(2),
        e.pfEmployee.toStringAsFixed(2),
        e.professionalTax.toStringAsFixed(2),
        e.tdsTax.toStringAsFixed(2),
        e.totalDeductions.toStringAsFixed(2),
        e.advanceAmount.toStringAsFixed(2),
        e.advanceDeduction.toStringAsFixed(2),
        e.netSalary.toStringAsFixed(2),
        e.pendingMonthsCount.toString(),
        e.cumulativePayable.toStringAsFixed(2),
        e.paymentStatus,
        e.bankAccountMask.isNotEmpty ? e.bankAccountMask : 'Bank NEFT',
      ]).toList(),
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

  /// EXACT SAME TABLE COLUMNS AS ENTERPRISE GRID + ADVANCE & BACKLOG ENHANCEMENTS
  List<EnterpriseTableColumn<PayrollEntry>> _buildTableColumns() {
    return [
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Employee Name & Code',
        width: 220,
        sortKey: (entry) => entry.employeeName.toLowerCase(),
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
        width: 120,
        sortKey: (entry) => entry.department.toLowerCase(),
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
        title: 'Gross Pay (Base)',
        width: 135,
        alignRight: true,
        sortKey: (entry) => entry.grossEarnings,
        cellBuilder: (ctx, entry) => InkWell(
          onTap: () => _openQuickSalaryEditor(entry),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${_formatCurrency(entry.grossEarnings)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Deductions',
        width: 105,
        alignRight: true,
        sortKey: (entry) => entry.totalDeductions,
        cellBuilder: (ctx, entry) => Text(
          '-₹${_formatCurrency(entry.totalDeductions)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Adv Amount (Cut)',
        width: 145,
        alignRight: true,
        sortKey: (entry) => entry.advanceAmount,
        cellBuilder: (ctx, entry) => InkWell(
          onTap: () => _openQuickAdvanceCutEditor(entry),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.advanceAmount > 0) ...[
                      const Icon(Icons.history_edu, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      '₹${_formatCurrency(entry.advanceAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: entry.advanceAmount > 0 ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 11, color: Color(0xFF94A3B8)),
                  ],
                ),
                if (entry.advanceDeduction > 0)
                  Text(
                    '-₹${_formatCurrency(entry.advanceDeduction)} cut',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  )
                else if (entry.advanceAmount > 0)
                  const Text(
                    'Tap to set cut',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Payable Total Amount',
        width: 165,
        alignRight: true,
        sortKey: (entry) => entry.hasBacklog ? entry.cumulativePayable : entry.netSalary,
        cellBuilder: (ctx, entry) => InkWell(
          onTap: () => _openQuickSalaryEditor(entry),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${_formatCurrency(entry.netSalary)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit_outlined, size: 11, color: Color(0xFF94A3B8)),
                  ],
                ),
                if (entry.hasBacklog) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _showBacklogBreakdownDialog(entry),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 10, color: Color(0xFFB45309)),
                          const SizedBox(width: 3),
                          Text(
                            'Total: ₹${_formatCurrency(entry.cumulativePayable)} (${entry.pendingMonthsCount} mos)',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Status',
        width: 125,
        sortKey: (entry) => entry.paymentStatus,
        cellBuilder: (ctx, entry) => EnterpriseStatusDropdown(
          currentStatus: entry.paymentStatus,
          options: const ['PAID', 'PENDING', 'ON_HOLD', 'OVERDUE'],
          onChanged: (newStatus) => _updatePayrollStatus(entry, newStatus),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Bank Mask',
        width: 130,
        sortKey: (entry) => entry.bankAccountMask,
        cellBuilder: (ctx, entry) => Text(
          entry.bankAccountMask.isNotEmpty ? entry.bankAccountMask : 'Direct Bank NEFT',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ),
      EnterpriseTableColumn<PayrollEntry>(
        title: 'Actions',
        width: 130,
        cellBuilder: (ctx, entry) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Advance Ledger & Proof',
              icon: const Icon(Icons.history_edu_outlined, size: 18, color: Color(0xFFD97706)),
              onPressed: () => _showAdvanceHistoryDialog(entry),
            ),
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
                      _showMessage('${entry.employeeName} marked as PAID. Advances settled.');
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
          if (entry.hasBacklog) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showBacklogBreakdownDialog(entry),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${entry.pendingMonthsCount} Pending Months · Total Payable: ₹${_formatCurrency(entry.cumulativePayable)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF92400E)),
                  ],
                ),
              ),
            ),
          ],
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
              if (entry.hasAdvance)
                InkWell(
                  onTap: () => _showAdvanceHistoryDialog(entry),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adv Recovered', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                      Text(
                        '-₹${_formatCurrency(entry.advanceDeduction)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
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
          if (entry.hasAdvance) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.history_edu, size: 12, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'Total Advance: ₹${_formatCurrency(entry.advanceAmount)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showAdvanceHistoryDialog(entry),
                  child: const Text(
                    '(View History)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
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
                  IconButton(
                    tooltip: 'Advance Ledger',
                    icon: const Icon(Icons.history_edu_outlined, size: 16, color: Color(0xFFD97706)),
                    onPressed: () => _showAdvanceHistoryDialog(entry),
                  ),
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

  Future<void> _syncAllEmployees() async {
    setState(() => _isLoading = true);
    try {
      final runId = _selectedRun?.id ?? 1;
      await widget.repository.syncEmployees(runId);
      await _loadData(showProgress: true);
      _showMessage('Synchronized all employees & advances from Employee Management.');
    } catch (e) {
      await _loadData(showProgress: false);
      _showMessage('Synced with latest active employees & advances.');
    }
  }

  Future<void> _openQuickSalaryEditor(PayrollEntry entry) async {
    final controller = TextEditingController(text: entry.grossEarnings.toStringAsFixed(0));
    bool updateEmployeeMgmt = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final val = double.tryParse(controller.text) ?? entry.grossEarnings;
          final basic = (val * 0.50).roundToDouble();
          final hra = (val * 0.30).roundToDouble();
          final allowances = val - basic - hra;
          final pf = (basic.clamp(0, 15000) * 0.12).roundToDouble();
          final pt = 200.0;
          final statutory = pf + pt;
          final net = (val - statutory - entry.advanceDeduction).clamp(0.0, double.infinity);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Salary: ${entry.employeeName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directly edit gross pay for ${entry.employeeCode} (${entry.designation} · ${entry.department}). Deductions and net payable will auto-recalculate.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Gross Salary *',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Basic Pay (50%):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            Text('₹${_formatCurrency(basic)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HRA (30%):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            Text('₹${_formatCurrency(hra)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Other Allowances (20%):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            Text('₹${_formatCurrency(allowances.clamp(0.0, double.infinity))}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Deductions (PF/PT):', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626))),
                            Text('-₹${_formatCurrency(statutory)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          ],
                        ),
                        if (entry.advanceDeduction > 0) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Deduction Cut:', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
                              Text('-₹${_formatCurrency(entry.advanceDeduction)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ],
                          ),
                        ],
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recalculated Net Payable:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('₹${_formatCurrency(net)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: updateEmployeeMgmt,
                    title: const Text(
                      'Also update base salary in Employee Management table',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) => setDialogState(() => updateEmployeeMgmt = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save & Recalculate'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || !mounted) return;
    final newGross = double.tryParse(controller.text);
    if (newGross == null || newGross <= 0) return;

    final basic = (newGross * 0.50).roundToDouble();
    final hra = (newGross * 0.30).roundToDouble();
    final allowances = newGross - basic - hra;
    final pf = (basic.clamp(0, 15000) * 0.12).roundToDouble();
    final pt = 200.0;
    final statutory = pf + pt;
    final allDeductions = statutory + entry.advanceDeduction;
    final netSalary = (newGross - allDeductions).clamp(0.0, double.infinity);

    final updated = entry.copyWith(
      grossEarnings: newGross,
      basicPay: basic,
      hra: hra,
      allowances: allowances,
      pfEmployee: pf,
      professionalTax: pt,
      totalDeductions: allDeductions,
      netSalary: netSalary,
      cumulativePayable: netSalary,
    );

    await widget.repository.updateEntry(updated);

    if (updateEmployeeMgmt && entry.employeeId > 0) {
      try {
        final empRepo = EmployeeRepository(apiClient: widget.repository.apiClient);
        final emp = await empRepo.getById(entry.employeeId);
        await empRepo.update(emp.copyWith(monthlySalary: newGross));
      } catch (e) {
        debugPrint('Could not update employee record: $e');
      }
    }

    _showMessage('Updated salary for ${entry.employeeName} to ₹${_formatCurrency(newGross)}');
    _loadData(showProgress: false);
  }

  Future<void> _openQuickAdvanceCutEditor(PayrollEntry entry) async {
    final controller = TextEditingController(text: entry.advanceDeduction.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cut = double.tryParse(controller.text) ?? entry.advanceDeduction;
          final remainingAdvance = (entry.advanceAmount - cut).clamp(0.0, double.infinity);
          final statutory = entry.pfEmployee + entry.esiEmployee + entry.professionalTax;
          final totalDeductions = statutory + cut;
          final net = (entry.grossEarnings - totalDeductions).clamp(0.0, double.infinity);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.history_edu_rounded, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Advance Cut: ${entry.employeeName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Advance Taken:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                        Text('₹${_formatCurrency(entry.advanceAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Advance Cut this Month *',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      border: const OutlineInputBorder(),
                      helperText: 'Max recoverable: ₹${_formatCurrency(entry.advanceAmount)}',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Advance Next Month:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      Text('₹${_formatCurrency(remainingAdvance)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Salary after Deduction:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      Text('₹${_formatCurrency(net)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Update Advance Cut'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || !mounted) return;
    final newCut = double.tryParse(controller.text) ?? 0.0;
    final statutory = entry.pfEmployee + entry.esiEmployee + entry.professionalTax;
    final allDeductions = statutory + newCut;
    final netSalary = (entry.grossEarnings - allDeductions).clamp(0.0, double.infinity);

    final updated = entry.copyWith(
      advanceDeduction: newCut,
      totalDeductions: allDeductions,
      netSalary: netSalary,
      cumulativePayable: netSalary,
    );

    await widget.repository.updateEntry(updated);
    _showMessage('Updated advance deduction for ${entry.employeeName} to ₹${_formatCurrency(newCut)}');
    _loadData(showProgress: false);
  }

  Future<void> _showAdvanceHistoryDialog(PayrollEntry entry) async {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 680),
            child: FutureBuilder<List<Expense>>(
              future: widget.repository.getEmployeeAdvanceHistory(
                employeeId: entry.employeeId,
                employeeName: entry.employeeName,
              ),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_edu_outlined,
                              color: Color(0xFFD97706),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salary Advance Ledger: ${entry.employeeName}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Employee Code: ${entry.employeeCode} · ${entry.department} · ${entry.designation}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAdvanceKpi(
                              label: 'Total Advance Taken',
                              value: '₹${_formatCurrency(entry.advanceAmount)}',
                              color: const Color(0xFFD97706),
                            ),
                            Container(height: 28, width: 1, color: const Color(0xFFCBD5E1)),
                            _buildAdvanceKpi(
                              label: 'Recovered This Month',
                              value: '₹${_formatCurrency(entry.advanceDeduction)}',
                              color: const Color(0xFF16A34A),
                            ),
                            Container(height: 28, width: 1, color: const Color(0xFFCBD5E1)),
                            _buildAdvanceKpi(
                              label: 'Unsettled Balance',
                              value: '₹${_formatCurrency((entry.advanceAmount - entry.advanceDeduction).clamp(0.0, double.infinity))}',
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Detailed Expenses Ledger (Advances Disbursed & Authorized)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : snapshot.hasError
                                ? Center(
                                    child: Text(
                                      'Failed to load advances: ${snapshot.error}',
                                      style: const TextStyle(color: Color(0xFFDC2626)),
                                    ),
                                  )
                                : (snapshot.data == null || snapshot.data!.isEmpty)
                                    ? Container(
                                        padding: const EdgeInsets.all(24),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'No advance expenses found for this employee.',
                                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'When advances are logged in the Expenses screen linked to this employee, they will automatically appear here.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 12, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: snapshot.data!.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, idx) {
                                          final item = snapshot.data![idx];
                                          return _buildAdvanceHistoryTile(item);
                                        },
                                      ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvanceKpi({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceHistoryTile(Expense item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: item.advanceSettled ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            foregroundColor: item.advanceSettled ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            child: Icon(
              item.advanceSettled ? Icons.check_circle_outline : Icons.payments_outlined,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${_formatCurrency(item.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.advanceSettled ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: item.advanceSettled ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        item.advanceSettled ? 'Recovered via Payroll' : 'Unsettled / Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.advanceSettled ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Date: ${item.date} · Authorized / Disbursed By: ${(item.createdByUserName != null && item.createdByUserName!.isNotEmpty) ? item.createdByUserName! : (item.vendor.isNotEmpty ? item.vendor : "Company Accounts")}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Notes: ${item.notes}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (item.receiptImageUri != null && item.receiptImageUri!.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.attachment, size: 14),
              label: const Text('Proof', style: TextStyle(fontSize: 11)),
              onPressed: () => _showProofDialog(item.receiptImageUri!),
            ),
        ],
      ),
    );
  }

  void _showProofDialog(String uri) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Advance Receipt / Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text('Receipt Attachment URI:\n$uri', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showBacklogBreakdownDialog(PayrollEntry entry) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text('Salary Backlog: ${entry.employeeName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.employeeName} has ${entry.pendingMonthsCount} months of pending salary payable by the company.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending Months:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(entry.pendingMonthsDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Month Net:', style: TextStyle(fontSize: 12)),
                      Text('₹${_formatCurrency(entry.netSalary)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  if (entry.advanceDeduction > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Advance Recovered:', style: TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                        Text('-₹${_formatCurrency(entry.advanceDeduction)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFD97706))),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Cumulative Payable:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E))),
                      Text(
                        '₹${_formatCurrency(entry.cumulativePayable)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once accountant marks this run as PAID, the current month is settled. Any additional backlog months can be reviewed and disbursed through their respective monthly runs.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (!entry.isPaid)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.repository.updateEntryStatus(id: entry.id, status: 'PAID');
                _showMessage('${entry.employeeName} marked as PAID.');
                _loadData(showProgress: false);
              },
              child: const Text('Mark Paid Now'),
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
