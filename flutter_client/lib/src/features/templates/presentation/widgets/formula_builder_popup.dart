import 'package:flutter/material.dart';

class FormulaBuilderResult {
  const FormulaBuilderResult({
    required this.formulaCode,
    required this.formulaExpression,
    required this.standardDutyDays,
  });

  /// Canonical calculation mode for InvoiceItem / LineItemEditor:
  /// 'monthly_salary_30', 'calendar_month', 'monthly_salary_26', 'per_duty', 'flat_monthly', 'standard'
  final String formulaCode;

  /// Human-readable formula expression saved on the StudioField or section
  final String formulaExpression;

  /// Base days in the month (e.g. 30, 31, 28, 29, 26)
  final double standardDutyDays;
}

class FormulaBuilderPopup extends StatefulWidget {
  const FormulaBuilderPopup({
    super.key,
    required this.targetTitle,
    this.initialFormulaCode = 'monthly_salary_30',
    this.initialExpression = '',
    this.initialStandardDays = 30,
    this.currencySymbol = '₹',
  });

  final String targetTitle;
  final String initialFormulaCode;
  final String initialExpression;
  final double initialStandardDays;
  final String currencySymbol;

  static Future<FormulaBuilderResult?> show(
    BuildContext context, {
    required String targetTitle,
    String initialFormulaCode = 'monthly_salary_30',
    String initialExpression = '',
    double initialStandardDays = 30,
    String currencySymbol = '₹',
  }) {
    return showDialog<FormulaBuilderResult>(
      context: context,
      builder: (ctx) => FormulaBuilderPopup(
        targetTitle: targetTitle,
        initialFormulaCode: initialFormulaCode,
        initialExpression: initialExpression,
        initialStandardDays: initialStandardDays,
        currencySymbol: currencySymbol,
      ),
    );
  }

  @override
  State<FormulaBuilderPopup> createState() => _FormulaBuilderPopupState();
}

class _FormulaBuilderPopupState extends State<FormulaBuilderPopup> {
  late String _selectedMode;
  late double _baseMonthDays;
  late final TextEditingController _expressionCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _dutyCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _baseDaysCtrl;

  static const List<({String code, String title, String subtitle, String expr, double days})> _presets = [
    (
      code: 'monthly_salary_30',
      title: 'Daily Wage (Monthly Rate ÷ 30 Days)',
      subtitle: 'Rate ₹30,000 ÷ 30 = ₹1,000/day × Worked Duty Days × Qty',
      expr: '(Monthly Rate ÷ 30) × Qty × No. of Duty',
      days: 30,
    ),
    (
      code: 'calendar_month',
      title: 'Daily Wage by Month Days (28 / 29 / 30 / 31)',
      subtitle: 'Auto divides monthly rate by calendar month days × Worked Days',
      expr: '(Monthly Rate ÷ Month Days) × Qty × No. of Duty',
      days: 30,
    ),
    (
      code: 'monthly_salary_26',
      title: 'Security Standard (Monthly Rate ÷ 26 Duties)',
      subtitle: 'Standard 26-duty cycle (4 weekly offs) × Worked Duty Days',
      expr: '(Monthly Rate ÷ 26) × Qty × No. of Duty',
      days: 26,
    ),
    (
      code: 'per_duty',
      title: 'Direct Per-Duty / Daily Wage Rate',
      subtitle: 'Rate is already 1 day wage: Qty × No. of Duty × Daily Rate',
      expr: 'Qty × No. of Duty × Daily Rate',
      days: 1,
    ),
    (
      code: 'flat_monthly',
      title: 'Flat Monthly Rate (Fixed Lumpsum)',
      subtitle: 'Fixed monthly charge regardless of duty days: Qty × Rate',
      expr: 'Qty × Monthly Rate',
      days: 30,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialFormulaCode.isNotEmpty
        ? widget.initialFormulaCode
        : 'monthly_salary_30';
    if (!_presets.any((p) => p.code == _selectedMode)) {
      _selectedMode = 'monthly_salary_30';
    }
    _baseMonthDays = widget.initialStandardDays > 0
        ? widget.initialStandardDays
        : (_selectedMode == 'monthly_salary_26' ? 26 : 30);

    final defaultExpr = widget.initialExpression.trim().isNotEmpty
        ? widget.initialExpression.trim()
        : _presets.firstWhere((p) => p.code == _selectedMode).expr;

    _expressionCtrl = TextEditingController(text: defaultExpr);
    _qtyCtrl = TextEditingController(text: '1');
    _dutyCtrl = TextEditingController(text: '25');
    _rateCtrl = TextEditingController(text: '30000');
    _baseDaysCtrl = TextEditingController(
      text: _baseMonthDays.truncateToDouble() == _baseMonthDays
          ? _baseMonthDays.toInt().toString()
          : _baseMonthDays.toString(),
    );
  }

  @override
  void dispose() {
    _expressionCtrl.dispose();
    _qtyCtrl.dispose();
    _dutyCtrl.dispose();
    _rateCtrl.dispose();
    _baseDaysCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String code) {
    final preset = _presets.firstWhere((p) => p.code == code);
    setState(() {
      _selectedMode = code;
      if (code == 'monthly_salary_30') {
        _baseMonthDays = 30;
        _baseDaysCtrl.text = '30';
      } else if (code == 'monthly_salary_26') {
        _baseMonthDays = 26;
        _baseDaysCtrl.text = '26';
      }
      _expressionCtrl.text = preset.expr;
    });
  }

  void _insertToken(String token) {
    final current = _expressionCtrl.text.trim();
    setState(() {
      _expressionCtrl.text = current.isEmpty ? token : '$current $token';
    });
  }

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 1;
  double get _workedDays => double.tryParse(_dutyCtrl.text.trim()) ?? 0;
  double get _monthlyRate => double.tryParse(_rateCtrl.text.trim()) ?? 0;
  double get _monthDays {
    final d = double.tryParse(_baseDaysCtrl.text.trim()) ?? _baseMonthDays;
    return d > 0 ? d : 30;
  }

  double get _dailyWage {
    if (_selectedMode == 'per_duty') return _monthlyRate;
    if (_selectedMode == 'flat_monthly') return _monthlyRate / 30.0;
    if (_selectedMode == 'monthly_salary_30') return _monthlyRate / 30.0;
    if (_selectedMode == 'monthly_salary_26') return _monthlyRate / 26.0;
    return _monthlyRate / _monthDays;
  }

  double get _calculatedSubtotal {
    if (_workedDays <= 0) return _qty * _monthlyRate;
    switch (_selectedMode) {
      case 'per_duty':
        return _qty * _workedDays * _monthlyRate;
      case 'flat_monthly':
        return _qty * _monthlyRate;
      case 'monthly_salary_30':
        return (_monthlyRate / 30.0) * _qty * _workedDays;
      case 'monthly_salary_26':
        return (_monthlyRate / 26.0) * _qty * _workedDays;
      case 'calendar_month':
      default:
        return (_monthlyRate / _monthDays) * _qty * _workedDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.currencySymbol;
    final daily = _dailyWage;
    final subtotal = _calculatedSubtotal;
    final effectiveDivisor = _selectedMode == 'monthly_salary_30'
        ? 30
        : (_selectedMode == 'monthly_salary_26' ? 26 : _monthDays.toInt());

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Gradient Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.functions_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formula & Daily Wage Setup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.targetTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 19),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),

            // Scrollable Body (Mobile-Fitted)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Live Interactive Daily Wage & Subtotal Calculator Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Live Daily Wage & Subtotal Calculator',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Daily: $sym${daily.toStringAsFixed(0)}/d',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 4 Mini Inputs in one compact row: Qty, Worked Days, Monthly Rate, Month Days
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _miniField(
                                  controller: _qtyCtrl,
                                  label: 'Qty',
                                  onChanged: () => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: _miniField(
                                  controller: _dutyCtrl,
                                  label: 'Worked Days',
                                  onChanged: () => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 4,
                                child: _miniField(
                                  controller: _rateCtrl,
                                  label: 'Monthly Rate ($sym)',
                                  onChanged: () => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: _miniField(
                                  controller: _baseDaysCtrl,
                                  label: 'Month Days',
                                  onChanged: () {
                                    setState(() {
                                      _baseMonthDays =
                                          double.tryParse(_baseDaysCtrl.text.trim()) ?? 30;
                                      if (_baseMonthDays == 30) {
                                        _selectedMode = 'monthly_salary_30';
                                      } else if (_baseMonthDays == 26) {
                                        _selectedMode = 'monthly_salary_26';
                                      } else {
                                        _selectedMode = 'calendar_month';
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quick Worked Days & Month Base Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Text(
                                  'Worked Duty: ',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                ),
                                for (final d in const [15, 20, 22, 25, 26, 28, 30, 31])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: InkWell(
                                      onTap: () => setState(() => _dutyCtrl.text = '$d'),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _dutyCtrl.text.trim() == '$d'
                                              ? const Color(0xFF2563EB)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          '${d}d',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _dutyCtrl.text.trim() == '$d'
                                                ? Colors.white
                                                : const Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Live Subtotal Breakdown Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedMode == 'per_duty'
                                        ? '${_qty.toStringAsFixed(0)} × ${_workedDays.toStringAsFixed(0)}d × $sym${_monthlyRate.toStringAsFixed(0)}'
                                        : _selectedMode == 'flat_monthly'
                                            ? '${_qty.toStringAsFixed(0)} × $sym${_monthlyRate.toStringAsFixed(0)} (Flat)'
                                            : '($sym${_monthlyRate.toStringAsFixed(0)} ÷ ${effectiveDivisor}d = $sym${daily.toStringAsFixed(2)}/d) × ${_qty.toStringAsFixed(0)} × ${_workedDays.toStringAsFixed(0)}d',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$sym${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Calculation Mode Presets
                    const Text(
                      'Select Calculation Rule:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final preset in _presets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => _selectPreset(preset.code),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedMode == preset.code
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMode == preset.code
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: _selectedMode == preset.code ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedMode == preset.code
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  size: 17,
                                  color: _selectedMode == preset.code
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMode == preset.code
                                              ? const Color(0xFF1E3A8A)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        preset.subtitle,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // 3. Formula Expression & Quick Variable Tokens
                    const Text(
                      'Formula Expression (Editable for Any Field):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _expressionCtrl,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.functions_rounded, size: 16, color: Color(0xFF2563EB)),
                        suffixIcon: IconButton(
                          tooltip: 'Clear formula',
                          icon: const Icon(Icons.clear_rounded, size: 15),
                          onPressed: () => setState(() => _expressionCtrl.clear()),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final token in const [
                          'Monthly Rate',
                          '÷',
                          '30',
                          'Month Days',
                          '×',
                          'Qty',
                          'No. of Duty',
                          'Daily Wage',
                          '+',
                          '-',
                          'Subtotal',
                          'CGST%',
                          'SGST%',
                        ])
                          InkWell(
                            onTap: () => _insertToken(token),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                token,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12.5)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final days = double.tryParse(_baseDaysCtrl.text.trim()) ?? _baseMonthDays;
                      Navigator.of(context).pop(
                        FormulaBuilderResult(
                          formulaCode: _selectedMode,
                          formulaExpression: _expressionCtrl.text.trim(),
                          standardDutyDays: days > 0 ? days : 30,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Save Formula',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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

  Widget _miniField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
