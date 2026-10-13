import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../data/models/auth_models.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../ai/presentation/ai_chat_screen.dart';
import '../../invoices/invoice_feature.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tax/presentation/tax_calculator_screen.dart';
import '../../team/presentation/team_management_screen.dart';
import '../../templates/data/template_config.dart';
import '../../templates/presentation/invoice_template_studio_screen.dart';
import '../../employees/presentation/employee_management_screen.dart';
import '../../settings/presentation/email_scheduler_settings_screen.dart';
import '../../audit/presentation/audit_logs_screen.dart';
import '../../payroll/data/payroll_repository.dart';
import '../../payroll/presentation/payroll_screen.dart';
import 'placeholder_screen.dart';

enum _Destination {
  dashboard('Dashboard', Icons.dashboard_outlined),
  invoices('Invoices', Icons.receipt_long_outlined),
  aiAgent('AI Agent', Icons.auto_awesome_outlined),
  expenses('Expenses', Icons.payments_outlined),
  templates('Templates', Icons.auto_awesome_mosaic_outlined),
  menu('More', Icons.menu);

  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.onLogout,
    required this.apiClient,
    required this.dashboardRepository,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;
  final ApiClient apiClient;
  final DashboardRepository dashboardRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Destination _destination = _Destination.dashboard;
  String? _moreSection;
  String _invoiceStatusFilter = 'All';
  late final LocalPreferences _localPreferences;
  TemplateConfig? _preferredTemplate;
  Map<String, Object?> _invoiceLocalSettings = <String, Object?>{};
  bool _invoiceFullscreen = false;

  @override
  void initState() {
    super.initState();
    final accountScope = widget.session.company?.id ??
        widget.session.user.companyId ??
        widget.session.user.email;
    _localPreferences = LocalPreferences(scope: '$accountScope');
    unawaited(_loadLocalSettings());
  }

  Future<void> _loadLocalSettings() async {
    try {
      final templateJson = await _localPreferences.readString('template');
      final template = TemplateConfig.tryDecode(templateJson);
      final invoiceSettings =
          await _localPreferences.readMap('invoice_settings');
      final merged = Map<String, Object?>.from(invoiceSettings);

      // Fetch server business profile to sync currency and business defaults if missing or updated
      try {
        final profile = await SettingsRepository(apiClient: widget.apiClient).loadProfile();
        if (profile.isNotEmpty) {
          final cur = profile['defaultCurrency']?.toString();
          if (cur != null && cur.isNotEmpty) {
            merged['defaultCurrency'] = cur;
            merged['defaultCurrencySymbol'] = profile['defaultCurrencySymbol']?.toString() ??
                (cur == 'INR' ? '₹' : (cur == 'USD' ? r'$' : cur));
            merged['defaultCurrencyFormat'] = profile['defaultCurrencyFormat']?.toString() ?? 'before';
          }
          final bName = profile['businessName']?.toString().trim().isNotEmpty == true
              ? profile['businessName'].toString().trim()
              : (profile['companyName']?.toString().trim().isNotEmpty == true
                  ? profile['companyName'].toString().trim()
                  : (profile['legalName']?.toString().trim().isNotEmpty == true
                      ? profile['legalName'].toString().trim()
                      : null));
          if (bName != null && bName.isNotEmpty) {
            merged['businessName'] = bName;
            merged['companyName'] = bName;
          }
          if (profile['address'] != null) merged['businessAddress'] ??= profile['address'];
          if (profile['gstin'] != null) merged['businessGstin'] ??= profile['gstin'];
          if (profile['panNumber'] != null) merged['businessPan'] ??= profile['panNumber'];
          if (profile['phone'] != null) merged['businessPhone'] ??= profile['phone'];
          if (profile['email'] != null) merged['businessEmail'] ??= profile['email'];
          if (profile['upiId'] != null) merged['upiId'] ??= profile['upiId'];
          if (profile['bankName'] != null) merged['bankName'] ??= profile['bankName'];
          if (profile['accountNumber'] != null) merged['accountNumber'] ??= profile['accountNumber'];
          if (profile['accountHolder'] != null) merged['accountHolder'] ??= profile['accountHolder'];
          if (profile['ifscCode'] != null) merged['ifscCode'] ??= profile['ifscCode'];
        }
      } catch (_) {}

      // Default currency to INR if still unset
      merged.putIfAbsent('defaultCurrency', () => 'INR');
      merged.putIfAbsent('defaultCurrencySymbol', () => '₹');

      if (!mounted) return;
      setState(() {
        _preferredTemplate = template;
        _invoiceLocalSettings = merged;
      });
      await _localPreferences.writeMap('invoice_settings', merged);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not restore local invoice settings: $error');
    }
  }

  Future<void> _saveTemplate(TemplateConfig template) async {
    try {
      await _localPreferences.writeString('template', template.encode());
      if (mounted) {
        setState(() {
          _preferredTemplate = template;
        });
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save invoice template: $error');
    }
  }

  Future<void> _saveInvoiceSettings(Map<String, Object?> settings) async {
    try {
      await _localPreferences.writeMap('invoice_settings', settings);
      if (mounted) {
        setState(() {
          _invoiceLocalSettings = Map<String, Object?>.from(settings);
        });
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save invoice settings: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final page = _buildPage();
    if (!isWide) {
      final showBottomBar = !_invoiceFullscreen &&
          !(_destination == _Destination.menu && _moreSection != null);
      return PopScope(
        canPop: _destination == _Destination.dashboard && _moreSection == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_moreSection != null) {
            setState(() => _moreSection = null);
          } else if (_destination != _Destination.dashboard) {
            setState(() {
              _destination = _Destination.dashboard;
              _moreSection = null;
            });
          }
        },
        child: Scaffold(
          body: page,
          bottomNavigationBar: showBottomBar ? _buildMobileBottomBar() : null,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _destination.index,
            onDestinationSelected: (index) => setState(() {
              _destination = _Destination.values[index];
              _moreSection = null;
              if (_destination == _Destination.invoices) {
                _invoiceStatusFilter = 'All';
              }
            }),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 32,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1F00F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F2FE), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: Color(0xFF00F2FE)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 58),
                          child: Text(
                            widget.session.company?.code ?? 'Workspace',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00F2FE),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            destinations: [
              for (final item in _Destination.values)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: page),
        ],
      ),
    );
  }

  Widget _buildPage() {
    return switch (_destination) {
      _Destination.dashboard => DashboardScreen(
          session: widget.session,
          repository: widget.dashboardRepository,
          localSettings: _invoiceLocalSettings,
          registeredCompanyName: _invoiceLocalSettings['businessName']?.toString().trim().isNotEmpty == true
              ? _invoiceLocalSettings['businessName']!.toString().trim()
              : (_invoiceLocalSettings['companyName']?.toString().trim().isNotEmpty == true
                  ? _invoiceLocalSettings['companyName']!.toString().trim()
                  : widget.session.company?.name),
          onLogout: widget.onLogout,
          onCreateInvoice: () => setState(() {
            _invoiceStatusFilter = 'All';
            _destination = _Destination.invoices;
          }),
          onViewInvoices: (status) => setState(() {
            _invoiceStatusFilter = status;
            _destination = _Destination.invoices;
          }),
          onViewClients: () => setState(() {
            _destination = _Destination.menu;
            _moreSection = 'Clients';
          }),
          onViewExpenses: () => setState(
            () => _destination = _Destination.expenses,
          ),
          onOpenAiChat: () => setState(
            () => _destination = _Destination.aiAgent,
          ),
          onOpenTemplates: () => setState(() {
            _destination = _Destination.templates;
            _moreSection = null;
          }),
          onOpenPayroll: () => _openMoreSection('Payroll & Disbursals'),
          onOpenAuditLogs: () => _openMoreSection('Audit Logs'),
        ),
      _Destination.invoices => InvoiceFeatureScreen(
          key: ValueKey('invoices-$_invoiceStatusFilter'),
          apiClient: widget.apiClient,
          preferredTemplate: _preferredTemplate,
          localSettings: _invoiceLocalSettings,
          onOpenBusinessSettings: _openBusinessSettings,
          onSaveLocalSettings: _saveInvoiceSettings,
          initialStatusFilter: _invoiceStatusFilter,
          onFullscreenChanged: (fullscreen) =>
              setState(() => _invoiceFullscreen = fullscreen),
        ),
      _Destination.aiAgent => AiChatScreen(
          apiClient: widget.apiClient,
          accountScope:
              '${widget.session.company?.id ?? widget.session.user.companyId ?? widget.session.user.email}:${widget.session.user.email.toLowerCase()}',
        ),
      _Destination.expenses => _buildExpenses(),
      _Destination.templates => InvoiceTemplateStudioScreen(
          apiClient: widget.apiClient,
          initialConfig: _preferredTemplate,
          initialLocalSettings: _invoiceLocalSettings,
          onSaveLocalSettings: _saveInvoiceSettings,
          onSaveTemplate: _saveTemplate,
          onBack: () => setState(() => _destination = _Destination.dashboard),
        ),
      _Destination.menu => _buildMorePage(),
    };
  }

  Widget _buildMorePage() {
    final section = _moreSection;
    if (section == null) {
      return _MoreMenu(
        session: widget.session,
        onSelect: (value) => setState(() => _moreSection = value),
        onLogout: widget.onLogout,
      );
    }
    void onBack() => setState(() => _moreSection = null);
    return switch (section) {
      'Payroll & Disbursals' || 'Payroll' || 'Employee Payroll' => PayrollScreen(
          repository: PayrollRepository(client: widget.apiClient),
          onBack: onBack,
        ),
      'Employee management' => EmployeeManagementScreen(
          apiClient: widget.apiClient,
          companyName: _invoiceLocalSettings['businessName']?.toString() ??
              _invoiceLocalSettings['companyName']?.toString() ??
              widget.session.company?.name ??
              '',
          companyAddress: _invoiceLocalSettings['businessAddress']?.toString() ?? '',
          onBack: onBack,
        ),
      'Email & Reminders' || 'Email Settings & Reminders' => EmailSchedulerSettingsScreen(
          apiClient: widget.apiClient,
          localPreferences: _localPreferences,
          onBack: onBack,
        ),
      'Clients' => ClientsScreen(
          repository: ClientsRepository(apiClient: widget.apiClient),
          onBack: onBack,
        ),
      'Reports' => ReportsScreen(apiClient: widget.apiClient, onBack: onBack),
      'Audit Logs' || 'Audit logs' => AuditLogsScreen(
          apiClient: widget.apiClient,
          session: widget.session,
          onBack: onBack,
        ),
      'Team management' =>
        TeamManagementScreen(apiClient: widget.apiClient, onBack: onBack),
      'Templates' ||
      'Invoice settings' ||
      'Invoice & Template Studio' ||
      'Invoice & Template Settings' =>
        InvoiceTemplateStudioScreen(
          apiClient: widget.apiClient,
          initialConfig: _preferredTemplate,
          initialLocalSettings: _invoiceLocalSettings,
          onSaveLocalSettings: _saveInvoiceSettings,
          onSaveTemplate: _saveTemplate,
          onBack: onBack,
        ),
      'Settings' || 'Business Settings' || 'Business settings' => SettingsScreen(
          apiClient: widget.apiClient,
          localPreferences: _localPreferences,
          initialLocalSettings: _invoiceLocalSettings,
          onSaveLocalSettings: (settings) => setState(
            () => _invoiceLocalSettings = Map<String, Object?>.from(settings),
          ),
          onBack: onBack,
        ),
      'Tax calculator' => TaxCalculatorScreen(onBack: onBack),
      _ => PlaceholderScreen(
          title: section,
          description: '$section is not supported yet.',
          icon: Icons.construction_outlined,
          onBack: onBack,
          onLogout: widget.onLogout,
        ),
    };
  }

  void _openMoreSection(String section) => setState(() {
        _destination = _Destination.menu;
        _moreSection = section;
      });

  Future<void> _openBusinessSettings() => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (routeContext) => SettingsScreen(
            apiClient: widget.apiClient,
            localPreferences: _localPreferences,
            initialLocalSettings: _invoiceLocalSettings,
            onSaveLocalSettings: (settings) => setState(
              () => _invoiceLocalSettings = Map<String, Object?>.from(settings),
            ),
            onBack: () => Navigator.of(routeContext).pop(),
          ),
        ),
      );

  Widget _buildExpenses() => ExpensesScreen(
        repository: ExpensesRepository(apiClient: widget.apiClient),
        initialLocalSettings: _invoiceLocalSettings,
      );

  Widget _buildMobileBottomBar() {
    const activeColor = Color(0xFF2563EB);
    const inactiveColor = Color(0xFF64748B);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Invoices
              _buildBottomNavItem(
                icon: Icons.description_outlined,
                isSelected: _destination == _Destination.invoices,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => setState(() {
                  _destination = _Destination.invoices;
                  _moreSection = null;
                  _invoiceStatusFilter = 'All';
                }),
              ),

              // 2. Center Prominent Plus Button
              GestureDetector(
                onTap: _showQuickCreateSheet,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),

              // 3. Clients
              _buildBottomNavItem(
                icon: Icons.people_outline_rounded,
                isSelected: _destination == _Destination.menu && _moreSection == 'Clients',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => setState(() {
                  _destination = _Destination.menu;
                  _moreSection = 'Clients';
                }),
              ),

              // 4. More / Grid
              _buildBottomNavItem(
                icon: Icons.grid_view_rounded,
                isSelected: _destination == _Destination.menu && _moreSection != 'Clients',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => setState(() {
                  _destination = _Destination.menu;
                  _moreSection = null;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showQuickCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Create',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            _quickActionTile(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFEFF6FF),
              title: 'Create Invoice',
              subtitle: 'Draft a new client invoice or quotation',
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _destination = _Destination.invoices;
                  _invoiceStatusFilter = 'All';
                });
              },
            ),
            const SizedBox(height: 8),
            _quickActionTile(
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              title: 'Record Expense',
              subtitle: 'Add a business receipt or operational expense',
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() => _destination = _Destination.expenses);
              },
            ),
            const SizedBox(height: 8),
            _quickActionTile(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFE0F2FE),
              title: 'Add New Client',
              subtitle: 'Register customer details, GSTIN and billing address',
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _destination = _Destination.menu;
                  _moreSection = 'Clients';
                });
              },
            ),
            const SizedBox(height: 8),
            _quickActionTile(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFF3E8FF),
              title: 'Add Employee / Staff',
              subtitle: 'Onboard guard, supervisor, or field personnel',
              onTap: () {
                Navigator.of(ctx).pop();
                _openMoreSection('Employee management');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.session,
    required this.onSelect,
    required this.onLogout,
  });

  final AuthSession session;
  final ValueChanged<String> onSelect;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isAdmin = session.user.role.toUpperCase() == 'ADMIN';
    final canSeeInvoices = session.user.hasPermission('INVOICES');
    final canSeeAuditLogs = isAdmin || session.user.hasPermission('AUDIT_LOGS');
    final sections = <(String, IconData)>[
      if (session.user.hasPermission('CLIENTS'))
        ('Clients', Icons.people_outline),
      if (session.user.hasPermission('REPORTS'))
        ('Reports', Icons.bar_chart_outlined),
      if (canSeeAuditLogs)
        ('Audit Logs', Icons.history_edu_rounded),
      if (isAdmin)
        ('Payroll & Disbursals', Icons.account_balance_wallet_outlined),
      if (isAdmin) ('Employee management', Icons.badge_outlined),
      if (isAdmin) ('Team management', Icons.groups_outlined),
      if (isAdmin || canSeeInvoices)
        ('Invoice & Template Studio', Icons.tune_rounded),
      if (isAdmin) ('Business Settings', Icons.settings_outlined),
      if (isAdmin) ('Email & Reminders', Icons.alarm_on_rounded),
      ('Tax calculator', Icons.calculate_outlined),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'More',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: onLogout,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF0F172A)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(section.$2, color: const Color(0xFF334155), size: 22),
                title: Text(
                  section.$1,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onTap: () => onSelect(section.$1),
              ),
            ),
        ],
      ),
    );
  }
}
