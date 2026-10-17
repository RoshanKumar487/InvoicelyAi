import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/studio_section_model.dart';

class InvoiceSectionAccordion extends StatelessWidget {
  const InvoiceSectionAccordion({
    super.key,
    required this.section,
    required this.onEnabledChanged,
    required this.onExpansionChanged,
    required this.onFieldVisibilityChanged,
    required this.onAddField,
    required this.onEditField,
    required this.onDuplicateField,
    required this.onDeleteField,
    this.onFieldFormula,
    this.onSectionFormula,
    this.onSectionSettings,
    this.onDeleteSection,
    this.customContent,
  });

  final StudioSection section;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onExpansionChanged;
  final void Function(StudioField field, bool isVisible) onFieldVisibilityChanged;
  final VoidCallback onAddField;
  final ValueChanged<StudioField> onEditField;
  final ValueChanged<StudioField> onDuplicateField;
  final ValueChanged<StudioField> onDeleteField;
  final ValueChanged<StudioField>? onFieldFormula;
  final VoidCallback? onSectionFormula;
  final VoidCallback? onSectionSettings;
  final VoidCallback? onDeleteSection;
  final Widget? customContent;

  @override
  Widget build(BuildContext context) {
    final enabled = section.enabled;
    final isExpanded = section.isExpanded;
    final total = section.totalFieldCount;
    final visible = section.visibleFieldCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.neuCardDecoration(
        radius: 20,
        borderColor: isExpanded ? const Color(0xFF93C5FD) : Colors.white.withValues(alpha: 0.75),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header Tile
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Neumorphic circular icon orb
                  Container(
                    width: 40,
                    height: 40,
                    decoration: AppTheme.neuOrbDecoration(
                      isActive: isExpanded && enabled,
                      activeColor: const Color(0xFF2563EB),
                    ),
                    child: Center(
                      child: Icon(
                        section.icon,
                        size: 19,
                        color: (isExpanded && enabled)
                            ? Colors.white
                            : (enabled ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          section.subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Formula Icon Button on Section Header (Subtotal / Tax & Totals and Services & Duty)
                  if (onSectionFormula != null) ...[
                    Tooltip(
                      message: 'Formula & Daily Wage Auto-Calculation Settings',
                      child: InkWell(
                        onTap: onSectionFormula,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: AppTheme.neuPillDecoration(radius: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.functions_rounded, size: 15, color: Color(0xFF1D4ED8)),
                              SizedBox(width: 3),
                              Text(
                                'Formula',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Field Count Badges
                  if (enabled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: AppTheme.neuRecessedDecoration(radius: 12),
                      child: Text(
                        '$total fields',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        '$visible visible',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text(
                        'Hidden from invoice',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),

                  // Independent Master Switch (Toggling does NOT collapse accordion)
                  GestureDetector(
                    onTap: () {}, // Stop event propagation
                    child: Transform.scale(
                      scale: 0.82,
                      child: Switch(
                        value: enabled,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: onEnabledChanged,
                      ),
                    ),
                  ),

                  // Chevron indicator in Neumorphic mini-orb
                  Container(
                    width: 26,
                    height: 26,
                    decoration: AppTheme.neuOrbDecoration(),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content: Field Table
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFD5DCE6)),
            Container(
              color: AppColors.neuRecessed,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (customContent != null) ...[
                    customContent!,
                    const SizedBox(height: 12),
                  ],
                  // Field Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text('Field Label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text('Req.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text('Visible', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 104,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Field Rows
                  for (int i = 0; i < section.fields.length; i++) ...[
                    _buildFieldRow(
                      context: context,
                      index: i + 1,
                      field: section.fields[i],
                      onVisibilityChanged: (val) => onFieldVisibilityChanged(section.fields[i], val),
                      onFormula: onFieldFormula != null ? () => onFieldFormula!(section.fields[i]) : null,
                      onEdit: () => onEditField(section.fields[i]),
                      onDuplicate: () => onDuplicateField(section.fields[i]),
                      onDelete: () => onDeleteField(section.fields[i]),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Bottom Action Bar: + Add Custom Field, Status & Settings
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 15, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Add Custom Field',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: onAddField,
                      ),
                      if (onSectionFormula != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.functions_rounded, size: 15, color: Color(0xFF1D4ED8)),
                          label: const Text(
                            'Formula Setup',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: const Color(0xFFEFF6FF),
                          ),
                          onPressed: onSectionFormula,
                        ),
                      ],
                      const Spacer(),
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      const Text(
                        'Changes saved',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      if (onSectionSettings != null)
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 17, color: Color(0xFF64748B)),
                          tooltip: 'Section settings',
                          onPressed: onSectionSettings,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      if (onDeleteSection != null && !section.isLocked)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                          tooltip: 'Remove section',
                          onPressed: onDeleteSection,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required BuildContext context,
    required int index,
    required StudioField field,
    required ValueChanged<bool> onVisibilityChanged,
    VoidCallback? onFormula,
    required VoidCallback onEdit,
    required VoidCallback onDuplicate,
    required VoidCallback onDelete,
  }) {
    final hasFormula = field.formula.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Drag handle & index
          SizedBox(
            width: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator, size: 14, color: Color(0xFFCBD5E1)),
                const SizedBox(width: 2),
                Text(
                  '$index',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Field Label + optional active formula badge
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: field.isVisible ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasFormula)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.functions_rounded, size: 11, color: Color(0xFF2563EB)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            field.formula,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Type pill badge
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  field.type.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),

          // Required status
          SizedBox(
            width: 52,
            child: Text(
              field.isRequired ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 11.5,
                color: field.isRequired ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                fontWeight: field.isRequired ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Visible toggle
          SizedBox(
            width: 52,
            child: Transform.scale(
              scale: 0.72,
              child: Switch(
                value: field.isVisible,
                activeColor: const Color(0xFF2563EB),
                onChanged: onVisibilityChanged,
              ),
            ),
          ),

          // Actions: Formula Icon BEFORE Edit Icon, then Duplicate, Delete
          SizedBox(
            width: 104,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onFormula != null)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: hasFormula ? const Color(0xFFDBEAFE) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.functions_rounded,
                        size: 15,
                        color: hasFormula ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                    ),
                    tooltip: hasFormula
                        ? 'Formula: ${field.formula} (Click to configure)'
                        : 'Configure Formula / Auto-Calculation',
                    onPressed: onFormula,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
                  tooltip: 'Edit Field',
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                  tooltip: 'Duplicate Field',
                  onPressed: onDuplicate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                if (!field.isRequired)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    tooltip: 'Remove field from template',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  )
                else
                  const Tooltip(
                    message: 'Required field (cannot be removed)',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
