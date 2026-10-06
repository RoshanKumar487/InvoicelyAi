import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/team_repository.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({
    required this.apiClient,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback? onBack;

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamRepository _repository;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _company = <String, dynamic>{};
  List<Map<String, dynamic>> _employees = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];
  final Set<int> _editingEmployeeIds = <int>{};
  final Map<int, Set<String>> _draftPermissions = <int, Set<String>>{};

  static const _permissionLabels = <String, String>{
    'INVOICES': 'Invoices',
    'EXPENSES': 'Expenses',
    'CLIENTS': 'Clients',
    'REPORTS': 'Reports',
  };

  @override
  void initState() {
    super.initState();
    _repository = TeamRepository(apiClient: widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object>([
        _repository.loadCompany(),
        _repository.loadEmployees(),
        _repository.loadJoinRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _company = result[0] as Map<String, dynamic>;
        _employees = result[1] as List<Map<String, dynamic>>;
        _requests = result[2] as List<Map<String, dynamic>>;
        _loading = false;
        _draftPermissions.clear();
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
    setState(() => _saving = true);
    try {
      await _repository.processJoinRequest(id: id, action: action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${action.toLowerCase()}d.')),
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

  Future<void> _savePermissions(int id) async {
    final permissions = _draftPermissions[id] ?? <String>{};
    setState(() => _saving = true);
    try {
      await _repository.updatePermissions(
        employeeId: id,
        permissions: permissions,
      );
      if (!mounted) return;
      setState(() {
        _editingEmployeeIds.remove(id);
        _draftPermissions.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee access updated.')),
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

  @override
  Widget build(BuildContext context) {
    final companyName =
        _company['companyName']?.toString() ?? 'Organization Workspace';
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('Team & Join Requests'),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(companyName,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            const Text(
                              'Organization code',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _company['companyCode']?.toString() ??
                                        'Not available',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      _company['companyCode'] == null
                                          ? null
                                          : _copyCompanyCode,
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy organization code',
                                ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['fullName']?.toString() ?? 'Team member',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(employee['email']?.toString() ?? ''),
                    ],
                  ),
                ),
                Text(employee['status']?.toString() ?? ''),
              ],
            ),
            const SizedBox(height: 8),
            if (isEditing)
              Wrap(
                spacing: 6,
                children: _permissionLabels.entries.map((entry) {
                  return FilterChip(
                    label: Text(entry.value),
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
              )
            else
              Text(
                'Access: ${permissions.map((value) => _permissionLabels[value]).join(', ').ifEmpty('None')}',
                style: const TextStyle(color: AppColors.muted),
              ),
            if (id != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving
                      ? null
                      : isEditing
                          ? () => _savePermissions(id)
                          : () {
                              setState(() {
                                _editingEmployeeIds.add(id);
                                _draftPermissions[id] =
                                    _permissionsFor(employee);
                              });
                            },
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.tune),
                  label: Text(isEditing ? 'Save access' : 'Edit access'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

extension on String {
  String ifEmpty(String replacement) => isEmpty ? replacement : this;
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
