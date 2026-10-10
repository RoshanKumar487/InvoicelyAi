import 'package:flutter/material.dart';

import '../../../templates/data/template_config.dart';
import 'invoice_preview_widgets.dart';

class TemplatePickerModal extends StatefulWidget {
  const TemplatePickerModal({
    required this.selectedId,
    required this.onSelectTemplate,
    required this.onSetDefault,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<TemplateConfig> onSelectTemplate;
  final ValueChanged<TemplateConfig> onSetDefault;

  @override
  State<TemplatePickerModal> createState() => _TemplatePickerModalState();
}

class _TemplatePickerModalState extends State<TemplatePickerModal> {
  String _selectedCategory = 'All';
  String _selectedStyle = 'All';
  late String? _currentId = widget.selectedId;

  static const _categories = [
    ('All', 'All Categories', Icons.apps_rounded),
    ('Security Agency', '🛡️ Security Agency', Icons.shield_outlined),
    ('HR & Staffing', '👥 HR & Staffing', Icons.people_outline_rounded),
    ('IT & Consulting', '💻 IT & Consulting', Icons.terminal_rounded),
    ('Retail & GST', '🛍️ Retail & GST', Icons.storefront_rounded),
    ('Corporate Suite', '🏢 Corporate Suite', Icons.apartment_rounded),
  ];

  static const _styles = [
    'All',
    'Modern',
    'Classic',
    'Corporate',
    'Smart',
    'Minimal',
    'Industry',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = templatePresets.where((TemplateConfig p) {
      final matchCat =
          _selectedCategory == 'All' || p.businessCategory == _selectedCategory;
      final matchStyle =
          _selectedStyle == 'All' || p.designStyle == _selectedStyle;
      return matchCat && matchStyle;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_rounded,
                      color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Invoice Template',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Industry presets with auto duty, rates & modern layouts',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Category Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Style Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Style: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
                ..._styles.map((style) {
                  final isSelected = _selectedStyle == style;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        style,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2563EB) : null,
                        ),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() => _selectedStyle = style);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 16),

          // Presets Grid / List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final preset = filtered[index];
                final isSelected = preset.id == _currentId;
                final color = parseTemplateColor(preset.color, Colors.blue);

                return InkWell(
                  onTap: () {
                    setState(() => _currentId = preset.id);
                    widget.onSelectTemplate(preset);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E3A8A).withAlpha(60)
                              : const Color(0xFFEFF6FF))
                          : (isDark
                              ? const Color(0xFF334155).withAlpha(50)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Color Pill & Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color, width: 1.5),
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      preset.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF475569)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      preset.businessCategory,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF3B82F6).withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Style: ${preset.designStyle}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  if (preset.showDuty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        preset.dutyHeader,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Set as Default button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            widget.onSetDefault(preset);
                            Navigator.pop(context);
                          },
                          child: const Text('Set Default',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
