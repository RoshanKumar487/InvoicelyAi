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
import 'widgets/invoice_preview_a4_paper.dart';
import 'widgets/invoice_preview_widgets.dart';
import 'widgets/invoice_template_picker_modal.dart';

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

  void _openTemplatePickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TemplatePickerModal(
        selectedId: _template?.id,
        onSelectTemplate: (preset) {
          setState(() => _selectedTemplateId = preset.id);
        },
        onSetDefault: (preset) async {
          final updated = Map<String, Object?>.from(_localSettings)
            ..['preferredTemplateId'] = preset.id
            ..['customTitle'] = preset.title
            ..['customItemHeader'] = preset.itemHeader
            ..['customQtyHeader'] = preset.quantityHeader
            ..['customRateHeader'] = preset.rateHeader
            ..['customAmountHeader'] = preset.amountHeader
            ..['customDutyHeader'] = preset.dutyHeader
            ..['showItemDuty'] = preset.showDuty;
          await widget.onSaveLocalSettings?.call(updated);
          if (mounted) {
            setState(() {
              _localSettings = updated;
              _selectedTemplateId = preset.id;
            });
            _showMessage('✓ Template "${preset.name}" set as default!');
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
                        template?.name ?? 'Standard Template',
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
          // 1. SWITCH TEMPLATE (Palette button opening category-wise template studio sheet)
          _buildPillButton(
            tooltip: 'Switch Template Style & Category',
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            child: IconButton(
              icon: Icon(
                Icons.palette_outlined,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => _openTemplatePickerSheet(context),
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
