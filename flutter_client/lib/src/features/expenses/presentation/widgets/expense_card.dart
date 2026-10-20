import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import '../../data/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.onSendEmail,
    this.onSendWhatsApp,
    this.onMarkPaid,
    this.currencySymbol = '₹',
    super.key,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSendEmail;
  final VoidCallback? onSendWhatsApp;
  final VoidCallback? onMarkPaid;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySymbol = (expense.currencySymbol == r'$' || expense.currency == 'USD')
        ? (currencySymbol.isNotEmpty ? currencySymbol : '₹')
        : (expense.currencySymbol.isNotEmpty ? expense.currencySymbol : currencySymbol);
    final isDue = expense.isDue;
    final isPaid = expense.status.toUpperCase() == 'PAID';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 540;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isDue
                        ? Colors.red.shade50
                        : (isPaid
                            ? Colors.green.shade50
                            : const Color(0xFFF1F5F9)),
                    foregroundColor: isDue
                        ? Colors.red.shade700
                        : (isPaid
                            ? Colors.green.shade700
                            : const Color(0xFF475569)),
                    radius: 20,
                    child: Icon(
                      isDue
                          ? Icons.warning_amber_rounded
                          : (isPaid
                              ? Icons.check_circle_outline
                              : Icons.receipt_long_outlined),
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
                                expense.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(theme, isPaid, isDue),
                            if (expense.isAdvance) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: expense.advanceSettled
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: expense.advanceSettled
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      expense.advanceSettled
                                          ? Icons.check_circle_outline
                                          : Icons.account_balance_wallet_outlined,
                                      size: 11,
                                      color: expense.advanceSettled
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      expense.advanceSettled
                                          ? 'Recovered in Payroll'
                                          : 'Advance · Unsettled',
                                      style: TextStyle(
                                        color: expense.advanceSettled
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFB45309),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expense.isAdvance && (expense.employeeName?.isNotEmpty ?? false)
                              ? 'Employee Advance: ${expense.employeeName} · ${expense.vendor.isNotEmpty ? expense.vendor : expense.category}'
                              : (expense.vendor.isEmpty
                                  ? expense.category
                                  : '${expense.vendor} · ${expense.category}'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$displaySymbol${expense.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (expense.dueDate.isNotEmpty)
                        Text(
                          'Due: ${expense.dueDate}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDue ? Colors.red.shade700 : AppColors.muted,
                            fontWeight: isDue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      tooltip: 'Expense actions',
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            onEdit();
                          case 'delete':
                            onDelete();
                          case 'paid':
                            onMarkPaid?.call();
                          case 'email':
                            onSendEmail?.call();
                          case 'whatsapp':
                            onSendWhatsApp?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (!isPaid) ...[
                          const PopupMenuItem(
                              value: 'paid', child: Text('Mark as Paid')),
                          const PopupMenuItem(
                              value: 'email', child: Text('Send Email Alert')),
                          const PopupMenuItem(
                              value: 'whatsapp', child: Text('Send WhatsApp Alert')),
                        ],
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (expense.date.isNotEmpty)
                    _ExpenseDetail(
                      icon: Icons.calendar_today_outlined,
                      value: expense.date,
                    ),
                  _ExpenseDetail(
                    icon: Icons.credit_card_outlined,
                    value: expense.paymentMethod,
                  ),
                  _ExpenseDetail(
                    icon: expense.taxDeductible
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    value: expense.taxDeductible
                        ? 'Tax deductible'
                        : 'Not deductible',
                  ),
                  if (expense.taxAmount > 0)
                    _ExpenseDetail(
                      icon: Icons.request_quote_outlined,
                      value:
                          'Tax $displaySymbol${expense.taxAmount.toStringAsFixed(2)}',
                    ),
                  if (expense.amount >= 15000)
                    _ExpenseDetail(
                      icon: Icons.verified_user_outlined,
                      value: 'High Value (>15k)',
                    ),
                  if (expense.receiptImageUri != null && expense.receiptImageUri!.isNotEmpty)
                    _ExpenseDetail(
                      icon: Icons.attachment_rounded,
                      value: 'Bill Attached',
                    ),
                ],
              ),
              if (expense.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(expense.notes, style: theme.textTheme.bodyMedium),
              ],
              if (isDue && !isPaid) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm_on, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Payment due! Send instant reminder:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onSendWhatsApp != null)
                        InkWell(
                          onTap: onSendWhatsApp,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'WhatsApp',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (onSendEmail != null)
                        InkWell(
                          onTap: onSendEmail,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mail_outline,
                                    size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Email',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (onMarkPaid != null)
                        InkWell(
                          onTap: onMarkPaid,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Mark Paid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (compact) ...[
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (!isPaid && onMarkPaid != null)
                      TextButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Paid'),
                      ),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isPaid, bool isDue) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    String label = expense.status.toUpperCase();
    if (label.isEmpty) label = 'PENDING';

    if (isPaid) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'PAID';
    } else if (isDue) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = 'DUE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExpenseDetail extends StatelessWidget {
  const _ExpenseDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
