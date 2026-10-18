import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/table_export_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/enterprise_data_view.dart';
import '../../../shared/widgets/offline_cache_banner.dart';
import '../../audit/data/audit_log_service.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';
import 'widgets/invoice_record_payment_dialog.dart';
import 'widgets/recurring_invoice_setup_dialog.dart';

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
  DateTimeRange? _dateRange;
  final Set<String> _selectedIds = {};

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

  Future<void> _recordPayment(Invoice invoice) async {
    final result = await InvoiceRecordPaymentDialog.show(context, invoice: invoice);
    if (result != null && mounted) {
      try {
        await widget.repository.updateInvoice(result.updatedInvoice);
        _showMessage('Recorded settlement of ${invoice.currencySymbol}${result.amountRecorded.toStringAsFixed(2)}');
        await _load();
      } catch (e) {
        if (mounted) _showMessage('Could not record settlement: $e');
      }
    }
  }

  Future<void> _setupRecurring(Invoice invoice) async {
    final result = await RecurringInvoiceSetupDialog.show(context, invoice: invoice);
    if (result != null && mounted) {
      try {
        await widget.repository.updateInvoice(result.updatedInvoice);
        _showMessage('Configured ${result.frequency} schedule for ${invoice.invoiceNumber}');
        await _load();
      } catch (e) {
        if (mounted) _showMessage('Could not update schedule: $e');
      }
    }
  }

  void _downloadInvoicesReport(List<Invoice> currentInvoices) {
    TableExportHelper.showExportMenu(
      context: context,
      title: 'Invoices Ledger',
      headers: ['Invoice #', 'Client', 'Company', 'Issue Date', 'Due Date', 'Total', 'Balance Due', 'Status'],
      rows: currentInvoices.map((inv) => [
        inv.invoiceNumber.isEmpty ? 'INV-${inv.id ?? ""}' : inv.invoiceNumber,
        inv.clientName,
        inv.clientCompany,
        inv.issueDate,
        inv.dueDate,
        inv.total.toStringAsFixed(2),
        inv.balanceDue.toStringAsFixed(2),
        inv.status,
      ]).toList(),
    );
  }

  Future<void> _batchMarkStatus(String status) async {
    final count = _selectedIds.length;
    for (final idStr in _selectedIds.toList()) {
      final inv = _invoices.firstWhere(
        (i) => (i.id?.toString() == idStr) || (i.invoiceNumber == idStr),
        orElse: () => _invoices.first,
      );
      if (inv.id != null) {
        await widget.repository.updateStatus(inv.id!, status);
      }
    }
    setState(() => _selectedIds.clear());
    _showMessage('Updated $count invoices to $status');
    await _load();
  }

  Future<void> _shareInvoiceWhatsApp(Invoice invoice) async {
    final client = invoice.clientName.isNotEmpty ? invoice.clientName : 'Customer';
    final invNum = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : 'Invoice';
    final amount = _money(invoice.total, invoice.currencySymbol);
    final balance = _money(invoice.balanceDue, invoice.currencySymbol);
    final isPaid = invoice.status.toLowerCase() == 'paid';

    final message = isPaid
        ? 'Hello *$client*, thank you for your payment! Here is your receipt confirmation for invoice *$invNum* ($amount). Status: *PAID* ✅.'
        : 'Hello *$client*, here is the billing reminder for invoice *$invNum*.\nTotal: *$amount*\nBalance Due: *$balance*\nDue Date: *${invoice.dueDate}*.\nPlease let us know once transferred. Thank you!';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  List<EnterpriseTableColumn<Invoice>> _invoiceTableColumns() {
    return [
      EnterpriseTableColumn<Invoice>(
        title: 'Invoice #',
        width: 140,
        sortKey: (inv) => inv.invoiceNumber,
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
        sortKey: (inv) => inv.clientName.toLowerCase(),
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
        sortKey: (inv) => inv.issueDate,
        cellBuilder: (ctx, inv) => Text(inv.issueDate, style: const TextStyle(fontSize: 12)),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Due Date',
        width: 110,
        sortKey: (inv) => inv.dueDate,
        cellBuilder: (ctx, inv) => Text(inv.dueDate, style: const TextStyle(fontSize: 12)),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Total Amount',
        width: 130,
        alignRight: true,
        sortKey: (inv) => inv.total,
        cellBuilder: (ctx, inv) => Text(
          _money(inv.total, inv.currencySymbol),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Balance Due',
        width: 130,
        alignRight: true,
        sortKey: (inv) => inv.balanceDue,
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
        width: 130,
        sortKey: (inv) => inv.status,
        cellBuilder: (ctx, inv) => EnterpriseStatusDropdown(
          currentStatus: inv.status,
          options: const ['Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled'],
          onChanged: (newStatus) => _setStatus(inv, newStatus),
        ),
      ),
      EnterpriseTableColumn<Invoice>(
        title: 'Actions',
        width: 165,
        cellBuilder: (ctx, inv) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: Color(0xFF10B981)),
              tooltip: 'Share via WhatsApp',
              onPressed: () => _shareInvoiceWhatsApp(inv),
            ),
            if (inv.status.toLowerCase() != 'paid')
              IconButton(
                icon: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF16A34A)),
                tooltip: 'Record settlement',
                onPressed: () => _recordPayment(inv),
              ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: 'View preview',
              onPressed: () => widget.onOpen(inv),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              tooltip: 'More actions',
              onSelected: (action) {
                if (action == 'whatsapp') _shareInvoiceWhatsApp(inv);
                if (action == 'settle') _recordPayment(inv);
                if (action == 'recurring') _setupRecurring(inv);
                if (action == 'edit') widget.onEdit(inv);
                if (action == 'delete') _delete(inv);
                if (action == 'mark_paid') _setStatus(inv, 'Paid');
                if (action == 'mark_sent') _setStatus(inv, 'Sent');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'whatsapp', child: Text('Share via WhatsApp')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
                if (inv.status.toLowerCase() != 'paid')
                  const PopupMenuItem(value: 'settle', child: Text('Record Settlement')),
                const PopupMenuItem(value: 'recurring', child: Text('Recurring Schedule')),
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

  List<EnterpriseMetricCardItem> _buildMetrics(List<Invoice> allInvoices) {
    final totalInvoiced = allInvoices.fold<double>(0.0, (acc, i) => acc + i.total);
    final paidInvoices = allInvoices.where((i) => i.status.toLowerCase() == 'paid').toList();
    final totalPaid = paidInvoices.fold<double>(0.0, (acc, i) => acc + i.total);
    final outstandingInvoices = allInvoices.where((i) => i.balanceDue > 0 && i.status.toLowerCase() != 'paid').toList();
    final totalOutstanding = outstandingInvoices.fold<double>(0.0, (acc, i) => acc + i.balanceDue);
    final overdueCount = allInvoices.where((i) => i.status.toLowerCase() == 'overdue').length;

    return [
      EnterpriseMetricCardItem(
        label: 'Total Invoiced',
        value: '₹${totalInvoiced.toStringAsFixed(0)}',
        count: '${allInvoices.length} bills',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF1E3A8A),
        filterKey: 'All',
        isSelected: _filter == 'All',
        onTap: () => setState(() => _filter = 'All'),
      ),
      EnterpriseMetricCardItem(
        label: 'Total Collected',
        value: '₹${totalPaid.toStringAsFixed(0)}',
        count: '${paidInvoices.length} paid',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF047857),
        filterKey: 'Paid',
        isSelected: _filter.toLowerCase() == 'paid',
        onTap: () => setState(() => _filter = _filter.toLowerCase() == 'paid' ? 'All' : 'Paid'),
      ),
      EnterpriseMetricCardItem(
        label: 'Outstanding',
        value: '₹${totalOutstanding.toStringAsFixed(0)}',
        count: '${outstandingInvoices.length} pending',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFD97706),
        filterKey: 'Outstanding',
        isSelected: _filter == 'Outstanding',
        onTap: () => setState(() => _filter = _filter == 'Outstanding' ? 'All' : 'Outstanding'),
      ),
      EnterpriseMetricCardItem(
        label: 'Overdue Bills',
        value: '$overdueCount overdue',
        count: 'Action required',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
        filterKey: 'Overdue',
        isSelected: _filter.toLowerCase() == 'overdue',
        onTap: () => setState(() => _filter = _filter.toLowerCase() == 'overdue' ? 'All' : 'Overdue'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _invoices.where((invoice) {
      bool matchesStatus = true;
      if (_filter == 'Outstanding') {
        matchesStatus = invoice.balanceDue > 0 && invoice.status.toLowerCase() != 'paid';
      } else if (_filter != 'All') {
        matchesStatus = invoice.status.toLowerCase() == _filter.toLowerCase();
      }

      if (_dateRange != null) {
        final issue = DateTime.tryParse(invoice.issueDate);
        if (issue != null) {
          if (issue.isBefore(_dateRange!.start) ||
              issue.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      final matchesSearch = query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.clientCompany.toLowerCase().contains(query) ||
          invoice.clientEmail.toLowerCase().contains(query);

      final matchesCreator = _creatorFilter == 'All' ||
          invoice.createdByUserName.toLowerCase().contains('you') ||
          invoice.createdByUserName.toLowerCase().contains('me');

      return matchesStatus && matchesSearch && matchesCreator;
    }).toList();

    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
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
                const SizedBox(width: 16),
              ],
            ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
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
              padding: EdgeInsets.fromLTRB(horizontalPadding, isDesktop ? 6 : 8, horizontalPadding, 100),
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

                if (_loading && _invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  EnterpriseDataView<Invoice>(
                    items: filtered,
                    headerTitle: 'Invoice Directory',
                    metrics: _buildMetrics(_invoices),
                    dateRange: _dateRange,
                    onDateRangeChanged: (range) => setState(() => _dateRange = range),
                    onDownloadReport: () => _downloadInvoicesReport(filtered),
                    searchController: _searchController,
                    searchHint: 'Search invoice #, client or email...',
                    filterChips: _filters,
                    selectedFilterChip: _filter == 'Outstanding' ? null : _filter,
                    onFilterChipSelected: (f) => setState(() => _filter = f),
                    idGetter: (inv) => inv.id?.toString() ?? inv.invoiceNumber,
                    selectedIds: _selectedIds,
                    onToggleSelect: (id) => setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                    onSelectAll: (ids) => setState(() => _selectedIds.addAll(ids)),
                    onDeselectAll: () => setState(() => _selectedIds.clear()),
                    batchActions: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.check_circle, size: 15),
                        label: const Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _batchMarkStatus('Paid'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text('Mark Sent', style: TextStyle(fontSize: 12)),
                        onPressed: () => _batchMarkStatus('Sent'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                        tooltip: 'Export Selected',
                        onPressed: () {
                          final selected = _invoices.where((i) => _selectedIds.contains(i.id?.toString()) || _selectedIds.contains(i.invoiceNumber)).toList();
                          _downloadInvoicesReport(selected);
                        },
                      ),
                    ],
                    onRowTap: (inv) => widget.onOpen(inv),
                    directoryActions: [
                      if (isDesktop) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D68F0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ],
                    ],
                    expandedFilterExtra: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        const Text(
                          'CREATOR:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _creatorFilter = 'All'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _creatorFilter == 'All' ? const Color(0xFF1D68F0) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _creatorFilter == 'All' ? const Color(0xFF1D68F0) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.layers_outlined,
                                  size: 13,
                                  color: _creatorFilter == 'All' ? Colors.white : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'All Invoices',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _creatorFilter == 'All' ? FontWeight.w800 : FontWeight.w600,
                                    color: _creatorFilter == 'All' ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => _creatorFilter = 'Me'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _creatorFilter == 'Me' ? const Color(0xFF1D68F0) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _creatorFilter == 'Me' ? const Color(0xFF1D68F0) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 13,
                                  color: _creatorFilter == 'Me' ? Colors.white : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Created by Me',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _creatorFilter == 'Me' ? FontWeight.w800 : FontWeight.w600,
                                    color: _creatorFilter == 'Me' ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      onRecordPayment: () => _recordPayment(invoice),
                      onScheduleRecurring: () => _setupRecurring(invoice),
                      onShareWhatsApp: () => _shareInvoiceWhatsApp(invoice),
                    ),
                    columns: _invoiceTableColumns(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}


class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onRecordPayment,
    required this.onScheduleRecurring,
    required this.onShareWhatsApp,
  });

  final Invoice invoice;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onRecordPayment;
  final VoidCallback onScheduleRecurring;
  final VoidCallback onShareWhatsApp;

  @override
  Widget build(BuildContext context) {
    final hasRecurring = invoice.terms.contains('🔁 Recurring');

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
                      if (action == 'settle') onRecordPayment();
                      if (action == 'recurring') onScheduleRecurring();
                      if (action == 'edit') onEdit();
                      if (action == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (invoice.status.toLowerCase() != 'paid')
                        const PopupMenuItem(value: 'settle', child: Text('Record Settlement')),
                      const PopupMenuItem(value: 'recurring', child: Text('Recurring Schedule')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.clientCompany.isEmpty
                          ? invoice.clientName
                          : '${invoice.clientName} · ${invoice.clientCompany}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: const Text(
                        '🔁 Retainer',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7E22CE)),
                      ),
                    ),
                ],
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFDC2626)),
                          ),
                      ],
                    ),
                  ),
                  if (invoice.status.toLowerCase() != 'paid') ...[
                    InkWell(
                      onTap: onRecordPayment,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined, size: 14, color: Color(0xFF15803D)),
                            SizedBox(width: 4),
                            Text('Settle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: onShareWhatsApp,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text('Share', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
