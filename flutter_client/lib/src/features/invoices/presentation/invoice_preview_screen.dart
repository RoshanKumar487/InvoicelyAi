import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/utils/file_download_helper.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../../../shared/widgets/whatsapp_icon.dart';
import '../../settings/data/settings_repository.dart';
import '../../templates/data/template_config.dart';
import '../data/invoice.dart';
import '../data/invoice_docx_export.dart';
import '../data/invoice_pdf_export.dart';
import '../data/invoice_repository.dart';
import 'widgets/invoice_live_customize_sheet.dart';
import 'widgets/invoice_preview_a4_paper.dart';
import 'widgets/invoice_preview_widgets.dart';
import 'widgets/invoice_share_dialog.dart';
import '../../notifications/data/notification_repository.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    required this.invoice,
    required this.repository,
    required this.onBack,
    required this.onEdit,
    required this.onDeleted,
    this.onOpenBusinessSettings,
    this.preferredTemplate,
    this.localSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    super.key,
  });

  final Invoice invoice;
  final InvoiceRepository repository;
  final VoidCallback onBack;
  final ValueChanged<Invoice> onEdit;
  final VoidCallback onDeleted;
  final VoidCallback? onOpenBusinessSettings;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> localSettings;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late Invoice _invoice = widget.invoice;
  late Map<String, Object?> _localSettings =
      Map<String, Object?>.from(widget.localSettings);
  Map<String, dynamic> _profile = <String, dynamic>{};
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  late final LocalPreferences _studioPreferences =
      LocalPreferences(scope: 'template_studio');
  String? _selectedTemplateId;
  double _zoomScale = 1.0;
  double _basePinchScale = 1.0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStudioPreferences();
  }

  @override
  void didUpdateWidget(covariant InvoicePreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localSettings != widget.localSettings) {
      _localSettings = <String, Object?>{
        ..._localSettings,
        ...widget.localSettings,
      };
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudioPreferences() async {
    try {
      final updated = Map<String, Object?>.from(_localSettings);
      bool changed = false;

      Future<void> readIfMissingOrAlways(String prefKey, String mapKey, {bool alwaysPreferSaved = false}) async {
        final val = await _studioPreferences.readString(prefKey);
        if (val != null && val.isNotEmpty) {
          if (alwaysPreferSaved || updated[mapKey] == null || updated[mapKey].toString().isEmpty) {
            updated[mapKey] = val;
            changed = true;
          }
        }
      }

      await readIfMissingOrAlways('sections_cache', 'studio_sections_json', alwaysPreferSaved: true);
      await readIfMissingOrAlways('studio_preset', 'studio_preset');
      await readIfMissingOrAlways('studio_template_name', 'studio_template_name');
      await readIfMissingOrAlways('company_default_template_id', 'company_default_template_id');
      await readIfMissingOrAlways('preferredTemplateId', 'preferredTemplateId');
      await readIfMissingOrAlways('studio_primary_color', 'studio_primary_color');
      await readIfMissingOrAlways('studio_table_header_text_color', 'studio_table_header_text_color');
      await readIfMissingOrAlways('studio_font_family', 'studio_font_family');
      await readIfMissingOrAlways('studio_font_scale', 'studio_font_scale');
      await readIfMissingOrAlways('studio_table_border', 'studio_table_border');
      await readIfMissingOrAlways('studio_doc_title', 'customTitle');
      await readIfMissingOrAlways('studio_watermark', 'studio_watermark');
      await readIfMissingOrAlways('studio_page_margin', 'studio_page_margin');
      await readIfMissingOrAlways('invoiceLogo', 'invoiceLogo');
      await readIfMissingOrAlways('invoiceStamp', 'invoiceStamp');
      await readIfMissingOrAlways('invoiceSignature', 'invoiceSignature');
      await readIfMissingOrAlways('signeeName', 'signeeName');
      await readIfMissingOrAlways('signeeTitle', 'signeeTitle');
      await readIfMissingOrAlways('letterhead_style_id', 'letterhead_style_id', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_company_name', 'letterhead_company_name', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_tagline', 'letterhead_tagline', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_phone', 'letterhead_phone', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_email', 'letterhead_email', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_website', 'letterhead_website', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_address', 'letterhead_address', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_gstin', 'letterhead_gstin', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_pan', 'letterhead_pan', alwaysPreferSaved: true);
      await readIfMissingOrAlways('letterhead_cin', 'letterhead_cin', alwaysPreferSaved: true);

      final savedLhEnabled = await _studioPreferences.readString('letterhead_enabled');
      if (savedLhEnabled != null) {
        updated['letterhead_enabled'] = savedLhEnabled == 'true';
        changed = true;
      }
      final savedUppercase = await _studioPreferences.readString('studio_uppercase_headings');
      if (savedUppercase != null && updated['studio_uppercase_headings'] == null) {
        updated['studio_uppercase_headings'] = savedUppercase == 'true';
        changed = true;
      }
      final savedShowQr = await _studioPreferences.readString('studio_show_qr');
      if (savedShowQr != null && updated['showQrCode'] == null) {
        updated['showQrCode'] = savedShowQr == 'true';
        changed = true;
      }

      if (changed && mounted) {
        setState(() => _localSettings = updated);
      }
    } catch (_) {}
  }

  static const double a4PaperWidth = 760.0;

  double? _initialFitScale;
  double _lastViewportWidth = 0.0;

  void _initFitZoom(double viewportWidth) {
    if (_initialFitScale != null &&
        (_lastViewportWidth - viewportWidth).abs() < 2.0) {
      return;
    }
    _lastViewportWidth = viewportWidth;
    final fit = ((viewportWidth - 32) / a4PaperWidth).clamp(0.35, 1.05);
    _initialFitScale = fit;
    _zoomScale = fit;
  }

  void _zoomToFit(double viewportWidth) {
    final fit = ((viewportWidth - 32) / a4PaperWidth).clamp(0.35, 1.05);
    setState(() => _zoomScale = fit);
  }

  void _zoomToActual(double viewportWidth) {
    setState(() => _zoomScale = 1.0);
  }

  void _setZoomStep(double delta, double viewportWidth) {
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(0.35, 2.5);
    });
  }

  void _handleDoubleTap(double viewportWidth) {
    final fit = ((viewportWidth - 32) / a4PaperWidth).clamp(0.35, 1.05);
    if ((_zoomScale - fit).abs() < 0.08) {
      _zoomToActual(viewportWidth);
    } else {
      _zoomToFit(viewportWidth);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final repo = SettingsRepository(apiClient: widget.repository.apiClient);
      final profile = await repo.loadProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (_) {}
  }

  static String _mapPresetAlias(String id) {
    return switch (id) {
      'security_agency' => 'security_modern',
      'security_gst' => 'security_modern',
      'security-service' => 'security_modern',
      'consulting' => 'consulting_standard',
      'retail' => 'retail_standard',
      'modern' => 'modern_minimal',
      'gst_service' => 'gst_tax_invoice',
      _ => id,
    };
  }

  TemplateConfig? get _template {
    // 1. If user explicitly selected in the current preview session
    if (_selectedTemplateId != null) {
      if (widget.preferredTemplate?.id == _selectedTemplateId) {
        return widget.preferredTemplate;
      }
      for (final preset in templatePresets) {
        if (preset.id == _selectedTemplateId) return preset;
      }
      final aliasId = _mapPresetAlias(_selectedTemplateId!);
      for (final preset in templatePresets) {
        if (preset.id == aliasId) return preset;
      }
    }

    // 2. Company Default / Preferred Template from localSettings
    final prefId = _localSettings['preferredTemplateId']?.toString() ??
        _localSettings['company_default_template_id']?.toString() ??
        _localSettings['templateId']?.toString() ??
        _localSettings['studio_preset']?.toString();
    if (prefId != null && prefId.isNotEmpty) {
      if (widget.preferredTemplate?.id == prefId) {
        return widget.preferredTemplate;
      }
      for (final preset in templatePresets) {
        if (preset.id == prefId) return preset;
      }
      final aliasId = _mapPresetAlias(prefId);
      for (final preset in templatePresets) {
        if (preset.id == aliasId) return preset;
      }
    }

    // 3. User's customized preferredTemplate passed from AppShell
    if (widget.preferredTemplate != null) {
      return widget.preferredTemplate;
    }

    // 4. Fallback to invoice-level templateId if set
    final selectedId = _invoice.templateId;
    if (selectedId.isNotEmpty) {
      for (final preset in templatePresets) {
        if (preset.id == selectedId) return preset;
      }
      final aliasId = _mapPresetAlias(selectedId);
      for (final preset in templatePresets) {
        if (preset.id == aliasId) return preset;
      }
    }

    return templatePresets.first;
  }

  String get _activeCurrencySymbol {
    final s = _localSettings['defaultCurrencySymbol']?.toString().trim();
    if (s != null && s.isNotEmpty && s != r'$') return s;
    final c = _localSettings['defaultCurrency']?.toString().trim();
    if (c != null && c.isNotEmpty && c != 'USD') return currencySymbolFor(c);
    if (_invoice.currencySymbol.isNotEmpty && _invoice.currencySymbol != r'$') {
      return _invoice.currencySymbol;
    }
    if (_invoice.currencyCode.isNotEmpty && _invoice.currencyCode != 'USD') {
      return currencySymbolFor(_invoice.currencyCode);
    }
    return (s != null && s.isNotEmpty) ? s : '₹';
  }

  Invoice get _effectiveInvoice {
    final effectiveSymbol = _activeCurrencySymbol;
    final effectiveCode = _localSettings['defaultCurrency']?.toString().trim().isNotEmpty == true
        ? _localSettings['defaultCurrency']!.toString().trim().toUpperCase()
        : 'INR';
    if (_invoice.currencyCode == 'USD' || _invoice.currencySymbol == r'$') {
      return _invoice.copyWith(
        currencyCode: effectiveCode,
        currencySymbol: effectiveSymbol,
      );
    }
    return _invoice;
  }

  String? get _activeBusinessCategory {
    final domain = _localSettings['businessType']?.toString() ??
        _profile['businessType']?.toString() ??
        _localSettings['industryPresetId']?.toString();
    if (domain == 'security') return 'Security Agency';
    if (domain == 'it') return 'IT & Consulting';
    if (domain == 'retail') return 'Retail & GST';
    if (domain == 'wholesale') return 'Wholesale & Logistics';
    if (domain == 'freelance') return 'Freelance & Creative';
    final cat = _localSettings['businessCategory']?.toString() ??
        _profile['businessCategory']?.toString();
    if (cat != null && cat.isNotEmpty && cat != 'General') return cat;
    return null;
  }


  Future<void> _changeStatus(String status) async {
    final id = _invoice.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.updateStatus(id, status);
      if (mounted) setState(() => _invoice = updated);
      if (mounted) _showMessage('Invoice status updated to $status.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Could not update status: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _convertEstimateToInvoice() async {
    final id = _invoice.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.updateStatus(id, 'Sent');
      if (mounted) {
        setState(() {
          _invoice = updated;
          _localSettings['customTitle'] = 'Tax Invoice';
        });
        _showMessage('Converted to Tax Invoice successfully!');
      }
    } catch (e) {
      if (mounted) _showMessage('Could not convert estimate: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocuHubSigner() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: _localSettings['signeeName']?.toString(),
      initialSigneeTitle: _localSettings['signeeTitle']?.toString(),
    );
    if (result == null) return;

    final updated = Map<String, Object?>.from(_localSettings)
      ..['invoiceSignature'] = result.base64Png
      ..['showSignature'] = true;
    if (result.signeeName != null) {
      updated['signeeName'] = result.signeeName;
    }
    if (result.signeeTitle != null) {
      updated['signeeTitle'] = result.signeeTitle;
    }

    setState(() => _localSettings = updated);
    await widget.onSaveLocalSettings?.call(updated);
    if (mounted) {
      _showMessage('Signature captured & applied via DocuHub Studio!');
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
        '${_money(item.unitPrice, _activeCurrencySymbol)} | '
        '${_money(item.total, _activeCurrencySymbol)}',
      );
    }
    summary
      ..writeln()
      ..writeln(
          'Subtotal: ${_money(_invoice.subtotal, _activeCurrencySymbol)}')
      ..writeln(
        '${_invoice.taxLabel} (${_invoice.taxRate}%): '
        '${_money(_invoice.taxAmount, _activeCurrencySymbol)}',
      )
      ..writeln('Total: ${_money(_invoice.total, _activeCurrencySymbol)}')
      ..writeln(
        'Amount paid: ${_money(_invoice.amountPaid, _activeCurrencySymbol)}',
      )
      ..writeln(
        'Balance due: ${_money(_invoice.balanceDue, _activeCurrencySymbol)}',
      );
    if (_invoice.notes.isNotEmpty) {
      summary.writeln('\nNotes: ${_invoice.notes}');
    }
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (mounted) _showMessage('Invoice details copied to clipboard.');
  }

  String get _safeFileName =>
      _invoice.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<Uint8List> _generatePdfBytes() async {
    return InvoicePdfExport.build(
      _effectiveInvoice,
      template: _template,
      localSettings: _localSettings,
      businessProfile: _profile,
    );
  }

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await _generatePdfBytes();
      await Printing.layoutPdf(
        name: 'Invoice_$_safeFileName.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (mounted) _showMessage('Could not print invoice: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadOrSharePdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await _generatePdfBytes();
      final pdfName = 'Invoice_$_safeFileName.pdf';
      await FileDownloadHelper.downloadFile(
        bytes: bytes,
        filename: pdfName,
        mimeType: 'application/pdf',
      );
      if (mounted) _showMessage('✓ Saved $pdfName to Downloads');
    } catch (error) {
      if (mounted) _showMessage('Could not download PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareDocx() async {
    setState(() => _busy = true);
    try {
      final bytes = InvoiceDocxExport.build(
        _effectiveInvoice,
        template: _template,
        localSettings: _localSettings,
        businessProfile: _profile,
      );
      final name = 'Invoice_$_safeFileName.docx';
      await FileDownloadHelper.downloadFile(
        bytes: bytes,
        filename: name,
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      if (mounted) _showMessage('✓ Saved $name to Downloads');
    } catch (error) {
      if (mounted) _showMessage('Could not download DOCX: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openShareDialog({int initialTab = 0}) async {
    await InvoiceShareDialog.show(
      context,
      invoice: _effectiveInvoice,
      localSettings: _localSettings,
      businessProfile: _profile,
      template: _template,
      onSaveDefaultTemplate: (channel, text, subject) async {
        final updated = Map<String, Object?>.from(_localSettings);
        if (channel == 'whatsapp') {
          updated['whatsappDefaultTemplate'] = text;
        } else {
          updated['emailDefaultTemplate'] = text;
          if (subject != null) updated['emailDefaultSubject'] = subject;
        }
        await widget.onSaveLocalSettings?.call(updated);
        if (mounted) setState(() => _localSettings = updated);
      },
    );
  }

  Future<void> _shareWhatsApp() => _openShareDialog(initialTab: 0);

  Future<void> _shareEmail() => _openShareDialog(initialTab: 1);

  Future<void> _sendPaymentReminder() async {
    final invoice = _invoice;
    final invoiceId = invoice.id;

    final selectedChannel = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Color(0xFF0284C7)),
                  const SizedBox(width: 10),
                  Text(
                    'Send Payment Reminder (${invoice.invoiceNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Client: ${invoice.clientName} | Balance Due: ${_money(invoice.balanceDue, _activeCurrencySymbol)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.email_rounded, color: Colors.blue),
                ),
                title: const Text('Email Reminder (Background Engine)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Queue email to ${invoice.clientEmail.isNotEmpty ? invoice.clientEmail : "client email"} using template'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, 'EMAIL'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.chat_rounded, color: Colors.green),
                ),
                title: const Text('WhatsApp Reminder (Background Engine)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Queue WhatsApp to ${invoice.clientPhone.isNotEmpty ? invoice.clientPhone : "client phone"} using template'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, 'WHATSAPP'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.share_rounded, color: Colors.purple),
                ),
                title: const Text('Share via Device Apps', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open device share sheet or copy text message'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, 'LOCAL_SHARE'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedChannel == null) return;

    if (selectedChannel == 'LOCAL_SHARE' || invoiceId == null) {
      final text = 'Payment reminder for invoice ${invoice.invoiceNumber}\n'
          'Amount due: ${_money(invoice.balanceDue, _activeCurrencySymbol)}\n'
          'Due date: ${invoice.dueDate}\n'
          'Please let us know if you have any questions. Thank you.';
      try {
        final result = await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'Payment reminder - ${invoice.invoiceNumber}',
          ),
        );
        if (mounted && result.status == ShareResultStatus.unavailable) {
          _showMessage('Sharing is unavailable on this platform.');
        }
      } catch (error) {
        if (mounted) _showMessage('Could not share payment reminder: $error');
      }
      return;
    }

    try {
      final notifRepo = NotificationRepository(apiClient: widget.repository.apiClient);
      await notifRepo.sendInvoiceReminder(
        invoiceId: invoiceId,
        channel: selectedChannel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          content: Text('✓ Payment reminder queued for async dispatch via $selectedChannel!'),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Could not queue reminder: $error');
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

  void _openTemplatePickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvoiceLiveCustomizeSheet(
        selectedTemplateId: _template?.id,
        localSettings: _localSettings,
        studioPreferences: _studioPreferences,
        activeBusinessCategory: _activeBusinessCategory,
        onOpenDocuHubSigner: _openDocuHubSigner,
        onSettingsChanged: (updated) {
          if (mounted) {
            setState(() => _localSettings = updated);
          }
          widget.onSaveLocalSettings?.call(updated);
        },
        onSelectTemplate: (preset) {
          final updated = Map<String, Object?>.from(_localSettings)
            ..['preferredTemplateId'] = preset.id
            ..['studio_primary_color'] = preset.color
            ..['customTitle'] = preset.title;
          setState(() {
            _localSettings = updated;
            _selectedTemplateId = preset.id;
            _invoice = _invoice.copyWith(templateId: preset.id);
          });
          widget.onSaveLocalSettings?.call(updated);
        },
        onSetDefaultTemplate: (preset) async {
          final updated = Map<String, Object?>.from(_localSettings)
            ..['preferredTemplateId'] = preset.id
            ..['company_default_template_id'] = preset.id
            ..['studio_primary_color'] = preset.color
            ..['customTitle'] = preset.title
            ..['customItemHeader'] = preset.itemHeader
            ..['customQtyHeader'] = preset.quantityHeader
            ..['customRateHeader'] = preset.rateHeader
            ..['customAmountHeader'] = preset.amountHeader
            ..['customDutyHeader'] = preset.dutyHeader
            ..['showItemDuty'] = preset.showDuty;
          await _studioPreferences.writeString('preferredTemplateId', preset.id);
          await _studioPreferences.writeString('company_default_template_id', preset.id);
          await widget.onSaveLocalSettings?.call(updated);
          if (mounted) {
            setState(() {
              _localSettings = updated;
              _selectedTemplateId = preset.id;
              _invoice = _invoice.copyWith(templateId: preset.id);
            });
            _showMessage('✓ Template "${preset.name}" set as company default!');
          }
        },
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _effectiveInvoice;
    final template = _template;
    final templateColor = _templateColor(
      template?.color,
      Theme.of(context).colorScheme.primary,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isEstimate = invoice.status.toLowerCase().contains('quotation') ||
        invoice.status.toLowerCase().contains('estimate') ||
        (template?.title.toLowerCase().contains('estimate') ?? false) ||
        (template?.title.toLowerCase().contains('quotation') ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek high-contrast dark canvas
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: InkWell(
          onTap: () => _openTemplatePickerSheet(context),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        template?.name ?? 'Customize Design & Sections',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [

          // 1. LIVE CUSTOMIZE DESIGN & SECTIONS STUDIO
          _buildPillButton(
            tooltip: 'Customize Design, Sections, Colors & Columns',
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => _openTemplatePickerSheet(context),
            ),
          ),

          // 2. EXPORT / SHARE PDF (Red circular pill)
          _buildPillButton(
            tooltip: 'Export / Download PDF',
            backgroundColor:
                isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
            child: IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                size: 18,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
              onPressed: _busy ? null : _downloadOrSharePdf,
            ),
          ),

          // 3. PRINT DIRECTLY TO PRINTER (Blue circular pill)
          _buildPillButton(
            tooltip: 'Print to printer',
            backgroundColor:
                isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
            child: IconButton(
              icon: Icon(
                Icons.print_rounded,
                size: 18,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              ),
              onPressed: _busy ? null : _printPdf,
            ),
          ),

          // 4. EXPORT WORD DOCX (Indigo/Green pill)
          _buildPillButton(
            tooltip: 'Export Word (.docx)',
            backgroundColor:
                isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
            child: IconButton(
              icon: Icon(
                Icons.description_rounded,
                size: 18,
                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
              ),
              onPressed: _busy ? null : _shareDocx,
            ),
          ),

          // 5. EDIT INVOICE (Pill button)
          _buildPillButton(
            tooltip: 'Edit Invoice',
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            child: IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 17,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: _busy ? null : () => widget.onEdit(_effectiveInvoice),
            ),
          ),

          // 4. OVERFLOW MENU (3 dots: Sign, WhatsApp, DOCX, Reminder, Copy, Status, Delete)
          PopupMenuButton<String>(
            tooltip: 'More actions',
            enabled: !_busy,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              switch (action) {
                case 'sign':
                  _openDocuHubSigner();
                case 'whatsapp':
                  _shareWhatsApp();
                case 'email':
                  _shareEmail();
                case 'docx':
                  _shareDocx();
                case 'reminder':
                  _sendPaymentReminder();
                case 'copy':
                  _copySummary();
                case 'delete':
                  _delete();
                case 'branding':
                  widget.onOpenBusinessSettings?.call();
                default:
                  if (action.startsWith('status:')) {
                    _changeStatus(action.substring(7));
                  }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sign',
                child: ListTile(
                  leading: Icon(Icons.draw_rounded, color: Color(0xFF2563EB)),
                  title: Text('DocuHub Digital Sign'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: ListTile(
                  leading: WhatsAppIcon(size: 20),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: ListTile(
                  leading: Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'docx',
                child: ListTile(
                  leading: Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
                  title: Text('Generate DOCX file'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (invoice.balanceDue > 0 &&
                  invoice.status.toLowerCase() != 'paid')
                const PopupMenuItem(
                  value: 'reminder',
                  child: ListTile(
                    leading: Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706)),
                    title: Text('Send payment reminder'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy_rounded),
                  title: Text('Copy invoice text'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.onOpenBusinessSettings != null)
                const PopupMenuItem(
                  value: 'branding',
                  child: ListTile(
                    leading: Icon(Icons.branding_watermark_outlined),
                    title: Text('Business branding'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'Change Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'status:Draft',
                child: Text('• Draft'),
              ),
              const PopupMenuItem(
                value: 'status:Sent',
                child: Text('• Sent'),
              ),
              const PopupMenuItem(
                value: 'status:Paid',
                child: Text('• Paid'),
              ),
              const PopupMenuItem(
                value: 'status:Overdue',
                child: Text('• Overdue'),
              ),
              const PopupMenuItem(
                value: 'status:Cancelled',
                child: Text('• Cancelled'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Delete invoice',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          _initFitZoom(viewportWidth);
          final scaledPaperWidth = (a4PaperWidth * _zoomScale).clamp(240.0, 2200.0);

          return Stack(
            children: [
              // FULL PAGE SMOOTH SCROLLABLE & ZOOMABLE A4 WORKSPACE (MOUSE + TOUCH + TRACKPAD)
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    if (HardwareKeyboard.instance.isControlPressed ||
                        HardwareKeyboard.instance.isMetaPressed) {
                      // Ctrl + Mouse Wheel = Smooth Zoom In / Out
                      final delta = pointerSignal.scrollDelta.dy < 0 ? 0.08 : -0.08;
                      _setZoomStep(delta, viewportWidth);
                    } else if (HardwareKeyboard.instance.isShiftPressed &&
                        _horizontalScrollController.hasClients) {
                      // Shift + Mouse Wheel = Smooth Horizontal Scroll
                      final target = (_horizontalScrollController.offset +
                              pointerSignal.scrollDelta.dy)
                          .clamp(
                        0.0,
                        _horizontalScrollController.position.maxScrollExtent,
                      );
                      _horizontalScrollController.jumpTo(target);
                    }
                  }
                },
                child: GestureDetector(
                  onDoubleTap: () => _handleDoubleTap(viewportWidth),
                  onScaleStart: (details) {
                    _basePinchScale = _zoomScale;
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount >= 2 &&
                        (details.scale - 1.0).abs() > 0.01) {
                      setState(() {
                        _zoomScale = (_basePinchScale * details.scale)
                            .clamp(0.35, 2.5);
                      });
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: const {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: Scrollbar(
                      controller: _verticalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 16 : 24,
                        ),
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: viewportWidth,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: SizedBox(
                                  width: scaledPaperWidth,
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: a4PaperWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Quotation / Estimate conversion banner
                                          if (isEstimate) ...[
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF064E3B),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFF059669),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              '📑 Quotation / Estimate',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                                fontSize: 14,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                  0xFF10B981,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(4),
                                                              ),
                                                              child: const Text(
                                                                'ESTIMATE',
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        const Text(
                                                          'Ready to finalize this estimate into a bill?',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFFA7F3D0),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  FilledButton(
                                                    onPressed: _busy
                                                        ? null
                                                        : _convertEstimateToInvoice,
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(0xFF10B981),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          8,
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Convert to Tax Invoice',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          // A4 PAPER DOCUMENT CARD (DESIGNED IN TEMPLATE STUDIO)
                                          _buildA4Paper(
                                            invoice: invoice,
                                            template: template,
                                            templateColor: templateColor,
                                            isMobile: isMobile,
                                          ),

                                          const SizedBox(
                                            height: 96,
                                          ), // bottom clearance for zoom bar
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // FLOATING QUICK ZOOM THUMB CONTROLLER (RESPONSIVE ON MOBILE & DESKTOP)
              Positioned(
                left: isMobile ? 16 : null,
                right: 16,
                bottom: 16,
                child: Align(
                  alignment: isMobile ? Alignment.bottomCenter : Alignment.bottomRight,
                  child: Material(
                  color: isDark
                      ? const Color(0xEE1E293B)
                      : Colors.white.withAlpha(245),
                  elevation: 8,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(40)
                            : Colors.black.withAlpha(25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_out, size: 18),
                          tooltip: 'Zoom Out',
                          onPressed: () => _setZoomStep(-0.15, viewportWidth),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.fit_screen_rounded, size: 18),
                          tooltip: 'Fit Page to Screen',
                          onPressed: () => _zoomToFit(viewportWidth),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        InkWell(
                          onTap: () => _handleDoubleTap(viewportWidth),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              '${(_zoomScale * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in, size: 18),
                          tooltip: 'Zoom In',
                          onPressed: () => _setZoomStep(0.15, viewportWidth),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          tooltip: '100% Print Actual Size',
                          onPressed: () => _zoomToActual(viewportWidth),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  Widget _buildPillButton({
    required Widget child,
    required Color backgroundColor,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildA4Paper({
    required Invoice invoice,
    required TemplateConfig? template,
    required Color templateColor,
    required bool isMobile,
  }) {
    return InvoicePreviewA4Paper(
      invoice: invoice,
      template: template,
      templateColor: templateColor,
      isMobile: isMobile,
      localSettings: _localSettings,
      profile: _profile,
      onSignTap: _openDocuHubSigner,
    );
  }
}

Color _templateColor(String? hex, Color fallback) => parseTemplateColor(hex, fallback);
String _quantity(double quantity) => formatQuantity(quantity);
String _money(double amount, String symbol) => formatMoney(amount, symbol);
