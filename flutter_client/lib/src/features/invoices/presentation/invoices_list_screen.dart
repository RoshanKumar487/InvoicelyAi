import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({
    required this.repository,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    super.key,
  });

  final InvoiceRepository repository;
  final VoidCallback onCreate;
  final ValueChanged<Invoice> onOpen;
  final ValueChanged<Invoice> onEdit;

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
  String? _error;
  bool _loading = true;
  bool _usingCachedData = false;

  @override
  void initState() {
    super.initState();
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteInvoice(id);
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

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final invoices = _invoices.where((invoice) {
      final matchesStatus = _filter == 'All' ||
          invoice.status.toLowerCase() == _filter.toLowerCase();
      final matchesSearch = query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.clientCompany.toLowerCase().contains(query) ||
          invoice.clientEmail.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _OverviewCards(invoices: _invoices),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search invoice number, client or email',
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'All invoices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${invoices.length} ${invoices.length == 1 ? 'record' : 'records'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            ] else if (_loading && _invoices.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (invoices.isEmpty) ...[
              _EmptyInvoices(
                hasInvoices: _invoices.isNotEmpty,
                onCreate: widget.onCreate,
              ),
            ] else ...[
              for (final invoice in invoices) ...[
                _InvoiceCard(
                  invoice: invoice,
                  onOpen: () => widget.onOpen(invoice),
                  onEdit: () => widget.onEdit(invoice),
                  onDelete: () => _delete(invoice),
                  onStatusChanged: (status) => _setStatus(invoice, status),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    final outstanding = invoices
        .where((invoice) => invoice.status.toLowerCase() != 'paid')
        .fold<double>(0, (sum, invoice) => sum + invoice.balanceDue);
    final paid = invoices
        .where((invoice) => invoice.status.toLowerCase() == 'paid')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final cards = [
          _SummaryCard(
            label: 'Invoices',
            value: '${invoices.length}',
            icon: Icons.receipt_long_outlined,
          ),
          _SummaryCard(
            label: 'Paid',
            value: '$paid',
            icon: Icons.check_circle_outline,
          ),
          _SummaryCard(
            label: 'Outstanding',
            value: _money(
              outstanding,
              invoices.isEmpty ? r'$' : invoices.first.currencySymbol,
            ),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: compact
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 24) / 3,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
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
