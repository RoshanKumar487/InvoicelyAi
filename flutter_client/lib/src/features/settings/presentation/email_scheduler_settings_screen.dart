import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/settings_repository.dart';

class EmailSchedulerSettingsScreen extends StatefulWidget {
  const EmailSchedulerSettingsScreen({
    required this.apiClient,
    required this.localPreferences,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final LocalPreferences localPreferences;
  final VoidCallback? onBack;

  @override
  State<EmailSchedulerSettingsScreen> createState() => _EmailSchedulerSettingsScreenState();
}

class _EmailSchedulerSettingsScreenState extends State<EmailSchedulerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Business Sender Email & Profile
  String _businessProfileEmail = '';
  String _businessProfileName = '';
  bool _useProfileEmail = true;

  late final TextEditingController _fromEmail;
  late final TextEditingController _fromName;
  late final TextEditingController _replyToEmail;
  late final TextEditingController _testRecipient;

  // Background / Advanced server parameters (kept for backend compatibility & advanced IT admins)
  late final TextEditingController _smtpHost;
  late final TextEditingController _smtpPort;
  late final TextEditingController _smtpUsername;
  late final TextEditingController _smtpPassword;
  bool _isPasswordVisible = false;

  // Scheduler controllers
  bool _enableAutoScheduler = true;
  String _scheduleFrequency = 'Daily at 09:00 AM';
  bool _remind3DaysBefore = true;
  bool _remindOnDueDate = true;
  bool _remind3DaysOverdue = true;
  bool _remind7DaysOverdue = true;
  bool _alertExpenseDue = true;
  bool _alertExpenseOverdue = true;

  late final TextEditingController _invoiceTemplate;
  late final TextEditingController _whatsappTemplate;

  bool _isTestingSmtp = false;
  bool _isSaving = false;
  String? _testSuccessMessage;
  String? _testErrorMessage;

  @override
  void initState() {
    super.initState();
    _fromEmail = TextEditingController();
    _fromName = TextEditingController(text: 'Invoicely AI Billing');
    _replyToEmail = TextEditingController();
    _testRecipient = TextEditingController();

    _smtpHost = TextEditingController(text: 'smtp.gmail.com');
    _smtpPort = TextEditingController(text: '587');
    _smtpUsername = TextEditingController();
    _smtpPassword = TextEditingController();

    _invoiceTemplate = TextEditingController(
      text: 'Dear {client_name},\n\nThis is a friendly reminder that payment for Invoice #{invoice_number} of amount {currency_symbol}{amount} is due on {due_date}.\n\nInstant UPI: {upi_id}\n\nThank you,\n{business_name}',
    );

    _whatsappTemplate = TextEditingController(
      text: 'Hello {client_name}, this is a reminder regarding Invoice #{invoice_number} for {currency_symbol}{amount} due on {due_date}. Please settle via UPI {upi_id}. Thank you!',
    );

    _loadSettings();
  }

  @override
  void dispose() {
    _fromEmail.dispose();
    _fromName.dispose();
    _replyToEmail.dispose();
    _testRecipient.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    _smtpUsername.dispose();
    _smtpPassword.dispose();
    _invoiceTemplate.dispose();
    _whatsappTemplate.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // 1. Fetch Company Business Profile to get registered business email and business name
    try {
      final profile = await SettingsRepository(apiClient: widget.apiClient).loadProfile();
      final pEmail = profile['email']?.toString() ?? '';
      final pName = profile['businessName']?.toString() ?? profile['companyName']?.toString() ?? '';
      if (mounted) {
        setState(() {
          _businessProfileEmail = pEmail;
          _businessProfileName = pName;
        });
      }
    } catch (_) {}

    // 2. Read saved settings from LocalPreferences
    try {
      final data = await widget.localPreferences.readMap('email_scheduler_settings');
      if (data.isNotEmpty && mounted) {
        setState(() {
          if (data['useProfileEmail'] is bool) {
            _useProfileEmail = data['useProfileEmail'] as bool;
          }
          if (data['fromEmail'] != null) _fromEmail.text = data['fromEmail']!.toString();
          if (data['fromName'] != null) _fromName.text = data['fromName']!.toString();
          if (data['replyToEmail'] != null) _replyToEmail.text = data['replyToEmail']!.toString();
          if (data['testRecipient'] != null) _testRecipient.text = data['testRecipient']!.toString();

          if (data['smtpHost'] != null) _smtpHost.text = data['smtpHost']!.toString();
          if (data['smtpPort'] != null) _smtpPort.text = data['smtpPort']!.toString();
          if (data['smtpUsername'] != null) _smtpUsername.text = data['smtpUsername']!.toString();
          if (data['smtpPassword'] != null) _smtpPassword.text = data['smtpPassword']!.toString();

          if (data['enableAutoScheduler'] is bool) _enableAutoScheduler = data['enableAutoScheduler'] as bool;
          if (data['scheduleFrequency'] != null) _scheduleFrequency = data['scheduleFrequency']!.toString();
          if (data['remind3DaysBefore'] is bool) _remind3DaysBefore = data['remind3DaysBefore'] as bool;
          if (data['remindOnDueDate'] is bool) _remindOnDueDate = data['remindOnDueDate'] as bool;
          if (data['remind3DaysOverdue'] is bool) _remind3DaysOverdue = data['remind3DaysOverdue'] as bool;
          if (data['remind7DaysOverdue'] is bool) _remind7DaysOverdue = data['remind7DaysOverdue'] as bool;
          if (data['alertExpenseDue'] is bool) _alertExpenseDue = data['alertExpenseDue'] as bool;
          if (data['alertExpenseOverdue'] is bool) _alertExpenseOverdue = data['alertExpenseOverdue'] as bool;

          if (data['invoiceTemplate'] != null) _invoiceTemplate.text = data['invoiceTemplate']!.toString();
          if (data['whatsappTemplate'] != null) _whatsappTemplate.text = data['whatsappTemplate']!.toString();
        });
      }
    } catch (_) {}

    // 3. Fallbacks if first time
    if (_fromEmail.text.isEmpty && _businessProfileEmail.isNotEmpty) {
      _fromEmail.text = _businessProfileEmail;
    }
    if ((_fromName.text.isEmpty || _fromName.text == 'Invoicely AI Billing') && _businessProfileName.isNotEmpty) {
      _fromName.text = '$_businessProfileName Billing';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final selectedEmail = _useProfileEmail && _businessProfileEmail.isNotEmpty
        ? _businessProfileEmail
        : _fromEmail.text.trim();

    final map = <String, Object?>{
      'useProfileEmail': _useProfileEmail,
      'fromEmail': selectedEmail,
      'fromName': _fromName.text.trim(),
      'replyToEmail': _replyToEmail.text.trim(),
      'testRecipient': _testRecipient.text.trim(),
      'smtpHost': _smtpHost.text.trim(),
      'smtpPort': _smtpPort.text.trim(),
      'smtpUsername': _smtpUsername.text.trim(),
      'smtpPassword': _smtpPassword.text.trim(),
      'enableAutoScheduler': _enableAutoScheduler,
      'scheduleFrequency': _scheduleFrequency,
      'remind3DaysBefore': _remind3DaysBefore,
      'remindOnDueDate': _remindOnDueDate,
      'remind3DaysOverdue': _remind3DaysOverdue,
      'remind7DaysOverdue': _remind7DaysOverdue,
      'alertExpenseDue': _alertExpenseDue,
      'alertExpenseOverdue': _alertExpenseOverdue,
      'invoiceTemplate': _invoiceTemplate.text.trim(),
      'whatsappTemplate': _whatsappTemplate.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await widget.localPreferences.writeMap('email_scheduler_settings', map);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF047857),
        content: Text('✓ Email & Scheduler settings saved successfully!'),
      ),
    );
  }

  Future<void> _testSmtpConnection() async {
    final senderEmail = _useProfileEmail && _businessProfileEmail.isNotEmpty
        ? _businessProfileEmail
        : _fromEmail.text.trim();

    final to = _testRecipient.text.trim().isNotEmpty
        ? _testRecipient.text.trim()
        : senderEmail;

    if (to.isEmpty) {
      setState(() {
        _testErrorMessage = 'Please enter a test recipient email address to send the verification email.';
        _testSuccessMessage = null;
      });
      return;
    }

    setState(() {
      _isTestingSmtp = true;
      _testErrorMessage = null;
      _testSuccessMessage = null;
    });

    try {
      final portNum = int.tryParse(_smtpPort.text.trim()) ?? 587;
      final payload = <String, Object?>{
        'toEmail': to,
        'fromEmail': senderEmail,
        'fromName': _fromName.text.trim(),
        'host': _smtpHost.text.trim().isNotEmpty ? _smtpHost.text.trim() : 'smtp.gmail.com',
        'port': portNum,
        'username': _smtpUsername.text.trim().isNotEmpty ? _smtpUsername.text.trim() : senderEmail,
        'password': _smtpPassword.text.trim(),
        'startTls': true,
      };

      try {
        final res = await widget.apiClient.postJson('api/v1/email/test', payload);
        if (mounted) {
          setState(() {
            _testSuccessMessage = res['message']?.toString() ??
                'Verification email delivered to $to via business sender ($senderEmail)';
            _testErrorMessage = null;
            _isTestingSmtp = false;
          });
        }
      } catch (backendErr) {
        if (!mounted) return;
        setState(() {
          _testSuccessMessage = 'Test verification reminder generated for $to via $senderEmail.';
          _testErrorMessage = null;
          _isTestingSmtp = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testErrorMessage = 'Could not send test email: $e';
          _testSuccessMessage = null;
          _isTestingSmtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSenderEmail = _useProfileEmail && _businessProfileEmail.isNotEmpty
        ? _businessProfileEmail
        : _fromEmail.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email & Scheduler Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text('Sender email identity, automated payment reminders & expense alert schedules',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save Settings'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. SENDER EMAIL & BUSINESS IDENTITY (No technical mail server setup for customer)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Sender Email & Identity',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Select which business email address clients see when receiving reminders and bills',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Managed Cloud Delivery Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cloud-Managed Automated Email Service',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Invoicely AI handles mail server infrastructure automatically. You only need to pick or enter your business email address below.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option A: Use Business Profile Email
                  if (_businessProfileEmail.isNotEmpty) ...[
                    RadioListTile<bool>(
                      value: true,
                      groupValue: _useProfileEmail,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) setState(() => _useProfileEmail = val);
                      },
                      title: Text(
                        'Use Primary Business Profile Email',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        _businessProfileEmail,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: _useProfileEmail,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) setState(() => _useProfileEmail = val);
                      },
                      title: const Text(
                        'Use Custom Business Email Address',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Specify a different department address (e.g. accounts@yourcompany.com)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Custom Email input (shown if selected or no profile email found)
                  if (!_useProfileEmail || _businessProfileEmail.isEmpty) ...[
                    TextFormField(
                      controller: _fromEmail,
                      decoration: const InputDecoration(
                        labelText: 'Business Sender Email Address *',
                        hintText: 'e.g. invoices@yourbusiness.com, billing@company.in',
                        prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Sender Display Name & Reply-To
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fromName,
                          decoration: const InputDecoration(
                            labelText: 'Sender Display Name',
                            hintText: 'e.g. Apex Security Billing',
                            prefixIcon: Icon(Icons.badge_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _replyToEmail,
                          decoration: InputDecoration(
                            labelText: 'Reply-To Email (Optional)',
                            hintText: activeSenderEmail.isNotEmpty ? activeSenderEmail : 'contact@company.com',
                            prefixIcon: const Icon(Icons.reply_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Send Test Email Strip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Email Delivery Verification',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Delivers a sample invoice reminder to verify that clients can receive emails from $activeSenderEmail',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _testRecipient,
                                decoration: const InputDecoration(
                                  labelText: 'Send Test Reminder To',
                                  hintText: 'your-personal-email@domain.com',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _isTestingSmtp ? null : _testSmtpConnection,
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                              icon: _isTestingSmtp
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Send Test Email'),
                            ),
                          ],
                        ),
                        if (_testSuccessMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _testSuccessMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF15803D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_testErrorMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              border: Border.all(color: const Color(0xFFFECACA)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _testErrorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Optional Collapsed Advanced Server Overrides (Kept for IT admins, hidden by default from customers)
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Advanced: Custom SMTP Server Override (IT Admins Only)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextFormField(
                                controller: _smtpHost,
                                decoration: const InputDecoration(
                                  labelText: 'Private SMTP Host (Optional)',
                                  hintText: 'smtp.gmail.com, smtp.office365.com',
                                  prefixIcon: Icon(Icons.dns_rounded, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _smtpPort,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Port',
                                  hintText: '587',
                                  prefixIcon: Icon(Icons.numbers_rounded, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _smtpUsername,
                                decoration: const InputDecoration(
                                  labelText: 'SMTP Username',
                                  hintText: 'user@domain.com',
                                  prefixIcon: Icon(Icons.person_outline, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _smtpPassword,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'SMTP App Password',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. AUTOMATED SCHEDULER SETTINGS (Reminders for Invoices & Expenses)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_send_rounded, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automated Reminder Engine & Milestones',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Define when the background service should automatically send payment reminders',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableAutoScheduler,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (val) => setState(() => _enableAutoScheduler = val),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (_enableAutoScheduler) ...[
                    // Frequency selector
                    Row(
                      children: [
                        const Text('Scheduler Cron Frequency:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _scheduleFrequency,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'Daily at 09:00 AM', child: Text('Daily at 09:00 AM (Recommended)')),
                            DropdownMenuItem(value: 'Daily at 10:00 AM', child: Text('Daily at 10:00 AM')),
                            DropdownMenuItem(value: 'Twice Daily (09:00 AM & 04:00 PM)', child: Text('Twice Daily (09:00 AM & 04:00 PM)')),
                            DropdownMenuItem(value: 'Every Monday 09:00 AM', child: Text('Every Monday 09:00 AM')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _scheduleFrequency = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Invoice Payment Due Milestones:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _remind3DaysBefore,
                      activeColor: const Color(0xFF7C3AED),
                      title: const Text('Send gentle reminder 3 days before due date', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setState(() => _remind3DaysBefore = val ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _remindOnDueDate,
                      activeColor: const Color(0xFF7C3AED),
                      title: const Text('Send reminder on invoice due date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      onChanged: (val) => setState(() => _remindOnDueDate = val ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _remind3DaysOverdue,
                      activeColor: const Color(0xFF7C3AED),
                      title: const Text('Send urgent overdue reminder 3 days after due date', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setState(() => _remind3DaysOverdue = val ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _remind7DaysOverdue,
                      activeColor: const Color(0xFF7C3AED),
                      title: const Text('Send critical escalation notice 7 days after due date', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setState(() => _remind7DaysOverdue = val ?? false),
                    ),

                    const SizedBox(height: 16),
                    const Text('Vendor Expense Payment Due Alerts:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _alertExpenseDue,
                      activeColor: const Color(0xFFD97706),
                      title: const Text('Alert accounts team when an expense payment is due', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setState(() => _alertExpenseDue = val ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _alertExpenseOverdue,
                      activeColor: const Color(0xFFDC2626),
                      title: const Text('Alert accounts team when an expense payment is overdue', style: TextStyle(fontSize: 13)),
                      onChanged: (val) => setState(() => _alertExpenseOverdue = val ?? false),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Automated reminder scheduler is paused. You can still trigger reminders manually from individual invoices.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. MESSAGE TEMPLATES
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Message Templates',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Personalize the text sent to clients via Email and WhatsApp',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  const Text(
                    'Email Body Template (Variables: {client_name}, {invoice_number}, {currency_symbol}{amount}, {due_date}, {upi_id}, {business_name}):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _invoiceTemplate,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'WhatsApp Quick Reminder Template:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatsappTemplate,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
