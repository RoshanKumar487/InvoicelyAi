import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/whatsapp_icon.dart';
import '../../data/invoice.dart';
import '../../../templates/data/template_config.dart';
import '../../data/invoice_pdf_export.dart';

class InvoiceShareDialog extends StatefulWidget {
  const InvoiceShareDialog({
    required this.invoice,
    required this.localSettings,
    required this.businessProfile,
    this.template,
    this.onSaveDefaultTemplate,
    super.key,
  });

  final Invoice invoice;
  final Map<String, Object?> localSettings;
  final Map<String, dynamic> businessProfile;
  final TemplateConfig? template;
  final Future<void> Function(String channel, String templateText, String? subject)? onSaveDefaultTemplate;

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    required Map<String, Object?> localSettings,
    required Map<String, dynamic> businessProfile,
    TemplateConfig? template,
    Future<void> Function(String channel, String templateText, String? subject)? onSaveDefaultTemplate,
  }) =>
      showDialog<void>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) => Dialog.fullscreen(
          child: InvoiceShareDialog(
            invoice: invoice,
            localSettings: localSettings,
            businessProfile: businessProfile,
            template: template,
            onSaveDefaultTemplate: onSaveDefaultTemplate,
          ),
        ),
      );

  @override
  State<InvoiceShareDialog> createState() => _InvoiceShareDialogState();
}

class _InvoiceShareDialogState extends State<InvoiceShareDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _whatsappMsgCtrl;
  late final TextEditingController _emailSubjectCtrl;
  late final TextEditingController _emailBodyCtrl;
  late final TextEditingController _recipientPhoneCtrl;
  late final TextEditingController _recipientEmailCtrl;

  bool _attachPdf = true;
  bool _isGeneratingPdf = false;
  bool _isSavingTemplate = false;

  static const String _defaultWhatsappTemplate =
      '🌟 *INVOICE FROM {company_name}* 🌟\n\n'
      'Dear {client_name},\n'
      'Please find attached invoice *#{invoice_number}* dated {invoice_date}.\n\n'
      '💵 *Total Amount Due:* {total_amount}\n'
      '📅 *Due Date:* {due_date}\n\n'
      '🏦 *Payment Details:*\n'
      '• UPI ID: {upi_id}\n'
      '• Bank: {bank_name}\n'
      '• A/C No: {account_number}\n'
      '• IFSC: {ifsc_code}\n\n'
      'Thank you for your business!';

  static const String _defaultEmailSubject =
      'Invoice #{invoice_number} from {company_name} - Due {due_date}';

  static const String _defaultEmailBody =
      'Dear {client_name},\n\n'
      'Please find attached Invoice #{invoice_number} from {company_name}.\n\n'
      'INVOICE SUMMARY:\n'
      '• Invoice Number: #{invoice_number}\n'
      '• Issue Date: {invoice_date}\n'
      '• Due Date: {due_date}\n'
      '• Total Amount Due: {total_amount}\n\n'
      'BANK & PAYMENT DETAILS:\n'
      '• Bank Name: {bank_name}\n'
      '• Account Holder: {account_holder}\n'
      '• Account Number: {account_number}\n'
      '• IFSC Code: {ifsc_code}\n'
      '• UPI ID: {upi_id}\n\n'
      'If you have any questions regarding this invoice, please do not hesitate to contact us.\n\n'
      'Warm regards,\n'
      '{company_name}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final ls = widget.localSettings;
    final savedWhatsapp = ls['whatsappDefaultTemplate']?.toString().trim();
    final savedEmailSubject = ls['emailDefaultSubject']?.toString().trim();
    final savedEmailBody = ls['emailDefaultTemplate']?.toString().trim();

    _whatsappMsgCtrl = TextEditingController(
      text: (savedWhatsapp != null && savedWhatsapp.isNotEmpty)
          ? savedWhatsapp
          : _defaultWhatsappTemplate,
    );

    _emailSubjectCtrl = TextEditingController(
      text: (savedEmailSubject != null && savedEmailSubject.isNotEmpty)
          ? savedEmailSubject
          : _defaultEmailSubject,
    );

    _emailBodyCtrl = TextEditingController(
      text: (savedEmailBody != null && savedEmailBody.isNotEmpty)
          ? savedEmailBody
          : _defaultEmailBody,
    );

    _recipientPhoneCtrl = TextEditingController(text: widget.invoice.clientPhone);
    _recipientEmailCtrl = TextEditingController(text: widget.invoice.clientEmail);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _whatsappMsgCtrl.dispose();
    _emailSubjectCtrl.dispose();
    _emailBodyCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _recipientEmailCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _buildTokens() {
    final inv = widget.invoice;
    final prof = widget.businessProfile;
    final ls = widget.localSettings;

    final companyName = (ls['businessName']?.toString().trim().isNotEmpty == true)
        ? ls['businessName']!.toString().trim()
        : ((prof['businessName']?.toString().trim().isNotEmpty == true)
            ? prof['businessName']!.toString().trim()
            : ((prof['companyName']?.toString().trim().isNotEmpty == true)
                ? prof['companyName']!.toString().trim()
                : 'Our Company'));

    final sym = inv.currencySymbol.isNotEmpty ? inv.currencySymbol : '₹';
    final totalDue = '$sym${inv.balanceDue.toStringAsFixed(2)}';

    return <String, String>{
      'client_name': inv.clientName.trim().isNotEmpty ? inv.clientName.trim() : 'Valued Client',
      'company_name': companyName,
      'invoice_number': inv.invoiceNumber,
      'invoice_date': inv.issueDate,
      'due_date': inv.dueDate,
      'total_amount': totalDue,
      'balance_due': totalDue,
      'currency': sym,
      'upi_id': (prof['upiId'] ?? ls['upiId'] ?? '').toString(),
      'bank_name': (prof['bankName'] ?? ls['bankName'] ?? '').toString(),
      'account_holder': (prof['accountHolder'] ?? ls['accountHolder'] ?? '').toString(),
      'account_number': (prof['accountNumber'] ?? ls['accountNumber'] ?? '').toString(),
      'ifsc_code': (prof['ifscCode'] ?? ls['ifscCode'] ?? '').toString(),
      'payment_link': (prof['paymentLink'] ?? ls['paymentLink'] ?? '').toString(),
    };
  }

  String _resolve(String text) {
    var out = text;
    for (final entry in _buildTokens().entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }

  Future<Uint8List> _generatePdfBytes() => InvoicePdfExport.build(
        widget.invoice,
        template: widget.template,
        localSettings: widget.localSettings,
        businessProfile: widget.businessProfile,
      );

  Future<void> _shareViaWhatsApp() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final text = _resolve(_whatsappMsgCtrl.text);
      final safeInvNum = widget.invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final pdfName = 'Invoice_$safeInvNum.pdf';

      if (_attachPdf) {
        final pdfBytes = await _generatePdfBytes();
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            files: [
              XFile.fromData(
                pdfBytes,
                mimeType: 'application/pdf',
                name: pdfName,
              ),
            ],
            fileNameOverrides: [pdfName],
            subject: 'Invoice #${widget.invoice.invoiceNumber}',
          ),
        );
      } else {
        // Direct WhatsApp launch with phone if available
        final phone = _recipientPhoneCtrl.text.replaceAll(RegExp(r'[^0-9+]'), '');
        final uri = Uri.parse(
          phone.isNotEmpty
              ? 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}'
              : 'https://wa.me/?text=${Uri.encodeComponent(text)}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await SharePlus.instance.share(
            ShareParams(
              text: text,
              subject: 'Invoice #${widget.invoice.invoiceNumber}',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete WhatsApp share: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareViaEmail() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final subject = _resolve(_emailSubjectCtrl.text);
      final body = _resolve(_emailBodyCtrl.text);
      final recipient = _recipientEmailCtrl.text.trim();
      final safeInvNum = widget.invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final pdfName = 'Invoice_$safeInvNum.pdf';

      if (_attachPdf) {
        final pdfBytes = await _generatePdfBytes();
        await SharePlus.instance.share(
          ShareParams(
            subject: subject,
            text: body,
            files: [
              XFile.fromData(
                pdfBytes,
                mimeType: 'application/pdf',
                name: pdfName,
              ),
            ],
            fileNameOverrides: [pdfName],
          ),
        );
      } else {
        final mailtoUri = Uri(
          scheme: 'mailto',
          path: recipient,
          queryParameters: <String, String>{
            'subject': subject,
            'body': body,
          },
        );
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        } else {
          await SharePlus.instance.share(
            ShareParams(subject: subject, text: body),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _saveCurrentAsDefault(String channel) async {
    setState(() => _isSavingTemplate = true);
    try {
      if (channel == 'whatsapp') {
        await widget.onSaveDefaultTemplate?.call('whatsapp', _whatsappMsgCtrl.text, null);
      } else {
        await widget.onSaveDefaultTemplate?.call('email', _emailBodyCtrl.text, _emailSubjectCtrl.text);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF047857),
            content: Text('✓ Saved as your default ${channel == 'whatsapp' ? 'WhatsApp' : 'Email'} template!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingTemplate = false);
    }
  }

  void _insertToken(TextEditingController ctrl, String token) {
    final text = ctrl.text;
    final selection = ctrl.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, '{$token}');
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length + 2),
    );
  }

  Widget _tokenChip(String token, String label, TextEditingController ctrl) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 13, color: Color(0xFF2563EB)),
      label: Text('{$token}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      tooltip: label,
      onPressed: () => _insertToken(ctrl, token),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share & Send Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: WhatsAppIcon(size: 20),
              text: 'WhatsApp Message',
            ),
            Tab(
              icon: Icon(Icons.email_outlined),
              text: 'Email Template',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWhatsappTab(),
          _buildEmailTab(),
        ],
      ),
    );
  }

  Widget _buildWhatsappTab() {
    final preview = _resolve(_whatsappMsgCtrl.text);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recipient card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const WhatsAppIcon(size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Client WhatsApp Recipient',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _recipientPhoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Recipient Phone Number (with Country Code)',
                  hintText: '+91 98765 43210',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _attachPdf,
                onChanged: (val) => setState(() => _attachPdf = val ?? true),
                title: const Text('Attach official PDF invoice to share', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('Includes company seal, signature, bank details and line items', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Template Editor
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_note, size: 20, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text('Customize WhatsApp Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _whatsappMsgCtrl.text = _defaultWhatsappTemplate);
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Tap chips below to insert dynamic invoice variables into your message:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tokenChip('client_name', 'Client Name', _whatsappMsgCtrl),
                  _tokenChip('company_name', 'Company Name', _whatsappMsgCtrl),
                  _tokenChip('invoice_number', 'Invoice #', _whatsappMsgCtrl),
                  _tokenChip('total_amount', 'Total Amount', _whatsappMsgCtrl),
                  _tokenChip('due_date', 'Due Date', _whatsappMsgCtrl),
                  _tokenChip('upi_id', 'UPI ID', _whatsappMsgCtrl),
                  _tokenChip('bank_name', 'Bank Name', _whatsappMsgCtrl),
                  _tokenChip('account_number', 'Account #', _whatsappMsgCtrl),
                  _tokenChip('ifsc_code', 'IFSC Code', _whatsappMsgCtrl),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsappMsgCtrl,
                maxLines: 10,
                minLines: 6,
                style: const TextStyle(fontSize: 13, height: 1.4),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isSavingTemplate ? null : () => _saveCurrentAsDefault('whatsapp'),
                  icon: const Icon(Icons.bookmark_border, size: 16),
                  label: Text(_isSavingTemplate ? 'Saving...' : 'Save as Default WhatsApp Template'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Preview Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE7FCE8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  WhatsAppIcon(size: 16, color: Color(0xFF047857)),
                  SizedBox(width: 6),
                  Text('LIVE WHATSAPP PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                preview,
                style: const TextStyle(fontSize: 13, color: Color(0xFF064E3B), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _isGeneratingPdf ? null : _shareViaWhatsApp,
          icon: _isGeneratingPdf
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const WhatsAppIcon(size: 20, color: Colors.white),
          label: Text(_isGeneratingPdf ? 'Preparing Invoice...' : 'Send via WhatsApp Now'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTab() {
    final resolvedSubject = _resolve(_emailSubjectCtrl.text);
    final resolvedBody = _resolve(_emailBodyCtrl.text);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recipient card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.alternate_email, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Email Recipient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _recipientEmailCtrl,
                decoration: InputDecoration(
                  labelText: 'Client Email Address',
                  hintText: 'accounts@clientcompany.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _attachPdf,
                onChanged: (val) => setState(() => _attachPdf = val ?? true),
                title: const Text('Attach official PDF invoice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('Sends attached Invoice PDF with complete line breakdown & stamp', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Template Editor
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_note, size: 20, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text('Customize Email Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _emailSubjectCtrl.text = _defaultEmailSubject;
                        _emailBodyCtrl.text = _defaultEmailBody;
                      });
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Tap chips to insert variables into subject or email body:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tokenChip('client_name', 'Client Name', _emailBodyCtrl),
                  _tokenChip('company_name', 'Company Name', _emailBodyCtrl),
                  _tokenChip('invoice_number', 'Invoice #', _emailBodyCtrl),
                  _tokenChip('total_amount', 'Total Amount', _emailBodyCtrl),
                  _tokenChip('due_date', 'Due Date', _emailBodyCtrl),
                  _tokenChip('upi_id', 'UPI ID', _emailBodyCtrl),
                  _tokenChip('bank_name', 'Bank Name', _emailBodyCtrl),
                  _tokenChip('account_holder', 'Holder Name', _emailBodyCtrl),
                  _tokenChip('account_number', 'Account #', _emailBodyCtrl),
                  _tokenChip('ifsc_code', 'IFSC Code', _emailBodyCtrl),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailSubjectCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Subject Template',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailBodyCtrl,
                maxLines: 12,
                minLines: 6,
                style: const TextStyle(fontSize: 13, height: 1.4),
                decoration: InputDecoration(
                  labelText: 'Email Body Template',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isSavingTemplate ? null : () => _saveCurrentAsDefault('email'),
                  icon: const Icon(Icons.bookmark_border, size: 16),
                  label: Text(_isSavingTemplate ? 'Saving...' : 'Save as Default Email Template'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Email Preview Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 6),
                  Text('LIVE EMAIL PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Subject: $resolvedSubject', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const Divider(height: 14),
              SelectableText(
                resolvedBody,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _isGeneratingPdf ? null : _shareViaEmail,
          icon: _isGeneratingPdf
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isGeneratingPdf ? 'Preparing Invoice...' : 'Send via Email Now'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
