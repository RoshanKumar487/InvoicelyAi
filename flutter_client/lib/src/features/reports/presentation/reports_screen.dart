import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.apiClient,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback? onBack;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportRepository _repository;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _statistics = <String, dynamic>{};
  List<Map<String, dynamic>> _invoices = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _expenses = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _repository = ReportRepository(apiClient: widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _repository.loadStatistics(),
        _repository.loadInvoices(),
        _repository.loadExpenses(),
      ]);
      if (!mounted) return;
      setState(() {
        _statistics = results[0] as Map<String, dynamic>;
        _invoices = results[1] as List<Map<String, dynamic>>;
        _expenses = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load reports: $error';
        _loading = false;
      });
    }
  }

  double _value(String key) {
    final value = _statistics[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(double amount) => amount.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final expensesTotal = _expenses.fold<double>(
      0,
      (sum, expense) => sum + _toDouble(expense['amount']),
    );
    final paidInvoices = _invoices
        .where(
          (invoice) =>
              invoice['status']?.toString().toLowerCase() == 'paid',
        )
        .toList(growable: false);
    final paidRevenue = _invoices.isEmpty
        ? _value('totalRevenue')
        : paidInvoices.fold<double>(
            0,
            (sum, invoice) => sum + _invoiceTotal(invoice),
          );
    final calculatedOutstanding = _invoices.fold<double>(0, (sum, invoice) {
      final status = invoice['status']?.toString().toLowerCase() ?? '';
      if (status == 'paid' || status == 'cancelled' || status == 'draft') {
        return sum;
      }
      final balance = _invoiceTotal(invoice) - _toDouble(invoice['amountPaid']);
      return sum + (balance > 0 ? balance : 0);
    });
    final outstanding = _invoices.isEmpty
        ? _value('outstandingAmount')
        : calculatedOutstanding;
    final netEarnings = paidRevenue - expensesTotal;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Reports'),
            Text(
              'Revenue, expenses & tax metrics',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Cashflow (Paid Invoices - Expenses)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _money(netEarnings),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: netEarnings < 0
                                        ? AppColors.overdue
                                        : AppColors.paid,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _MetricLine(
                              label: 'Paid invoice revenue',
                              value: _money(paidRevenue),
                            ),
                            _MetricLine(
                              label: 'Expenses',
                              value: _money(expensesTotal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 650 ? 4 : 2;
                          final cards = <Widget>[
                            _SummaryTile(
                              title: 'Invoices',
                              value: _value('totalInvoices').toStringAsFixed(0),
                              icon: Icons.receipt_long,
                            ),
                            _SummaryTile(
                              title: 'Paid',
                              value: _value('paidInvoices').toStringAsFixed(0),
                              icon: Icons.check_circle_outline,
                            ),
                            _SummaryTile(
                              title: 'Outstanding',
                              value: _money(outstanding),
                              icon: Icons.pending_actions,
                            ),
                            _SummaryTile(
                              title: 'Clients',
                              value: _value('totalClients').toStringAsFixed(0),
                              icon: Icons.people_outline,
                            ),
                          ];
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: constraints.maxWidth >= 650 ? 1.6 : 1.25,
                            children: cards,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_expenses.isEmpty)
                              const Text('No expenses are available.')
                            else
                              ..._expenses.take(12).map(
                                    (expense) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        expense['title']?.toString() ??
                                            expense['vendor']?.toString() ??
                                            'Expense',
                                      ),
                                      subtitle: Text(
                                        [
                                          expense['category']?.toString(),
                                          expense['date']?.toString(),
                                        ]
                                            .where((value) =>
                                                value != null && value.isNotEmpty)
                                            .join(' • '),
                                      ),
                                      trailing: Text(
                                        _money(_toDouble(expense['amount'])),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent invoices',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_invoices.isEmpty)
                              const Text('No invoices are available.')
                            else
                              ..._invoices.take(12).map(
                                    (invoice) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        invoice['invoiceNumber']?.toString() ??
                                            'Invoice',
                                      ),
                                      subtitle: Text(
                                        '${invoice['clientName'] ?? 'Client'} • ${invoice['status'] ?? 'Unknown'}',
                                      ),
                                      trailing: Text(
                                        '${invoice['currencySymbol'] ?? ''}${_money(_invoiceTotal(invoice))}',
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _invoiceTotal(Map<String, dynamic> invoice) {
  final explicit = invoice['total'] ?? invoice['grandTotal'];
  if (explicit != null) return _toDouble(explicit);

  Object? decoded;
  try {
    decoded = jsonDecode(invoice['itemsJson']?.toString() ?? '[]');
  } on FormatException {
    return 0;
  }
  if (decoded is! List<Object?>) return 0;
  var subtotal = 0.0;
  var itemDiscounts = 0.0;
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) continue;
    final lineBase =
        _toDouble(item['quantity'] ?? 1) * _toDouble(item['unitPrice']);
    subtotal += lineBase;
    itemDiscounts += lineBase * _toDouble(item['discountRate']) / 100;
  }

  final totalDiscount = itemDiscounts +
      (subtotal - itemDiscounts) *
          _toDouble(invoice['discountPercent']) /
          100 +
      _toDouble(invoice['discountAmount']);
  final taxableBase =
      (subtotal - totalDiscount).clamp(0, double.infinity).toDouble();
  final taxRate = _toDouble(invoice['taxRate']);
  final isTaxInclusive = invoice['isTaxInclusive'] == true;
  final tax = isTaxInclusive
      ? taxableBase - (taxableBase / (1 + taxRate / 100))
      : taxableBase * taxRate / 100;
  final total = isTaxInclusive
      ? taxableBase +
          _toDouble(invoice['shippingFee']) +
          _toDouble(invoice['additionalCharges'])
      : taxableBase +
          tax +
          _toDouble(invoice['shippingFee']) +
          _toDouble(invoice['additionalCharges']);
  return (total + _toDouble(invoice['roundOff']))
      .clamp(0, double.infinity)
      .toDouble();
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.blue),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(title, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
