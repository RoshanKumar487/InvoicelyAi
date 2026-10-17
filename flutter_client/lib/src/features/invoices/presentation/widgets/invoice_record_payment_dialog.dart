import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_theme.dart';
import '../../../audit/data/audit_log_service.dart';
import '../../data/invoice.dart';

class PaymentRecordResult {
  const PaymentRecordResult({
    required this.updatedInvoice,
    required this.amountRecorded,
    required this.paymentMode,
    required this.referenceNumber,
    required this.paymentDate,
    required this.notes,
  });

  final Invoice updatedInvoice;
  final double amountRecorded;
  final String paymentMode;
  final String referenceNumber;
  final String paymentDate;
  final String notes;
}

/// Dialog allowing business owners and accountants to record partial or full invoice settlements.
class InvoiceRecordPaymentDialog extends StatefulWidget {
  const InvoiceRecordPaymentDialog({
    required this.invoice,
    super.key,
  });

  final Invoice invoice;

  static Future<PaymentRecordResult?> show(
    BuildContext context, {
    required Invoice invoice,
  }) {
    return showDialog<PaymentRecordResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoiceRecordPaymentDialog(invoice: invoice),
    );
  }

  @override
  State<InvoiceRecordPaymentDialog> createState() => _InvoiceRecordPaymentDialogState();
}

class _InvoiceRecordPaymentDialogState extends State<InvoiceRecordPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;

  static const List<String> _paymentModes = [
    'Bank Transfer (NEFT / IMPS)',
    'UPI / QR Code',
    'Credit / Debit Card',
    'Cheque / DD',
    'Cash Settlement',
  ];

  String _selectedMode = 'Bank Transfer (NEFT / IMPS)';
  late DateTime _paymentDate;
  double _enteredAmount = 0.0;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final remaining = widget.invoice.balanceDue > 0
        ? widget.invoice.balanceDue
        : widget.invoice.total;
    _enteredAmount = remaining;
    _amountController = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
    _paymentDate = DateTime.now();

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(_amountController.text.trim());
    setState(() {
      if (parsed == null || parsed <= 0) {
        _amountError = 'Enter a valid payment amount';
        _enteredAmount = 0.0;
      } else if (parsed > widget.invoice.balanceDue && widget.invoice.balanceDue > 0) {
        _amountError = 'Amount exceeds remaining balance (${widget.invoice.currencySymbol}${widget.invoice.balanceDue.toStringAsFixed(2)})';
        _enteredAmount = parsed;
      } else {
        _amountError = null;
        _enteredAmount = parsed;
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _newBalanceDue {
    final initialBalance = widget.invoice.balanceDue > 0
        ? widget.invoice.balanceDue
        : (widget.invoice.total - widget.invoice.amountPaid);
    final remaining = initialBalance - _enteredAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  double get _newAmountPaid => widget.invoice.amountPaid + _enteredAmount;

  String get _newStatus {
    if (_newBalanceDue <= 0.001) return 'Paid';
    return widget.invoice.status.toLowerCase() == 'draft' ? 'Sent' : widget.invoice.status;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _submit() {
    if (_enteredAmount <= 0) {
      setState(() => _amountError = 'Enter a valid payment amount');
      return;
    }

    final dateStr = '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}';
    final notes = _notesController.text.trim();
    final ref = _referenceController.text.trim();

    // Append payment history record to paymentInstructions / notes for permanent audit trail
    final paymentAuditEntry = 'Payment recorded: ${widget.invoice.currencySymbol}${_enteredAmount.toStringAsFixed(2)} via $_selectedMode on $dateStr${ref.isNotEmpty ? ' [Ref: $ref]' : ''}${notes.isNotEmpty ? ' ($notes)' : ''}';
    final updatedInstructions = widget.invoice.paymentInstructions.trim().isNotEmpty
        ? '${widget.invoice.paymentInstructions.trim()}\n• $paymentAuditEntry'
        : '• $paymentAuditEntry';

    final updated = widget.invoice.copyWith(
      amountPaid: _newAmountPaid,
      status: _newStatus,
      paidDate: _newBalanceDue <= 0.001 ? _paymentDate.millisecondsSinceEpoch : widget.invoice.paidDate,
      paymentInstructions: updatedInstructions,
    );

    // Audit log
    AuditLogService.log(
      module: 'INVOICE',
      action: 'PAYMENT_RECORDED',
      entityId: widget.invoice.invoiceNumber,
      title: 'Settlement recorded for ${widget.invoice.invoiceNumber}',
      description: 'Recorded ${widget.invoice.currencySymbol}${_enteredAmount.toStringAsFixed(2)} via $_selectedMode. New balance: ${widget.invoice.currencySymbol}${_newBalanceDue.toStringAsFixed(2)}',
    );

    Navigator.of(context).pop(
      PaymentRecordResult(
        updatedInvoice: updated,
        amountRecorded: _enteredAmount,
        paymentMode: _selectedMode,
        referenceNumber: ref,
        paymentDate: dateStr,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.invoice.currencySymbol;
    final total = widget.invoice.total;
    final balance = widget.invoice.balanceDue > 0 ? widget.invoice.balanceDue : total;
    final isSettlingFull = (_enteredAmount - balance).abs() < 0.01;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.neuSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: AppTheme.neuOrbDecoration(
                      active: true,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Settlement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        Text(
                          '${widget.invoice.invoiceNumber.isNotEmpty ? widget.invoice.invoiceNumber : "Invoice"} · ${widget.invoice.clientName}',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Invoiced', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '$sym${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 28, width: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Already Settled', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '$sym${widget.invoice.amountPaid.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 28, width: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Balance Due', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '$sym${balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Payment Amount Input + Quick Fill Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Amount *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (balance > 0)
                        InkWell(
                          onTap: () {
                            _amountController.text = (balance * 0.5).toStringAsFixed(2);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text('50% Partial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                          ),
                        ),
                      InkWell(
                        onTap: () {
                          _amountController.text = balance.toStringAsFixed(2);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text('Full Settlement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '$sym ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '0.00',
                  errorText: _amountError,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),

              // Payment Mode & Payment Date (Responsive Row)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 440;
                  final modeWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Mode *',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: _paymentModes
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMode = val);
                        },
                      ),
                    ],
                  );

                  final dateWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Date *',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_paymentDate.day.toString().padLeft(2, '0')}/${_paymentDate.month.toString().padLeft(2, '0')}/${_paymentDate.year}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        modeWidget,
                        const SizedBox(height: 12),
                        dateWidget,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 3, child: modeWidget),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: dateWidget),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Transaction / UTR Reference
              const Text(
                'Reference / UTR / Cheque # (Optional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _referenceController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'e.g. UTR-9823482734 or Cheque #49281',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),

              // Notes / Internal Memo
              const Text(
                'Settlement Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'e.g. Credited directly to current account; receipt sent to client',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 18),

              // Outcome preview indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSettlingFull ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSettlingFull ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSettlingFull ? Icons.check_circle_rounded : Icons.pie_chart_outline_rounded,
                      color: isSettlingFull ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSettlingFull
                            ? 'Invoice will be marked fully PAID ($sym${_newAmountPaid.toStringAsFixed(2)})'
                            : 'Partial settlement ($sym${_enteredAmount.toStringAsFixed(2)}). New balance due: $sym${_newBalanceDue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSettlingFull ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _enteredAmount > 0 ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isSettlingFull ? 'Record Full Settlement' : 'Record Partial Payment',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
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
