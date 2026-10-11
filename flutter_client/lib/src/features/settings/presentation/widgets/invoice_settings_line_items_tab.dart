import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import 'item_formula_builder_dialog.dart';

class InvoiceSettingsLineItemsTab extends StatelessWidget {
  const InvoiceSettingsLineItemsTab({
    super.key,
    required this.localSettings,
    required this.onChanged,
    required this.onSave,
    required this.onApplyPreset,
    required this.fieldTileBuilder,
    required this.customFieldsCardBuilder,
  });

  final Map<String, Object?> localSettings;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final ValueChanged<String> onApplyPreset;
  final Widget Function({
    required String title,
    required String description,
    required String toggleKey,
    required bool defaultToggle,
    required String labelKey,
    required String fallbackLabel,
    required String hint,
  }) fieldTileBuilder;
  final Widget Function({
    required String key,
    required String title,
    required String itemType,
    required String hintText,
  }) customFieldsCardBuilder;

  Widget _buildInfoBanner(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(BuildContext context, String id, String label, String subtitle) {
    final isSelected = localSettings['industryPresetId'] == id;
    return ChoiceChip(
      selected: isSelected,
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(subtitle, style: const TextStyle(fontSize: 10)),
        ],
      ),
      onSelected: (_) => onApplyPreset(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Line Items & Table Columns',
          'Rename all column headers, show/hide optional columns (tax, discount, units), and add brand new custom columns like HSN/SAC Code or SKU.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_center_outlined, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Business Industry Presets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your business category to instantly set the right column labels, duty/salary formulas, and SAC codes:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip(context, 'security', '🛡️ Security Agency & Guards', 'Supervisor, Guard, Days, Rate/Salary'),
                  _presetChip(context, 'hr_staffing', '👤 HR Staffing & Payroll', 'Staff, Days Worked, Monthly Salary'),
                  _presetChip(context, 'gst', '⚖️ GST Tax Invoice', 'Goods / Services, HSN/SAC, Qty, Rate'),
                  _presetChip(context, 'it', '💻 IT & Software Consulting', 'Deliverables, Hours, Hourly Rate'),
                  _presetChip(context, 'retail', '🛍️ Retail & Wholesale', 'Product, Qty, Price, Discount'),
                  _presetChip(context, 'freelance', '🎨 Freelance Services', 'Tasks, Milestones, Units, Fee'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Total Calculation Formula',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select how Staff / Duty / Salary computes line item totals',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: () {
                  final cur = localSettings['itemCalculationFormula']?.toString();
                  if (cur == 'calendar_month' ||
                      cur == 'monthly_salary_calendar' ||
                      cur == 'monthly_salary_26' ||
                      cur == 'monthly_salary_30' ||
                      cur == 'monthly_salary' ||
                      cur == 'per_duty' ||
                      cur == 'flat_monthly' ||
                      cur == 'standard') {
                    if (cur == 'monthly_salary_calendar') return 'calendar_month';
                    if (cur == 'monthly_salary') return 'monthly_salary_26';
                    return cur;
                  }
                  return 'calendar_month';
                }(),
                decoration: InputDecoration(
                  labelText: 'Calculation Formula',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'calendar_month',
                    child: Text('🗓️ Calendar Month: (Salary ÷ Month Days) × Duties (Auto 30/31/28)'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly_salary_26',
                    child: Text('🛡️ Security (26 Days): (Salary ÷ 26) × Duties × Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly_salary_30',
                    child: Text('📅 Commercial (30 Days): (Salary ÷ 30) × Duties × Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'per_duty',
                    child: Text('⚡ Per-Duty Rate: Daily Rate × Duties × Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'flat_monthly',
                    child: Text('💼 Flat Monthly: Monthly Salary × Staff'),
                  ),
                  DropdownMenuItem(
                    value: 'standard',
                    child: Text('📦 Standard Commercial: Quantity × Rate'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    localSettings['itemCalculationFormula'] = val;
                    if (val == 'calendar_month') {
                      final now = DateTime.now();
                      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
                      localSettings['standardDutyDays'] = daysInCurrentMonth.toDouble();
                    } else if (val == 'monthly_salary_26') {
                      localSettings['standardDutyDays'] = 26.0;
                    } else if (val == 'monthly_salary_30') {
                      localSettings['standardDutyDays'] = 30.0;
                    }
                    onChanged();
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 14, color: Color(0xFF2563EB)),
                    label: const Text('Auto Calendar Month', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      localSettings['itemCalculationFormula'] = 'calendar_month';
                      final now = DateTime.now();
                      localSettings['standardDutyDays'] = DateTime(now.year, now.month + 1, 0).day.toDouble();
                      onChanged();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF059669)),
                    label: const Text('Security 26 Days', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      localSettings['itemCalculationFormula'] = 'monthly_salary_26';
                      localSettings['standardDutyDays'] = 26.0;
                      onChanged();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.business_outlined, size: 14, color: Color(0xFFD97706)),
                    label: const Text('30 Days Standard', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      localSettings['itemCalculationFormula'] = 'monthly_salary_30';
                      localSettings['standardDutyDays'] = 30.0;
                      onChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.functions_rounded, size: 16, color: Color(0xFF38BDF8)),
                        SizedBox(width: 6),
                        Text(
                          'SALARY CALCULATION FORMULA',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Salary = (Total Net Salary ÷ Total Month Days) × Duty Days',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Example: Total Net Salary = ₹30,000 • Month Days = 30 • Duty Days = 21\n= (₹30,000 / 30) × 21 = ₹21,000 Result',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: (localSettings['standardDutyDays'] as num?)?.toString() ?? '30',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Standard Duty Days / Divisor',
                  helperText: 'Days considered full month (e.g. 30, 31, or 26)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  if (parsed != null && parsed > 0) {
                    localSettings['standardDutyDays'] = parsed;
                    onChanged();
                  }
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formulaExplanation(
                          localSettings['itemCalculationFormula']?.toString() ?? 'calendar_month',
                          (localSettings['standardDutyDays'] as num?)?.toDouble() ?? 30.0,
                        ),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final curKey = localSettings['itemCalculationFormula']?.toString() ?? 'monthly_salary_26';
                    final curDays = (localSettings['standardDutyDays'] as num?)?.toDouble() ?? 26.0;
                    final curSym = localSettings['defaultCurrencySymbol']?.toString() ?? '₹';
                    final res = await ItemFormulaBuilderDialog.show(
                      context,
                      initialFormulaKey: curKey,
                      initialStandardDutyDays: curDays,
                      currencySymbol: curSym,
                    );
                    if (res != null) {
                      localSettings['itemCalculationFormula'] = res.formulaKey;
                      localSettings['standardDutyDays'] = res.standardDutyDays;
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Open Visual Formula Studio (Tokens & Simulator)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Line Items Column Headers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              // Description Column
              fieldTileBuilder(
                title: 'Item Description Column',
                description: 'Primary product or service name',
                toggleKey: 'showItemDescription',
                defaultToggle: true,
                labelKey: 'customItemHeader',
                fallbackLabel: 'Description',
                hint: 'e.g. Particulars, Items, Services',
              ),
              const Divider(height: 24),

              // Quantity Column
              fieldTileBuilder(
                title: 'Quantity / Staff Column',
                description: 'Number of units purchased or guards deployed',
                toggleKey: 'showItemQty',
                defaultToggle: true,
                labelKey: 'customQtyHeader',
                fallbackLabel: 'Qty',
                hint: 'e.g. Units, No. of Staff, Guards',
              ),
              const Divider(height: 24),

              // Duty Column
              fieldTileBuilder(
                title: 'No. of Duty / Days Column',
                description: 'Duties, shifts, or days worked per staff (multiplies Staff × Duty × Rate)',
                toggleKey: 'showItemDuty',
                defaultToggle: false,
                labelKey: 'customDutyHeader',
                fallbackLabel: 'No. of Duty',
                hint: 'e.g. No. of Duty, Duty Days, Shifts',
              ),
              const Divider(height: 24),

              // Unit of Measure
              fieldTileBuilder(
                title: 'Unit Measurement Badge',
                description: 'e.g. hrs, pcs, kg, days',
                toggleKey: 'showItemUnit',
                defaultToggle: true,
                labelKey: 'customUnitHeader',
                fallbackLabel: 'Unit',
                hint: 'e.g. UOM, Unit',
              ),
              const Divider(height: 24),

              // Rate / Unit Price
              fieldTileBuilder(
                title: 'Rate / Price Column',
                description: 'Unit cost per item',
                toggleKey: 'showItemRate',
                defaultToggle: true,
                labelKey: 'customRateHeader',
                fallbackLabel: 'Rate',
                hint: 'e.g. Unit Price, Price, Fee',
              ),
              const Divider(height: 24),

              // Discount Column
              fieldTileBuilder(
                title: 'Item Discount Column',
                description: 'Per-item discount rate (%)',
                toggleKey: 'showItemDiscount',
                defaultToggle: false,
                labelKey: 'customDiscountHeader',
                fallbackLabel: 'Discount',
                hint: 'e.g. Disc %, Rebate',
              ),
              const Divider(height: 24),

              // Item Tax Column
              fieldTileBuilder(
                title: 'Item Tax Column',
                description: 'Per-item tax rate (%)',
                toggleKey: 'showItemTax',
                defaultToggle: true,
                labelKey: 'customTaxHeader',
                fallbackLabel: 'Tax (%)',
                hint: 'e.g. GST %, VAT %',
              ),
              const Divider(height: 24),

              // Line Amount / Total Column
              fieldTileBuilder(
                title: 'Amount / Total Column',
                description: 'Total line amount calculation',
                toggleKey: 'showItemAmount',
                defaultToggle: true,
                labelKey: 'customAmountHeader',
                fallbackLabel: 'Amount',
                hint: 'e.g. Total, Net Amount',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CUSTOM COLUMNS IN LINE ITEMS
        customFieldsCardBuilder(
          key: 'customColumns_items',
          title: 'Line Items Table',
          itemType: 'Column',
          hintText: 'e.g. HSN/SAC Code, SKU / Barcode, Part #, Batch No.',
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Save All Invoice Customizations'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  String _formulaExplanation(String formula, double days) {
    final d = days > 0 ? days : 26.0;
    final dStr = d == d.toInt() ? d.toInt().toString() : '$d';
    switch (formula) {
      case 'calendar_month':
      case 'monthly_salary_calendar':
        return 'Calendar Month Auto-Days: Daily rate = Net Salary ÷ Month Days (e.g. 30/31/28 days). Salary = (Salary ÷ Month Days) × Duty Days. Example: (₹30,000 ÷ 30) × 21 = ₹21,000.';
      case 'monthly_salary_26':
      case 'monthly_salary':
        return 'Formula: (Staff × Duty × Salary) / $dStr. Example: 1 Guard × 26 Duties × ₹18,500 / 26 = ₹18,500.';
      case 'monthly_salary_30':
        return 'Formula: (Staff × Duty × Salary) / 30. Example: 1 Guard × 21 Duties × ₹30,000 / 30 = ₹21,000.';
      case 'per_duty':
        return 'Formula: Staff × Duty × Daily Rate. Example: 1 Guard × 26 Duties × ₹700/day = ₹18,200.';
      case 'flat_monthly':
        return 'Formula: Staff × Monthly Salary. Example: 1 Guard × ₹18,500 = ₹18,500.';
      case 'standard':
      default:
        return 'Formula: Quantity × Rate. Example: 10 units × ₹500 = ₹5,000.';
    }
  }
}
