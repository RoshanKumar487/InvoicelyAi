import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

class ItemFormulaResult {
  const ItemFormulaResult({
    required this.formulaKey,
    required this.standardDutyDays,
    required this.formulaExpression,
  });

  final String formulaKey;
  final double standardDutyDays;
  final String formulaExpression;
}

/// Visual, interactive Item Formula Builder Studio.
/// Allows business users to construct custom formulas using column tokens,
/// mathematical operators, standard industry presets, and test calculations
/// live with real simulation inputs.
class ItemFormulaBuilderDialog extends StatefulWidget {
  const ItemFormulaBuilderDialog({
    required this.initialFormulaKey,
    required this.initialStandardDutyDays,
    this.currencySymbol = '₹',
    super.key,
  });

  final String initialFormulaKey;
  final double initialStandardDutyDays;
  final String currencySymbol;

  static Future<ItemFormulaResult?> show(
    BuildContext context, {
    required String initialFormulaKey,
    required double initialStandardDutyDays,
    String currencySymbol = '₹',
  }) =>
      showDialog<ItemFormulaResult>(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (context) => Dialog.fullscreen(
          child: ItemFormulaBuilderDialog(
            initialFormulaKey: initialFormulaKey,
            initialStandardDutyDays: initialStandardDutyDays,
            currencySymbol: currencySymbol,
          ),
        ),
      );

  @override
  State<ItemFormulaBuilderDialog> createState() =>
      _ItemFormulaBuilderDialogState();
}

class _ItemFormulaBuilderDialogState extends State<ItemFormulaBuilderDialog> {
  late String _formulaKey;
  late double _standardDutyDays;
  late String _formulaExpression;

  // Simulator test state
  double _simStaff = 1.0;
  double _simDuty = 26.0;
  double _simSalary = 12000.0;

  final TextEditingController _staffCtrl = TextEditingController(text: '1');
  final TextEditingController _dutyCtrl = TextEditingController(text: '26');
  final TextEditingController _salaryCtrl = TextEditingController(text: '12000');
  final TextEditingController _divisorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formulaKey = widget.initialFormulaKey.isNotEmpty
        ? widget.initialFormulaKey
        : 'monthly_salary_26';
    _standardDutyDays = widget.initialStandardDutyDays > 0
        ? widget.initialStandardDutyDays
        : 26.0;
    _divisorCtrl.text = _standardDutyDays.toStringAsFixed(
      _standardDutyDays == _standardDutyDays.roundToDouble() ? 0 : 1,
    );
    _formulaExpression = _defaultExpressionFor(_formulaKey, _standardDutyDays);
  }

  @override
  void dispose() {
    _staffCtrl.dispose();
    _dutyCtrl.dispose();
    _salaryCtrl.dispose();
    _divisorCtrl.dispose();
    super.dispose();
  }

  String _defaultExpressionFor(String key, double divisor) {
    final divStr = divisor == divisor.roundToDouble()
        ? divisor.toInt().toString()
        : divisor.toStringAsFixed(1);
    switch (key) {
      case 'calendar_month':
      case 'monthly_salary_calendar':
        return '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ $divStr';
      case 'monthly_salary_26':
      case 'monthly_salary':
        return '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ $divStr';
      case 'monthly_salary_30':
        return '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ 30';
      case 'per_duty':
      case 'daily_duty':
        return '[Staff / Guards] × [Duty / Days] × [Daily Rate]';
      case 'flat_monthly':
        return '[Staff / Guards] × [Monthly Salary]';
      case 'standard':
        return '[Quantity] × [Price]';
      default:
        return '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ $divStr';
    }
  }

  void _applyPreset({
    required String key,
    required double divisor,
    required String expression,
  }) {
    setState(() {
      _formulaKey = key;
      _standardDutyDays = divisor;
      _formulaExpression = expression;
      _divisorCtrl.text = divisor == divisor.roundToDouble()
          ? divisor.toInt().toString()
          : divisor.toStringAsFixed(1);
      if (key == 'calendar_month') {
        _simDuty = 21.0;
        _simSalary = 30000.0;
        _simStaff = 1.0;
        _staffCtrl.text = '1';
        _dutyCtrl.text = '21';
        _salaryCtrl.text = '30000';
      } else if (key == 'monthly_salary_26') {
        _simDuty = 26.0;
        _dutyCtrl.text = '26';
      } else if (key == 'monthly_salary_30') {
        _simDuty = 30.0;
        _dutyCtrl.text = '30';
      }
    });
  }

  void _addToken(String token) {
    setState(() {
      if (_formulaExpression.trim().isEmpty) {
        _formulaExpression = token;
      } else {
        _formulaExpression = '$_formulaExpression $token';
      }
    });
  }

  void _removeLastToken() {
    final parts = _formulaExpression.trim().split(' ');
    if (parts.isNotEmpty) {
      parts.removeLast();
      setState(() {
        _formulaExpression = parts.join(' ');
      });
    }
  }

  double _calculateSimTotal() {
    switch (_formulaKey) {
      case 'calendar_month':
      case 'monthly_salary_calendar':
        final div = _standardDutyDays > 0 ? _standardDutyDays : 30.0;
        return (_simStaff * _simDuty * _simSalary) / div;
      case 'monthly_salary_26':
      case 'monthly_salary':
        final div = _standardDutyDays > 0 ? _standardDutyDays : 26.0;
        return (_simStaff * _simDuty * _simSalary) / div;
      case 'monthly_salary_30':
        final div = _standardDutyDays > 0 ? _standardDutyDays : 30.0;
        return (_simStaff * _simDuty * _simSalary) / div;
      case 'per_duty':
      case 'daily_duty':
        return _simStaff * _simDuty * _simSalary;
      case 'flat_monthly':
        return _simStaff * _simSalary;
      case 'standard':
        return _simStaff * _simSalary;
      default:
        final div = _standardDutyDays > 0 ? _standardDutyDays : 26.0;
        return (_simStaff * _simDuty * _simSalary) / div;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final simTotal = _calculateSimTotal();
    final dailyRate = _standardDutyDays > 0
        ? _simSalary / _standardDutyDays
        : _simSalary / 26.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Formula & Calculation Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Configure automatic duty, staff & salary calculation math',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  ItemFormulaResult(
                    formulaKey: _formulaKey,
                    standardDutyDays: _standardDutyDays,
                    formulaExpression: _formulaExpression,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Apply Formula'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. LIVE FORMULA EXPRESSION MONITOR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ACTIVE FORMULA EXPRESSION',
                            style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF2563EB).withAlpha(100)),
                        ),
                        child: Text(
                          _formulaKey.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _formulaExpression.isNotEmpty
                        ? _formulaExpression
                        : '(Empty formula - click tokens below)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formulaKey == 'monthly_salary_26'
                              ? 'Pro-rata monthly wage: Full salary paid for 26 duties. Each duty pays ₹${dailyRate.toStringAsFixed(2)}.'
                              : _formulaKey == 'monthly_salary_30'
                                  ? 'Calendar wage: Full monthly salary divided across 30 days.'
                                  : _formulaKey == 'per_duty'
                                      ? 'Direct rate multiplied per duty count.'
                                      : 'Standard pricing: Quantity multiplied by unit price.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. MATHEMATICAL OPERATORS & CONTROLS
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Operators & Controls',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: _removeLastToken,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.amber.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.backspace_outlined,
                                      size: 13, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    'Backspace',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _formulaExpression = ''),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.red.withAlpha(80)),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final op in ['×', '÷', '+', '-', '(', ')', '%'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: InkWell(
                              onTap: () => _addToken(op),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFBFDBFE)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  op,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. COLUMN VARIABLE TOKENS
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insert Column Tokens',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap column tokens to inject dynamic values into formula',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTokenChip('[Staff / Guards]', const Color(0xFF2563EB)),
                      _buildTokenChip('[Duty / Days]', const Color(0xFF0D9488)),
                      _buildTokenChip('[Salary / Rate]', const Color(0xFF7C3AED)),
                      _buildTokenChip('[Discount %]', const Color(0xFFD97706)),
                      _buildTokenChip('[Tax %]', const Color(0xFFDC2626)),
                      _buildTokenChip('26', const Color(0xFF475569)),
                      _buildTokenChip('30', const Color(0xFF475569)),
                      _buildTokenChip('100', const Color(0xFF475569)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. INDUSTRY PRESETS
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded,
                          color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Standard Industry Presets',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildPresetTile(
                    title: '🗓️ Calendar Month (Salary ÷ Month Days) × Duties',
                    formula: '([Salary] ÷ [Month Days]) × [Duty Days] × [Staff]',
                    description:
                        'Auto-detects calendar days from invoice month (30, 31, 28/29d). Example: (₹30,000 / 30) × 21 = ₹21,000.',
                    isSelected: _formulaKey == 'calendar_month' || _formulaKey == 'monthly_salary_calendar',
                    onTap: () => _applyPreset(
                      key: 'calendar_month',
                      divisor: 30.0,
                      expression:
                          '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ 30',
                    ),
                  ),
                  const Divider(height: 16),
                  _buildPresetTile(
                    title: '🛡️ Security Agency (26-Day Standard)',
                    formula: '([Staff] × [Duty] × [Salary]) ÷ 26',
                    description:
                        'Full monthly salary paid for 26 duties. Pro-rata daily wage (Salary ÷ 26) per duty.',
                    isSelected: _formulaKey == 'monthly_salary_26',
                    onTap: () => _applyPreset(
                      key: 'monthly_salary_26',
                      divisor: 26.0,
                      expression:
                          '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ 26',
                    ),
                  ),
                  const Divider(height: 16),
                  _buildPresetTile(
                    title: '📅 Monthly Calendar (30 Days)',
                    formula: '([Staff] × [Duty] × [Salary]) ÷ 30',
                    description:
                        'Calendar month pro-rata calculation using 30 days divisor.',
                    isSelected: _formulaKey == 'monthly_salary_30',
                    onTap: () => _applyPreset(
                      key: 'monthly_salary_30',
                      divisor: 30.0,
                      expression:
                          '([Staff / Guards] × [Duty / Days] × [Salary / Rate]) ÷ 30',
                    ),
                  ),
                  const Divider(height: 16),
                  _buildPresetTile(
                    title: '⚡ Daily Shift Rate (Per-Duty)',
                    formula: '[Staff] × [Duty] × [Daily Rate]',
                    description:
                        'Straight daily rate per duty performed without monthly divisor.',
                    isSelected: _formulaKey == 'per_duty',
                    onTap: () => _applyPreset(
                      key: 'per_duty',
                      divisor: 26.0,
                      expression:
                          '[Staff / Guards] × [Duty / Days] × [Daily Rate]',
                    ),
                  ),
                  const Divider(height: 16),
                  _buildPresetTile(
                    title: '💼 Flat Monthly Salary',
                    formula: '[Staff] × [Monthly Salary]',
                    description:
                        'Fixed monthly amount ignoring duty variations.',
                    isSelected: _formulaKey == 'flat_monthly',
                    onTap: () => _applyPreset(
                      key: 'flat_monthly',
                      divisor: 26.0,
                      expression: '[Staff / Guards] × [Monthly Salary]',
                    ),
                  ),
                  const Divider(height: 16),
                  _buildPresetTile(
                    title: '📦 Standard Commercial (Qty × Rate)',
                    formula: '[Quantity] × [Price]',
                    description:
                        'Classic retail & wholesale calculation for goods.',
                    isSelected: _formulaKey == 'standard',
                    onTap: () => _applyPreset(
                      key: 'standard',
                      divisor: 26.0,
                      expression: '[Quantity] × [Price]',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. STANDARD DUTY DAYS DIVISOR SETTING
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Duty Days Divisor',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Number of days considered a full working month for pro-rata wage calculation:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _divisorCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Standard Duty Days',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed != null && parsed > 0) {
                              setState(() => _standardDutyDays = parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('26 Days'),
                        onPressed: () {
                          setState(() {
                            _standardDutyDays = 26.0;
                            _divisorCtrl.text = '26';
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('30 Days'),
                        onPressed: () {
                          setState(() {
                            _standardDutyDays = 30.0;
                            _divisorCtrl.text = '30';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. INTERACTIVE LIVE SIMULATOR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFBBF7D0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calculate_rounded,
                            color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Live Interactive Calculation Simulator',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF166534),
                              ),
                            ),
                            Text(
                              'Change inputs below to verify live math and daily wage rate',
                              style: TextStyle(
                                  fontSize: 10.5, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _staffCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Staff / Guards',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed != null && parsed >= 0) {
                              setState(() => _simStaff = parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _dutyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Duty / Days',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed != null && parsed >= 0) {
                              setState(() => _simDuty = parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _salaryCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Salary / Rate',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed != null && parsed >= 0) {
                              setState(() => _simSalary = parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calculated Daily Wage Rate:',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${widget.currencySymbol}${dailyRate.toStringAsFixed(2)} / day',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Computed Line Item Total:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF166534),
                              ),
                            ),
                            Text(
                              '${widget.currencySymbol}${simTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  ItemFormulaResult(
                    formulaKey: _formulaKey,
                    standardDutyDays: _standardDutyDays,
                    formulaExpression: _formulaExpression,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Apply Formula & Save Settings'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChip(String label, Color color) {
    return InkWell(
      onTap: () => _addToken(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetTile({
    required String title,
    required String formula,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formula,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
