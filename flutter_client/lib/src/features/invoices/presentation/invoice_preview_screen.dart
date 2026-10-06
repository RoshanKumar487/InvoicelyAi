import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../templates/data/template_config.dart';
import '../data/invoice.dart';
import '../data/invoice_docx_export.dart';
import '../data/invoice_pdf_export.dart';
import '../data/invoice_repository.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    required this.invoice,
    required this.repository,
    required this.onBack,
    required this.onEdit,
    required this.onDeleted,
    this.preferredTemplate,
    this.localSettings = const <String, Object?>{},
    super.key,
  });

  final Invoice invoice;
  final InvoiceRepository repository;
  final VoidCallback onBack;
  final ValueChanged<Invoice> onEdit;
  final VoidCallback onDeleted;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> localSettings;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late Invoice _invoice = widget.invoice;
  bool _busy = false;

  bool _show(String key) => widget.localSettings[key] != false;

  Future<void> _changeStatus(String status) async {
    final id = _invoice.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.updateStatus(id, status);
      if (mounted) setState(() => _invoice = updated);
      if (mounted) _showMessage('Invoice status changed to $status.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Could not update status: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copySummary() async {
    final summary = StringBuffer()
      ..writeln('Invoice ${_invoice.invoiceNumber}')
      ..writeln('Bill to: ${_invoice.clientName}')
      ..writeln(_invoice.clientCompany)
      ..writeln(_invoice.clientEmail)
      ..writeln('Issued: ${_invoice.issueDate} · Due: ${_invoice.dueDate}')
      ..writeln()
      ..writeln('Description | Quantity | Unit price | Amount');
    for (final item in _invoice.items) {
      summary.writeln(
        '${item.description} | ${_quantity(item.quantity)} ${item.unit} | '
        '${_money(item.unitPrice, _invoice.currencySymbol)} | '
        '${_money(item.total, _invoice.currencySymbol)}',
      );
    }
    summary
      ..writeln()
      ..writeln(
          'Subtotal: ${_money(_invoice.subtotal, _invoice.currencySymbol)}')
      ..writeln(
        '${_invoice.taxLabel} (${_invoice.taxRate}%): '
        '${_money(_invoice.taxAmount, _invoice.currencySymbol)}',
      )
      ..writeln('Total: ${_money(_invoice.total, _invoice.currencySymbol)}')
      ..writeln(
        'Amount paid: ${_money(_invoice.amountPaid, _invoice.currencySymbol)}',
      )
      ..writeln(
        'Balance due: ${_money(_invoice.balanceDue, _invoice.currencySymbol)}',
      );
    if (_invoice.notes.isNotEmpty) {
      summary.writeln('\nNotes: ${_invoice.notes}');
    }
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (mounted) _showMessage('Invoice details copied to clipboard.');
  }

  TemplateConfig? get _template {
    for (final preset in templatePresets) {
      if (preset.id == _invoice.templateId) return preset;
    }
    if (widget.preferredTemplate?.id == _invoice.templateId) {
      return widget.preferredTemplate;
    }
    return null;
  }

  String get _safeFileName =>
      _invoice.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await InvoicePdfExport.build(
        _invoice,
        template: _template,
        localSettings: widget.localSettings,
      );
      await Printing.layoutPdf(
        name: 'Invoice_$_safeFileName.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (mounted) _showMessage('Could not create PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await InvoicePdfExport.build(
        _invoice,
        template: _template,
        localSettings: widget.localSettings,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_$_safeFileName.pdf',
      );
    } catch (error) {
      if (mounted) _showMessage('Could not share PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareDocx() async {
    setState(() => _busy = true);
    try {
      final bytes = InvoiceDocxExport.build(
        _invoice,
        template: _template,
        localSettings: widget.localSettings,
      );
      final name = 'Invoice_$_safeFileName.docx';
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: 'Invoice ${_invoice.invoiceNumber}',
        ),
      );
      if (mounted && result.status == ShareResultStatus.unavailable) {
        _showMessage('File sharing is unavailable on this platform.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not share DOCX: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = _invoice.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'Invoice ${_invoice.invoiceNumber} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep invoice'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.deleteInvoice(id);
      if (mounted) widget.onDeleted();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Could not delete invoice: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to invoices',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            tooltip: 'Copy invoice details',
            onPressed: _busy ? null : _copySummary,
            icon: const Icon(Icons.copy_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Export invoice',
            enabled: !_busy,
            onSelected: (action) {
              switch (action) {
                case 'print':
                  _printPdf();
                case 'pdf':
                  _sharePdf();
                case 'docx':
                  _shareDocx();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print_outlined),
                  title: Text('Print / download PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Share PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'docx',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Share DOCX'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Edit invoice',
            onPressed: _busy ? null : () => widget.onEdit(_invoice),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Change status',
            enabled: !_busy,
            onSelected: _changeStatus,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Draft', child: Text('Set draft')),
              PopupMenuItem(value: 'Sent', child: Text('Mark sent')),
              PopupMenuItem(value: 'Paid', child: Text('Mark paid')),
              PopupMenuItem(value: 'Overdue', child: Text('Mark overdue')),
              PopupMenuItem(value: 'Cancelled', child: Text('Cancel invoice')),
            ],
          ),
          IconButton(
            tooltip: 'Delete invoice',
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Invoice preview',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_show('showStatus'))
                        _StatusChip(status: invoice.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'INVOICE',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  invoice.invoiceNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                if (_show('showIssueDate'))
                                  Text('Issued ${invoice.issueDate}'),
                                if (_show('showDueDate'))
                                  Text('Due ${invoice.dueDate}'),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _ClientSummary(
                          invoice: invoice,
                          localSettings: widget.localSettings,
                        ),
                        const SizedBox(height: 28),
                        _LineItemsTable(
                          invoice: invoice,
                          localSettings: widget.localSettings,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Column(
                              children: [
                                _TotalLine(
                                  label: 'Subtotal',
                                  value: _money(
                                    invoice.subtotal,
                                    invoice.currencySymbol,
                                  ),
                                ),
                                if (invoice.totalDiscount > 0)
                                  _TotalLine(
                                    label: 'Discount',
                                    value:
                                        '−${_money(invoice.totalDiscount, invoice.currencySymbol)}',
                                  ),
                                if (_template?.showTaxBreakdown != false)
                                  _TotalLine(
                                    label:
                                        '${invoice.taxLabel} (${invoice.taxRate}%)',
                                    value: _money(
                                      invoice.taxAmount,
                                      invoice.currencySymbol,
                                    ),
                                  ),
                                if (_show('showShippingSection') &&
                                    invoice.shippingFee > 0)
                                  _TotalLine(
                                    label: 'Shipping',
                                    value: _money(
                                      invoice.shippingFee,
                                      invoice.currencySymbol,
                                    ),
                                  ),
                                if (_show('showShippingSection') &&
                                    invoice.additionalCharges > 0)
                                  _TotalLine(
                                    label: 'Additional charges',
                                    value: _money(
                                      invoice.additionalCharges,
                                      invoice.currencySymbol,
                                    ),
                                  ),
                                if (invoice.roundOff != 0)
                                  _TotalLine(
                                    label: 'Round off',
                                    value: _money(
                                      invoice.roundOff,
                                      invoice.currencySymbol,
                                    ),
                                  ),
                                const Divider(),
                                _TotalLine(
                                  label: 'Total',
                                  value: _money(
                                    invoice.total,
                                    invoice.currencySymbol,
                                  ),
                                  bold: true,
                                ),
                                _TotalLine(
                                  label: 'Amount paid',
                                  value: _money(
                                    invoice.amountPaid,
                                    invoice.currencySymbol,
                                  ),
                                ),
                                _TotalLine(
                                  label: 'Balance due',
                                  value: _money(
                                    invoice.balanceDue,
                                    invoice.currencySymbol,
                                  ),
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if ((_show('showNotesSection') &&
                            ((_show('showNotes') && invoice.notes.isNotEmpty) ||
                                (_show('showTerms') &&
                                    invoice.terms.isNotEmpty) ||
                                (_show('showPaymentInstructions') &&
                                    invoice
                                        .paymentInstructions.isNotEmpty)))) ...[
                          const Divider(height: 32),
                          if (_show('showNotes') && invoice.notes.isNotEmpty)
                            _TextBlock(title: 'Notes', text: invoice.notes),
                          if (_show('showTerms') && invoice.terms.isNotEmpty)
                            _TextBlock(
                              title: 'Terms and conditions',
                              text: invoice.terms,
                            ),
                          if (_show('showPaymentInstructions') &&
                              _template?.showPaymentInstructions != false &&
                              invoice.paymentInstructions.isNotEmpty)
                            _TextBlock(
                              title: 'Payment instructions',
                              text: invoice.paymentInstructions,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Print, download, or share this invoice as a PDF or editable DOCX.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSummary extends StatelessWidget {
  const _ClientSummary({
    required this.invoice,
    required this.localSettings,
  });

  final Invoice invoice;
  final Map<String, Object?> localSettings;

  bool _show(String key) => localSettings[key] != false;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SummaryBlock(
              title: 'BILL TO',
              children: [
                Text(
                  invoice.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_show('showClientCompany') &&
                    invoice.clientCompany.isNotEmpty)
                  Text(invoice.clientCompany),
                if (_show('showClientEmail') && invoice.clientEmail.isNotEmpty)
                  Text(invoice.clientEmail),
                if (_show('showClientPhone') && invoice.clientPhone.isNotEmpty)
                  Text(invoice.clientPhone),
                if (_show('showClientAddress') &&
                    invoice.clientAddress.isNotEmpty)
                  Text(invoice.clientAddress),
                if (_show('showClientTaxId') && invoice.clientTaxId.isNotEmpty)
                  Text('Tax ID: ${invoice.clientTaxId}'),
              ],
            ),
          ),
          if (_show('showPoNumber') && invoice.poNumber.isNotEmpty)
            Expanded(
              child: _SummaryBlock(
                title: 'PURCHASE ORDER',
                children: [Text(invoice.poNumber)],
              ),
            ),
        ],
      );
}

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({
    required this.invoice,
    required this.localSettings,
  });

  final Invoice invoice;
  final Map<String, Object?> localSettings;

  bool _show(String key) => localSettings[key] != false;

  @override
  Widget build(BuildContext context) {
    if (invoice.items.isEmpty) {
      return const Text('This invoice has no line items.');
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Expanded(flex: 5, child: Text('Description')),
              if (_show('showItemQty'))
                const Expanded(child: Text('Qty', textAlign: TextAlign.end)),
              if (_show('showItemRate'))
                const Expanded(
                  flex: 2,
                  child: Text('Rate', textAlign: TextAlign.end),
                ),
              if (_show('showItemDiscount'))
                const Expanded(
                  child: Text('Discount', textAlign: TextAlign.end),
                ),
              if (_show('showItemTax'))
                const Expanded(
                  child: Text('Tax', textAlign: TextAlign.end),
                ),
              const Expanded(
                flex: 2,
                child: Text('Amount', textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
        for (final item in invoice.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: Text(item.description)),
                if (_show('showItemQty'))
                  Expanded(
                    child: Text(
                      '${_quantity(item.quantity)}'
                      '${_show('showItemUnit') ? ' ${item.unit}' : ''}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                if (_show('showItemRate'))
                  Expanded(
                    flex: 2,
                    child: Text(
                      _money(item.unitPrice, invoice.currencySymbol),
                      textAlign: TextAlign.end,
                    ),
                  ),
                if (_show('showItemDiscount'))
                  Expanded(
                    child: Text(
                      '${item.discountRate}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                if (_show('showItemTax'))
                  Expanded(
                    child: Text(
                      '${item.taxRate}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _money(item.total, invoice.currencySymbol),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style:
                    bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
              ),
            ),
            Text(
              value,
              style: bold ? const TextStyle(fontWeight: FontWeight.w800) : null,
            ),
          ],
        ),
      );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child:
            _SummaryBlock(title: title.toUpperCase(), children: [Text(text)]),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'paid' => const Color(0xFF059669),
      'overdue' => const Color(0xFFDC2626),
      'sent' => const Color(0xFF2563EB),
      'cancelled' => Theme.of(context).colorScheme.outline,
      _ => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _quantity(double quantity) => quantity == quantity.truncateToDouble()
    ? quantity.toInt().toString()
    : '$quantity';

String _money(double amount, String symbol) =>
    '$symbol${amount.toStringAsFixed(2)}';
