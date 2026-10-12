import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../notifications/data/notification_repository.dart';

class EmailTemplatesTab extends StatefulWidget {
  const EmailTemplatesTab({
    required this.apiClient,
    required this.profile,
    super.key,
  });

  final ApiClient apiClient;
  final Map<String, dynamic> profile;

  @override
  State<EmailTemplatesTab> createState() => _EmailTemplatesTabState();
}

class _EmailTemplatesTabState extends State<EmailTemplatesTab> {
  late final NotificationRepository _repository;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedTemplate;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _selectedChannel = 'EMAIL';

  static const _availableTokens = [
    '{{clientName}}',
    '{{invoiceNumber}}',
    '{{amountDue}}',
    '{{dueDate}}',
    '{{issueDate}}',
    '{{companyName}}',
    '{{companyEmail}}',
    '{{paymentLink}}',
    '{{companyCode}}',
    '{{inviteeName}}',
    '{{inviterName}}',
    '{{inviteLink}}',
    '{{userFullName}}',
    '{{adminFeedback}}',
  ];

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository(apiClient: widget.apiClient);
    _loadTemplates();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _repository.loadTemplates();
      if (!mounted) return;
      setState(() {
        _templates = list;
        _loading = false;
        if (list.isNotEmpty) {
          _selectTemplate(list.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load templates: $e';
        _loading = false;
      });
    }
  }

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplate = template;
      _selectedChannel = template['channel']?.toString() ?? 'EMAIL';
      _subjectController.text = template['subject']?.toString() ?? template['title']?.toString() ?? '';
      _bodyController.text = template['body']?.toString() ?? '';
    });
  }

  void _insertToken(String token) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, token);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + token.length),
      );
    } else {
      _bodyController.text = '$text $token';
    }
    setState(() {});
  }

  Future<void> _saveCurrentTemplate() async {
    if (_selectedTemplate == null) return;
    setState(() => _saving = true);

    try {
      final templateName = _selectedTemplate!['templateName']?.toString() ?? 'PAYMENT_REMINDER';
      final id = _selectedTemplate!['id'];

      if (id != null && _selectedTemplate!['companyId'] != null) {
        await _repository.updateTemplate(
          id: (id as num).toInt(),
          templateName: templateName,
          channel: _selectedChannel,
          subject: _subjectController.text,
          title: _selectedTemplate!['title']?.toString() ?? templateName,
          body: _bodyController.text,
        );
      } else {
        await _repository.saveTemplate(
          templateName: templateName,
          channel: _selectedChannel,
          subject: _subjectController.text,
          title: _selectedTemplate!['title']?.toString() ?? templateName,
          body: _bodyController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ Template saved successfully to company profile!'),
        ),
      );

      await _loadTemplates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text('Error saving template: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToDefault() async {
    if (_selectedTemplate == null) return;
    final id = _selectedTemplate!['id'];
    if (id == null || _selectedTemplate!['companyId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template is already using standard system defaults.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Template?'),
        content: const Text('This will delete your company custom template and restore the system default template.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await _repository.resetTemplate((id as num).toInt());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template reset to system default.')),
      );
      await _loadTemplates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text('Error resetting template: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showOutboxAuditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OutboxAuditBottomSheet(repository: _repository),
    );
  }

  String _renderPreviewText(String input) {
    var out = input;
    final companyName = widget.profile['companyName']?.toString() ??
        widget.profile['businessName']?.toString() ??
        'Apex Nova Dynamics';
    final email = widget.profile['email']?.toString() ?? 'billing@apexnova.io';
    final code = widget.profile['companyCode']?.toString() ?? 'APEX-2026';

    out = out.replaceAll('{{clientName}}', 'Acme Global Corp');
    out = out.replaceAll('{{invoiceNumber}}', 'INV-2026-0042');
    out = out.replaceAll('{{amountDue}}', '\$ 3,450.00');
    out = out.replaceAll('{{dueDate}}', '2026-10-25');
    out = out.replaceAll('{{issueDate}}', '2026-10-10');
    out = out.replaceAll('{{companyName}}', companyName);
    out = out.replaceAll('{{companyEmail}}', email);
    out = out.replaceAll('{{companyCode}}', code);
    out = out.replaceAll('{{paymentLink}}', 'https://invoicelyai.onrender.com/pay/inv-42');
    out = out.replaceAll('{{inviteeName}}', 'Sarah Miller');
    out = out.replaceAll('{{inviterName}}', 'Administrator');
    out = out.replaceAll('{{inviteLink}}', 'https://invoicelyai.onrender.com/join?code=$code');
    out = out.replaceAll('{{userFullName}}', 'Jordan Hayes');
    out = out.replaceAll('{{adminFeedback}}', 'Welcome aboard! Full accountant permissions granted.');
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadTemplates, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. BANNER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF60A5FA), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email & Messaging Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Customize automated payment reminders, WhatsApp alerts, team invites, and outbox delivery queue.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showOutboxAuditSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                ),
                icon: const Icon(Icons.outbox_rounded, size: 16),
                label: const Text('Outbox Audit'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. TEMPLATE SELECTOR
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Template to Customize',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedTemplate,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: _templates.map((tmpl) {
                  final isCustom = tmpl['companyId'] != null;
                  final channel = tmpl['channel']?.toString() ?? 'EMAIL';
                  final title = tmpl['title']?.toString() ?? tmpl['templateName']?.toString() ?? 'Template';
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: tmpl,
                    child: Row(
                      children: [
                        Icon(
                          channel == 'WHATSAPP' ? Icons.chat_rounded : Icons.email_rounded,
                          size: 18,
                          color: channel == 'WHATSAPP' ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                        if (isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Customized', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _selectTemplate(val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. TEMPLATE EDITOR
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Template Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  // Channel Toggle
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'EMAIL', label: Text('Email'), icon: Icon(Icons.email_outlined, size: 16)),
                      ButtonSegment(value: 'WHATSAPP', label: Text('WhatsApp'), icon: Icon(Icons.chat_outlined, size: 16)),
                    ],
                    selected: {_selectedChannel},
                    onSelectionChanged: (set) {
                      setState(() => _selectedChannel = set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject / Headline
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: _selectedChannel == 'WHATSAPP' ? 'Header / Headline' : 'Email Subject Line',
                  hintText: 'e.g. Payment Reminder for Invoice {{invoiceNumber}}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 14),

              // Placeholder Tokens Chips
              const Text('Insert Variable Placeholders:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableTokens.map((token) {
                  return ActionChip(
                    label: Text(token, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _insertToken(token),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Body Editor
              TextFormField(
                controller: _bodyController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Message Body',
                  alignLabelWithHint: true,
                  hintText: 'Dear {{clientName}},\n\nYour payment of {{amountDue}} is due on {{dueDate}}...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetToDefault,
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Reset Default'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveCurrentTemplate,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Save Template'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. LIVE PREVIEW CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  const Text('Live Rendered Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _selectedChannel == 'WHATSAPP' ? const Color(0xFF22C55E).withValues(alpha: 0.15) : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedChannel == 'WHATSAPP' ? '📱 WhatsApp View' : '✉️ Email View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedChannel == 'WHATSAPP' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_selectedChannel == 'EMAIL') ...[
                Text('Subject: ${_renderPreviewText(_subjectController.text)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedChannel == 'WHATSAPP' ? const Color(0xFFDCF8C6).withValues(alpha: 0.25) : Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedChannel == 'WHATSAPP' ? const Color(0xFF86EFAC) : Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  _renderPreviewText(_bodyController.text),
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutboxAuditBottomSheet extends StatefulWidget {
  const _OutboxAuditBottomSheet({required this.repository});

  final NotificationRepository repository;

  @override
  State<_OutboxAuditBottomSheet> createState() => _OutboxAuditBottomSheetState();
}

class _OutboxAuditBottomSheetState extends State<_OutboxAuditBottomSheet> {
  bool _loading = true;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final metrics = await widget.repository.loadMetrics();
      final queueResp = await widget.repository.loadQueue();
      final content = queueResp['data']?['content'] ?? queueResp['content'] ?? [];
      final List<Map<String, dynamic>> items = (content as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _queueItems = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retryItem(int id) async {
    try {
      await widget.repository.retryNotification(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification reset to PENDING for dispatcher pickup.')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error retrying: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.outbox_rounded, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                const Text('Notification Outbox & Audit Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Metrics Row
                  Row(
                    children: [
                      _metricBox('Total Queued', '${_metrics['total'] ?? 0}', Colors.blue),
                      const SizedBox(width: 8),
                      _metricBox('Pending', '${_metrics['pending'] ?? 0}', Colors.orange),
                      const SizedBox(width: 8),
                      _metricBox('Sent', '${_metrics['sent'] ?? 0}', Colors.green),
                      const SizedBox(width: 8),
                      _metricBox('Stuck/Failed', '${_metrics['failed'] ?? 0}', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Recent Outbox Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_queueItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No outgoing notifications queued yet.', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ..._queueItems.map((item) {
                      final id = (item['id'] as num?)?.toInt() ?? 0;
                      final status = item['status']?.toString() ?? 'PENDING';
                      final channel = item['channel']?.toString() ?? 'EMAIL';
                      final to = item['recipientTo']?.toString() ?? '';
                      final title = item['title']?.toString() ?? 'Notification';
                      final error = item['errorMessage']?.toString();

                      Color statusColor;
                      switch (status) {
                        case 'SENT':
                          statusColor = Colors.green;
                          break;
                        case 'PROCESSING':
                          statusColor = Colors.blue;
                          break;
                        case 'FAILED':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(channel == 'WHATSAPP' ? Icons.chat_rounded : Icons.email_rounded, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              if (error != null && error.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                                  child: Text('Error: $error', style: const TextStyle(color: Colors.red, fontSize: 11)),
                                ),
                              ],
                              if (status == 'FAILED') ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _retryItem(id),
                                    icon: const Icon(Icons.replay_rounded, size: 14),
                                    label: const Text('Retry Sending', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
