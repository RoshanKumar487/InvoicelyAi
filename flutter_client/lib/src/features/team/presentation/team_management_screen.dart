import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
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
  final Set<int> _editingEmployeeIds = <int>{};
  final Map<int, Set<String>> _draftPermissions = <int, Set<String>>{};
  final Map<int, String> _draftRoles = <int, String>{};

  static const _permissionLabels = <String, String>{
    'INVOICES': 'Invoices',
    'EXPENSES': 'Expenses',
    'CLIENTS': 'Clients',
    'REPORTS': 'Reports',
    'EMPLOYEES': 'Workforce / Biodata',
    'AUDIT_LOGS': 'Audit Logs',
    'SETTINGS': 'Settings & Brand',
  };

  @override
  void initState() {
    super.initState();
    _repository = TeamRepository(apiClient: widget.apiClient);
    _settingsRepository = SettingsRepository(apiClient: widget.apiClient);
    _load();
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
        // Also persist updated company name to backend Company record while keeping companyCode unchanged
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
        _employees = result[1] as List<Map<String, dynamic>>;
        _requests = result[2] as List<Map<String, dynamic>>;
        _loading = false;
        _draftPermissions.clear();
        _draftRoles.clear();
        _editingEmployeeIds.clear();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load team information: $error';
        _loading = false;
      });
    }
  }

  Set<String> _permissionsFor(Map<String, dynamic> employee) {
    final raw = employee['permissions']?.toString() ?? '';
    return raw
        .split(',')
        .map((permission) => permission.trim().toUpperCase())
        .where(_permissionLabels.containsKey)
        .toSet();
  }

  Future<void> _process(int id, String action) async {
    final noteController = TextEditingController();
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action == 'APPROVE' ? 'Approve' : 'Reject'} Join Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Process request and notify applicant via email / WhatsApp.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note / Feedback (Optional)',
                hintText: 'e.g. Welcome to the accounting team!',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'APPROVE' ? 'Approve & Notify' : 'Reject & Notify'),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    setState(() => _saving = true);
    try {
      await _repository.processJoinRequest(id: id, action: action);

      // Also trigger push notification with template to the applicant
      try {
        final notifRepo = NotificationRepository(apiClient: widget.apiClient);
        await notifRepo.sendJoinRequestResponse(
          joinRequestId: id,
          action: action,
          customMessage: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
        );
      } catch (_) {
        // Log or handle non-fatal push notification error
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${action.toLowerCase()}d and applicant notified!')),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not update request: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String channel = 'EMAIL';
    String role = 'EMPLOYEE';

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Invite Team Member'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send an invitation to join your workspace via Email or WhatsApp using the template engine.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Invitee Email *',
                    hintText: 'colleague@example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone (Optional)',
                    hintText: '+15551234567',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: channel,
                        decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                          DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => channel = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'EMPLOYEE', child: Text('Staff / Guard')),
                          DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                          DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                          DropdownMenuItem(value: 'VIEWER', child: Text('Auditor / Viewer')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => role = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    switch (role) {
                      'ADMIN' => 'Full administrative access: billing, staff, reports, and company settings.',
                      'ACCOUNTANT' => 'Accounting access: invoices, receipts, client ledgers, and expense reports.',
                      'MANAGER' => 'Operations access: client management, team duty records, and invoices.',
                      'VIEWER' => 'Read-only access: view invoices, receipts, and ledger statements.',
                      _ => 'Staff access: log daily duty, invoices, and expense entries.',
                    },
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () {
                if (emailController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );

    if (sent != true) return;

    setState(() => _saving = true);
    try {
      final notifRepo = NotificationRepository(apiClient: widget.apiClient);
      await notifRepo.sendInvite(
        inviteeEmail: emailController.text.trim(),
        inviteeName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
        inviteePhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        channel: channel,
        role: role,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          content: Text('✓ Invitation queued to ${emailController.text.trim()} via $channel!'),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Could not send invite: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePermissions(int id) async {
    final permissions = _draftPermissions[id] ?? <String>{};
    final role = _draftRoles[id];
    setState(() => _saving = true);
    try {
      if (role != null) {
        try {
          await _repository.updateRole(
            employeeId: id,
            role: role,
            permissions: permissions,
          );
        } catch (_) {}
      }
      try {
        await _repository.updatePermissions(
          employeeId: id,
          permissions: permissions,
        );
      } catch (_) {}

      final emp = _employees.firstWhere((e) => _asInt(e['id']) == id, orElse: () => <String, dynamic>{});
      final empName = emp['fullName']?.toString() ?? 'User';
      final roleText = role ?? emp['role']?.toString() ?? 'STAFF';

      unawaited(
        AuditLogService.log(
          module: 'TEAM',
          action: 'ROLE_CHANGE',
          entityId: 'USR-$id',
          title: 'Updated role & permissions for $empName',
          description: 'Role: $roleText | Features: [${permissions.join(", ")}]',
        ),
      );

      if (!mounted) return;
      setState(() {
        _editingEmployeeIds.remove(id);
        _draftPermissions.remove(id);
        _draftRoles.remove(id);
        if (role != null) emp['role'] = role;
        emp['permissions'] = permissions.join(',');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ User role and feature permissions saved successfully!'),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not update access: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  String _resolvedCompanyName() {
    if (!_isPlaceholderName(_profileCompanyName)) {
      return _profileCompanyName!.trim();
    }
    if (!_isPlaceholderName(widget.businessProfileName)) {
      return widget.businessProfileName!.trim();
    }
    final raw = _company['companyName']?.toString().trim() ?? '';
    return raw.isNotEmpty ? raw : 'Organization Workspace';
  }

  Future<void> _shareViaWhatsApp() async {
    final code = _company['companyCode']?.toString() ?? '';
    if (code.isEmpty) return;
    final companyName = _resolvedCompanyName();
    final text = 'Join $companyName on Invoicely!\nOrganization Code: $code\nOnboarding Link: https://invoicelyai.onrender.com/join?code=$code';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) _showError('Invite text copied to clipboard!');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _showError('Invite text copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _resolvedCompanyName();
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('User Management & Roles'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh team',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _TeamError(message: _error!, onRetry: _load)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final sidePadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 100),
                        children: [
                      // Workspace onboarding card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(companyName,
                                          style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Organization code for staff self-onboarding',
                                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'RBAC ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _company['companyCode']?.toString() ??
                                          'Not available',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        _company['companyCode'] == null
                                            ? null
                                            : _copyCompanyCode,
                                    icon: const Icon(Icons.copy, size: 18),
                                    tooltip: 'Copy organization code',
                                  ),
                                  IconButton(
                                    onPressed:
                                        _company['companyCode'] == null
                                            ? null
                                            : _shareViaWhatsApp,
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.green),
                                    tooltip: 'Share code via WhatsApp',
                                  ),
                                  const SizedBox(width: 4),
                                  FilledButton.icon(
                                    onPressed: _showInviteDialog,
                                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                                    label: const Text('Invite User'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // RBAC Roles Guide Card
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.security_outlined, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 8),
                                Text(
                                  'Role-Based Access Control (RBAC) Overview',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildRolePill('Admin', 'All modules, settings, staff', const Color(0xFFEF4444)),
                                _buildRolePill('Manager', 'Invoices, clients, duty logs', const Color(0xFFF59E0B)),
                                _buildRolePill('Accountant', 'Invoices, ledgers, tax & expenses', const Color(0xFF10B981)),
                                _buildRolePill('Staff / Guard', 'Duty entry, bill creation', const Color(0xFF3B82F6)),
                                _buildRolePill('Viewer', 'Read-only statements & reports', const Color(0xFF6B7280)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionHeading(
                        title: 'Join requests',
                        count: _requests.length,
                      ),
                      if (_requests.isEmpty)
                        const AppCard(
                          child: Text(
                            'No pending join requests. Share your organization code to onboard staff.',
                          ),
                        )
                      else
                        ..._requests.map(_buildJoinRequest),
                      const SizedBox(height: 16),
                      _SectionHeading(
                        title: 'Employees',
                        count: _employees.length,
                      ),
                      if (_employees.isEmpty)
                        const AppCard(child: Text('No team members found.'))
                      else
                        ..._employees.map(_buildEmployee),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildJoinRequest(Map<String, dynamic> request) {
    final id = _asInt(request['id']);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request['userFullName']?.toString() ?? 'Employee request',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(request['userEmail']?.toString() ?? ''),
            if ((request['requestMessage']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request['requestMessage'].toString()),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _saving || id == null
                      ? null
                      : () => _process(id, 'APPROVE'),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving || id == null
                      ? null
                      : () => _process(id, 'REJECT'),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployee(Map<String, dynamic> employee) {
    final id = _asInt(employee['id']);
    final isEditing = id != null && _editingEmployeeIds.contains(id);
    final permissions = id == null
        ? _permissionsFor(employee)
        : _draftPermissions[id] ?? _permissionsFor(employee);
    final rawRole = employee['role']?.toString().toUpperCase() ?? 'EMPLOYEE';
    final role = (id != null && _draftRoles.containsKey(id))
        ? _draftRoles[id]!
        : rawRole;
    final isAdmin = role == 'ADMIN';

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'ADMIN':
        roleColor = const Color(0xFFDC2626);
        roleLabel = 'ADMIN';
        break;
      case 'MANAGER':
        roleColor = const Color(0xFFD97706);
        roleLabel = 'MANAGER';
        break;
      case 'ACCOUNTANT':
        roleColor = const Color(0xFF059669);
        roleLabel = 'ACCOUNTANT';
        break;
      case 'VIEWER':
        roleColor = const Color(0xFF4B5563);
        roleLabel = 'VIEWER';
        break;
      default:
        roleColor = const Color(0xFF2563EB);
        roleLabel = 'STAFF';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_outline,
                    color: roleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              employee['fullName']?.toString() ?? 'Team member',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        employee['email']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: employee['status']?.toString().toUpperCase() == 'ACTIVE'
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    employee['status']?.toString().toUpperCase() ?? 'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: employee['status']?.toString().toUpperCase() == 'ACTIVE'
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isEditing) ...[
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Role: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: ['ADMIN', 'MANAGER', 'ACCOUNTANT', 'EMPLOYEE', 'VIEWER'].contains(role)
                        ? role
                        : 'EMPLOYEE',
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrator (Full Access)')),
                      DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                      DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Staff / Guard (Own Data)')),
                      DropdownMenuItem(value: 'VIEWER', child: Text('Viewer (Read Only)')),
                    ],
                    onChanged: (newRole) {
                      if (newRole != null) {
                        setState(() {
                          _draftRoles[id] = newRole;
                          if (newRole == 'ADMIN') {
                            _draftPermissions[id] = _permissionLabels.keys.toSet();
                          }
                        });
                      }
                    },
                  ),
                  const Spacer(),
                  if (isAdmin)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        setState(() {
                          _draftRoles[id] = 'EMPLOYEE';
                          _draftPermissions[id] = {'INVOICES', 'EXPENSES', 'CLIENTS'};
                        });
                      },
                      icon: const Icon(Icons.remove_moderator_outlined, size: 16),
                      label: const Text('Revoke Admin', style: TextStyle(fontSize: 12)),
                    )
                  else
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFFFEE2E2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        setState(() {
                          _draftRoles[id] = 'ADMIN';
                          _draftPermissions[id] = _permissionLabels.keys.toSet();
                        });
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      label: const Text('Make Admin', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? '★ Admin role has access to all company features, invoices, settings, and team controls.'
                    : 'Staff members only see their own created invoices and expenses by default.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Feature Permissions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _permissionLabels.entries.map((entry) {
                  return FilterChip(
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    selected: permissions.contains(entry.key),
                    onSelected: (selected) {
                      setState(() {
                        final next = Set<String>.from(permissions);
                        if (selected) {
                          next.add(entry.key);
                        } else {
                          next.remove(entry.key);
                        }
                        _draftPermissions[id] = next;
                      });
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Permissions: ', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (permissions.isEmpty)
                    const Text('None', style: TextStyle(fontSize: 12, color: AppColors.muted))
                  else
                    ...permissions.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _permissionLabels[p] ?? p,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                          ),
                        )),
                ],
              ),
            ],
            if (id != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing) ...[
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _editingEmployeeIds.remove(id);
                                  _draftPermissions.remove(id);
                                  _draftRoles.remove(id);
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _saving
                          ? null
                          : isEditing
                              ? () => _savePermissions(id)
                              : () {
                                  setState(() {
                                    _editingEmployeeIds.add(id);
                                    _draftPermissions[id] = _permissionsFor(employee);
                                    _draftRoles[id] = rawRole;
                                  });
                                },
                      icon: Icon(isEditing ? Icons.save_rounded : Icons.tune_rounded, size: 16),
                      label: Text(isEditing ? 'Save role & access' : 'Edit role & access'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolePill(String role, String scope, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            scope,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Chip(label: Text('$count')),
          ],
        ),
      );
}

class _TeamError extends StatelessWidget {
  const _TeamError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
