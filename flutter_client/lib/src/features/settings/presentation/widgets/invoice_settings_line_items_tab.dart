import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

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
}
