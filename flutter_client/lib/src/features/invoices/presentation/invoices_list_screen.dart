import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../audit/data/audit_log_service.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({
    required this.repository,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    this.initialFilter = 'All',
    super.key,
  });

  final InvoiceRepository repository;
  final VoidCallback onCreate;
  final ValueChanged<Invoice> onOpen;
  final ValueChanged<Invoice> onEdit;
  final String initialFilter;

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  static const _filters = [
    'All',
    'Draft',
    'Sent',
    'Paid',
    'Overdue',
    'Cancelled'
  ];

  final _searchController = TextEditingController();
  List<Invoice> _invoices = [];
  String _filter = 'All';
  String _creatorFilter = 'All'; // 'All' or 'Me'
  bool _showCreatorFilter = false;
  String? _error;
  bool _loading = true;
  bool _usingCachedData = false;

  @override
  void initState() {
    super.initState();
    _filter = _filters.contains(widget.initialFilter) ? widget.initialFilter : 'All';
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoices = await widget.repository.getInvoices();
      if (mounted) {
        setState(() {
          _invoices = invoices;
          _usingCachedData = widget.repository.lastLoadUsedCache;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load invoices: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Invoice invoice) async {
    final id = invoice.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'Invoice ${invoice.invoiceNumber} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep invoice'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteInvoice(id);
      unawaited(
        AuditLogService.log(
          module: 'INVOICE',
          action: 'DELETE',
          entityId: invoice.invoiceNumber,
          title: 'Deleted invoice ${invoice.invoiceNumber}',
          description: 'Removed invoice for ${invoice.clientName} (₹${invoice.total.toStringAsFixed(2)})',
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Could not delete invoice: $error');
    }
  }

  Future<void> _setStatus(Invoice invoice, String status) async {
    final id = invoice.id;
    if (id == null) return;
    try {
      await widget.repository.updateStatus(id, status);
      unawaited(
        AuditLogService.log(
          module: 'INVOICE',
          action: 'STATUS_CHANGE',
          entityId: invoice.invoiceNumber,
          title: 'Changed ${invoice.invoiceNumber} status to $status',
          description: 'Updated billing status for ${invoice.clientName} to $status',
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Could not update invoice status: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<EnterpriseTableColumn<Invoice>> _invoiceTableColumns() {
    return [
      EnterpriseTableColumn<Invoice>(
        title: 'Invoice #',
        width: 140,
        cellBuilder: (ctx, inv) => InkWell(
          onTap: () => widget.onOpen(inv),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                inv.invoiceNumber.isEmpty ? 'INV-${inv.id ?? ""}' : inv.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
              ),
            ],
          ),
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Client / Company',
        width: 200,
        cellBuilder: (ctx, inv) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              inv.clientName.isNotEmpty ? inv.clientName : 'Walk-in Client',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            if (inv.clientCompany.isNotEmpty)
              Text(
                inv.clientCompany,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Issue Date',
        width: 110,
        cellBuilder: (ctx, inv) => Text(inv.issueDate, style: const TextStyle(fontSize: 12)),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Due Date',
        width: 110,
        cellBuilder: (ctx, inv) => Text(inv.dueDate, style: const TextStyle(fontSize: 12)),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Total Amount',
        width: 130,
        alignRight: true,
        cellBuilder: (ctx, inv) => Text(
          _money(inv.total, inv.currencySymbol),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Balance Due',
        width: 130,
        alignRight: true,
        cellBuilder: (ctx, inv) => Text(
          inv.balanceDue > 0 ? _money(inv.balanceDue, inv.currencySymbol) : '₹0.00',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: inv.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          ),
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Status',
        width: 110,
        cellBuilder: (ctx, inv) => _StatusChip(status: inv.status),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Actions',
        width: 90,
        cellBuilder: (ctx, inv) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: 'View preview',
              onPressed: () => widget.onOpen(inv),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              tooltip: 'More actions',
              onSelected: (action) {
                if (action == 'edit') widget.onEdit(inv);
                if (action == 'delete') _delete(inv);
                if (action == 'mark_paid') _setStatus(inv, 'Paid');
                if (action == 'mark_sent') _setStatus(inv, 'Sent');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
                if (inv.status.toLowerCase() != 'paid')
                  const PopupMenuItem(value: 'mark_paid', child: Text('Mark as Paid')),
                if (inv.status.toLowerCase() == 'draft')
                  const PopupMenuItem(value: 'mark_sent', child: Text('Mark as Sent')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Invoice', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildMetricsStrip(List<Invoice> allInvoices) {
    final totalInvoiced = allInvoices.fold<double>(0.0, (acc, i) => acc + i.total);
    final paidInvoices = allInvoices.where((i) => i.status.toLowerCase() == 'paid').toList();
    final totalPaid = paidInvoices.fold<double>(0.0, (acc, i) => acc + i.total);
    final outstandingInvoices = allInvoices.where((i) => i.balanceDue > 0 && i.status.toLowerCase() != 'paid').toList();
    final totalOutstanding = outstandingInvoices.fold<double>(0.0, (acc, i) => acc + i.balanceDue);
    final overdueCount = allInvoices.where((i) => i.status.toLowerCase() == 'overdue').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        final metrics = [
          _InvoiceKpi(label: 'Total Invoiced', value: '₹${totalInvoiced.toStringAsFixed(0)}', count: '${allInvoices.length} bills', icon: Icons.receipt_long_rounded, color: const Color(0xFF1E3A8A)),
          _InvoiceKpi(label: 'Total Collected', value: '₹${totalPaid.toStringAsFixed(0)}', count: '${paidInvoices.length} paid', icon: Icons.check_circle_outline, color: const Color(0xFF047857)),
          _InvoiceKpi(label: 'Outstanding', value: '₹${totalOutstanding.toStringAsFixed(0)}', count: '${outstandingInvoices.length} pending', icon: Icons.pending_actions_rounded, color: const Color(0xFFD97706)),
          _InvoiceKpi(label: 'Overdue Bills', value: '$overdueCount overdue', count: 'Action required', icon: Icons.warning_amber_rounded, color: const Color(0xFFDC2626)),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(m.icon, color: m.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                          Text(m.label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _invoices.where((invoice) {
      final matchesStatus = _filter == 'All' ||
          invoice.status.toLowerCase() == _filter.toLowerCase();
      final matchesSearch = query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.clientCompany.toLowerCase().contains(query) ||
          invoice.clientEmail.toLowerCase().contains(query);

      final matchesCreator = _creatorFilter == 'All' ||
          invoice.createdByUserName.toLowerCase().contains('you') ||
          invoice.createdByUserName.toLowerCase().contains('me');

      return matchesStatus && matchesSearch && matchesCreator;
    }).toList()
      ..sort((first, second) => second.issueDate.compareTo(first.issueDate));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_usingCachedData) const OfflineCacheBanner(),
            Text(
              'Invoices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Create, track and manage billing',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showCreatorFilter ? 'Hide creator filter' : 'Filter by creator',
            onPressed: () => setState(() => _showCreatorFilter = !_showCreatorFilter),
            icon: Icon(
              Icons.filter_list_rounded,
              color: _creatorFilter != 'All' || _showCreatorFilter ? const Color(0xFF0284C7) : null,
            ),
          ),
          IconButton(
            tooltip: 'Refresh invoices',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 900 ? 24.0 : 16.0;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 100),
              children: [
                if (_error != null) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoices could not be loaded',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(_error!),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_showCreatorFilter) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_circle_rounded, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter by Creator:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0369A1)),
                        ),
                        const Spacer(),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'All', label: Text('All Creators')),
                            ButtonSegment(value: 'Me', label: Text('Created by Me')),
                          ],
                          selected: {_creatorFilter},
                          onSelectionChanged: (set) => setState(() => _creatorFilter = set.first),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_loading && _invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  EnterpriseDataView<Invoice>(
                    items: filtered,
                    headerTitle: 'Invoice Directory',
                    metricsStrip: _buildMetricsStrip(_invoices),
                    searchController: _searchController,
                    searchHint: 'Search invoice #, client or email...',
                    filterChips: _filters,
                    selectedFilterChip: _filter,
                    onFilterChipSelected: (f) => setState(() => _filter = f),
                    topTrailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(value: 'Me', label: Text('Created by Me')),
                      ],
                      selected: {_creatorFilter},
                      onSelectionChanged: (set) => setState(() => _creatorFilter = set.first),
                    ),
                    groupBy: (inv) => inv.status.toUpperCase(),
                    groupLabelBuilder: (status, items) {
                      final total = items.fold<double>(0.0, (acc, i) => acc + i.total);
                      return '$status (${items.length} ${items.length == 1 ? "invoice" : "invoices"} · ₹${total.toStringAsFixed(2)})';
                    },
                    emptyWidget: _EmptyInvoices(
                      hasInvoices: _invoices.isNotEmpty,
                      onCreate: widget.onCreate,
                    ),
                    cardBuilder: (context, invoice) => _InvoiceCard(
                      invoice: invoice,
                      onOpen: () => widget.onOpen(invoice),
                      onEdit: () => widget.onEdit(invoice),
                      onDelete: () => _delete(invoice),
                      onStatusChanged: (status) => _setStatus(invoice, status),
                    ),
                    columns: _invoiceTableColumns(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceKpi {
  const _InvoiceKpi({
    required this.label,
    required this.value,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String count;
  final IconData icon;
  final Color color;
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final Invoice invoice;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber.isEmpty
                          ? 'Invoice'
                          : invoice.invoiceNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _StatusChip(status: invoice.status),
                  PopupMenuButton<String>(
                    tooltip: 'Invoice actions',
                    onSelected: (action) {
                      if (action == 'edit') onEdit();
                      if (action == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                invoice.clientCompany.isEmpty
                    ? invoice.clientName
                    : '${invoice.clientName} · ${invoice.clientCompany}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _MetaItem(
                    icon: Icons.event_outlined,
                    label: 'Issued ${invoice.issueDate}',
                  ),
                  _MetaItem(
                    icon: Icons.schedule_outlined,
                    label: 'Due ${invoice.dueDate}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _money(invoice.total, invoice.currencySymbol),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        if (invoice.balanceDue > 0 &&
                            invoice.status.toLowerCase() != 'paid')
                          Text(
                            '${_money(invoice.balanceDue, invoice.currencySymbol)} due',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Change status',
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Draft', child: Text('Set draft')),
                      PopupMenuItem(value: 'Sent', child: Text('Mark sent')),
                      PopupMenuItem(value: 'Paid', child: Text('Mark paid')),
                      PopupMenuItem(
                          value: 'Overdue', child: Text('Mark overdue')),
                      PopupMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancel invoice'),
                      ),
                    ],
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 4),
                        Text('Status'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'View invoice',
                    onPressed: onOpen,
                    icon: const Icon(Icons.chevron_right),
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  const _EmptyInvoices({
    required this.hasInvoices,
    required this.onCreate,
  });

  final bool hasInvoices;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            Icon(
              hasInvoices ? Icons.search_off : Icons.receipt_long_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasInvoices ? 'No matching invoices' : 'Your invoices start here',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              hasInvoices
                  ? 'Try another search or status filter.'
                  : 'Create an invoice with client details, line items and tax.',
              textAlign: TextAlign.center,
            ),
            if (!hasInvoices) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create invoice'),
              ),
            ],
          ],
        ),
      );
}

String _money(double amount, String symbol) =>
    '$symbol${amount.toStringAsFixed(2)}';
