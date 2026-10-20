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
  final TextEditingController _globalSearchController = TextEditingController();
  String _selectedDateFilter = 'FY 2025-26';
  final List<DashboardNotificationItem> _shellNotifications = [
    DashboardNotificationItem(
      id: '1',
      title: 'Payment Received',
      message: 'Payment of ₹45,200 received for Invoice #INV-2025-001 from Acme Security',
      timeAgo: '12m ago',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '2',
      title: 'Invoice Overdue Notice',
      message: 'Invoice #INV-2025-004 is overdue by 3 days (₹18,500)',
      timeAgo: '2h ago',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFEF4444),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '3',
      title: 'New Client Onboarded',
      message: 'Metro Guard Logistics profile has been verified and activated',
      timeAgo: 'Yesterday',
      icon: Icons.person_add_alt_1_rounded,
      color: const Color(0xFF0284C7),
      isRead: false,
    ),
    DashboardNotificationItem(
      id: '4',
      title: 'Tax & GST Summary Ready',
      message: 'Monthly GST summary for March 2025 is ready for review',
      timeAgo: '2d ago',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF8B5CF6),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final accountScope = widget.session.company?.id ??
        widget.session.user.companyId ??
        widget.session.user.email;
    _localPreferences = LocalPreferences(scope: '$accountScope');
    unawaited(_loadLocalSettings());
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
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
          if (profile['logoUrl'] != null && profile['logoUrl'].toString().trim().isNotEmpty) {
            merged['invoiceLogo'] = profile['logoUrl'].toString().trim();
          }
          if (profile['stampUrl'] != null && profile['stampUrl'].toString().trim().isNotEmpty) {
            merged['invoiceStamp'] = profile['stampUrl'].toString().trim();
          }
          if (profile['signatureUrl'] != null && profile['signatureUrl'].toString().trim().isNotEmpty) {
            merged['invoiceSignature'] = profile['signatureUrl'].toString().trim();
          }
          if (profile['qrCodeUrl'] != null && profile['qrCodeUrl'].toString().trim().isNotEmpty) {
            merged['invoiceQrCode'] = profile['qrCodeUrl'].toString().trim();
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

      // Restore cached brand assets from local preferences if present
      for (final key in const ['invoiceLogo', 'invoiceStamp', 'invoiceSignature', 'invoiceQrCode']) {
        final val = await _localPreferences.readString(key);
        if (val != null && val.trim().isNotEmpty) {
          merged[key] = val.trim();
        }
      }
      if (merged['invoiceLogo'] == null && merged['logoUrl'] != null) {
        merged['invoiceLogo'] = merged['logoUrl'];
      }
      if (merged['invoiceStamp'] == null && merged['stampUrl'] != null) {
        merged['invoiceStamp'] = merged['stampUrl'];
      }
      if (merged['invoiceSignature'] == null && merged['signatureUrl'] != null) {
        merged['invoiceSignature'] = merged['signatureUrl'];
      }
      if (merged['invoiceQrCode'] == null && merged['qrCodeUrl'] != null) {
        merged['invoiceQrCode'] = merged['qrCodeUrl'];
      }

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
      for (final key in const ['invoiceLogo', 'invoiceStamp', 'invoiceSignature', 'invoiceQrCode']) {
        final val = settings[key]?.toString().trim();
        if (val != null && val.isNotEmpty) {
          await _localPreferences.writeString(key, val);
        }
      }
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
      // Keep bottom navigation bar visible on mobile and tablet screens even during invoice edit/preview
      return PopScope(
        canPop: _destination == _Destination.dashboard && _moreSection == null && !_invoiceFullscreen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_invoiceFullscreen) {
            setState(() => _invoiceFullscreen = false);
            return;
          }
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
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            decoration: AppTheme.neuPillDecoration(radius: 26),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NavigationBar(
                height: 64,
                backgroundColor: AppColors.neuSurface,
                surfaceTintColor: Colors.transparent,
                indicatorColor: const Color(0xFFE2E8F0),
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
                      selectedIcon: Icon(item.icon, color: const Color(0xFF0F172A)),
                      label: item.label,
                    ),
                ],
              ),
            ),
          ),
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
                indicatorColor: const Color(0xFFE2E8F0),
                selectedIconTheme: const IconThemeData(color: Color(0xFF0F172A), size: 22),
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
                      activeColor: const Color(0xFFE2E8F0),
                      shape: BoxShape.rectangle,
                      radius: 15,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 23,
                      color: Color(0xFF0F172A),
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
                                  activeColor: const Color(0xFFE2E8F0),
                                ),
                                child: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: (_destination == _Destination.menu && _moreSection == 'Business Settings')
                                      ? const Color(0xFF0F172A)
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_destination != _Destination.dashboard)
                  _buildDesktopTopNavBar(),
                Expanded(child: page),
              ],
            ),
          ),
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

  void _openBusinessSettings() {
    setState(() {
      _destination = _Destination.menu;
      _moreSection = 'Business Settings';
    });
  }

  Widget _buildDesktopTopNavBar() {
    final registeredName = _invoiceLocalSettings['businessName']?.toString().trim().isNotEmpty == true
        ? _invoiceLocalSettings['businessName']!.toString().trim()
        : (_invoiceLocalSettings['companyName']?.toString().trim().isNotEmpty == true
            ? _invoiceLocalSettings['companyName']!.toString().trim()
            : (widget.session.company?.name.trim().isNotEmpty == true
                ? widget.session.company!.name.trim()
                : 'Your business'));

    final userInitial = widget.session.user.fullName.trim().isNotEmpty
        ? widget.session.user.fullName.trim()[0].toUpperCase()
        : (widget.session.user.email.isNotEmpty
            ? widget.session.user.email[0].toUpperCase()
            : 'R');

    final unreadCount = _shellNotifications.where((n) => !n.isRead).length;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final sideMargin = screenWidth > 900 ? 24.0 : 16.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(sideMargin, 14, sideMargin, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: AppTheme.neuCardDecoration(radius: 20),
      child: Row(
        children: [
          // Company Name TOTALLY on the left
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1736),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    registeredName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),

          // Sub-section back button if in More submenu
          if (_destination == _Destination.menu && _moreSection != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() => _moreSection = null),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFF475569)),
                    SizedBox(width: 5),
                    Text(
                      'More menu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // SPACER to push all actions TOTALLY to the right!
          const Spacer(),

          // Search Field
          Container(
            height: 38,
            width: 270,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _globalSearchController,
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        setState(() {
                          _destination = _Destination.invoices;
                          _invoiceStatusFilter = 'All';
                        });
                      }
                    },
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Search invoices, clients, etc...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // FY Dropdown
          PopupMenuButton<String>(
            tooltip: 'Fiscal Year Filter',
            initialValue: _selectedDateFilter,
            onSelected: (val) => setState(() => _selectedDateFilter = val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'FY 2025-26', child: Text('FY 2025-26 (Apr 2025 - Mar 2026)')),
              PopupMenuItem(value: 'FY 2024-25', child: Text('FY 2024-25 (Apr 2024 - Mar 2025)')),
              PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
              PopupMenuItem(value: 'This Month', child: Text('This Month')),
              PopupMenuItem(value: 'All Time', child: Text('All Time')),
            ],
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    _selectedDateFilter,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Refresh Button
          Tooltip(
            message: 'Sync view',
            child: InkWell(
              onTap: () => setState(() {}),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF334155)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Notifications Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Tooltip(
                message: 'Notifications',
                child: InkWell(
                  onTap: () => DashboardScreen.showNotificationsDialog(
                    context: context,
                    notifications: _shellNotifications,
                    onMarkAllRead: () => setState(() {
                      for (final n in _shellNotifications) {
                        n.isRead = true;
                      }
                    }),
                    onNotificationRead: (_) => setState(() {}),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // User Profile Avatar
          Tooltip(
            message: 'View profile details',
            child: InkWell(
              onTap: () => DashboardScreen.showUserProfileDialog(
                context: context,
                session: widget.session,
                userInitial: userInitial,
                onOpenBusinessSettings: _openBusinessSettings,
                onLogout: widget.onLogout,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenses() => ExpensesScreen(
        repository: ExpensesRepository(apiClient: widget.apiClient),
        initialLocalSettings: _invoiceLocalSettings,
        session: widget.session,
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
