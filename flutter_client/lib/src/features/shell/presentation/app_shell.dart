import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../data/models/auth_models.dart';
import '../../../theme/app_theme.dart';
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
  dashboard('Dashboard', Icons.grid_view_rounded),
  invoices('Invoices', Icons.receipt_long_rounded),
  aiAgent('AI Agent', Icons.auto_awesome_rounded),
  expenses('Expenses', Icons.account_balance_wallet_rounded),
  menu('More', Icons.tune_rounded);

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

      // Fetch server business profile to sync currency, branding assets, and business defaults per organization
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
          if (bName != null &&
              bName.isNotEmpty &&
              bName.toLowerCase() != 'apex nova dynamics' &&
              bName.toLowerCase() != 'northstar security services pvt. ltd.') {
            merged['businessName'] = bName;
            merged['companyName'] = bName;
          }
          if (profile['address'] != null) merged['businessAddress'] = profile['address'];
          if (profile['gstin'] != null) merged['businessGstin'] = profile['gstin'];
          if (profile['panNumber'] != null) merged['businessPan'] = profile['panNumber'];
          if (profile['phone'] != null) merged['businessPhone'] = profile['phone'];
          if (profile['email'] != null) merged['businessEmail'] = profile['email'];
          if (profile['upiId'] != null) merged['upiId'] = profile['upiId'];
          if (profile['bankName'] != null) merged['bankName'] = profile['bankName'];
          if (profile['accountNumber'] != null) merged['accountNumber'] = profile['accountNumber'];
          if (profile['accountHolder'] != null) merged['accountHolder'] = profile['accountHolder'];
          if (profile['ifscCode'] != null) merged['ifscCode'] = profile['ifscCode'];
          for (final assetKey in const ['logoUrl', 'stampUrl', 'signatureUrl', 'qrCodeUrl']) {
            final val = profile[assetKey]?.toString().trim() ?? '';
            if (val.isNotEmpty) {
              merged[assetKey] = val;
            }
          }
        }
      } catch (_) {}

      // Fetch organization-scoped template settings & section boolean selections from backend
      try {
        final tplRes = await widget.apiClient.getJson('api/v1/templates/settings');
        final tplData = tplRes['data'] is Map<String, dynamic>
            ? tplRes['data'] as Map<String, dynamic>
            : tplRes;
        if (tplData.isNotEmpty) {
          final settingsStr = tplData['settingsJson']?.toString();
          if (settingsStr != null && settingsStr.isNotEmpty) {
            try {
              final parsedSettings = jsonDecode(settingsStr);
              if (parsedSettings is Map<String, dynamic>) {
                merged.addAll(parsedSettings);
              }
            } catch (_) {}
          }
          final configStr = tplData['configurationJson']?.toString();
          if (configStr != null && configStr.isNotEmpty) {
            merged['studio_sections_json'] = configStr;
          }
          if (tplData['orgCode'] != null) merged['orgCode'] = tplData['orgCode'];
          if (tplData['createdBy'] != null) merged['createdBy'] = tplData['createdBy'];
          if (tplData['updatedBy'] != null) merged['updatedBy'] = tplData['updatedBy'];
          for (final key in const [
            'secBrandingEnabled',
            'secInvoiceDetailsEnabled',
            'secBillToEnabled',
            'secShipToEnabled',
            'secServicesEnabled',
            'secTaxTotalsEnabled',
            'secBankPaymentEnabled',
            'secAdjustmentsEnabled',
            'secTermsNotesEnabled',
            'secSignatureEnabled',
            'letterheadEnabled',
            'showQrCode',
          ]) {
            if (tplData[key] is bool) {
              merged[key] = tplData[key];
            }
          }
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
          backgroundColor: AppColors.background,
          body: page,
          bottomNavigationBar: showBottomBar
              ? Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  decoration: AppTheme.neuPillDecoration(radius: 26),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: NavigationBar(
                      height: 64,
                      backgroundColor: AppColors.neuSurface,
                      surfaceTintColor: Colors.transparent,
                      indicatorColor: const Color(0xFF2B3548),
                      selectedIndex: _destination.index,
                      onDestinationSelected: (index) => setState(() {
                        _destination = _Destination.values[index];
                        _moreSection = null;
                        _invoiceFullscreen = false;
                        if (_destination == _Destination.invoices) {
                          _invoiceStatusFilter = 'All';
                        }
                      }),
                      destinations: [
                        for (final item in _Destination.values)
                          NavigationDestination(
                            icon: Icon(item.icon, color: const Color(0xFF64748B)),
                            selectedIcon: Icon(item.icon, color: Colors.white),
                            label: item.label,
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            decoration: AppTheme.neuCardDecoration(radius: 26),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NavigationRail(
                backgroundColor: AppColors.neuSurface,
                indicatorColor: const Color(0xFF2B3548),
                selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
                unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B), size: 21),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
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
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: AppTheme.neuOrbDecoration(
                      active: true,
                      activeColor: const Color(0xFF2B3548),
                      shape: BoxShape.rectangle,
                      radius: 15,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 23,
                      color: Colors.white,
                    ),
                  ),
                ),
                destinations: [
                  for (final item in _Destination.values)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ),
                ],
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Business Settings Icon in down of side menu (Desktop only)
                          Tooltip(
                            message: 'Business Settings',
                            child: InkWell(
                              onTap: _openBusinessSettings,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: AppTheme.neuOrbDecoration(
                                  active: _destination == _Destination.menu && _moreSection == 'Business Settings',
                                  activeColor: const Color(0xFF2B3548),
                                ),
                                child: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: (_destination == _Destination.menu && _moreSection == 'Business Settings')
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Logout Icon above/below matching more menu
                          Tooltip(
                            message: 'Sign out',
                            child: InkWell(
                              onTap: widget.onLogout,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: AppTheme.neuOrbDecoration(),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  size: 19,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
          onOpenTemplates: () => _openMoreSection('Invoice & Template Studio'),
          onOpenPayroll: () => _openMoreSection('Payroll & Disbursals'),
          onOpenAuditLogs: () => _openMoreSection('Audit Logs'),
          onOpenBusinessSettings: _openBusinessSettings,
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
      'Team management' => TeamManagementScreen(
          apiClient: widget.apiClient,
          businessProfileName: _invoiceLocalSettings['businessName']?.toString() ??
              _invoiceLocalSettings['companyName']?.toString(),
          onBack: onBack,
        ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Workspace & Tools',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: AppTheme.neuOrbDecoration(),
                child: const Icon(Icons.logout_rounded, color: Color(0xFF1E293B), size: 19),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: AppTheme.neuPillDecoration(radius: 26),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: AppTheme.neuOrbDecoration(),
                  child: Icon(section.$2, color: const Color(0xFF334155), size: 20),
                ),
                title: Text(
                  section.$1,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: AppTheme.neuOrbDecoration(),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF475569),
                    size: 18,
                  ),
                ),
                onTap: () => onSelect(section.$1),
              ),
            ),
        ],
      ),
    );
  }
}
