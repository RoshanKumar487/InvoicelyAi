import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../audit/data/audit_log_service.dart';
import '../../data/invoice.dart';

class RecurringScheduleResult {
  const RecurringScheduleResult({
    required this.updatedInvoice,
    required this.frequency,
    required this.nextDate,
    required this.autoSendEmail,
  });

  final Invoice updatedInvoice;
  final String frequency;
  final String nextDate;
  final bool autoSendEmail;
}

/// Modal for scheduling recurring billing, retainers, and automated invoice dispatch.
class RecurringInvoiceSetupDialog extends StatefulWidget {
  const RecurringInvoiceSetupDialog({
    required this.invoice,
    super.key,
  });

  final Invoice invoice;

  static Future<RecurringScheduleResult?> show(
    BuildContext context, {
    required Invoice invoice,
  }) {
    return showDialog<RecurringScheduleResult>(
      context: context,
      builder: (context) => RecurringInvoiceSetupDialog(invoice: invoice),
    );
  }

  @override
  State<RecurringInvoiceSetupDialog> createState() => _RecurringInvoiceSetupDialogState();
}

class _RecurringInvoiceSetupDialogState extends State<RecurringInvoiceSetupDialog> {
  static const List<String> _frequencies = [
    'Monthly Retainer',
    'Bi-Weekly (Every 2 Weeks)',
    'Quarterly (Every 3 Months)',
    'Annual Contract',
  ];

  String _selectedFrequency = 'Monthly Retainer';
  late DateTime _nextRunDate;
  bool _autoSendEmail = true;

  @override
  void initState() {
    super.initState();
    // Default next run date to 1 month from today
    _nextRunDate = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _selectNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRunDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _nextRunDate = picked);
    }
  }

  void _submit() {
    final nextDateStr = '${_nextRunDate.year}-${_nextRunDate.month.toString().padLeft(2, '0')}-${_nextRunDate.day.toString().padLeft(2, '0')}';
    final recurringTag = '🔁 Recurring: $_selectedFrequency (Next: $nextDateStr)${_autoSendEmail ? " · Auto-Notify" : ""}';

    final updatedTerms = widget.invoice.terms.trim().isNotEmpty
        ? '${widget.invoice.terms.trim()}\n• $recurringTag'
        : recurringTag;

    final updated = widget.invoice.copyWith(
      terms: updatedTerms,
      paymentTerms: 'Recurring - $_selectedFrequency',
    );

    AuditLogService.log(
      module: 'INVOICE',
      action: 'RECURRING_CONFIGURED',
      entityId: widget.invoice.invoiceNumber,
      title: 'Configured recurring schedule for ${widget.invoice.invoiceNumber}',
      description: 'Set schedule: $_selectedFrequency, next run on $nextDateStr for ${widget.invoice.clientName}',
    );

    Navigator.of(context).pop(
      RecurringScheduleResult(
        updatedInvoice: updated,
        frequency: _selectedFrequency,
        nextDate: nextDateStr,
        autoSendEmail: _autoSendEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = '${_nextRunDate.day.toString().padLeft(2, '0')}/${_nextRunDate.month.toString().padLeft(2, '0')}/${_nextRunDate.year}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.neuSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppTheme.neuOrbDecoration(
                      active: true,
                      activeColor: const Color(0xFF7C3AED),
                    ),
                    child: const Icon(Icons.autorenew_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recurring Billing Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${widget.invoice.invoiceNumber} · ${widget.invoice.clientName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Billing Frequency
              const Text(
                'Billing Frequency *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFrequency = val);
                },
              ),
              const SizedBox(height: 16),

              // Next Run Date
              const Text(
                'Next Scheduled Run Date *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectNextDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded, size: 18, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Text(dateFormatted, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Auto email toggle
              SwitchListTile(
                value: _autoSendEmail,
                onChanged: (v) => setState(() => _autoSendEmail = v),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF7C3AED),
                title: const Text(
                  'Automated Email Notification',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                subtitle: const Text(
                  'Send invoice directly to client email when cycle triggers',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
