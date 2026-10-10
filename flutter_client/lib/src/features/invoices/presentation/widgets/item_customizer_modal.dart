import 'package:flutter/material.dart';

class ItemCustomizerModal extends StatefulWidget {
  const ItemCustomizerModal({
    required this.initialSettings,
    required this.onApply,
    this.onOpenInvoiceSettings,
    super.key,
  });

  final Map<String, Object?> initialSettings;
  final ValueChanged<Map<String, Object?>> onApply;
  final VoidCallback? onOpenInvoiceSettings;

  @override
  State<ItemCustomizerModal> createState() => _ItemCustomizerModalState();
}

class _ItemCustomizerModalState extends State<ItemCustomizerModal> {
  late final Map<String, Object?> tempSettings;
  late final TextEditingController itemHeaderCtrl;
  late final TextEditingController qtyHeaderCtrl;
  late final TextEditingController dutyHeaderCtrl;
  late final TextEditingController unitHeaderCtrl;
  late final TextEditingController rateHeaderCtrl;
  late final TextEditingController discountHeaderCtrl;
  late final TextEditingController taxHeaderCtrl;
  late final TextEditingController amountHeaderCtrl;

  @override
  void initState() {
    super.initState();
    tempSettings = Map<String, Object?>.from(widget.initialSettings);
    itemHeaderCtrl = TextEditingController(
      text: tempSettings['customItemHeader']?.toString() ?? 'Description',
    );
    qtyHeaderCtrl = TextEditingController(
      text: tempSettings['customQtyHeader']?.toString() ?? 'Qty',
    );
    dutyHeaderCtrl = TextEditingController(
      text: tempSettings['customDutyHeader']?.toString() ?? 'No. of Duty / Days',
    );
    unitHeaderCtrl = TextEditingController(
      text: tempSettings['customUnitHeader']?.toString() ?? 'Unit',
    );
    rateHeaderCtrl = TextEditingController(
      text: tempSettings['customRateHeader']?.toString() ?? 'Rate',
    );
    discountHeaderCtrl = TextEditingController(
      text: tempSettings['customDiscountHeader']?.toString() ?? 'Discount',
    );
    taxHeaderCtrl = TextEditingController(
      text: tempSettings['customTaxHeader']?.toString() ?? 'Tax',
    );
    amountHeaderCtrl = TextEditingController(
      text: tempSettings['customAmountHeader']?.toString() ?? 'Amount',
    );
  }

  @override
  void dispose() {
    itemHeaderCtrl.dispose();
    qtyHeaderCtrl.dispose();
    dutyHeaderCtrl.dispose();
    unitHeaderCtrl.dispose();
    rateHeaderCtrl.dispose();
    discountHeaderCtrl.dispose();
    taxHeaderCtrl.dispose();
    amountHeaderCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String presetId) {
    setState(() {
      tempSettings['industryPresetId'] = presetId;
      switch (presetId) {
        case 'security':
          tempSettings['customTitle'] = 'TAX INVOICE';
          tempSettings['customItemHeader'] = 'Designation / Post';
          tempSettings['customQtyHeader'] = 'No. of Staff / Guards';
          tempSettings['customDutyHeader'] = 'No. of Duty / Days';
          tempSettings['customUnitHeader'] = 'Duty / Shift';
          tempSettings['customRateHeader'] = 'Rate / Salary per Month';
          tempSettings['customDiscountHeader'] = 'Deductions';
          tempSettings['customTaxHeader'] = 'GST (18%)';
          tempSettings['customAmountHeader'] = 'Total Amount';
          tempSettings['showItemDuty'] = true;
          tempSettings['showItemUnit'] = true;
          tempSettings['showItemQty'] = true;
          tempSettings['showItemRate'] = true;
          tempSettings['showItemDiscount'] = false;
          tempSettings['showItemTax'] = true;
          itemHeaderCtrl.text = 'Designation / Post';
          qtyHeaderCtrl.text = 'No. of Staff / Guards';
          dutyHeaderCtrl.text = 'No. of Duty / Days';
          unitHeaderCtrl.text = 'Duty / Shift';
          rateHeaderCtrl.text = 'Rate / Salary per Month';
          discountHeaderCtrl.text = 'Deductions';
          taxHeaderCtrl.text = 'GST (18%)';
          amountHeaderCtrl.text = 'Total Amount';
        case 'hr_staffing':
          tempSettings['customTitle'] = 'Staffing & Salary Invoice';
          tempSettings['customItemHeader'] = 'Employee Name / Role';
          tempSettings['customQtyHeader'] = 'Staff Count';
          tempSettings['customDutyHeader'] = 'Days Worked';
          tempSettings['customUnitHeader'] = 'Days Worked';
          tempSettings['customRateHeader'] = 'Monthly Salary';
          tempSettings['customTaxHeader'] = 'GST (18%)';
          tempSettings['customAmountHeader'] = 'Total Salary Due';
          tempSettings['showItemDuty'] = true;
          tempSettings['showItemUnit'] = true;
          tempSettings['showItemQty'] = true;
          tempSettings['showItemRate'] = true;
          tempSettings['showItemDiscount'] = false;
          tempSettings['showItemTax'] = true;
          itemHeaderCtrl.text = 'Employee Name / Role';
          qtyHeaderCtrl.text = 'Staff Count';
          dutyHeaderCtrl.text = 'Days Worked';
          unitHeaderCtrl.text = 'Days Worked';
          rateHeaderCtrl.text = 'Monthly Salary';
          taxHeaderCtrl.text = 'GST (18%)';
          amountHeaderCtrl.text = 'Total Salary Due';
        case 'gst':
          tempSettings['customItemHeader'] = 'Goods / Services';
          tempSettings['customQtyHeader'] = 'Qty';
          tempSettings['customUnitHeader'] = 'Unit';
          tempSettings['customRateHeader'] = 'Rate';
          tempSettings['customTaxHeader'] = 'GST Rate (%)';
          tempSettings['customAmountHeader'] = 'Total (INR)';
          tempSettings['showItemDuty'] = false;
          tempSettings['showItemTax'] = true;
          itemHeaderCtrl.text = 'Goods / Services';
          qtyHeaderCtrl.text = 'Qty';
          unitHeaderCtrl.text = 'Unit';
          rateHeaderCtrl.text = 'Rate';
          taxHeaderCtrl.text = 'GST Rate (%)';
          amountHeaderCtrl.text = 'Total (INR)';
        case 'it':
          tempSettings['customItemHeader'] = 'Milestone / Deliverable';
          tempSettings['customQtyHeader'] = 'Hours';
          tempSettings['customUnitHeader'] = 'hrs';
          tempSettings['customRateHeader'] = 'Hourly Rate';
          tempSettings['customTaxHeader'] = 'Tax (%)';
          tempSettings['customAmountHeader'] = 'Total Fee';
          tempSettings['showItemDuty'] = false;
          itemHeaderCtrl.text = 'Milestone / Deliverable';
          qtyHeaderCtrl.text = 'Hours';
          unitHeaderCtrl.text = 'hrs';
          rateHeaderCtrl.text = 'Hourly Rate';
          taxHeaderCtrl.text = 'Tax (%)';
          amountHeaderCtrl.text = 'Total Fee';
        case 'retail':
          tempSettings['customItemHeader'] = 'Product / Item';
          tempSettings['customQtyHeader'] = 'Quantity';
          tempSettings['customUnitHeader'] = 'Pcs';
          tempSettings['customRateHeader'] = 'Unit Price';
          tempSettings['customDiscountHeader'] = 'Discount (%)';
          tempSettings['customAmountHeader'] = 'Total';
          tempSettings['showItemDuty'] = false;
          tempSettings['showItemDiscount'] = true;
          itemHeaderCtrl.text = 'Product / Item';
          qtyHeaderCtrl.text = 'Quantity';
          unitHeaderCtrl.text = 'Pcs';
          rateHeaderCtrl.text = 'Unit Price';
          discountHeaderCtrl.text = 'Discount (%)';
          amountHeaderCtrl.text = 'Total';
      }
    });
  }

  Widget _presetChip(String id, String title, String subtitle) {
    final isSelected = tempSettings['industryPresetId'] == id ||
        (id == 'security' && (itemHeaderCtrl.text.contains('Guards') || itemHeaderCtrl.text.contains('Designation')));
    return InkWell(
      onTap: () => _applyPreset(id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 13, color: Color(0xFF2563EB)),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Columns & Industry Setup',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text(
                        'Customize column headers, duty/salary formulas & presets',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              '1-Click Business Industry Preset',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip('security', '🛡️ Security Agency & Guards', 'Designation, Staff, Duty, Rate/Salary'),
                _presetChip('hr_staffing', '👤 HR Staffing & Payroll', 'Staff, Days Worked, Monthly Salary'),
                _presetChip('gst', '⚖️ GST Tax Invoice', 'HSN/SAC, Qty, Rate, GST%'),
                _presetChip('it', '💻 IT & Consulting', 'Milestones, Hours, Hourly Rate'),
                _presetChip('retail', '🛍️ Retail Store', 'Product, Qty, Price, Discount'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Column Header Names',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: itemHeaderCtrl,
              decoration: const InputDecoration(
                labelText: 'Item / Service Column Name',
                hintText: 'e.g. Designation / Post, Particulars',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyHeaderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity / Staff Column Name',
                      hintText: 'e.g. No. of Staff, Qty',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: dutyHeaderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Duty / Days Column Name',
                      hintText: 'e.g. No. of Duty / Days',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: unitHeaderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit Badge Name',
                      hintText: 'e.g. Duty, Days, Shift',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: rateHeaderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rate / Salary Column Name',
                      hintText: 'e.g. Rate/Salary per Month',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountHeaderCtrl,
              decoration: const InputDecoration(
                labelText: 'Total Column Name',
                hintText: 'e.g. Total Amount, Amount',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Column Visibility Toggles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Duty / Days Column (Staff × Duty × Rate)', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Calculates Total = Staff × Duty Days × Rate', style: TextStyle(fontSize: 11)),
              value: tempSettings['showItemDuty'] == true,
              onChanged: (val) => setState(() => tempSettings['showItemDuty'] = val),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Unit Badge (Duty/Days/hrs)', style: TextStyle(fontSize: 13)),
              value: tempSettings['showItemUnit'] != false,
              onChanged: (val) => setState(() => tempSettings['showItemUnit'] = val),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Discount / Deduction Column', style: TextStyle(fontSize: 13)),
              value: tempSettings['showItemDiscount'] == true,
              onChanged: (val) => setState(() => tempSettings['showItemDiscount'] = val),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Item Tax Column', style: TextStyle(fontSize: 13)),
              value: tempSettings['showItemTax'] != false,
              onChanged: (val) => setState(() => tempSettings['showItemTax'] = val),
            ),
            const SizedBox(height: 16),
            if (widget.onOpenInvoiceSettings != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOpenInvoiceSettings!();
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Open Full Invoice Settings Page (Logo, Bank, Sign)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                final applied = Map<String, Object?>.from(tempSettings)
                  ..['customItemHeader'] = itemHeaderCtrl.text.trim()
                  ..['customQtyHeader'] = qtyHeaderCtrl.text.trim()
                  ..['customDutyHeader'] = dutyHeaderCtrl.text.trim()
                  ..['customUnitHeader'] = unitHeaderCtrl.text.trim()
                  ..['customRateHeader'] = rateHeaderCtrl.text.trim()
                  ..['customDiscountHeader'] = discountHeaderCtrl.text.trim()
                  ..['customTaxHeader'] = taxHeaderCtrl.text.trim()
                  ..['customAmountHeader'] = amountHeaderCtrl.text.trim();
                widget.onApply(applied);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply to Invoice'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
}
