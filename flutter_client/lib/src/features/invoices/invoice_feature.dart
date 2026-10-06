import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../templates/data/template_config.dart';
import 'data/invoice.dart';
import 'data/invoice_repository.dart';
import 'presentation/invoice_editor_screen.dart';
import 'presentation/invoice_preview_screen.dart';
import 'presentation/invoices_list_screen.dart';

export 'data/invoice.dart';
export 'data/invoice_repository.dart';
export 'presentation/invoice_editor_screen.dart';
export 'presentation/invoice_preview_screen.dart';
export 'presentation/invoices_list_screen.dart';

/// Full invoice workflow entry point for an authenticated app section.
///
/// Mount [InvoiceFeatureScreen] with the app's shared [ApiClient], for example:
/// `InvoiceFeatureScreen(apiClient: apiClient)`.
class InvoiceFeatureScreen extends StatefulWidget {
  const InvoiceFeatureScreen({
    required this.apiClient,
    this.repository,
    this.preferredTemplate,
    this.localSettings = const <String, Object?>{},
    super.key,
  });

  final ApiClient apiClient;
  final InvoiceRepository? repository;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> localSettings;

  @override
  State<InvoiceFeatureScreen> createState() => _InvoiceFeatureScreenState();
}

class _InvoiceFeatureScreenState extends State<InvoiceFeatureScreen> {
  late InvoiceRepository _repository;
  _InvoicePage _page = _InvoicePage.list;
  Invoice? _selected;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? InvoiceRepository(apiClient: widget.apiClient);
  }

  @override
  void didUpdateWidget(covariant InvoiceFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiClient != widget.apiClient ||
        oldWidget.repository != widget.repository) {
      _repository =
          widget.repository ?? InvoiceRepository(apiClient: widget.apiClient);
    }
  }

  void _backToList() {
    setState(() {
      _selected = null;
      _page = _InvoicePage.list;
    });
  }

  @override
  Widget build(BuildContext context) => switch (_page) {
        _InvoicePage.list => InvoicesListScreen(
            key: const ValueKey('invoice-list'),
            repository: _repository,
            onCreate: () => setState(() {
              _selected = null;
              _page = _InvoicePage.editor;
            }),
            onOpen: (invoice) => setState(() {
              _selected = invoice;
              _page = _InvoicePage.preview;
            }),
            onEdit: (invoice) => setState(() {
              _selected = invoice;
              _page = _InvoicePage.editor;
            }),
          ),
        _InvoicePage.editor => InvoiceEditorScreen(
            key: ValueKey('invoice-editor-${_selected?.id ?? 'new'}'),
            repository: _repository,
            invoice: _selected,
            preferredTemplate: widget.preferredTemplate,
            onCancel: _selected == null
                ? _backToList
                : () => setState(() => _page = _InvoicePage.preview),
            onSaved: (invoice) => setState(() {
              _selected = invoice;
              _page = _InvoicePage.preview;
            }),
          ),
        _InvoicePage.preview => InvoicePreviewScreen(
            key: ValueKey('invoice-preview-${_selected?.id}'),
            invoice: _selected!,
            repository: _repository,
            preferredTemplate: widget.preferredTemplate,
            localSettings: widget.localSettings,
            onBack: _backToList,
            onEdit: (invoice) => setState(() {
              _selected = invoice;
              _page = _InvoicePage.editor;
            }),
            onDeleted: _backToList,
          ),
      };
}

enum _InvoicePage { list, editor, preview }
