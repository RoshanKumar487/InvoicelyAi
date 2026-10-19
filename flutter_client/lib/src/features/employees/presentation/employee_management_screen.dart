import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/utils/table_export_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../theme/app_theme.dart';
import '../data/aadhaar_ocr_scanner.dart';
import '../data/employee.dart';
import '../data/employee_repository.dart';
import 'widgets/employee_biodata_preview_dialog.dart';
import 'widgets/employee_editor_dialog.dart';
import '../../payroll/presentation/widgets/statutory_wage_calculator_dialog.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({
    required this.apiClient,
    this.companyName = '',
    this.companyAddress = '',
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final String companyName;
  final String companyAddress;
  final VoidCallback? onBack;

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  late final EmployeeRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _isScanningAadhaar = false;
  String? _error;
  DateTimeRange? _dateRange;
  final Set<String> _selectedIds = {};

  String _selectedFilter = 'All';
  // Filters: All, Active, Security, Operations, Accounts, On Leave, Inactive
  static const List<String> _filters = [
    'All',
    'Active',
    'Security',
    'Operations',
    'Accounts',
    'On Leave',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();
    _repository = EmployeeRepository(apiClient: widget.apiClient);
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repository.list();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load employees: $e';
        _isLoading = false;
      });
    }
  }

  List<Employee> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();
    return _employees.where((emp) {
      // Apply chip filter in memory too in case API returned broad list
      if (_selectedFilter == 'Active' && emp.status.toUpperCase() != 'ACTIVE') return false;
      if (_selectedFilter == 'Inactive' && emp.status.toUpperCase() != 'INACTIVE') return false;
      if (_selectedFilter == 'On Leave' && emp.status.toUpperCase() != 'ON_LEAVE') return false;
      if (_selectedFilter == 'Security' &&
          !emp.department.toLowerCase().contains('security') &&
          !emp.designation.toLowerCase().contains('guard')) {
        return false;
      }
      if (_selectedFilter == 'Operations' && !emp.department.toLowerCase().contains('operation')) return false;
      if (_selectedFilter == 'Accounts' && !emp.department.toLowerCase().contains('account')) return false;

      if (_dateRange != null) {
        DateTime? dt;
        if (emp.joiningDate.isNotEmpty) {
          dt = DateTime.tryParse(emp.joiningDate);
        }
        dt ??= emp.createdAt;
        if (dt != null) {
          if (dt.isBefore(_dateRange!.start) ||
              dt.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      if (query.isEmpty) return true;
      return emp.fullName.toLowerCase().contains(query) ||
          emp.employeeCode.toLowerCase().contains(query) ||
          emp.designation.toLowerCase().contains(query) ||
          emp.aadhaarNumber.toLowerCase().contains(query) ||
          emp.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openAddEmployeeDialog([Employee? draft]) async {
    final created = await showDialog<Employee>(
      context: context,
      builder: (ctx) => EmployeeEditorDialog(initialDraft: draft),
    );
    if (created == null || !mounted) return;

    try {
      await _repository.create(created);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ Employee registered successfully!'),
        ),
      );
      await _loadEmployees();
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar('Could not save employee: $e');
    }
  }

  Future<void> _scanAadhaarDirect() async {
    setState(() => _isScanningAadhaar = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) {
        setState(() => _isScanningAadhaar = false);
        return;
      }

      final scanned = await AadhaarOcrScanner.scan(imagePath: image.path);
      if (!mounted) return;

      final draft = scanned.toEmployeeDraft(frontImageUri: image.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0284C7),
          content: Text('✓ Aadhaar recognized! Opening onboarding form...'),
        ),
      );
      await _openAddEmployeeDialog(draft);
    } catch (e) {
      if (mounted) _showSnackBar('Aadhaar scanning failed: $e');
    } finally {
      if (mounted) setState(() => _isScanningAadhaar = false);
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final updated = await showDialog<Employee>(
      context: context,
      builder: (ctx) => EmployeeEditorDialog(employee: employee),
    );
    if (updated == null || !mounted) return;

    try {
      await _repository.update(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Employee profile updated.')),
      );
      await _loadEmployees();
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar('Update failed: $e');
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete employee?'),
        content: Text('Are you sure you want to remove ${employee.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || employee.id == null || !mounted) return;

    try {
      await _repository.delete(employee.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee removed.')),
      );
      await _loadEmployees();
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar('Delete failed: $e');
    }
  }

  Future<void> _updateEmployeeStatus(Employee employee, String newStatus) async {
    final updated = employee.copyWith(status: newStatus);
    try {
      await _repository.update(updated);
      if (!mounted) return;
      _showSnackBar('✓ Status updated to $newStatus');
      await _loadEmployees();
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar('Update failed: $e');
    }
  }

  void _previewBiodata(Employee employee) {
    showDialog<void>(
      context: context,
      builder: (ctx) => EmployeeBiodataPreviewDialog(
        employee: employee,
        companyName: widget.companyName,
        companyAddress: widget.companyAddress,
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<EnterpriseMetricCardItem> _buildMetrics() {
    final totalCount = _employees.length;
    final activeCount = _employees.where((e) => e.status.toUpperCase() == 'ACTIVE').length;
    final inactiveCount = _employees.where((e) => e.status.toUpperCase() == 'INACTIVE').length;
    final onLeaveCount = _employees.where((e) => e.status.toUpperCase() == 'ON_LEAVE').length;

    return [
      EnterpriseMetricCardItem(
        label: 'Total Workforce',
        value: totalCount.toString(),
        icon: Icons.groups_outlined,
        color: const Color(0xFF2563EB),
        filterKey: 'All',
        isSelected: _selectedFilter == 'All',
        onTap: () => setState(() => _selectedFilter = 'All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Active on Duty',
        value: activeCount.toString(),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF047857),
        filterKey: 'Active',
        isSelected: _selectedFilter == 'Active',
        onTap: () => setState(
          () => _selectedFilter = _selectedFilter == 'Active' ? 'All' : 'Active',
        ),
      ),
      EnterpriseMetricCardItem(
        label: 'Inactive / Exited',
        value: inactiveCount.toString(),
        icon: Icons.person_off_outlined,
        color: const Color(0xFFDC2626),
        filterKey: 'Inactive',
        isSelected: _selectedFilter == 'Inactive',
        onTap: () => setState(
          () => _selectedFilter = _selectedFilter == 'Inactive' ? 'All' : 'Inactive',
        ),
      ),
      EnterpriseMetricCardItem(
        label: 'On Leave / Off-Duty',
        value: onLeaveCount.toString(),
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFD97706),
        filterKey: 'On Leave',
        isSelected: _selectedFilter == 'On Leave',
        onTap: () => setState(
          () => _selectedFilter = _selectedFilter == 'On Leave' ? 'All' : 'On Leave',
        ),
      ),
    ];
  }

  void _handleDownloadEmployees(List<Employee> currentList) {
    if (_selectedIds.isNotEmpty) {
      final selectedList = <Employee>[];
      for (final e in currentList) {
        final idStr = e.id?.toString() ?? e.employeeCode;
        if (_selectedIds.contains(idStr) || _selectedIds.contains(e.employeeCode)) {
          selectedList.add(e);
        }
      }
      _downloadEmployeesReport(selectedList);
    } else {
      _downloadEmployeesReport(currentList);
    }
  }

  void _downloadEmployeesReport(List<Employee> list) {
    final isSubset = _selectedIds.isNotEmpty && list.length == _selectedIds.length;
    final title = isSubset
        ? 'Employee Workforce (${list.length} Selected)'
        : 'Employee Workforce';
    TableExportHelper.showExportMenu(
      context: context,
      title: title,
      headers: [
        'Code',
        'Full Name',
        'Designation',
        'Department',
        'Aadhaar UID',
        'Mobile',
        'Salary (₹)',
        'Status',
      ],
      rows: list.map((e) => [
        e.employeeCode,
        e.fullName,
        e.designation,
        e.department,
        e.aadhaarNumber,
        e.phone,
        e.monthlySalary.toStringAsFixed(2),
        e.status,
      ]).toList(),
    );
  }

  Future<void> _batchDeleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Employees?'),
        content: Text('Are you sure you want to remove $count selected employees? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    int deleted = 0;
    for (final idStr in _selectedIds.toList()) {
      final id = int.tryParse(idStr);
      if (id != null) {
        try {
          await _repository.delete(id);
          deleted++;
        } catch (_) {}
      }
    }
    setState(() => _selectedIds.clear());
    _showSnackBar('Removed $deleted employees.');
    await _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEmployees;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
        title: const Text('Employee Management & Biodata'),
        actions: [
          if (_isScanningAadhaar)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Scan Aadhaar Card',
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: _scanAadhaarDirect,
            ),
          IconButton(
            tooltip: 'Statutory Wage & CTC Calculator',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => const StatutoryWageCalculatorDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Refresh list',
            icon: const Icon(Icons.sync),
            onPressed: _isLoading ? null : _loadEmployees,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEmployeeDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Employee'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
          return RefreshIndicator(
            onRefresh: _loadEmployees,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 100),
              children: [
                if (_error != null) ...[
                  _buildErrorPanel(),
                  const SizedBox(height: 14),
                ],

                if (_isLoading && _employees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  EnterpriseDataView<Employee>(
                    items: filtered,
                    headerTitle: 'Workforce Directory',
                    metrics: _buildMetrics(),
                    dateRange: _dateRange,
                    onDateRangeChanged: (range) => setState(() => _dateRange = range),
                    onDownloadReport: () => _handleDownloadEmployees(filtered),
                    idGetter: (emp) => emp.id?.toString() ?? emp.employeeCode,
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
                    onSelectAll: (ids) => setState(() => _selectedIds.addAll(ids)),
                    onDeselectAll: () => setState(() => _selectedIds.clear()),
                    onRowTap: (emp) => _previewBiodata(emp),
                    batchActions: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          final selected = filtered
                              .where((e) => _selectedIds.contains(e.id?.toString() ?? e.employeeCode))
                              .toList();
                          _downloadEmployeesReport(selected);
                        },
                        icon: const Icon(Icons.file_download_outlined, size: 14),
                        label: const Text('Export Selected', style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _batchDeleteSelected,
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Delete Selected', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    searchController: _searchController,
                    searchHint: 'Search by employee name, code, UID, phone...',
                    filterChips: _filters,
                    selectedFilterChip: _selectedFilter,
                    onFilterChipSelected: (filter) => setState(() => _selectedFilter = filter),
                    groupBy: (emp) => emp.department.isNotEmpty ? emp.department : 'General',
                    groupLabelBuilder: (dept, items) =>
                        '$dept Department (${items.length} ${items.length == 1 ? "staff" : "staff"})',
                    emptyWidget: _buildEmptyState(),
                    cardBuilder: (context, emp) => _EmployeeCard(
                      employee: emp,
                      onTap: () => _previewBiodata(emp),
                      onPreviewBiodata: () => _previewBiodata(emp),
                      onEdit: () => _editEmployee(emp),
                      onDelete: () => _deleteEmployee(emp),
                    ),
                    columns: _employeeTableColumns(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<EnterpriseTableColumn<Employee>> _employeeTableColumns() {
    return [
      EnterpriseTableColumn<Employee>(
        title: 'Code / Name',
        width: 190,
        sortKey: (emp) => emp.fullName.toLowerCase(),
        cellBuilder: (ctx, emp) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE0E7FF),
              child: Text(
                emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(emp.employeeCode, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Post / Dept',
        width: 160,
        sortKey: (emp) => emp.designation.toLowerCase(),
        cellBuilder: (ctx, emp) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emp.designation, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(emp.department, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Aadhaar UID',
        width: 140,
        sortKey: (emp) => emp.aadhaarNumber,
        cellBuilder: (ctx, emp) => Text(
          emp.aadhaarNumber.isNotEmpty ? emp.aadhaarNumber : '—',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Mobile / Contact',
        width: 130,
        sortKey: (emp) => emp.phone,
        cellBuilder: (ctx, emp) => Text(
          emp.phone.isNotEmpty ? emp.phone : '—',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Salary (₹)',
        width: 110,
        alignRight: true,
        sortKey: (emp) => emp.monthlySalary,
        cellBuilder: (ctx, emp) => Text(
          emp.monthlySalary > 0 ? '₹${emp.monthlySalary.toStringAsFixed(0)}' : '—',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Status',
        width: 125,
        sortKey: (emp) => emp.status,
        cellBuilder: (ctx, emp) => EnterpriseStatusDropdown(
          currentStatus: emp.status,
          options: const ['ACTIVE', 'INACTIVE', 'ON_LEAVE'],
          onChanged: (newStatus) => _updateEmployeeStatus(emp, newStatus),
        ),
      ),
      EnterpriseTableColumn<Employee>(
        title: 'Actions',
        width: 130,
        cellBuilder: (ctx, emp) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Preview & Sign Biodata',
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF0284C7)),
              onPressed: () => _previewBiodata(emp),
            ),
            IconButton(
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editEmployee(emp),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _deleteEmployee(emp),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.badge_outlined, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            const Text(
              'No employees found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start onboarding staff manually or by scanning their Aadhaar card.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _scanAadhaarDirect,
                  icon: const Icon(Icons.document_scanner_outlined, size: 16),
                  label: const Text('Scan Aadhaar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openAddEmployeeDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Employee'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade900))),
          TextButton(onPressed: _loadEmployees, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// Sleek Mobile Employee Card (Identical structure to _InvoiceCard & _ExpenseCard)
class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.onTap,
    required this.onPreviewBiodata,
    required this.onEdit,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onTap;
  final VoidCallback onPreviewBiodata;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Designation + Status + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: const Color(0xFF3730A3),
                    child: Text(
                      employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : 'E',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${employee.designation} · ${employee.department}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: employee.status),
                  PopupMenuButton<String>(
                    tooltip: 'Employee actions',
                    onSelected: (action) {
                      if (action == 'biodata') onPreviewBiodata();
                      if (action == 'edit') onEdit();
                      if (action == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'biodata',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('Preview Biodata & Sign'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Profile'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Record', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metadata wrap (like Invoice Issued & Due date)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (employee.employeeCode.isNotEmpty)
                    _MetaItem(
                      icon: Icons.tag,
                      label: employee.employeeCode,
                    ),
                  if (employee.aadhaarNumber.isNotEmpty)
                    _MetaItem(
                      icon: Icons.verified_user_outlined,
                      label: 'UID: ${employee.aadhaarNumber}',
                    ),
                  if (employee.phone.isNotEmpty)
                    _MetaItem(
                      icon: Icons.phone_outlined,
                      label: employee.phone,
                    ),
                  if (employee.joiningDate.isNotEmpty)
                    _MetaItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Joined ${employee.joiningDate}',
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: Monthly Salary + Quick Action Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Salary',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.monthlySalary > 0
                              ? '₹${employee.monthlySalary.toStringAsFixed(0)}'
                              : 'Not configured',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPreviewBiodata,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Biodata'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final isActive = s == 'ACTIVE';
    final isOnLeave = s == 'ON_LEAVE';

    final Color bg = isActive
        ? const Color(0xFFDCFCE7)
        : isOnLeave
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF1F5F9);

    final Color text = isActive
        ? const Color(0xFF15803D)
        : isOnLeave
            ? const Color(0xFFB45309)
            : const Color(0xFF475569);

    final String label = isActive
        ? 'Active'
        : isOnLeave
            ? 'On Leave'
            : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
