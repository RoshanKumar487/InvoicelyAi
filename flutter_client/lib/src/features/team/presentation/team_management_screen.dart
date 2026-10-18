import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../data/team_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../audit/data/audit_log_service.dart';
import '../../settings/data/settings_repository.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({
    required this.apiClient,
    this.businessProfileName,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final String? businessProfileName;
  final VoidCallback? onBack;

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamRepository _repository;
  late final SettingsRepository _settingsRepository;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _company = <String, dynamic>{};
  String? _profileCompanyName;
  List<Map<String, dynamic>> _employees = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];

  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'All';

  static const _permissionLabels = <String, String>{
    'INVOICES': 'Invoices',
    'EXPENSES': 'Expenses',
    'CLIENTS': 'Clients',
    'REPORTS': 'Reports',
    'EMPLOYEES': 'Workforce',
    'AUDIT_LOGS': 'Audit Logs',
    'SETTINGS': 'Settings',
  };

  static const _filterOptions = <String>[
    'All',
    'Admin',
    'Manager',
    'Accountant',
    'Staff',
    'Viewer',
    'Join Requests',
  ];

  @override
  void initState() {
    super.initState();
    _repository = TeamRepository(apiClient: widget.apiClient);
    _settingsRepository = SettingsRepository(apiClient: widget.apiClient);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static bool _isPlaceholderName(String? value) {
    if (value == null) return true;
    final norm = value.trim().toLowerCase();
    return norm.isEmpty ||
        norm == 'apex nova dynamics' ||
        norm == 'northstar security services pvt. ltd.' ||
        norm == 'northstar security services' ||
        norm == 'your company name' ||
        norm == 'my business';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object?>([
        _repository.loadCompany(),
        _repository.loadEmployees(),
        _repository.loadJoinRequests(),
        _settingsRepository.loadProfile().catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final loadedCompany = Map<String, dynamic>.from(result[0] as Map<String, dynamic>);
      final profile = (result[3] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final profileBizName = profile['businessName']?.toString().trim() ??
          profile['companyName']?.toString().trim() ??
          widget.businessProfileName?.trim();

      String? resolvedName;
      if (!_isPlaceholderName(profileBizName)) {
        resolvedName = profileBizName;
      } else if (!_isPlaceholderName(widget.businessProfileName)) {
        resolvedName = widget.businessProfileName!.trim();
      }

      if (resolvedName != null && resolvedName.isNotEmpty) {
        final existingName = loadedCompany['companyName']?.toString().trim() ?? '';
        loadedCompany['companyName'] = resolvedName;
        if (existingName != resolvedName) {
          unawaited(
            widget.apiClient
                .putJson(
                  'api/v1/companies/my-company',
                  <String, Object?>{
                    ...loadedCompany,
                    'companyName': resolvedName,
                  },
                )
                .catchError((_) => <String, dynamic>{}),
          );
        }
      }

      setState(() {
        _company = loadedCompany;
        _profileCompanyName = resolvedName;
        _employees = List<Map<String, dynamic>>.from(result[1] as List<dynamic>);
        _requests = List<Map<String, dynamic>>.from(result[2] as List<dynamic>);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load workspace team: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Set<String> _permissionsFor(Map<String, dynamic> employee) {
    final raw = employee['permissions'];
    if (raw is List) {
      return raw.map((item) => item.toString().trim().toUpperCase()).toSet();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.split(',').map((item) => item.trim().toUpperCase()).toSet();
    }
    final role = employee['role']?.toString().toUpperCase() ?? 'STAFF';
    if (role == 'ADMIN') {
      return _permissionLabels.keys.toSet();
    }
    return const <String>{'INVOICES'};
  }

  int _countRole(String role) {
    return _employees.where((e) {
      final r = e['role']?.toString().toUpperCase() ?? '';
      return r == role.toUpperCase();
    }).length;
  }

  List<EnterpriseMetricCardItem> _buildMetrics() {
    final total = _employees.length;
    final admins = _countRole('ADMIN');
    final staff = _employees.where((e) {
      final r = e['role']?.toString().toUpperCase() ?? '';
      return r == 'MANAGER' || r == 'STAFF' || r == 'ACCOUNTANT' || r == 'EMPLOYEE';
    }).length;
    final pending = _requests.length;

    return [
      EnterpriseMetricCardItem(
        label: 'Total Members',
        value: '$total',
        count: 'Active Team',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF1D68F0),
        filterKey: 'All',
        isSelected: _roleFilter == 'All',
        onTap: () => setState(() => _roleFilter = 'All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Admins & Leads',
        value: '$admins',
        count: 'Full Control',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFFDC2626),
        filterKey: 'Admin',
        isSelected: _roleFilter == 'Admin',
        onTap: () => setState(() => _roleFilter = _roleFilter == 'Admin' ? 'All' : 'Admin'),
      ),
      EnterpriseMetricCardItem(
        label: 'Operations & Staff',
        value: '$staff',
        count: 'Standard Access',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF10B981),
        filterKey: 'Staff',
        isSelected: _roleFilter == 'Staff',
        onTap: () => setState(() => _roleFilter = _roleFilter == 'Staff' ? 'All' : 'Staff'),
      ),
      EnterpriseMetricCardItem(
        label: 'Join Requests',
        value: '$pending',
        count: pending > 0 ? 'Pending Approval' : 'Up to Date',
        icon: Icons.person_add_rounded,
        color: const Color(0xFFF59E0B),
        filterKey: 'Join Requests',
        isSelected: _roleFilter == 'Join Requests',
        onTap: () => setState(() => _roleFilter = _roleFilter == 'Join Requests' ? 'All' : 'Join Requests'),
      ),
    ];
  }

  Future<void> _process(int id, String action) async {
    final noteController = TextEditingController();
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${action == 'APPROVE' ? 'Approve' : 'Reject'} Join Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Process request and notify applicant via email / WhatsApp.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note / Feedback (Optional)',
                hintText: 'e.g. Welcome to the workspace!',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'APPROVE' ? 'Approve & Onboard' : 'Reject Request'),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    setState(() => _saving = true);
    try {
      await _repository.processJoinRequest(id: id, action: action);
      try {
        final notifRepo = NotificationRepository(apiClient: widget.apiClient);
        await notifRepo.sendJoinRequestResponse(
          joinRequestId: id,
          action: action,
          customMessage: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${action.toLowerCase()}d successfully!')),
      );
      await _load();
    } catch (error) {
      if (mounted) _showError('Could not process request: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showEditRoleAndPermissionsDialog(Map<String, dynamic> employee) async {
    final id = _asInt(employee['id']);
    if (id == null) return;

    String currentRole = employee['role']?.toString().toUpperCase() ?? 'STAFF';
    if (currentRole == 'EMPLOYEE') currentRole = 'STAFF';
    final existingPerms = _permissionsFor(employee);
    final Set<String> selectedPerms = Set<String>.from(existingPerms);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D68F0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF1D68F0), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Role & Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      employee['fullName']?.toString() ?? 'Team member',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned Role', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: ['ADMIN', 'MANAGER', 'ACCOUNTANT', 'STAFF', 'VIEWER'].contains(currentRole) ? currentRole : 'STAFF',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Full Workspace Control)')),
                      DropdownMenuItem(value: 'MANAGER', child: Text('Manager (Workforce & Operations)')),
                      DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant (Billing & Ledger)')),
                      DropdownMenuItem(value: 'STAFF', child: Text('Staff (Assigned Work)')),
                      DropdownMenuItem(value: 'VIEWER', child: Text('Viewer (Read-only Statements)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          currentRole = val;
                          if (currentRole == 'ADMIN') {
                            selectedPerms.addAll(_permissionLabels.keys);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Module Access Permissions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('Grant or revoke granular feature access for this user.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: _permissionLabels.entries.map((entry) {
                        final key = entry.key;
                        final label = entry.value;
                        final isChecked = selectedPerms.contains(key) || currentRole == 'ADMIN';
                        return CheckboxListTile(
                          dense: true,
                          title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: isChecked,
                          enabled: currentRole != 'ADMIN',
                          activeColor: const Color(0xFF1D68F0),
                          onChanged: currentRole == 'ADMIN'
                              ? null
                              : (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedPerms.add(key);
                                    } else {
                                      selectedPerms.remove(key);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D68F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Access Changes'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    setState(() => _saving = true);
    try {
      await _repository.updateRole(
        employeeId: id,
        role: currentRole,
        permissions: selectedPerms,
      );
      await _repository.updatePermissions(
        employeeId: id,
        permissions: selectedPerms,
      );

      final empName = employee['fullName']?.toString() ?? 'User';
      unawaited(
        AuditLogService.log(
          module: 'TEAM',
          action: 'ROLE_CHANGE',
          entityId: 'USR-$id',
          title: 'Updated role & permissions for $empName',
          description: 'Role: $currentRole | Permissions: [${selectedPerms.join(", ")}]',
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('✓ User role and access permissions saved successfully!'),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) _showError('Could not update member access: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEmployee(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Team Member?'),
        content: Text('Are you sure you want to remove $name from this workspace? Their access will be revoked immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove Member'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _repository.deleteEmployee(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ $name was removed from the workspace.')),
      );
      await _load();
    } catch (error) {
      if (mounted) _showError('Could not remove member: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showInviteMemberDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = 'STAFF';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1D68F0)),
              SizedBox(width: 8),
              Text('Invite Team Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send an invitation to join your workspace with pre-configured role permissions.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address or Mobile Number',
                  hintText: 'e.g. staff@company.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Assigned Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Full Control)')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager (Workforce & Operations)')),
                  DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant (Billing & Ledger)')),
                  DropdownMenuItem(value: 'STAFF', child: Text('Staff (Assigned Documents)')),
                  DropdownMenuItem(value: 'VIEWER', child: Text('Viewer (Read-only)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D68F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.send_rounded, size: 15),
              label: const Text('Copy Invite Link'),
              onPressed: () async {
                final target = emailCtrl.text.trim();
                final code = _company['companyCode']?.toString() ?? '';
                final companyName = _resolvedCompanyName();
                final inviteText = 'You have been invited to join $companyName as $selectedRole on Invoicely!\nOrg Code: $code\nJoin: https://invoicelyai.onrender.com/join?code=$code&role=$selectedRole';

                await Clipboard.setData(ClipboardData(text: inviteText));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  _showError('✓ Invite link for $target copied to clipboard!');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyCompanyCode() async {
    final code = _company['companyCode']?.toString() ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _showError('Organization code copied.');
  }

  Future<void> _shareViaWhatsApp() async {
    final code = _company['companyCode']?.toString() ?? '';
    if (code.isEmpty) return;
    final companyName = _resolvedCompanyName();
    final message = 'Join our workspace *$companyName* on Invoicely!\nOrganization Code: *$code*\nDownload & register to get started.';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await _copyCompanyCode();
    }
  }

  String _resolvedCompanyName() {
    if (!_isPlaceholderName(_profileCompanyName)) {
      return _profileCompanyName!.trim();
    }
    if (!_isPlaceholderName(widget.businessProfileName)) {
      return widget.businessProfileName!.trim();
    }
    final raw = _company['companyName']?.toString().trim() ?? '';
    return raw.isNotEmpty ? raw : 'Your Workspace';
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFFDC2626);
      case 'MANAGER':
        return const Color(0xFFD97706);
      case 'ACCOUNTANT':
        return const Color(0xFF059669);
      case 'VIEWER':
        return const Color(0xFF4B5563);
      default:
        return const Color(0xFF1D68F0);
    }
  }

  List<EnterpriseTableColumn<Map<String, dynamic>>> _buildTableColumns() {
    return [
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Team Member',
        width: 220,
        sortKey: (m) => m['fullName']?.toString().toLowerCase(),
        cellBuilder: (ctx, m) {
          final name = m['fullName']?.toString() ?? 'Team member';
          final email = m['email']?.toString() ?? '';
          final role = m['role']?.toString().toUpperCase() ?? 'STAFF';
          final roleColor = _getRoleColor(role);
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Phone / Mobile',
        width: 130,
        sortKey: (m) => m['mobile']?.toString() ?? '',
        cellBuilder: (ctx, m) {
          final phone = m['mobile']?.toString() ?? '';
          return Text(
            phone.isNotEmpty ? phone : '—',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
          );
        },
      ),
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Role',
        width: 120,
        sortKey: (m) => m['role']?.toString() ?? '',
        cellBuilder: (ctx, m) {
          final rawRole = m['role']?.toString().toUpperCase() ?? 'STAFF';
          final role = rawRole == 'EMPLOYEE' ? 'STAFF' : rawRole;
          final color = _getRoleColor(role);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          );
        },
      ),
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Module Access',
        width: 250,
        cellBuilder: (ctx, m) {
          final perms = _permissionsFor(m);
          final role = m['role']?.toString().toUpperCase() ?? 'STAFF';
          if (role == 'ADMIN') {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '★ Full Workspace Access',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: perms.map((p) {
                final label = _permissionLabels[p] ?? p;
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Status',
        width: 100,
        sortKey: (m) => m['status']?.toString() ?? '',
        cellBuilder: (ctx, m) {
          final status = m['status']?.toString().toUpperCase() ?? 'ACTIVE';
          final isActive = status == 'ACTIVE';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isActive ? 'Active' : status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      EnterpriseTableColumn<Map<String, dynamic>>(
        title: 'Actions',
        width: 130,
        alignRight: true,
        cellBuilder: (ctx, m) {
          final id = _asInt(m['id']);
          final name = m['fullName']?.toString() ?? 'Member';

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                iconSize: 18,
                tooltip: 'Edit Role & Access',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1D68F0)),
                onPressed: () => _showEditRoleAndPermissionsDialog(m),
              ),
              IconButton(
                iconSize: 18,
                tooltip: 'Remove Member',
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                onPressed: id != null ? () => _deleteEmployee(id, name) : null,
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> m) {
    final id = _asInt(m['id']);
    final name = m['fullName']?.toString() ?? 'Team member';
    final email = m['email']?.toString() ?? '';
    final role = m['role']?.toString().toUpperCase() ?? 'STAFF';
    final roleColor = _getRoleColor(role);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.12),
                child: Text(initial, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit Access', style: TextStyle(fontSize: 12)),
                onPressed: () => _showEditRoleAndPermissionsDialog(m),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                onPressed: id != null ? () => _deleteEmployee(id, name) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _resolvedCompanyName();
    final query = _searchController.text.trim().toLowerCase();

    // Filter employees based on search & role filter
    final visibleEmployees = _employees.where((emp) {
      final name = emp['fullName']?.toString().toLowerCase() ?? '';
      final email = emp['email']?.toString().toLowerCase() ?? '';
      final mobile = emp['mobile']?.toString().toLowerCase() ?? '';
      final role = emp['role']?.toString().toUpperCase() ?? '';

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          mobile.contains(query);

      bool matchesRole = true;
      if (_roleFilter == 'Admin') {
        matchesRole = role == 'ADMIN';
      } else if (_roleFilter == 'Manager') {
        matchesRole = role == 'MANAGER';
      } else if (_roleFilter == 'Accountant') {
        matchesRole = role == 'ACCOUNTANT';
      } else if (_roleFilter == 'Staff') {
        matchesRole = role == 'STAFF' || role == 'EMPLOYEE';
      } else if (_roleFilter == 'Viewer') {
        matchesRole = role == 'VIEWER';
      }

      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D68F0),
        foregroundColor: Colors.white,
        onPressed: _showInviteMemberDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Invite member'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;

                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 100),
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
                        ),
                      ],
                      // Organization Code & Invite Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D68F0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.badge_rounded, color: Color(0xFF1D68F0), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(companyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('RBAC ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  const Text('Organization Code for staff self-onboarding & join requests', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: SelectableText(
                                _company['companyCode']?.toString() ?? 'N/A',
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Copy organization code',
                              onPressed: _copyCompanyCode,
                              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF475569)),
                            ),
                            IconButton(
                              tooltip: 'Share via WhatsApp',
                              onPressed: _shareViaWhatsApp,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // If Join Requests tab is selected, show join requests
                      if (_roleFilter == 'Join Requests') ...[
                        EnterpriseMetricsStrip(metrics: _buildMetrics()),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_add_rounded, color: Color(0xFFF59E0B), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pending Join Requests (${_requests.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: () => setState(() => _roleFilter = 'All'),
                                    child: const Text('Back to All Members'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_requests.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text('No pending join requests found. Share your code to onboard staff.'),
                                  ),
                                )
                              else
                                ..._requests.map((req) {
                                  final id = _asInt(req['id']);
                                  final name = req['userFullName']?.toString() ?? 'Applicant';
                                  final email = req['userEmail']?.toString() ?? '';
                                  final msg = req['requestMessage']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                              Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                              if (msg.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text('Note: $msg', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                          onPressed: id != null && !_saving ? () => _process(id, 'APPROVE') : null,
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Approve'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: id != null && !_saving ? () => _process(id, 'REJECT') : null,
                                          icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                                          label: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Standard EnterpriseDataView Table for Team Management matching Invoices & Expenses!
                        EnterpriseDataView<Map<String, dynamic>>(
                          items: visibleEmployees,
                          headerTitle: 'Team Directory',
                          metrics: _buildMetrics(),
                          searchController: _searchController,
                          searchHint: 'Search member name, email or mobile...',
                          filterChips: _filterOptions,
                          selectedFilterChip: _roleFilter,
                          onFilterChipSelected: (chip) => setState(() => _roleFilter = chip),
                          columns: _buildTableColumns(),
                          cardBuilder: _buildMemberCard,
                          emptyMessage: 'No team members found matching current filter.',
                          directoryActions: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1D68F0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showInviteMemberDialog,
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                              label: const Text('Invite Member'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
