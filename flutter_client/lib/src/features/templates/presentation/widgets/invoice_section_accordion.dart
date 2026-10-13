import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: isExpanded
            ? const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
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
                  // Icon badge in rounded square
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: enabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: enabled ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        section.icon,
                        size: 20,
                        color: enabled ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
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
                            fontWeight: FontWeight.w700,
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
                  const SizedBox(width: 10),

                  // Field Count Badges
                  if (enabled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '$total fields',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
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
                  const SizedBox(width: 12),

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

                  // Chevron indicator
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content: Field Table
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              color: const Color(0xFFFAFAFA),
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
                          width: 38,
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
                          width: 60,
                          child: Text('Required', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 55,
                          child: Text('Visible', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 80,
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
    required VoidCallback onEdit,
    required VoidCallback onDuplicate,
    required VoidCallback onDelete,
  }) {
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
            width: 38,
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

          // Field Label
          Expanded(
            flex: 5,
            child: Text(
              field.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: field.isVisible ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            width: 60,
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
            width: 55,
            child: Transform.scale(
              scale: 0.72,
              child: Switch(
                value: field.isVisible,
                activeColor: const Color(0xFF2563EB),
                onChanged: onVisibilityChanged,
              ),
            ),
          ),

          // Actions: Edit, Duplicate, Delete
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
