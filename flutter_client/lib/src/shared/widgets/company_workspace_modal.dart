import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../data/models/auth_models.dart';

class CompanyWorkspaceModal extends StatefulWidget {
  const CompanyWorkspaceModal({
    required this.currentSession,
    required this.apiClient,
    required this.onWorkspaceSwitched,
    super.key,
  });

  final AuthSession currentSession;
  final ApiClient apiClient;
  final ValueChanged<AuthSession> onWorkspaceSwitched;

  static Future<void> show({
    required BuildContext context,
    required AuthSession currentSession,
    required ApiClient apiClient,
    required ValueChanged<AuthSession> onWorkspaceSwitched,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (context) => CompanyWorkspaceModal(
        currentSession: currentSession,
        apiClient: apiClient,
        onWorkspaceSwitched: onWorkspaceSwitched,
      ),
    );
  }

  @override
  State<CompanyWorkspaceModal> createState() => _CompanyWorkspaceModalState();
}

class _CompanyWorkspaceModalState extends State<CompanyWorkspaceModal> {
  bool _isLoading = true;
  String? _error;
  List<CompanySummary> _companies = [];
  bool _isCreatingNew = false;
  bool _isEditingCurrent = false;

  // New Workspace form controllers
  final _newCompanyNameController = TextEditingController();
  final _newGstinController = TextEditingController();
  final _newLocationController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newPhoneController = TextEditingController();

  // Edit Workspace form controllers
  late final TextEditingController _editNameController;
  late final TextEditingController _editGstinController;
  late final TextEditingController _editLocationController;
  late final TextEditingController _editEmailController;
  late final TextEditingController _editPhoneController;
  late final TextEditingController _editWebsiteController;

  @override
  void initState() {
    super.initState();
    final currentComp = widget.currentSession.company;
    _editNameController = TextEditingController(text: currentComp?.name ?? '');
    _editGstinController = TextEditingController(text: currentComp?.gstin ?? '');
    _editLocationController = TextEditingController(text: currentComp?.location ?? '');
    _editEmailController = TextEditingController(text: currentComp?.email ?? '');
    _editPhoneController = TextEditingController(text: currentComp?.phone ?? '');
    _editWebsiteController = TextEditingController(text: currentComp?.website ?? '');
    _loadCompanies();
  }

  @override
  void dispose() {
    _newCompanyNameController.dispose();
    _newGstinController.dispose();
    _newLocationController.dispose();
    _newEmailController.dispose();
    _newPhoneController.dispose();

    _editNameController.dispose();
    _editGstinController.dispose();
    _editLocationController.dispose();
    _editEmailController.dispose();
    _editPhoneController.dispose();
    _editWebsiteController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await widget.apiClient.getListJson('api/v1/companies/my-companies');
      if (mounted) {
        setState(() {
          _companies = list.map(CompanySummary.fromJson).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load company workspaces: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchCompany(int companyId) async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.apiClient.postJson('api/v1/companies/switch/$companyId', const {});
      final newSession = AuthSession.fromJson(data);
      if (mounted) {
        widget.onWorkspaceSwitched(newSession);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to switch workspace: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createWorkspace() async {
    final name = _newCompanyNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Company name is required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await widget.apiClient.postJson('api/v1/companies', {
        'companyName': name,
        'gstin': _newGstinController.text.trim(),
        'location': _newLocationController.text.trim(),
        'email': _newEmailController.text.trim(),
        'phone': _newPhoneController.text.trim(),
      });
      final newSession = AuthSession.fromJson(data);
      if (mounted) {
        widget.onWorkspaceSwitched(newSession);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create workspace: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateCompanyProfile() async {
    final name = _editNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Company name is required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedComp = await widget.apiClient.putJson('api/v1/companies/my-company', {
        'companyName': name,
        'gstin': _editGstinController.text.trim(),
        'location': _editLocationController.text.trim(),
        'email': _editEmailController.text.trim(),
        'phone': _editPhoneController.text.trim(),
        'website': _editWebsiteController.text.trim(),
      });
      final compSummary = CompanySummary.fromJson(updatedComp);
      final newSession = AuthSession(
        user: widget.currentSession.user,
        company: compSummary,
      );
      if (mounted) {
        widget.onWorkspaceSwitched(newSession);
        setState(() {
          _isEditingCurrent = false;
          _isLoading = false;
        });
        _loadCompanies();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to update company profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCompanyId = widget.currentSession.company?.id ?? widget.currentSession.user.companyId;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xEB0F172A) : const Color(0xF2FFFFFF),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0x1A1E3A8A),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3300F2FE),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCreatingNew
                                      ? 'Add New Workspace'
                                      : (_isEditingCurrent ? 'Edit Company Profile' : 'Select Workspace / Company'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isCreatingNew
                                      ? 'Set up an isolated business entity'
                                      : (_isEditingCurrent
                                          ? 'Update tax, location & contact details'
                                          : 'Switch between multi-tenant accounts seamlessly'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x26EF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x66EF4444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: _isCreatingNew
                            ? _buildCreateWorkspaceForm()
                            : (_isEditingCurrent ? _buildEditWorkspaceForm() : _buildWorkspaceList(currentCompanyId, isDark)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceList(int? currentCompanyId, bool isDark) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_companies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No registered workspaces found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          )
        else
          for (final comp in _companies) ...[
            _buildCompanyCard(comp, comp.id == currentCompanyId, isDark),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _isEditingCurrent = true;
                  _error = null;
                }),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Edit Active Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => setState(() {
                  _isCreatingNew = true;
                  _error = null;
                }),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('+ New Workspace'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCompanyCard(CompanySummary comp, bool isCurrent, bool isDark) {
    return InkWell(
      onTap: isCurrent ? null : () => comp.id != null ? _switchCompany(comp.id!) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0x1400F2FE)
              : (isDark ? const Color(0x991E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? const Color(0xFF00F2FE) : (isDark ? Colors.white12 : Colors.black12),
            width: isCurrent ? 1.8 : 1.0,
          ),
          boxShadow: isCurrent
              ? const [
                  BoxShadow(
                    color: Color(0x2200F2FE),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isCurrent ? const Color(0xFF00F2FE) : const Color(0xFF3B82F6),
              child: Text(
                comp.name.isNotEmpty ? comp.name[0].toUpperCase() : 'C',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comp.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x3300F2FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Color(0xFF00F2FE),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${comp.code ?? "N/A"}  •  Role: ${comp.role}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  if (comp.gstin != null && comp.gstin!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'GSTIN: ${comp.gstin}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (isCurrent)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE), size: 24)
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateWorkspaceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _newCompanyNameController,
          decoration: const InputDecoration(
            labelText: 'Company / Business Name *',
            hintText: 'e.g. Apex Security Agency Ltd',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newGstinController,
          decoration: const InputDecoration(
            labelText: 'GSTIN / Tax ID',
            hintText: 'e.g. 07AAAAA0000A1Z5',
            prefixIcon: Icon(Icons.receipt_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newLocationController,
          decoration: const InputDecoration(
            labelText: 'Registered Address / Location',
            hintText: 'e.g. Plot 42, Connaught Place, New Delhi',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'Billing Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _newPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _isCreatingNew = false;
                  _error = null;
                }),
                child: const Text('Back to List'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isLoading ? null : _createWorkspace,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create & Activate'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEditWorkspaceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editNameController,
          decoration: const InputDecoration(
            labelText: 'Company Legal Name *',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _editGstinController,
          decoration: const InputDecoration(
            labelText: 'GSTIN / Tax Identification #',
            prefixIcon: Icon(Icons.receipt_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _editLocationController,
          decoration: const InputDecoration(
            labelText: 'Office Address / Location',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _editEmailController,
                decoration: const InputDecoration(
                  labelText: 'Official Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _editPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _editWebsiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            prefixIcon: Icon(Icons.language_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _isEditingCurrent = false;
                  _error = null;
                }),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isLoading ? null : _updateCompanyProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
