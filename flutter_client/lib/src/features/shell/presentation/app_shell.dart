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
import '../../settings/presentation/invoice_settings_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tax/presentation/tax_calculator_screen.dart';
import '../../team/presentation/team_management_screen.dart';
import '../../templates/data/template_config.dart';
import '../../templates/presentation/templates_screen.dart';
import 'placeholder_screen.dart';

enum _Destination {
  dashboard('Dashboard', Icons.dashboard_outlined),
  invoices('Invoices', Icons.receipt_long_outlined),
  aiAgent('AI Agent', Icons.auto_awesome_outlined),
  expenses('Expenses', Icons.payments_outlined),
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
      if (!mounted) return;
      setState(() {
        _preferredTemplate = template;
        _invoiceLocalSettings = invoiceSettings;
      });
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
      return Scaffold(
        body: page,
        bottomNavigationBar: showBottomBar
            ? NavigationBar(
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
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              )
            : null,
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
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: Color(0xFF1E3A8A),
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
          onOpenTemplates: () => _openMoreSection('Templates'),
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
      'Clients' => ClientsScreen(
          repository: ClientsRepository(apiClient: widget.apiClient),
          onBack: onBack,
        ),
      'Reports' => ReportsScreen(apiClient: widget.apiClient, onBack: onBack),
      'Team management' =>
        TeamManagementScreen(apiClient: widget.apiClient, onBack: onBack),
      'Templates' => TemplatesScreen(
          apiClient: widget.apiClient,
          initialConfig: _preferredTemplate,
          initialLocalSettings: _invoiceLocalSettings,
          onSaveLocalSettings: _saveInvoiceSettings,
          onBack: onBack,
          onSave: _saveTemplate,
        ),
      'Settings' => SettingsScreen(
          apiClient: widget.apiClient,
          localPreferences: _localPreferences,
          initialLocalSettings: _invoiceLocalSettings,
          onSaveLocalSettings: (settings) => setState(
            () => _invoiceLocalSettings = Map<String, Object?>.from(settings),
          ),
          onBack: onBack,
        ),
      'Invoice settings' => InvoiceSettingsScreen(
          apiClient: widget.apiClient,
          initialLocalSettings: _invoiceLocalSettings,
          onBack: onBack,
          onSaveLocalSettings: _saveInvoiceSettings,
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
    final sections = <(String, IconData)>[
      if (session.user.hasPermission('CLIENTS'))
        ('Clients', Icons.people_outline),
      if (session.user.hasPermission('REPORTS'))
        ('Reports', Icons.bar_chart_outlined),
      if (isAdmin) ('Team management', Icons.groups_outlined),
      if (canSeeInvoices) ('Templates', Icons.dashboard_customize_outlined),
      if (isAdmin) ('Settings', Icons.settings_outlined),
      if (isAdmin) ('Invoice settings', Icons.tune_outlined),
      ('Tax calculator', Icons.calculate_outlined),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: [
          IconButton(
            onPressed: onLogout,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final section in sections)
            Card(
              child: ListTile(
                leading: Icon(section.$2),
                title: Text(section.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelect(section.$1),
              ),
            ),
        ],
      ),
    );
  }
}
