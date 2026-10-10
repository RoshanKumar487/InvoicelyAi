import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../../../shared/widgets/whatsapp_icon.dart';
import '../../settings/data/settings_repository.dart';
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

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late Invoice _invoice = widget.invoice;
  late Map<String, Object?> _localSettings =
      Map<String, Object?>.from(widget.localSettings);
  Map<String, dynamic> _profile = <String, dynamic>{};
  final TransformationController _zoomController = TransformationController();
  String? _selectedTemplateId;
  double _zoomScale = 1.0;
  bool _busy = false;

  AnimationController? _animController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _zoomController.value = _zoomAnimation!.value;
          setState(() {
            _zoomScale = _zoomController.value.getMaxScaleOnAxis();
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant InvoicePreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localSettings != widget.localSettings) {
      _localSettings = Map<String, Object?>.from(widget.localSettings);
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  static const double a4PaperWidth = 760.0;
  static const double a4PaperMinHeight = 1075.0;

  double? _initialFitScale;
  double _lastViewportWidth = 0.0;

  void _initFitZoom(double viewportWidth) {
    if (_initialFitScale != null && (_lastViewportWidth - viewportWidth).abs() < 2.0) {
      return;
    }
    _lastViewportWidth = viewportWidth;
    final fit = ((viewportWidth - 24) / a4PaperWidth).clamp(0.25, 1.2);
    _initialFitScale = fit;
    final tx = (viewportWidth - a4PaperWidth * fit) / 2;
    final targetMatrix = Matrix4.identity()
      ..translate(tx, 16.0)
      ..scale(fit, fit);
    _zoomController.value = targetMatrix;
    _zoomScale = fit;
  }

  void _animateToMatrix(Matrix4 targetMatrix, double targetScale) {
    if (_animController != null) {
      _zoomAnimation = Matrix4Tween(
        begin: _zoomController.value,
        end: targetMatrix,
      ).animate(
        CurvedAnimation(parent: _animController!, curve: Curves.easeOutCubic),
      );
      _animController!.forward(from: 0);
    } else {
      _zoomController.value = targetMatrix;
      setState(() => _zoomScale = targetScale);
    }
  }

  void _zoomToFit(double viewportWidth) {
    final fit = ((viewportWidth - 24) / a4PaperWidth).clamp(0.25, 1.2);
    final tx = (viewportWidth - a4PaperWidth * fit) / 2;
    final targetMatrix = Matrix4.identity()
      ..translate(tx, 16.0)
      ..scale(fit, fit);
    _animateToMatrix(targetMatrix, fit);
  }

  void _zoomToActual(double viewportWidth) {
    const actual = 1.0;
    final tx = ((viewportWidth - a4PaperWidth) / 2).clamp(-380.0, 16.0);
    final targetMatrix = Matrix4.identity()
      ..translate(tx, 16.0)
      ..scale(actual, actual);
    _animateToMatrix(targetMatrix, actual);
  }

  void _setZoomStep(double delta, double viewportWidth) {
    final newScale = (_zoomScale + delta).clamp(0.25, 3.5);
    final tx = (viewportWidth - a4PaperWidth * newScale) / 2;
    final targetMatrix = Matrix4.identity()
      ..translate(tx.clamp(-400.0, 24.0), 16.0)
      ..scale(newScale, newScale);
    _animateToMatrix(targetMatrix, newScale);
  }

  void _handleDoubleTap(double viewportWidth) {
    final fit = ((viewportWidth - 24) / a4PaperWidth).clamp(0.25, 1.2);
    if ((_zoomScale - fit).abs() < 0.12) {
      _zoomToActual(viewportWidth);
    } else {
      _zoomToFit(viewportWidth);
    }
  }

  bool _show(String key, {bool fallback = true}) {
    if (_localSettings.containsKey(key)) {
      return _localSettings[key] == true;
    }
    return fallback;
  }

  String _label(String key, String fallback) {
    final custom = _localSettings[key]?.toString().trim();
    return (custom != null && custom.isNotEmpty) ? custom : fallback;
  }

  List<Map<String, dynamic>> _customFields(String key) {
    final raw = _localSettings[key];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return <Map<String, dynamic>>[];
  }

  Image? _brandImage(String key, {double height = 65}) {
    final encoded = _localSettings[key]?.toString() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return Image.memory(
        base64Decode(encoded),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } on FormatException {
      return null;
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

  TemplateConfig? get _template {
    // If user explicitly switched via popup menu, find that preset
    if (_selectedTemplateId != null) {
      for (final preset in templatePresets) {
        if (preset.id == _selectedTemplateId) return preset;
      }
      if (widget.preferredTemplate?.id == _selectedTemplateId) {
        return widget.preferredTemplate;
      }
    }

    // Otherwise, prefer the user's customized preferredTemplate
    if (widget.preferredTemplate != null) {
      if (_invoice.templateId.isEmpty ||
          _invoice.templateId == widget.preferredTemplate!.id) {
        return widget.preferredTemplate;
      }
    }

    final selectedId = _invoice.templateId;
    for (final preset in templatePresets) {
      if (preset.id == selectedId) return preset;
    }
    return widget.preferredTemplate ?? templatePresets.first;
  }

  List<String> _shippingLines() {
    final json = _invoice.shippingDetailsJson;
    if (json.trim().isEmpty || json.trim() == '{}') return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic> || decoded['isEnabled'] != true) {
        return const [];
      }
      const fields = <String, String>{
        'shippingAddress': 'Shipping address',
        'deliveryAddress': 'Delivery address',
        'shippingMethod': 'Shipping method',
        'courier': 'Carrier',
        'trackingNumber': 'Tracking',
        'expectedDelivery': 'Expected delivery',
      };
      return fields.entries
          .where((entry) =>
              decoded[entry.key]?.toString().trim().isNotEmpty == true)
          .map((entry) => '${entry.value}: ${decoded[entry.key]}')
          .toList(growable: false);
    } on FormatException {
      return const ['Shipping details could not be displayed.'];
    }
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

  String get _safeFileName =>
      _invoice.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await InvoicePdfExport.build(
        _invoice,
        template: _template,
        localSettings: _localSettings,
        businessProfile: _profile,
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

  Future<void> _shareDocx() async {
    setState(() => _busy = true);
    try {
      final bytes = InvoiceDocxExport.build(
        _invoice,
        template: _template,
        localSettings: _localSettings,
        businessProfile: _profile,
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

  Future<void> _shareWhatsApp() async {
    setState(() => _busy = true);
    try {
      final bytes = await InvoicePdfExport.build(
        _invoice,
        template: _template,
        localSettings: _localSettings,
        businessProfile: _profile,
      );
      final pdfName = 'Invoice_$_safeFileName.pdf';
      final shareText =
          '${_template?.title ?? "Invoice"} #${_invoice.invoiceNumber}\n'
          'Amount Due: ${_money(_invoice.balanceDue, _invoice.currencySymbol)}\n'
          'Due Date: ${_invoice.dueDate}\n\n'
          'Thank you for your business!';

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: pdfName,
            ),
          ],
          fileNameOverrides: [pdfName],
          subject: 'Invoice ${_invoice.invoiceNumber}',
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Could not share on WhatsApp: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPaymentReminder() async {
    final invoice = _invoice;
    final text = 'Payment reminder for invoice ${invoice.invoiceNumber}\n'
        'Amount due: ${_money(invoice.balanceDue, invoice.currencySymbol)}\n'
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
        title: Column(
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
            Text(
              template?.name ?? 'Standard Template',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          // 1. SWITCH TEMPLATE (Icon pill button with popup menu)
          _buildPillButton(
            tooltip: 'Switch Template',
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            child: PopupMenuButton<String>(
              tooltip: 'Switch Template',
              icon: Icon(
                Icons.tune_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              padding: EdgeInsets.zero,
              onSelected: (id) => setState(() => _selectedTemplateId = id),
              itemBuilder: (context) => [
                for (final preset in templatePresets)
                  PopupMenuItem(
                    value: preset.id,
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _templateColor(preset.color, Colors.blue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            preset.name,
                            style: TextStyle(
                              fontWeight: preset.id == template?.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: preset.id == template?.id
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (preset.id == template?.id)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 2. DOWNLOAD / PRINT PDF (Red circular pill)
          _buildPillButton(
            tooltip: 'Download / Print PDF',
            backgroundColor:
                isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
            child: IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                size: 18,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
              onPressed: _busy ? null : _printPdf,
            ),
          ),

          // 3. GENERATE DOCX (Blue circular pill)
          _buildPillButton(
            tooltip: 'Generate DOCX',
            backgroundColor:
                isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
            child: IconButton(
              icon: Icon(
                Icons.download_rounded,
                size: 18,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              ),
              onPressed: _busy ? null : _shareDocx,
            ),
          ),

          // 4. WHATSAPP SHARE (Green circular pill)
          _buildPillButton(
            tooltip: 'Share via WhatsApp',
            backgroundColor:
                isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
            child: IconButton(
              icon: const WhatsAppIcon(size: 19),
              onPressed: _busy ? null : _shareWhatsApp,
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
              onPressed: _busy ? null : () => widget.onEdit(_invoice),
            ),
          ),

          // 6. SEND REMINDER (Amber circular pill when unpaid)
          if (invoice.balanceDue > 0 &&
              invoice.status.toLowerCase() != 'paid')
            _buildPillButton(
              tooltip: 'Send Payment Reminder',
              backgroundColor:
                  isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_active_rounded,
                  size: 17,
                  color: isDark
                      ? const Color(0xFFFCD34D)
                      : const Color(0xFFD97706),
                ),
                onPressed: _busy ? null : _sendPaymentReminder,
              ),
            ),

          // 7. OVERFLOW MENU
          PopupMenuButton<String>(
            tooltip: 'More actions',
            enabled: !_busy,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              switch (action) {
                case 'sign':
                  _openDocuHubSigner();
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

          return Stack(
            children: [
              // FULL PAGE ZOOMABLE CANVAS (EXACT A4 PROPORTIONS)
              GestureDetector(
                onDoubleTap: () => _handleDoubleTap(viewportWidth),
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: 0.25,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.symmetric(horizontal: 160, vertical: 200),
                  constrained: false,
                  clipBehavior: Clip.none,
                  onInteractionUpdate: (_) {
                    final currentScale = _zoomController.value.getMaxScaleOnAxis();
                    if ((currentScale - _zoomScale).abs() > 0.02) {
                      setState(() => _zoomScale = currentScale);
                    }
                  },
                  child: SizedBox(
                    width: a4PaperWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quotation / Estimate conversion banner (Kotlin style)
                        if (isEstimate) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF059669),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '📑 Quotation / Estimate',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'ESTIMATE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
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
                                  onPressed: _busy ? null : _convertEstimateToInvoice,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
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

                        // A4 PAPER DOCUMENT CARD (EXACT PDF PRINT SIZE)
                        _buildA4Paper(
                          invoice: invoice,
                          template: template,
                          templateColor: templateColor,
                          isMobile: isMobile,
                        ),

                        const SizedBox(height: 140), // generous bottom clearance
                      ],
                    ),
                  ),
                ),
              ),

              // FLOATING QUICK ZOOM THUMB CONTROLLER
              Positioned(
                right: 16,
                bottom: 16,
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
    final signatureImage =
        _show('showSignature') ? _brandImage('invoiceSignature') : null;
    final stampImage = _show('showStamp') ? _brandImage('invoiceStamp') : null;
    final logoImage =
        (_show('showLogo') && (template?.showLogo ?? true)) ? _brandImage('invoiceLogo') : null;

    final documentTitle = _label(
      'customTitle',
      template?.title ?? 'INVOICE',
    );
    final invoiceNoLabel = _label('customInvoiceNoLabel', 'Invoice #');
    final issueDateLabel = _label('customDateLabel', 'Creation Date');
    final dueDateLabel = _label('customDueDateLabel', 'Due Date');
    final poLabel = _label('customPoLabel', 'PO Number');
    final billToLabel = _label('customBillToLabel', 'BILL TO');
    final notesLabel = _label('customNotesLabel', 'Notes');
    final termsLabel = _label('customTermsLabel', 'Terms and conditions');
    final signeeTitle = _label('signeeTitle', 'Authorized Signatory');
    final signeeName = _label('signeeName', '');

    final customDetails = _customFields('customFields_details');
    final customBilling = _customFields('customFields_billing');
    final customAdjustments = _customFields('customFields_adjustments');
    final customFooter = _customFields('customFields_footer');

    final showBillFrom = _show('showBillFrom', fallback: true) && (template?.showBillFrom ?? true);
    final showBank = _show('showBankDetails', fallback: true) && (template?.showBankDetails ?? true);
    final showBillTo = _show('showBillTo', fallback: true) && (template?.showBillTo ?? true);

    final bizName = _profile['businessName']?.toString().trim().isNotEmpty == true
        ? _profile['businessName'].toString()
        : (_localSettings['businessName']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessName'].toString()
            : '');
    final bizLegalName = _profile['legalName']?.toString().trim().isNotEmpty == true
        ? _profile['legalName'].toString()
        : '';
    final bizAddress = _profile['address']?.toString().trim().isNotEmpty == true
        ? _profile['address'].toString()
        : (_localSettings['businessAddress']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessAddress'].toString()
            : '');
    final bizGstin = _profile['gstin']?.toString().trim().isNotEmpty == true
        ? _profile['gstin'].toString()
        : (_profile['taxId']?.toString().trim().isNotEmpty == true
            ? _profile['taxId'].toString()
            : (_localSettings['businessGstin']?.toString().trim().isNotEmpty == true
                ? _localSettings['businessGstin'].toString()
                : ''));
    final bizPan = _profile['panNumber']?.toString().trim().isNotEmpty == true
        ? _profile['panNumber'].toString()
        : (_localSettings['businessPan']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessPan'].toString()
            : '');
    final bizPhone = _profile['phone']?.toString().trim().isNotEmpty == true
        ? _profile['phone'].toString()
        : (_localSettings['businessPhone']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessPhone'].toString()
            : '');
    final bizEmail = _profile['email']?.toString().trim().isNotEmpty == true
        ? _profile['email'].toString()
        : (_localSettings['businessEmail']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessEmail'].toString()
            : '');
    final bizWebsite = _profile['website']?.toString().trim().isNotEmpty == true
        ? _profile['website'].toString()
        : (_localSettings['businessWebsite']?.toString().trim().isNotEmpty == true
            ? _localSettings['businessWebsite'].toString()
            : '');

    final bankName = _profile['bankName']?.toString().trim().isNotEmpty == true
        ? _profile['bankName'].toString()
        : (_localSettings['bankName']?.toString().trim().isNotEmpty == true
            ? _localSettings['bankName'].toString()
            : '');
    final accountHolder = _profile['accountHolder']?.toString().trim().isNotEmpty == true
        ? _profile['accountHolder'].toString()
        : (_localSettings['accountHolder']?.toString().trim().isNotEmpty == true
            ? _localSettings['accountHolder'].toString()
            : '');
    final accountNumber = _profile['accountNumber']?.toString().trim().isNotEmpty == true
        ? _profile['accountNumber'].toString()
        : (_localSettings['accountNumber']?.toString().trim().isNotEmpty == true
            ? _localSettings['accountNumber'].toString()
            : '');
    final ifscCode = _profile['ifscCode']?.toString().trim().isNotEmpty == true
        ? _profile['ifscCode'].toString()
        : (_localSettings['ifscCode']?.toString().trim().isNotEmpty == true
            ? _localSettings['ifscCode'].toString()
            : '');
    final upiId = _profile['upiId']?.toString().trim().isNotEmpty == true
        ? _profile['upiId'].toString()
        : (_localSettings['upiId']?.toString().trim().isNotEmpty == true
            ? _localSettings['upiId'].toString()
            : '');
    final paymentLink = _profile['paymentLink']?.toString().trim().isNotEmpty == true
        ? _profile['paymentLink'].toString()
        : (_localSettings['paymentLink']?.toString().trim().isNotEmpty == true
            ? _localSettings['paymentLink'].toString()
            : '');

    return Container(
      width: a4PaperWidth,
      constraints: const BoxConstraints(minHeight: a4PaperMinHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            spreadRadius: 4,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Layout based (Classic Centered vs Modern Side-by-Side)
          if (template?.headerLayout == 'classic') ...[
            Center(
              child: Column(
                children: [
                  if (logoImage != null) ...[
                    logoImage,
                    const SizedBox(height: 8),
                  ],
                  if (showBillFrom && bizName.isNotEmpty) ...[
                    Text(
                      bizName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: templateColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                      Text(bizLegalName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), textAlign: TextAlign.center),
                    if (bizAddress.isNotEmpty)
                      Text(bizAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        if (bizGstin.isNotEmpty) Text('GSTIN: $bizGstin', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (bizPan.isNotEmpty) Text('PAN: $bizPan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (bizPhone.isNotEmpty) Text('Ph: $bizPhone', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if (bizEmail.isNotEmpty) Text('Email: $bizEmail', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    documentTitle,
                    style: TextStyle(
                      color: templateColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    children: [
                      Text('$invoiceNoLabel: ${invoice.invoiceNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (_show('showIssueDate', fallback: true))
                        Text('$issueDateLabel: ${invoice.issueDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      if (_show('showDueDate', fallback: false))
                        Text('$dueDateLabel: ${invoice.dueDate}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (_show('showStatus', fallback: false))
                        _StatusChip(status: invoice.status),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Modern Side-by-Side (Default)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        logoImage,
                        const SizedBox(height: 8),
                      ],
                      if (showBillFrom && bizName.isNotEmpty) ...[
                        Text(
                          bizName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                          Text(bizLegalName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        if (bizAddress.isNotEmpty)
                          Text(bizAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (bizGstin.isNotEmpty || bizPan.isNotEmpty)
                          Text([if (bizGstin.isNotEmpty) 'GSTIN: $bizGstin', if (bizPan.isNotEmpty) 'PAN: $bizPan'].join('  |  '),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                          Text([if (bizPhone.isNotEmpty) bizPhone, if (bizEmail.isNotEmpty) bizEmail].join(' • '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if (bizWebsite.isNotEmpty)
                          Text(bizWebsite, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      documentTitle,
                      style: TextStyle(
                        color: templateColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$invoiceNoLabel: ${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (_show('showStatus', fallback: false)) ...[
                      const SizedBox(height: 6),
                      _StatusChip(status: invoice.status),
                    ],
                    const SizedBox(height: 6),
                    if (_show('showIssueDate', fallback: true))
                      Text(
                        '$issueDateLabel: ${invoice.issueDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    if (_show('showDueDate', fallback: false))
                      Text(
                        '$dueDateLabel: ${invoice.dueDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    if (_show('showPoNumber', fallback: false) && invoice.poNumber.isNotEmpty)
                      Text(
                        '$poLabel: ${invoice.poNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    if (_show('showPaymentTerms', fallback: false) && invoice.paymentTerms.isNotEmpty)
                      Text(
                        'Terms: ${invoice.paymentTerms}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    for (final field in customDetails)
                      if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                        Text(
                          '${field['label']}: ${field['value'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          Container(height: 2.5, color: templateColor),
          const SizedBox(height: 20),

          // Bill To & Ship To Details
          if (showBillTo || ((_show('showShippingSection', fallback: false) || (template?.showShipping ?? false)) && _shippingLines().isNotEmpty)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBillTo)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billToLabel,
                          style: TextStyle(
                            color: templateColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          invoice.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_show('showClientCompany') && invoice.clientCompany.isNotEmpty)
                          Text(invoice.clientCompany, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                        if (_show('showClientEmail') && invoice.clientEmail.isNotEmpty)
                          Text(invoice.clientEmail, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientPhone') && invoice.clientPhone.isNotEmpty)
                          Text(invoice.clientPhone, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientAddress') && invoice.clientAddress.isNotEmpty)
                          Text(invoice.clientAddress, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientTaxId') && invoice.clientTaxId.isNotEmpty)
                          Text('${_label('customClientTaxIdLabel', 'Tax ID')}: ${invoice.clientTaxId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        for (final field in customBilling)
                          if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                            Text('${field['label']}: ${field['value'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                if ((_show('showShippingSection', fallback: false) || (template?.showShipping ?? false)) && _shippingLines().isNotEmpty) ...[
                  if (showBillTo) const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label('customShipToLabel', 'SHIPPING DETAILS'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: templateColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final line in _shippingLines())
                            Text(line, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

          // LINE ITEMS TABLE
          _LineItemsTable(
            invoice: invoice,
            localSettings: _localSettings,
            template: template,
            headerColor: templateColor,
          ),

          const SizedBox(height: 18),

          // TOTALS SECTION
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                children: [
                  _TotalLine(
                    label: _label('customSubtotalLabel', 'Subtotal'),
                    value: _money(invoice.subtotal, invoice.currencySymbol),
                  ),
                  if (invoice.totalDiscount > 0 && _show('showDiscount', fallback: true))
                    _TotalLine(
                      label: _label('customDiscountLabel', 'Discount'),
                      value:
                          '−${_money(invoice.totalDiscount, invoice.currencySymbol)}',
                    ),
                  if (template?.showTaxBreakdown != false && _show('showTax', fallback: true))
                    _TotalLine(
                      label: _label('customTaxLabel', '${invoice.taxLabel} (${invoice.taxRate}%)'),
                      value: _money(invoice.taxAmount, invoice.currencySymbol),
                    ),
                  if (invoice.shippingFee > 0 || _show('showShippingFee', fallback: false))
                    _TotalLine(
                      label: _label('customShippingLabel', 'Shipping'),
                      value: _money(invoice.shippingFee, invoice.currencySymbol),
                    ),
                  if (invoice.additionalCharges > 0 || _show('showAdditionalCharges', fallback: false))
                    _TotalLine(
                      label: _label('customAdjustmentsLabel', 'Additional charges'),
                      value: _money(
                        invoice.additionalCharges,
                        invoice.currencySymbol,
                      ),
                    ),
                  if (invoice.roundOff != 0 || _show('showRoundOff', fallback: false))
                    _TotalLine(
                      label: _label('customRoundOffLabel', 'Round off'),
                      value: _money(invoice.roundOff, invoice.currencySymbol),
                    ),
                  for (final adj in customAdjustments)
                    if (adj['isVisible'] != false && adj['label']?.toString().isNotEmpty == true)
                      _TotalLine(
                        label: adj['label'] as String,
                        value: adj['value'] != null && adj['value'].toString().isNotEmpty
                            ? '${invoice.currencySymbol}${adj['value']}'
                            : '−',
                      ),
                  const Divider(thickness: 1.5),
                  _TotalLine(
                    label: _label('customTotalLabel', 'Total'),
                    value: _money(invoice.total, invoice.currencySymbol),
                    bold: true,
                    fontSize: 16,
                  ),
                  if (_show('showAmountPaid', fallback: true))
                    _TotalLine(
                      label: _label('customAmountPaidLabel', 'Amount paid'),
                      value: _money(invoice.amountPaid, invoice.currencySymbol),
                    ),
                  if (_show('showBalanceDue', fallback: true))
                    _TotalLine(
                      label: _label('customBalanceDueLabel', 'Balance due'),
                      value: _money(invoice.balanceDue, invoice.currencySymbol),
                      bold: true,
                      color: const Color(0xFFDC2626),
                      fontSize: 16,
                    ),
                ],
              ),
            ),
          ),

          // BANK & PAYMENT DETAILS (Requested by user)
          if (showBank &&
              (bankName.isNotEmpty ||
                  accountNumber.isNotEmpty ||
                  upiId.isNotEmpty ||
                  paymentLink.isNotEmpty)) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          size: 16, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Text(
                        'BANK & PAYMENT DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: templateColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (bankName.isNotEmpty)
                        Text('Bank: $bankName',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      if (accountHolder.isNotEmpty)
                        Text('A/C Name: $accountHolder',
                            style: const TextStyle(fontSize: 12)),
                      if (accountNumber.isNotEmpty)
                        Text('A/C No: $accountNumber',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                      if (ifscCode.isNotEmpty)
                        Text('IFSC / SWIFT: $ifscCode',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      if (upiId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('UPI: $upiId',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534))),
                        ),
                    ],
                  ),
                  if (paymentLink.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Payment Link: $paymentLink',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2563EB))),
                  ],
                ],
              ),
            ),
          ],

          // NOTES, TERMS, PAYMENT INSTRUCTIONS
          if ((_show('showNotes') && (template?.showNotes ?? true) && invoice.notes.isNotEmpty) ||
              (_show('showTerms') && (template?.showTerms ?? true) && invoice.terms.isNotEmpty) ||
              (_show('showPaymentInstructions') &&
                  (template?.showPaymentInstructions ?? true) &&
                  invoice.paymentInstructions.isNotEmpty) ||
              customFooter.any((f) => f['isVisible'] != false)) ...[
            const Divider(height: 36),
            if (_show('showNotes') && (template?.showNotes ?? true) && invoice.notes.isNotEmpty) ...[
              Text(
                notesLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.notes,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
            ],
            if (_show('showTerms') && (template?.showTerms ?? true) && invoice.terms.isNotEmpty) ...[
              Text(
                termsLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.terms,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
            ],
            if (_show('showPaymentInstructions') &&
                (template?.showPaymentInstructions ?? true) &&
                invoice.paymentInstructions.isNotEmpty) ...[
              Text(
                _label('customPaymentInstructionsLabel', 'PAYMENT INSTRUCTIONS'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.paymentInstructions,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
            for (final foot in customFooter)
              if (foot['isVisible'] != false && foot['label']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  foot['label'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: templateColor),
                ),
                if (foot['value']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(foot['value'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ],
          ],

          // SIGNATURE & STAMP BLOCK (with tap to capture sign via DocuHub)
          if ((_show('showSignature') && (template?.showSignature ?? true)) || _show('showStamp')) ...[
            const Divider(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (stampImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stampImage,
                      const SizedBox(height: 4),
                      const Text(
                        'Official Stamp',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                // Signature block
                if (_show('showSignature') && (template?.showSignature ?? true))
                  InkWell(
                    onTap: _openDocuHubSigner,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: signatureImage != null
                              ? Colors.transparent
                              : Colors.blue.withAlpha(80),
                          style: signatureImage != null
                              ? BorderStyle.none
                              : BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (signatureImage != null) ...[
                            signatureImage,
                            const SizedBox(height: 6),
                          ] else ...[
                            const Icon(
                              Icons.draw_rounded,
                              size: 32,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to add signature',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Container(
                            width: 170,
                            height: 1,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            signeeTitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          if (signeeName.isNotEmpty)
                            Text(
                              signeeName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (template?.footer.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                template!.footer,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({
    required this.invoice,
    required this.localSettings,
    required this.template,
    required this.headerColor,
  });

  final Invoice invoice;
  final Map<String, Object?> localSettings;
  final TemplateConfig? template;
  final Color headerColor;

  bool _show(String key) => localSettings[key] != false;

  String _label(String key, String fallback) {
    final custom = localSettings[key]?.toString().trim();
    return (custom != null && custom.isNotEmpty) ? custom : fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (invoice.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('This invoice has no line items.'),
      );
    }

    final itemHeader = _label(
      'customItemHeader',
      template?.itemHeader ?? 'Description',
    );
    final qtyHeader = _label(
      'customQtyHeader',
      template?.quantityHeader ?? 'Qty',
    );
    final rateHeader = _label(
      'customRateHeader',
      template?.rateHeader ?? 'Rate',
    );
    final amountHeader = _label(
      'customAmountHeader',
      template?.amountHeader ?? 'Amount',
    );

    final customCols = <Map<String, dynamic>>[];
    final rawCols = localSettings['customColumns_items'];
    if (rawCols is List) {
      for (final c in rawCols) {
        if (c is Map && c['isVisible'] != false) {
          customCols.add(Map<String, dynamic>.from(c));
        }
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(itemHeader),
                ),
                if (_show('showItemQty'))
                  Expanded(
                    flex: 2,
                    child: Text(qtyHeader, textAlign: TextAlign.end),
                  ),
                if (_show('showItemRate'))
                  Expanded(
                    flex: 2,
                    child: Text(rateHeader, textAlign: TextAlign.end),
                  ),
                if (_show('showItemDiscount'))
                  Expanded(
                    flex: 2,
                    child: Text(_label('customDiscountHeader', 'Discount'), textAlign: TextAlign.end),
                  ),
                if (_show('showItemTax'))
                  Expanded(
                    flex: 2,
                    child: Text(_label('customTaxHeader', 'Tax'), textAlign: TextAlign.end),
                  ),
                for (final col in customCols)
                  Expanded(
                    flex: 2,
                    child: Text(col['label']?.toString() ?? '', textAlign: TextAlign.end),
                  ),
                Expanded(
                  flex: 3,
                  child: Text(amountHeader, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < invoice.items.length; i++) ...[
          () {
            final item = invoice.items[i];
            final isAlt = template?.tableStyle == 'striped' && (i % 2 == 1);
            final isBoxed = template?.tableStyle == 'boxed';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: isAlt ? const Color(0xFFF8FAFC) : Colors.transparent,
                border: isBoxed
                    ? const Border(
                        left: BorderSide(color: Color(0xFFCBD5E1)),
                        right: BorderSide(color: Color(0xFFCBD5E1)),
                        bottom: BorderSide(color: Color(0xFFCBD5E1)),
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (_show('showItemQty'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_quantity(item.quantity)}'
                        '${_show('showItemUnit') ? ' ${item.unit}' : ''}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemRate'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        _money(item.unitPrice, invoice.currencySymbol),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemDiscount'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.discountRate}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (_show('showItemTax'))
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.taxRate}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  for (final col in customCols)
                    Expanded(
                      flex: 2,
                      child: Text(
                        col['value']?.toString() ?? '−',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _money(item.total, invoice.currencySymbol),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],
        if (template?.tableStyle != 'boxed')
          const Divider(color: Color(0xFFCBD5E1)),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.fontSize = 13,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: color ?? const Color(0xFF334155),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: color ?? const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
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
      'cancelled' => const Color(0xFF64748B),
      _ => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

String _quantity(double quantity) => quantity == quantity.truncateToDouble()
    ? quantity.toInt().toString()
    : '$quantity';

String _money(double amount, String symbol) =>
    '$symbol${amount.toStringAsFixed(2)}';

Color _templateColor(String? hex, Color fallback) {
  final value = hex?.replaceFirst('#', '');
  if (value == null || !RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
    return fallback;
  }
  return Color(0xFF000000 | int.parse(value, radix: 16));
}
