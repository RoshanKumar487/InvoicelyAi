import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Interactive Statutory Deductions & Wages Calculator for Indian / Enterprise payroll.
/// Computes EPF (12%), ESIC (0.75% / 3.25%), Professional Tax, and Daily Wages.
class StatutoryWageCalculatorDialog extends StatefulWidget {
  const StatutoryWageCalculatorDialog({
    this.initialMonthlyGross = 25000.0,
    this.currencySymbol = '₹',
    super.key,
  });

  final double initialMonthlyGross;
  final String currencySymbol;

  @override
  State<StatutoryWageCalculatorDialog> createState() => _StatutoryWageCalculatorDialogState();
}

class _StatutoryWageCalculatorDialogState extends State<StatutoryWageCalculatorDialog> {
  late final TextEditingController _grossController;
  late final TextEditingController _dutyDaysController;

  final bool _isDailyWageMode = false;
  bool _includePf = true;
  bool _includeEsi = true;
  bool _includePt = true;

  double _gross = 25000.0;
  int _dutyDays = 26;

  @override
  void initState() {
    super.initState();
    _gross = widget.initialMonthlyGross;
    _grossController = TextEditingController(text: _gross.toStringAsFixed(0));
    _dutyDaysController = TextEditingController(text: _dutyDays.toString());
  }

  @override
  void dispose() {
    _grossController.dispose();
    _dutyDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Basic Pay (typically 50% of Gross in Indian statutory framework)
    final basicPay = _gross * 0.50;
    final hra = _gross * 0.30;
    final specialAllowance = _gross - (basicPay + hra);

    // 2. Employee Statutory Deductions
    // EPF: 12% of Basic Pay (capped at ₹15,000 basic = max ₹1,800/mo)
    final pfEligibleBasic = basicPay > 15000 ? 15000.0 : basicPay;
    final pfEmployee = _includePf ? (pfEligibleBasic * 0.12) : 0.0;

    // ESIC: 0.75% of Gross (applicable if Gross <= ₹21,000/mo)
    final isEsiApplicable = _gross <= 21000;
    final esiEmployee = (_includeEsi && isEsiApplicable) ? (_gross * 0.0075) : 0.0;

    // Professional Tax: standard slab ₹200/mo
    final pt = _includePt ? (_gross > 15000 ? 200.0 : 0.0) : 0.0;

    final totalEmployeeDeductions = pfEmployee + esiEmployee + pt;
    final netInHand = _gross - totalEmployeeDeductions;

    // 3. Employer Statutory Contributions (CTC additions)
    final pfEmployer = _includePf ? (pfEligibleBasic * 0.12) : 0.0; // 3.67% PF + 8.33% EPS
    final esiEmployer = (_includeEsi && isEsiApplicable) ? (_gross * 0.0325) : 0.0;
    final totalEmployerContribution = pfEmployer + esiEmployer;
    final totalCtc = _gross + totalEmployerContribution;

    // 4. Daily Wage Rate
    final dailyRate = _dutyDays > 0 ? (_gross / _dutyDays) : 0.0;
    final netDailyRate = _dutyDays > 0 ? (netInHand / _dutyDays) : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: AppTheme.neuCardDecoration(radius: 24),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statutory Wage & CTC Calculator',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Compute EPF, ESIC, PT, Net Take-Home & Employer Cost',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Inputs Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode selector & Input Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _grossController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: _isDailyWageMode ? 'Monthly Base Target (${widget.currencySymbol})' : 'Monthly Gross Salary (${widget.currencySymbol})',
                              prefixText: '${widget.currencySymbol} ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (val) {
                              final d = double.tryParse(val) ?? 0.0;
                              setState(() => _gross = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dutyDaysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Working Days',
                              suffixText: 'days',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (val) {
                              final d = int.tryParse(val) ?? 26;
                              setState(() => _dutyDays = d > 0 ? d : 26);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Statutory Checkbox Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          selected: _includePf,
                          label: const Text('EPF @ 12%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onSelected: (val) => setState(() => _includePf = val),
                          selectedColor: const Color(0xFFDBEAFE),
                          checkmarkColor: const Color(0xFF1D4ED8),
                        ),
                        FilterChip(
                          selected: _includeEsi,
                          label: Text(
                            'ESIC @ 0.75%${isEsiApplicable ? '' : ' (Gross > 21k)'}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onSelected: (val) => setState(() => _includeEsi = val),
                          selectedColor: const Color(0xFFDCFCE7),
                          checkmarkColor: const Color(0xFF15803D),
                        ),
                        FilterChip(
                          selected: _includePt,
                          label: const Text('Prof Tax (PT ₹200)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onSelected: (val) => setState(() => _includePt = val),
                          selectedColor: const Color(0xFFF3E8FF),
                          checkmarkColor: const Color(0xFF7E22CE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Results Cards (Net Take-Home vs Total CTC)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Net Take-Home Pay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.currencySymbol}${netInHand.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currencySymbol}${netDailyRate.toStringAsFixed(1)} / day',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Cost to Company (CTC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.currencySymbol}${totalCtc.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currencySymbol}${dailyRate.toStringAsFixed(1)} / day gross',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Detailed Line-Item Breakdown Table
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildBreakdownRow('Basic Pay (50%)', basicPay, isPositive: true),
                          _buildBreakdownRow('House Rent Allowance (HRA 30%)', hra, isPositive: true),
                          _buildBreakdownRow('Special Allowance', specialAllowance, isPositive: true),
                          const Divider(height: 12, color: Color(0xFFCBD5E1)),
                          _buildBreakdownRow('EPF Employee Contribution (12%)', -pfEmployee),
                          _buildBreakdownRow('ESIC Employee Contribution (0.75%)', -esiEmployee),
                          _buildBreakdownRow('Professional Tax (PT)', -pt),
                          const Divider(height: 12, color: Color(0xFFCBD5E1)),
                          _buildBreakdownRow('Total Deductions', -totalEmployeeDeductions, isBold: true),
                          _buildBreakdownRow('Net Payable Salary', netInHand, isBold: true, color: const Color(0xFF15803D)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.neuActiveDark,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Apply to Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop({
                          'gross': _gross,
                          'basic': basicPay,
                          'hra': hra,
                          'pf': pfEmployee,
                          'esi': esiEmployee,
                          'pt': pt,
                          'net': netInHand,
                          'ctc': totalCtc,
                          'dailyRate': dailyRate,
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isPositive = false, bool isBold = false, Color? color}) {
    final prefix = amount < 0 ? '-' : (isPositive ? '+' : '');
    final absAmount = amount.abs().toStringAsFixed(2);
    final rowColor = color ?? (amount < 0 ? const Color(0xFFDC2626) : const Color(0xFF1E293B));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
            ),
          ),
          Text(
            '$prefix${widget.currencySymbol}$absAmount',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: rowColor,
            ),
          ),
        ],
      ),
    );
  }
}
