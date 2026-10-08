import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _reverse = false;

  final _base = TextEditingController(text: '1000');
  final _taxLabel1 = TextEditingController(text: 'VAT / Sales Tax');
  final _rate1 = TextEditingController(text: '10');
  final _taxLabel2 = TextEditingController(text: 'Secondary Tax / Cess');
  final _rate2 = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _shipping = TextEditingController(text: '0');
  final _gross = TextEditingController(text: '1100');
  final _reverseRate = TextEditingController(text: '10');
  final _currencyAmount = TextEditingController(text: '1000');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  static const _currencyRatesToUsd = <String, double>{
    'USD': 1,
    'EUR': 1.08,
    'GBP': 1.28,
    'INR': 0.012,
    'CAD': 0.74,
    'AUD': 0.66,
    'JPY': 0.0067,
    'AED': 0.27,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_refreshOnTabChange);
    for (final controller in [
      _base,
      _taxLabel1,
      _rate1,
      _taxLabel2,
      _rate2,
      _discount,
      _shipping,
      _gross,
      _reverseRate,
      _currencyAmount,
    ]) {
      controller.addListener(_refresh);
    }
  }

  void _refreshOnTabChange() => setState(() {});

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_refreshOnTabChange)
      ..dispose();
    for (final controller in [
      _base,
      _taxLabel1,
      _rate1,
      _taxLabel2,
      _rate2,
      _discount,
      _shipping,
      _gross,
      _reverseRate,
      _currencyAmount,
    ]) {
      controller
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Tax & Currency Tools'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.calculate_outlined), text: 'Tax calculator'),
              Tab(
                icon: Icon(Icons.currency_exchange),
                text: 'Multi-currency',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTaxCalculator(),
            _buildCurrencyConverter(),
          ],
        ),
      );

  Widget _buildTaxCalculator() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reverse
                            ? 'Reverse tax (gross to net)'
                            : 'Forward tax (net to gross)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _reverse = !_reverse),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(_reverse ? 'Forward' : 'Reverse'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_reverse)
                  Column(
                    children: [
                      _numberField(
                        controller: _gross,
                        label: 'Gross / tax-inclusive total',
                      ),
                      const SizedBox(height: 10),
                      _numberField(
                        controller: _reverseRate,
                        label: 'Tax rate (%)',
                        allowHundred: true,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _numberField(
                        controller: _base,
                        label: 'Base net amount',
                      ),
                      const SizedBox(height: 10),
                      _adaptiveFields(
                        _textField(
                          controller: _taxLabel1,
                          label: 'Primary tax label',
                        ),
                        _numberField(
                          controller: _rate1,
                          label: 'Rate 1 (%)',
                          allowHundred: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _adaptiveFields(
                        _textField(
                          controller: _taxLabel2,
                          label: 'Secondary tax label',
                        ),
                        _numberField(
                          controller: _rate2,
                          label: 'Rate 2 (%)',
                          allowHundred: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _adaptiveFields(
                        _numberField(
                          controller: _discount,
                          label: 'Discount (%)',
                          allowHundred: true,
                        ),
                        _numberField(
                          controller: _shipping,
                          label: 'Shipping amount',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _reverse ? _reverseResult() : _forwardResult(),
              ],
            ),
          ),
        ],
      );

  Widget _forwardResult() {
    final base = _number(_base);
    final taxRate1 = _number(_rate1);
    final taxRate2 = _number(_rate2);
    final discountRate = _number(_discount);
    final shipping = _number(_shipping);
    final discountedBase =
        (base * (1 - (discountRate / 100)))
            .clamp(0, double.infinity)
            .toDouble();
    final discountAmount = base - discountedBase;
    final tax1 = discountedBase * taxRate1 / 100;
    final tax2 = discountedBase * taxRate2 / 100;
    final finalTotal = discountedBase + tax1 + tax2 + shipping;
    return _CalculationResult(
      title: 'Calculation result',
      rows: [
        _CalcLine('Net base amount', _money(base)),
        if (discountRate > 0)
          _CalcLine('Discount ($discountRate%)', '-${_money(discountAmount)}'),
        _CalcLine(
          '${_taxLabel1.text.isEmpty ? 'Tax 1' : _taxLabel1.text} ($taxRate1%)',
          _money(tax1),
        ),
        if (taxRate2 > 0)
          _CalcLine(
            '${_taxLabel2.text.isEmpty ? 'Tax 2' : _taxLabel2.text} ($taxRate2%)',
            _money(tax2),
          ),
        if (shipping > 0) _CalcLine('Shipping', _money(shipping)),
        _CalcLine('Final total amount', _money(finalTotal), bold: true),
      ],
    );
  }

  Widget _reverseResult() {
    final gross = _number(_gross);
    final rate = _number(_reverseRate);
    final net = rate >= 0 ? gross / (1 + rate / 100) : gross;
    return _CalculationResult(
      title: 'Extracted net & tax breakdown',
      rows: [
        _CalcLine('Gross amount (input)', _money(gross)),
        _CalcLine('Pre-tax base amount (net)', _money(net), bold: true),
        _CalcLine('Tax extracted ($rate%)', _money(gross - net)),
      ],
    );
  }

  Widget _buildCurrencyConverter() {
    final amount = _number(_currencyAmount);
    final fromRate = _currencyRatesToUsd[_fromCurrency] ?? 1;
    final toRate = _currencyRatesToUsd[_toCurrency] ?? 1;
    final rate = toRate == 0 ? 0 : fromRate / toRate;
    final converted = amount * rate;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currency converter',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _numberField(
                controller: _currencyAmount,
                label: 'Amount to convert',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final from = _currencyDropdown(
                    label: 'From',
                    value: _fromCurrency,
                    onChanged: (value) =>
                        setState(() => _fromCurrency = value),
                  );
                  final swap = IconButton(
                    onPressed: () {
                      setState(() {
                        final fromValue = _fromCurrency;
                        _fromCurrency = _toCurrency;
                        _toCurrency = fromValue;
                      });
                    },
                    tooltip: 'Swap currencies',
                    icon: const Icon(Icons.swap_horiz),
                  );
                  final to = _currencyDropdown(
                    label: 'To',
                    value: _toCurrency,
                    onChanged: (value) => setState(() => _toCurrency = value),
                  );
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(child: from),
                        swap,
                        Expanded(child: to),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      from,
                      Align(alignment: Alignment.center, child: swap),
                      to,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_money(amount)} $_fromCurrency =',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_money(converted)} $_toCurrency',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1 $_fromCurrency = ${rate.toStringAsFixed(4)} $_toCurrency',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Exchange rates are the static illustrative estimates ported from the existing client. They are not live market data and are not fetched from a server.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _currencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: _currencyRatesToUsd.keys
            .map(
              (currency) => DropdownMenuItem<String>(
                value: currency,
                child: Text(currency),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      );

  Widget _adaptiveFields(Widget first, Widget second) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                first,
                const SizedBox(height: 10),
                second,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          );
        },
      );

  Widget _textField({
    required TextEditingController controller,
    required String label,
  }) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool allowHundred = false,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
        ],
        decoration: InputDecoration(labelText: label),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          final amount = double.tryParse(value ?? '');
          if (amount == null || amount < 0) {
            return 'Enter a non-negative number.';
          }
          if (allowHundred && amount > 100) {
            return 'Rate must be 100% or less.';
          }
          return null;
        },
      );
}

double _number(TextEditingController controller) =>
    double.tryParse(controller.text) ?? 0;

String _money(double amount) => amount.toStringAsFixed(2);

class _CalculationResult extends StatelessWidget {
  const _CalculationResult({required this.title, required this.rows});

  final String title;
  final List<_CalcLine> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            const Divider(color: Colors.white30),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight:
                              row.bold ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      row.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            row.bold ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _CalcLine {
  const _CalcLine(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;
}
