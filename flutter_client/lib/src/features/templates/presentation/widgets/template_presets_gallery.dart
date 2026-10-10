import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import '../../data/template_config.dart';
import 'template_live_preview.dart';

class TemplatePresetsGallery extends StatelessWidget {
  const TemplatePresetsGallery({
    super.key,
    required this.selectedPresetId,
    required this.selectedCategory,
    required this.selectedStyle,
    required this.categories,
    required this.styles,
    required this.onSelectPreset,
    required this.onCategoryChanged,
    required this.onStyleChanged,
  });

  final String selectedPresetId;
  final String selectedCategory;
  final String selectedStyle;
  final List<(String, String)> categories;
  final List<String> styles;
  final ValueChanged<String> onSelectPreset;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = templatePresets.where((p) {
      final matchCat =
          selectedCategory == 'All' || p.businessCategory == selectedCategory;
      final matchStyle =
          selectedStyle == 'All' || p.designStyle == selectedStyle;
      return matchCat && matchStyle;
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Business Category & Style Templates',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${filtered.length} Templates',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select templates tailored for your industry (Security Agencies, Staffing, IT, Retail & GST) with specialized duty & salary formulas.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // 1. Business Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat.$1;
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
                      if (val) onCategoryChanged(cat.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Design Style Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Style: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                ...styles.map((style) {
                  final isSelected = selectedStyle == style;
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
                        onStyleChanged(style);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Grid of Filtered Templates
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 550 ? 1.4 : 1.15,
                ),
                itemBuilder: (context, index) {
                  final preset = filtered[index];
                  final selected = preset.id == selectedPresetId;
                  final color = parseHexColor(preset.color);

                  return InkWell(
                    onTap: () => onSelectPreset(preset.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.border,
                          width: selected ? 2.2 : 1,
                        ),
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08)
                            : Theme.of(context).colorScheme.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  preset.businessCategory,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    size: 16, color: Color(0xFF10B981)),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            preset.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  preset.designStyle,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (preset.showDuty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'Duty Calc',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
