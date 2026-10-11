import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
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
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth > 600 ? 0.95 : 0.82,
                ),
                itemBuilder: (context, index) {
                  final preset = filtered[index];
                  final selected = preset.id == selectedPresetId;
                  final color = parseHexColor(preset.color);

                  return InkWell(
                    onTap: () => onSelectPreset(preset.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: selected ? 2.2 : 1.0,
                        ),
                        color: selected
                            ? const Color(0xFFEFF6FF)
                            : Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(selected ? 15 : 6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mini Visual Invoice Sheet Representation
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Colored Header Stripe
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 24,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(180),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  // Mock Header Area
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(6, 5, 6, 3),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF94A3B8),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Container(
                                          width: 18,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Mock Mini Table Header
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(30),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  // Mock Table Rows
                                  for (int r = 0; r < 2; r++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFCBD5E1),
                                              borderRadius: BorderRadius.circular(1.5),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            width: 12,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(1.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  // Mock Total Box
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(25),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              fontSize: 6.5,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Template Title & Active Status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  preset.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                    color: selected ? const Color(0xFF1E3A8A) : null,
                                  ),
                                ),
                              ),
                              if (selected)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Badges Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  preset.designStyle,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (preset.showDuty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Duty / 26',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
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
