import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/table_export_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../../theme/app_theme.dart';
import '../data/client.dart';
import '../data/clients_repository.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({
    required this.repository,
    this.onBack,
    super.key,
  });

  final ClientsRepository repository;
  final VoidCallback? onBack;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Client> _clients = const [];
  String _clientFilter = 'All'; // 'All', 'Corporate', 'Individual', 'TaxRegistered'
  bool _isLoading = true;
  bool _usingCachedData = false;
  String? _error;
  int _loadRequest = 0;
  DateTimeRange? _dateRange;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients({bool showProgress = true}) async {
    final request = ++_loadRequest;
    if (showProgress && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final clients = await widget.repository.list(
        search: _searchController.text,
      );
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _clients = clients;
        _usingCachedData = widget.repository.lastLoadUsedCache;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _error = 'Could not load clients. Please try again.');
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadClients(),
    );
  }

  Future<void> _createClient() async {
    final client = await showDialog<Client>(
      context: context,
      builder: (context) => const ClientEditorDialog(),
    );
    if (client == null || !mounted) return;
    try {
      await widget.repository.create(client);
      if (!mounted) return;
      _showMessage('Client created.');
      await _loadClients();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not create client. Please try again.');
    }
  }

  Future<void> _editClient(Client client) async {
    final updated = await showDialog<Client>(
      context: context,
      builder: (context) => ClientEditorDialog(client: client),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.repository.update(updated);
      if (!mounted) return;
      _showMessage('Client updated.');
      await _loadClients();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not update client. Please try again.');
    }
  }

  Future<void> _deleteClient(Client client) async {
    final id = client.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('Delete ${client.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.delete(id);
      if (!mounted) return;
      _showMessage('Client deleted.');
      await _loadClients();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not delete client. Please try again.');
    }
  }

  Future<void> _updatePaymentTerms(Client client, String newTerms) async {
    final updated = Client(
      id: client.id,
      companyId: client.companyId,
      name: client.name,
      companyName: client.companyName,
      email: client.email,
      phone: client.phone,
      address: client.address,
      taxId: client.taxId,
      preferredCurrency: client.preferredCurrency,
      defaultPaymentTerms: newTerms,
      notes: client.notes,
      createdAt: client.createdAt,
    );
    try {
      await widget.repository.update(updated);
      if (mounted) {
        _showMessage('Payment terms updated to $newTerms.');
        await _loadClients();
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Could not update payment terms.');
    }
  }

  List<Client> get _visibleClients {
    return _clients.where((c) {
      if (_clientFilter == 'Corporate' && c.companyName.trim().isEmpty) return false;
      if (_clientFilter == 'Individual' && c.companyName.trim().isNotEmpty) return false;
      if (_clientFilter == 'TaxRegistered' && c.taxId.trim().isEmpty) return false;
      if (_dateRange != null && c.createdAt != null) {
        final dt = c.createdAt! > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(c.createdAt!)
            : DateTime.fromMillisecondsSinceEpoch(c.createdAt! * 1000);
        if (dt.isBefore(_dateRange!.start) ||
            dt.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<EnterpriseMetricCardItem> _buildMetrics(List<Client> all) {
    final total = all.length;
    final corporate = all.where((c) => c.companyName.trim().isNotEmpty).length;
    final individual = all.where((c) => c.companyName.trim().isEmpty).length;
    final taxRegistered = all.where((c) => c.taxId.trim().isNotEmpty).length;

    return [
      EnterpriseMetricCardItem(
        label: 'Total Accounts',
        value: '$total',
        icon: Icons.groups_outlined,
        color: const Color(0xFF2563EB),
        filterKey: 'All',
        isSelected: _clientFilter == 'All',
        onTap: () => setState(() => _clientFilter = 'All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Corporate Entities',
        value: '$corporate',
        icon: Icons.business_outlined,
        color: const Color(0xFF059669),
        filterKey: 'Corporate',
        isSelected: _clientFilter == 'Corporate',
        onTap: () => setState(
          () => _clientFilter = _clientFilter == 'Corporate' ? 'All' : 'Corporate',
        ),
      ),
      EnterpriseMetricCardItem(
        label: 'Individual Clients',
        value: '$individual',
        icon: Icons.person_outline,
        color: const Color(0xFFD97706),
        filterKey: 'Individual',
        isSelected: _clientFilter == 'Individual',
        onTap: () => setState(
          () => _clientFilter = _clientFilter == 'Individual' ? 'All' : 'Individual',
        ),
      ),
      EnterpriseMetricCardItem(
        label: 'Tax Registered (GST)',
        value: '$taxRegistered',
        icon: Icons.verified_outlined,
        color: const Color(0xFF7C3AED),
        filterKey: 'TaxRegistered',
        isSelected: _clientFilter == 'TaxRegistered',
        onTap: () => setState(
          () => _clientFilter = _clientFilter == 'TaxRegistered' ? 'All' : 'TaxRegistered',
        ),
      ),
    ];
  }

  void _downloadClientsReport(List<Client> list) {
    TableExportHelper.showExportMenu(
      context: context,
      title: 'Clients Directory',
      headers: [
        'ID',
        'Name',
        'Company',
        'Email',
        'Phone',
        'Tax ID / GST',
        'Currency',
        'Payment Terms',
        'Address',
      ],
      rows: list.map((c) => [
        '${c.id ?? ""}',
        c.name,
        c.companyName,
        c.email,
        c.phone,
        c.taxId,
        c.preferredCurrency,
        c.defaultPaymentTerms,
        c.address,
      ]).toList(),
    );
  }

  Future<void> _batchDeleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Clients?'),
        content: Text('Are you sure you want to delete $count selected clients? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    int deleted = 0;
    for (final idStr in _selectedIds.toList()) {
      final id = int.tryParse(idStr);
      if (id != null) {
        try {
          await widget.repository.delete(id);
          deleted++;
        } catch (_) {}
      }
    }
    setState(() => _selectedIds.clear());
    _showMessage('Deleted $deleted clients.');
    await _loadClients();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients & Accounts'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          IconButton(
            tooltip: 'Refresh clients',
            onPressed: _isLoading ? null : _loadClients,
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createClient,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add client'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;
          return RefreshIndicator(
            onRefresh: _loadClients,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 100),
              children: [
                if (_usingCachedData) const OfflineCacheBanner(),
                if (_error != null) ...[
                  _ErrorPanel(message: _error!, onRetry: _loadClients),
                  const SizedBox(height: 16),
                ],
                if (_isLoading && _clients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  EnterpriseDataView<Client>(
                    items: _visibleClients,
                    headerTitle: 'Client Directory',
                    metrics: _buildMetrics(_clients),
                    dateRange: _dateRange,
                    onDateRangeChanged: (range) => setState(() => _dateRange = range),
                    onDownloadReport: () => _downloadClientsReport(_visibleClients),
                    idGetter: (c) => c.id?.toString() ?? c.name,
                    selectedIds: _selectedIds,
                    onToggleSelect: (id) {
                      setState(() {
                        if (_selectedIds.contains(id)) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      });
                    },
                    onSelectAll: (ids) => setState(() => _selectedIds.addAll(ids)),
                    onDeselectAll: () => setState(() => _selectedIds.clear()),
                    onRowTap: (client) => _editClient(client),
                    batchActions: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          final selected = _visibleClients
                              .where((c) => _selectedIds.contains(c.id?.toString() ?? c.name))
                              .toList();
                          _downloadClientsReport(selected);
                        },
                        icon: const Icon(Icons.file_download_outlined, size: 14),
                        label: const Text('Export Selected', style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _batchDeleteSelected,
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Delete Selected', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    filterChips: const [
                      'All',
                      'Corporate',
                      'Individual',
                      'Tax Registered',
                    ],
                    selectedFilterChip: _clientFilter == 'TaxRegistered'
                        ? 'Tax Registered'
                        : _clientFilter,
                    onFilterChipSelected: (chip) {
                      setState(() {
                        if (chip == 'Tax Registered') {
                          _clientFilter = 'TaxRegistered';
                        } else {
                          _clientFilter = chip;
                        }
                      });
                    },
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    searchHint: 'Search name, company or email...',
                    groupBy: (client) =>
                        client.companyName.isNotEmpty ? client.companyName : 'Individual Clients',
                    groupLabelBuilder: (comp, items) =>
                        '$comp (${items.length} ${items.length == 1 ? "contact" : "contacts"})',
                    emptyWidget: _EmptyPanel(
                      hasSearch: _searchController.text.trim().isNotEmpty,
                      onAdd: _createClient,
                      onClear: () {
                        _searchController.clear();
                        _loadClients();
                      },
                    ),
                    cardBuilder: (context, client) => _ClientCard(
                      client: client,
                      onEdit: () => _editClient(client),
                      onDelete: () => _deleteClient(client),
                    ),
                    columns: _clientTableColumns(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<EnterpriseTableColumn<Client>> _clientTableColumns() {
    return [
      EnterpriseTableColumn<Client>(
        title: 'Client / Company',
        width: 200,
        sortKey: (client) => client.name.toLowerCase(),
        cellBuilder: (ctx, client) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFEFF6FF),
              foregroundColor: const Color(0xFF1D4ED8),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (client.companyName.isNotEmpty)
                  Text(client.companyName, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Email',
        width: 180,
        sortKey: (client) => client.email.toLowerCase(),
        cellBuilder: (ctx, client) => Text(
          client.email.isNotEmpty ? client.email : '—',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Phone',
        width: 140,
        sortKey: (client) => client.phone,
        cellBuilder: (ctx, client) => Text(
          client.phone.isNotEmpty ? client.phone : '—',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Currency',
        width: 100,
        sortKey: (client) => client.preferredCurrency,
        cellBuilder: (ctx, client) => Text(
          client.preferredCurrency.isNotEmpty ? client.preferredCurrency : 'INR',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Payment Terms',
        width: 135,
        sortKey: (client) => client.defaultPaymentTerms,
        cellBuilder: (ctx, client) => EnterpriseStatusDropdown(
          currentStatus: client.defaultPaymentTerms.isNotEmpty ? client.defaultPaymentTerms : 'Immediate',
          options: const ['Immediate', 'Net 15', 'Net 30', 'Net 60'],
          onChanged: (newTerms) => _updatePaymentTerms(client, newTerms),
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Tax ID / GST',
        width: 130,
        sortKey: (client) => client.taxId,
        cellBuilder: (ctx, client) => Text(
          client.taxId.isNotEmpty ? client.taxId : '—',
          style: TextStyle(
            fontSize: 12,
            color: client.taxId.isNotEmpty ? const Color(0xFF7C3AED) : AppColors.muted,
            fontWeight: client.taxId.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      EnterpriseTableColumn<Client>(
        title: 'Actions',
        width: 110,
        cellBuilder: (ctx, client) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit Client',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editClient(client),
            ),
            IconButton(
              tooltip: 'Delete Client',
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _deleteClient(client),
            ),
          ],
        ),
      ),
    ];
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(
                  client.name.isEmpty ? '?' : client.name[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (client.companyName.isNotEmpty)
                      Text(
                        client.companyName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              if (!compact) ...[
                IconButton(
                  tooltip: 'Edit client',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete client',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  if (client.email.isNotEmpty)
                    _ClientDetail(
                        icon: Icons.email_outlined, value: client.email),
                  if (client.phone.isNotEmpty)
                    _ClientDetail(
                        icon: Icons.phone_outlined, value: client.phone),
                  if (client.address.isNotEmpty)
                    _ClientDetail(
                      icon: Icons.location_on_outlined,
                      value: client.address,
                    ),
                  _ClientDetail(
                    icon: Icons.payments_outlined,
                    value:
                        '${client.preferredCurrency} · ${client.defaultPaymentTerms}',
                  ),
                  if (client.taxId.isNotEmpty)
                    _ClientDetail(
                      icon: Icons.badge_outlined,
                      value: 'Tax ID: ${client.taxId}',
                    ),
                ],
              ),
              if (client.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(client.notes, style: theme.textTheme.bodyMedium),
              ],
              if (compact) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
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
}

class _ClientDetail extends StatelessWidget {
  const _ClientDetail({required this.icon, required this.value});

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

class ClientEditorDialog extends StatefulWidget {
  const ClientEditorDialog({this.client, super.key});

  final Client? client;

  @override
  State<ClientEditorDialog> createState() => _ClientEditorDialogState();
}

class _ClientEditorDialogState extends State<ClientEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _taxId;
  late final TextEditingController _currency;
  late final TextEditingController _terms;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _name = TextEditingController(text: client?.name ?? '');
    _company = TextEditingController(text: client?.companyName ?? '');
    _email = TextEditingController(text: client?.email ?? '');
    _phone = TextEditingController(text: client?.phone ?? '');
    _address = TextEditingController(text: client?.address ?? '');
    _taxId = TextEditingController(text: client?.taxId ?? '');
    _currency = TextEditingController(text: client?.preferredCurrency ?? 'INR');
    _terms =
        TextEditingController(text: client?.defaultPaymentTerms ?? 'Net 30');
    _notes = TextEditingController(text: client?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _taxId.dispose();
    _currency.dispose();
    _terms.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.client;
    Navigator.pop(
      context,
      Client(
        id: existing?.id,
        companyId: existing?.companyId,
        name: _name.text.trim(),
        companyName: _company.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        taxId: _taxId.text.trim(),
        preferredCurrency:
            _currency.text.trim().isEmpty ? 'INR' : _currency.text.trim(),
        defaultPaymentTerms:
            _terms.text.trim().isEmpty ? 'Net 30' : _terms.text.trim(),
        notes: _notes.text.trim(),
        createdAt: existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.client != null;
    return AlertDialog(
      title: Text(editing ? 'Edit client' : 'Add client'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(_name, 'Full name *', validator: _required),
                _formField(_company, 'Company'),
                _formField(
                  _email,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty && !email.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                _formField(_phone, 'Phone', keyboardType: TextInputType.phone),
                _formField(_address, 'Address', maxLines: 2),
                _formField(_taxId, 'Tax ID'),
                Row(
                  children: [
                    Expanded(child: _formField(_currency, 'Currency')),
                    const SizedBox(width: 12),
                    Expanded(child: _formField(_terms, 'Payment terms')),
                  ],
                ),
                _formField(_notes, 'Notes', maxLines: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'Save changes' : 'Create client'),
        ),
      ],
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Name is required' : null;
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.overdue),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.hasSearch,
    required this.onAdd,
    required this.onClear,
  });

  final bool hasSearch;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.people_outline,
              size: 42,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch ? 'No matching clients' : 'No clients yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try another search or clear the filter.'
                  : 'Add a client to keep their billing details ready.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (hasSearch)
              OutlinedButton(
                onPressed: onClear,
                child: const Text('Clear search'),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add client'),
              ),
          ],
        ),
      );
}
