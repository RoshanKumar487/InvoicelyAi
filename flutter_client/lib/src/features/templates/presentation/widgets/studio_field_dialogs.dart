import 'package:flutter/material.dart';

import '../../data/studio_section_model.dart';
import 'formula_builder_popup.dart';

class StudioAddFieldDialog extends StatelessWidget {
  const StudioAddFieldDialog({
    required this.section,
    required this.initialFormulaCode,
    required this.initialStandardDays,
    required this.onFieldAdded,
    super.key,
  });

  final StudioSection section;
  final String initialFormulaCode;
  final double initialStandardDays;
  final ValueChanged<StudioField> onFieldAdded;

  static void show(
    BuildContext context, {
    required StudioSection section,
    required String initialFormulaCode,
    required double initialStandardDays,
    required ValueChanged<StudioField> onFieldAdded,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StudioAddFieldDialog(
        section: section,
        initialFormulaCode: initialFormulaCode,
        initialStandardDays: initialStandardDays,
        onFieldAdded: onFieldAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelCtrl = TextEditingController();
    final defaultValCtrl = TextEditingController();
    final formulaCtrl = TextEditingController();
    StudioFieldType selectedType = StudioFieldType.text;
    bool isRequired = false;
    String currentFormulaCode = initialFormulaCode;
    double currentStandardDays = initialStandardDays;

    return StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Custom Field to "${section.title}"',
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Field Label *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Supervisor Name, Allowance, Shift Bonus',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Field Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<StudioFieldType>(
                value: selectedType,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: StudioFieldType.values.map<DropdownMenuItem<StudioFieldType>>((StudioFieldType t) {
                  return DropdownMenuItem<StudioFieldType>(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 16, color: const Color(0xFF475569)),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Default / Sample Value',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: defaultValCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Days, Yes/No, or empty',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Formula / Auto-Calculation (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: formulaCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. (Monthly Rate ÷ 30) × Qty × Duty',
                        isDense: true,
                        prefixIcon: const Icon(Icons.functions_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Open Formula Builder',
                    icon: const Icon(Icons.functions_rounded,
                        size: 18, color: Color(0xFF1D4ED8)),
                    onPressed: () async {
                      final res = await FormulaBuilderPopup.show(
                        context,
                        targetTitle: labelCtrl.text.trim().isNotEmpty
                            ? labelCtrl.text.trim()
                            : 'Custom Field',
                        initialFormulaCode: currentFormulaCode,
                        initialExpression: formulaCtrl.text.trim(),
                        initialStandardDays: currentStandardDays,
                      );
                      if (res != null) {
                        setDlgState(() {
                          formulaCtrl.text = res.formulaExpression;
                          currentFormulaCode = res.formulaCode;
                          currentStandardDays = res.standardDutyDays;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Required Field',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: isRequired,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) => setDlgState(() => isRequired = val),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final newField = StudioField(
                id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
                label: label,
                type: selectedType,
                isRequired: isRequired,
                defaultValue: defaultValCtrl.text.trim(),
                formula: formulaCtrl.text.trim(),
              );
              onFieldAdded(newField);
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Field'),
          ),
        ],
      ),
    );
  }
}

class StudioEditFieldDialog extends StatelessWidget {
  const StudioEditFieldDialog({
    required this.field,
    required this.initialFormulaCode,
    required this.initialStandardDays,
    required this.onSaveField,
    super.key,
  });

  final StudioField field;
  final String initialFormulaCode;
  final double initialStandardDays;
  final ValueChanged<StudioField> onSaveField;

  static void show(
    BuildContext context, {
    required StudioField field,
    required String initialFormulaCode,
    required double initialStandardDays,
    required ValueChanged<StudioField> onSaveField,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StudioEditFieldDialog(
        field: field,
        initialFormulaCode: initialFormulaCode,
        initialStandardDays: initialStandardDays,
        onSaveField: onSaveField,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelCtrl = TextEditingController(text: field.label);
    final defaultValCtrl = TextEditingController(text: field.defaultValue);
    final formulaCtrl = TextEditingController(text: field.formula);
    StudioFieldType selectedType = field.type;
    bool isRequired = field.isRequired;
    String currentFormulaCode = initialFormulaCode;
    double currentStandardDays = initialStandardDays;

    return StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Field "${field.label}"',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Field Label',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Field Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<StudioFieldType>(
                value: selectedType,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: StudioFieldType.values.map<DropdownMenuItem<StudioFieldType>>((StudioFieldType t) {
                  return DropdownMenuItem<StudioFieldType>(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 16, color: const Color(0xFF475569)),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Default Value',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: defaultValCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Formula / Auto-Calculation',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: formulaCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. (Monthly Rate ÷ 30) × Qty × Duty',
                        isDense: true,
                        prefixIcon: const Icon(Icons.functions_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Configure Formula in Popup',
                    icon: const Icon(Icons.functions_rounded,
                        size: 18, color: Color(0xFF1D4ED8)),
                    onPressed: () async {
                      final res = await FormulaBuilderPopup.show(
                        context,
                        targetTitle: labelCtrl.text.trim().isNotEmpty
                            ? labelCtrl.text.trim()
                            : field.label,
                        initialFormulaCode: currentFormulaCode,
                        initialExpression: formulaCtrl.text.trim(),
                        initialStandardDays: currentStandardDays,
                      );
                      if (res != null) {
                        setDlgState(() {
                          formulaCtrl.text = res.formulaExpression;
                          currentFormulaCode = res.formulaCode;
                          currentStandardDays = res.standardDutyDays;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Required Field',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: isRequired,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) => setDlgState(() => isRequired = val),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              field.label = label;
              field.type = selectedType;
              field.isRequired = isRequired;
              field.defaultValue = defaultValCtrl.text.trim();
              field.formula = formulaCtrl.text.trim();
              onSaveField(field);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
