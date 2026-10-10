import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../clients/data/clients_repository.dart';
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
    this.onOpenBusinessSettings,
    this.initialStatusFilter = 'All',
    this.onSaveLocalSettings,
    this.onFullscreenChanged,
    super.key,
  });

  final ApiClient apiClient;
  final InvoiceRepository? repository;
  final TemplateConfig? preferredTemplate;
  final Map<String, Object?> localSettings;
  final VoidCallback? onOpenBusinessSettings;
  final String initialStatusFilter;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;
  final ValueChanged<bool>? onFullscreenChanged;

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

  void _setPage(_InvoicePage page, [Invoice? selected]) {
    setState(() {
      _page = page;
      if (selected != null || page == _InvoicePage.list) {
        _selected = selected;
      }
    });
    widget.onFullscreenChanged?.call(page != _InvoicePage.list);
  }

  void _backToList() => _setPage(_InvoicePage.list);

  @override
  Widget build(BuildContext context) => switch (_page) {
        _InvoicePage.list => InvoicesListScreen(
            key: ValueKey('invoice-list-${widget.initialStatusFilter}'),
            repository: _repository,
            initialFilter: widget.initialStatusFilter,
            onCreate: () => _setPage(_InvoicePage.editor),
            onOpen: (invoice) => _setPage(_InvoicePage.preview, invoice),
            onEdit: (invoice) => _setPage(_InvoicePage.editor, invoice),
          ),
        _InvoicePage.editor => InvoiceEditorScreen(
            key: ValueKey('invoice-editor-${_selected?.id ?? 'new'}'),
            repository: _repository,
            invoice: _selected,
            preferredTemplate: widget.preferredTemplate,
            initialLocalSettings: widget.localSettings,
            clientRepository: ClientsRepository(apiClient: widget.apiClient),
            onOpenInvoiceSettings: widget.onOpenBusinessSettings,
            onSaveLocalSettings: widget.onSaveLocalSettings,
            onCancel: _selected == null
                ? _backToList
                : () => _setPage(_InvoicePage.preview),
            onSaved: (invoice) => _setPage(_InvoicePage.preview, invoice),
          ),
        _InvoicePage.preview => InvoicePreviewScreen(
            key: ValueKey('invoice-preview-${_selected?.id}'),
            invoice: _selected!,
            repository: _repository,
            preferredTemplate: widget.preferredTemplate,
            localSettings: widget.localSettings,
            onOpenBusinessSettings: widget.onOpenBusinessSettings,
            onSaveLocalSettings: widget.onSaveLocalSettings,
            onBack: _backToList,
            onEdit: (invoice) => _setPage(_InvoicePage.editor, invoice),
            onDeleted: _backToList,
          ),
      };
}

enum _InvoicePage { list, editor, preview }
